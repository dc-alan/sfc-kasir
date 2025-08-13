import '../models/promotion.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../providers/promotion_provider.dart';

class PromotionService {
  static PromotionService? _instance;
  static PromotionService get instance => _instance ??= PromotionService._();
  PromotionService._();

  /// Calculate discount for a single product based on active promotions
  PromotionResult calculateProductDiscount(
    Product product,
    PromotionProvider promotionProvider,
  ) {
    final activePromotions = promotionProvider.activePromotions;
    double bestDiscount = 0.0;
    Promotion? bestPromotion;

    for (final promotion in activePromotions) {
      if (_isPromotionApplicableToProduct(promotion, product)) {
        final discount = _calculatePromotionDiscount(
          promotion,
          product.price,
          1,
        );
        if (discount > bestDiscount) {
          bestDiscount = discount;
          bestPromotion = promotion;
        }
      }
    }

    // Ensure finalPrice never goes below 0 and maintains original price when no promotion
    final finalPrice = bestDiscount > 0
        ? (product.price - bestDiscount).clamp(0.0, product.price)
        : product.price;

    return PromotionResult(
      discount: bestDiscount,
      promotion: bestPromotion,
      originalPrice: product.price,
      finalPrice: finalPrice,
    );
  }

  /// Calculate discount for cart items including bundle deals
  CartPromotionResult calculateCartDiscount(
    List<CartItem> cartItems,
    PromotionProvider promotionProvider, {
    String? couponCode,
  }) {
    double totalDiscount = 0.0;
    List<AppliedPromotion> appliedPromotions = [];
    Map<String, PromotionResult> itemDiscounts = {};

    // 1. Apply individual item discounts (including happy hour and quantity limits)
    for (final item in cartItems) {
      final activePromotions = promotionProvider.activePromotions;
      double bestDiscount = 0.0;
      Promotion? bestPromotion;

      for (final promotion in activePromotions) {
        if (_isPromotionApplicableToProduct(promotion, item.product)) {
          final discount = _calculatePromotionDiscount(
            promotion,
            item.product.price,
            item.quantity,
          );
          if (discount > bestDiscount) {
            bestDiscount = discount;
            bestPromotion = promotion;
          }
        }
      }

      if (bestDiscount > 0 && bestPromotion != null) {
        totalDiscount += bestDiscount;
        final originalPrice = item.product.price * item.quantity;
        final finalPrice = (originalPrice - bestDiscount).clamp(
          0.0,
          originalPrice,
        );

        itemDiscounts[item.id] = PromotionResult(
          discount: bestDiscount,
          promotion: bestPromotion,
          originalPrice: originalPrice,
          finalPrice: finalPrice,
        );

        appliedPromotions.add(
          AppliedPromotion(
            promotion: bestPromotion,
            discountAmount: bestDiscount,
            appliedToItems: [item.id],
          ),
        );
      }
    }

    // 2. Apply bundle deals
    final bundleResult = _calculateBundleDiscounts(
      cartItems,
      promotionProvider,
    );
    totalDiscount += bundleResult.totalDiscount;
    appliedPromotions.addAll(bundleResult.appliedPromotions);

    // 3. Apply coupon code if provided
    if (couponCode != null && couponCode.isNotEmpty) {
      final couponResult = _applyCouponCode(
        couponCode,
        cartItems,
        promotionProvider,
        totalDiscount,
      );
      if (couponResult.isValid) {
        totalDiscount += couponResult.discount;
        appliedPromotions.add(
          AppliedPromotion(
            promotion: couponResult.promotion!,
            discountAmount: couponResult.discount,
            appliedToItems: cartItems.map((item) => item.id).toList(),
          ),
        );
      }
    }

    // 4. Calculate cart totals
    final subtotal = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    return CartPromotionResult(
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      finalTotal: subtotal - totalDiscount,
      appliedPromotions: appliedPromotions,
      itemDiscounts: itemDiscounts,
    );
  }

  /// Validate and apply coupon code
  CouponResult validateCouponCode(
    String couponCode,
    List<CartItem> cartItems,
    PromotionProvider promotionProvider,
  ) {
    final coupon = promotionProvider.validateCouponCode(couponCode);
    if (coupon == null) {
      return CouponResult(
        isValid: false,
        message: 'Kode kupon tidak valid atau sudah kedaluwarsa',
      );
    }

    // Check usage limit
    if (coupon.maxUsage != null && coupon.currentUsage >= coupon.maxUsage!) {
      return CouponResult(
        isValid: false,
        message: 'Kupon sudah mencapai batas penggunaan',
      );
    }

    // Check minimum purchase
    final cartTotal = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    if (coupon.minimumPurchase != null && cartTotal < coupon.minimumPurchase!) {
      return CouponResult(
        isValid: false,
        message:
            'Minimum pembelian Rp ${coupon.minimumPurchase!.toStringAsFixed(0)} untuk menggunakan kupon ini',
      );
    }

    final discount = _calculatePromotionDiscount(coupon, cartTotal, 1);

    return CouponResult(
      isValid: true,
      promotion: coupon,
      discount: discount,
      message: 'Kupon berhasil diterapkan',
    );
  }

  /// Check if promotion is applicable to a product
  bool _isPromotionApplicableToProduct(Promotion promotion, Product product) {
    // Check if promotion is active
    if (!promotion.isValidNow()) return false;

    // Check happy hour timing
    if (promotion.type == PromotionType.happyHour) {
      if (!promotion.isHappyHourActive()) return false;
    }

    // Check applicable product IDs first (more specific)
    if (promotion.applicableProductIds.isNotEmpty) {
      return promotion.applicableProductIds.contains(product.id);
    }

    // Check applicable categories
    if (promotion.applicableCategories.isNotEmpty) {
      return promotion.applicableCategories.contains(product.category);
    }

    // If both applicableProductIds and applicableCategories are empty,
    // the promotion should NOT apply to any products (this prevents global application)
    // Only apply to all products if explicitly configured to do so
    return false;
  }

