import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/transaction.dart' as model;
import '../services/promotion_service.dart';
import 'promotion_provider.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  Customer? _selectedCustomer;
  double _discount = 0.0;
  double _tax = 0.0;
  String? _notes;
  String? _appliedCouponCode;
  CartPromotionResult? _promotionResult;

  List<CartItem> get items => List.unmodifiable(_items.reversed);
  Customer? get selectedCustomer => _selectedCustomer;
  double get discount => _discount;
  double get tax => _tax;
  String? get notes => _notes;
  String? get appliedCouponCode => _appliedCouponCode;
  CartPromotionResult? get promotionResult => _promotionResult;

  double get subtotal {
    return _items.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => sum + item.discount) + _discount;
  }

  double get taxAmount {
    return (subtotal - totalDiscount) * (_tax / 100);
  }

  double get total {
    return subtotal - totalDiscount + taxAmount;
  }

  int get itemCount => _items.length;

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Update existing item
      final existingItem = _items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;

      if (newQuantity <= product.stock) {
        _items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      }
    } else {
      // Add new item
      if (quantity <= product.stock) {
        _items.add(
          CartItem(
            id: const Uuid().v4(),
            product: product,
            quantity: quantity,
            unitPrice: product.price,
          ),
        );
      }
    }

    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateItemQuantity(String itemId, int quantity) {
    final index = _items.indexWhere((item) => item.id == itemId);

    if (index >= 0) {
      final item = _items[index];

      if (quantity <= 0) {
        _items.removeAt(index);
      } else if (quantity <= item.product.stock) {
        _items[index] = item.copyWith(quantity: quantity);
      }

      notifyListeners();
    }
  }

  void updateItemDiscount(String itemId, double discount) {
    final index = _items.indexWhere((item) => item.id == itemId);

    if (index >= 0) {
      _items[index] = _items[index].copyWith(discount: discount);
      notifyListeners();
    }
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setDiscount(double discount) {
    _discount = discount;
    notifyListeners();
  }

  void setTax(double tax) {
    _tax = tax;
    notifyListeners();
  }

  void setNotes(String? notes) {
    _notes = notes;
    notifyListeners();
  }

  /// Apply promotions to cart
  void applyPromotions(PromotionProvider promotionProvider) {
    if (_items.isEmpty) {
      _promotionResult = null;
      return;
    }

    _promotionResult = PromotionService.instance.calculateCartDiscount(
      _items,
      promotionProvider,
      couponCode: _appliedCouponCode,
    );

    // Update individual item discounts
    for (final item in _items) {
      final itemDiscount = _promotionResult?.itemDiscounts[item.id];
      if (itemDiscount != null) {
        updateItemDiscount(item.id, itemDiscount.discount);
      }
    }

    notifyListeners();
  }

  /// Apply coupon code
  CouponResult applyCouponCode(
    String couponCode,
    PromotionProvider promotionProvider,
  ) {
    final result = PromotionService.instance.validateCouponCode(
      couponCode,
      _items,
      promotionProvider,
    );

    if (result.isValid) {
      _appliedCouponCode = couponCode;
      applyPromotions(promotionProvider);
    }

    return result;
  }

  /// Remove applied coupon
  void removeCoupon(PromotionProvider promotionProvider) {
    _appliedCouponCode = null;
    applyPromotions(promotionProvider);
  }

  /// Get promotion-adjusted totals
  double get promotionAdjustedSubtotal {
    return _promotionResult?.subtotal ?? subtotal;
  }

  double get promotionAdjustedDiscount {
    return _promotionResult?.totalDiscount ?? totalDiscount;
  }

  /// Auto-rounding discount to make change easier
  double get autoRoundingDiscount {
    final baseTotal = promotionAdjustedSubtotal - promotionAdjustedDiscount;
    final tax = baseTotal * (_tax / 100);
    final totalWithTax = baseTotal + tax;

    // Check if total ends with 50 or more (e.g., 385050)
    final remainder = totalWithTax % 100;
    if (remainder >= 50) {
      return remainder; // Discount the remainder to round down to nearest 100
    }
    return 0.0;
  }

  double get promotionAdjustedTotal {
    final adjustedSubtotal = promotionAdjustedSubtotal;
    final adjustedDiscount = promotionAdjustedDiscount;
    final tax = (adjustedSubtotal - adjustedDiscount) * (_tax / 100);
    final baseTotal = adjustedSubtotal - adjustedDiscount + tax;
    return baseTotal - autoRoundingDiscount;
  }

  /// Get detailed discount breakdown
  Map<String, double> get discountBreakdown {
    Map<String, double> breakdown = {};

    // Add individual item discounts
    if (_promotionResult != null) {
      for (final appliedPromo in _promotionResult!.appliedPromotions) {
        final promoName = appliedPromo.promotion.name;
        if (breakdown.containsKey(promoName)) {
          breakdown[promoName] =
              breakdown[promoName]! + appliedPromo.discountAmount;
        } else {
          breakdown[promoName] = appliedPromo.discountAmount;
        }
      }
    }

    // Add manual discount if any
    if (_discount > 0) {
      breakdown['Diskon Manual'] = _discount;
    }

    // Add auto-rounding discount
    if (autoRoundingDiscount > 0) {
      breakdown['Pembulatan'] = autoRoundingDiscount;
    }

    return breakdown;
  }

  /// Get total discount including auto-rounding
  double get totalDiscountWithRounding {
    return promotionAdjustedDiscount + autoRoundingDiscount;
  }

  /// Get applied promotions list
  List<AppliedPromotion> get appliedPromotions {
    return _promotionResult?.appliedPromotions ?? [];
  }

  /// Get discount for specific item
  PromotionResult? getItemPromotion(String itemId) {
    return _promotionResult?.itemDiscounts[itemId];
  }

  void clear() {
    _items.clear();
    _selectedCustomer = null;
    _discount = 0.0;
    _tax = 0.0;
    _notes = null;
    _appliedCouponCode = null;
    _promotionResult = null;
    notifyListeners();
  }

  void populateFromTransaction(model.Transaction transaction) {
    clear();

    // Add all items from the transaction
    for (final item in transaction.items) {
      _items.add(item);
    }

    // Set transaction details
    _selectedCustomer = transaction.customer;
    _discount = transaction.discount;
    _tax = transaction.subtotal > 0
        ? (transaction.tax / transaction.subtotal) * 100
        : 0.0; // Convert back to percentage
    _notes = transaction.notes;

    notifyListeners();
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
}