  /// Calculate discount amount based on promotion type
  double _calculatePromotionDiscount(
    Promotion promotion,
    double price,
    int quantity,
  ) {
    // Apply quantity limit if specified
    int discountableQuantity = quantity;
    if (promotion.maxQuantityPerItem != null) {
      discountableQuantity = quantity > promotion.maxQuantityPerItem!
          ? promotion.maxQuantityPerItem!
          : quantity;
    }

    switch (promotion.discountType) {
      case DiscountType.percentage:
        return (price * discountableQuantity) * (promotion.discountValue / 100);

      case DiscountType.nominal:
        return promotion.discountValue * discountableQuantity;

      case DiscountType.bogo:
        // For BOGO, give 50% discount (buy 1 get 1 free)
        final freeItems = discountableQuantity ~/ 2;
        return price * freeItems;
    }
  }

  /// Calculate bundle discounts
  BundleDiscountResult _calculateBundleDiscounts(
    List<CartItem> cartItems,
    PromotionProvider promotionProvider,
  ) {
    double totalDiscount = 0.0;
    List<AppliedPromotion> appliedPromotions = [];

    final bundleDeals = promotionProvider.bundleDeals;

    for (final bundle in bundleDeals) {
      if (bundle.bundleItems?.isEmpty ?? true) continue;

      // Check if cart contains all required bundle items
      bool canApplyBundle = true;
      Map<String, int> requiredItems = {};

      for (final bundleItem in bundle.bundleItems ?? []) {
        requiredItems[bundleItem.productId] = bundleItem.quantity;
      }

      for (final entry in requiredItems.entries) {
        final cartItem = cartItems
            .where((item) => item.product.id == entry.key)
            .firstOrNull;
        if (cartItem == null || cartItem.quantity < entry.value) {
          canApplyBundle = false;
          break;
        }
      }

      if (canApplyBundle) {
        // Calculate bundle discount
        double bundleOriginalPrice = 0.0;
        List<String> bundleItemIds = [];

        for (final entry in requiredItems.entries) {
          final cartItem = cartItems.firstWhere(
            (item) => item.product.id == entry.key,
          );
          bundleOriginalPrice += cartItem.product.price * entry.value;
          bundleItemIds.add(cartItem.id);
        }

        double bundleDiscount = 0.0;
        if (bundle.discountType == DiscountType.nominal) {
          // Bundle price is fixed, discount is difference
          bundleDiscount = bundleOriginalPrice - bundle.discountValue;
        } else if (bundle.discountType == DiscountType.percentage) {
          bundleDiscount = bundleOriginalPrice * (bundle.discountValue / 100);
        }

        if (bundleDiscount > 0) {
          totalDiscount += bundleDiscount;
          appliedPromotions.add(
            AppliedPromotion(
              promotion: bundle,
              discountAmount: bundleDiscount,
              appliedToItems: bundleItemIds,
            ),
          );
        }
      }
    }

    return BundleDiscountResult(
      totalDiscount: totalDiscount,
      appliedPromotions: appliedPromotions,
    );
  }

  /// Apply coupon code discount
  CouponResult _applyCouponCode(
    String couponCode,
    List<CartItem> cartItems,
    PromotionProvider promotionProvider,
    double currentDiscount,
  ) {
    final coupon = promotionProvider.validateCouponCode(couponCode);
    if (coupon == null) {
      return CouponResult(isValid: false, message: 'Kode kupon tidak valid');
    }

    final cartSubtotal = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    // Apply coupon to cart total after other discounts
    final discountableAmount = cartSubtotal - currentDiscount;
    final couponDiscount = _calculatePromotionDiscount(
      coupon,
      discountableAmount,
      1,
    );

    return CouponResult(
      isValid: true,
      promotion: coupon,
      discount: couponDiscount,
      message: 'Kupon berhasil diterapkan',
    );
  }
}

// Data classes for promotion results
class PromotionResult {
  final double discount;
  final Promotion? promotion;
  final double originalPrice;
  final double finalPrice;

  PromotionResult({
    required this.discount,
    this.promotion,
    required this.originalPrice,
    required this.finalPrice,
  });
}

class CartPromotionResult {
  final double subtotal;
  final double totalDiscount;
  final double finalTotal;
  final List<AppliedPromotion> appliedPromotions;
  final Map<String, PromotionResult> itemDiscounts;

  CartPromotionResult({
    required this.subtotal,
    required this.totalDiscount,
    required this.finalTotal,
    required this.appliedPromotions,
    required this.itemDiscounts,
  });
}

class AppliedPromotion {
  final Promotion promotion;
  final double discountAmount;
  final List<String> appliedToItems;

  AppliedPromotion({
    required this.promotion,
    required this.discountAmount,
    required this.appliedToItems,
  });
}

class CouponResult {
  final bool isValid;
  final Promotion? promotion;
  final double discount;
  final String message;

  CouponResult({
    required this.isValid,
    this.promotion,
    this.discount = 0.0,
    required this.message,
  });
}

class BundleDiscountResult {
  final double totalDiscount;
  final List<AppliedPromotion> appliedPromotions;

  BundleDiscountResult({
    required this.totalDiscount,
    required this.appliedPromotions,
  });
}
