import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/promotion.dart';
import '../services/database_service.dart';

class PromotionProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Promotion> _promotions = [];
  List<Promotion> _filteredPromotions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  PromotionType? _selectedType;

  List<Promotion> get promotions => _filteredPromotions;
  List<Promotion> get allPromotions => _promotions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  PromotionType? get selectedType => _selectedType;

  // Get active promotions
  List<Promotion> get activePromotions =>
      _promotions.where((p) => p.isValidNow()).toList();

  // Get promotions by type
  List<Promotion> getPromotionsByType(PromotionType type) =>
      _promotions.where((p) => p.type == type).toList();

  // Get active happy hour promotions
  List<Promotion> get activeHappyHourPromotions => _promotions
      .where((p) => p.type == PromotionType.happyHour && p.isHappyHourActive())
      .toList();

  // Get available coupons
  List<Promotion> get availableCoupons => _promotions
      .where((p) => p.type == PromotionType.coupon && p.isValidNow())
      .toList();

  // Get bundle deals
  List<Promotion> get bundleDeals => _promotions
      .where((p) => p.type == PromotionType.bundle && p.isValidNow())
      .toList();

  Future<void> loadPromotions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final promotionMaps = await _databaseService.getPromotions();
      _promotions = promotionMaps.map((map) => Promotion.fromMap(map)).toList();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading promotions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPromotion(Promotion promotion) async {
    try {
      await _databaseService.insertPromotion(promotion.toMap());
      _promotions.add(promotion);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding promotion: $e');
      rethrow;
    }
  }

  Future<void> updatePromotion(Promotion promotion) async {
    try {
      await _databaseService.updatePromotion(promotion.toMap());
      final index = _promotions.indexWhere((p) => p.id == promotion.id);
      if (index != -1) {
        _promotions[index] = promotion;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating promotion: $e');
      rethrow;
    }
  }

  Future<void> deletePromotion(String promotionId) async {
    try {
      await _databaseService.deletePromotion(promotionId);
      _promotions.removeWhere((p) => p.id == promotionId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting promotion: $e');
      rethrow;
    }
  }

  Future<void> togglePromotionStatus(String promotionId) async {
    try {
      final promotion = _promotions.firstWhere((p) => p.id == promotionId);
      final updatedPromotion = promotion.copyWith(
        isActive: !promotion.isActive,
      );
      await updatePromotion(updatedPromotion);
    } catch (e) {
      debugPrint('Error toggling promotion status: $e');
      rethrow;
    }
  }

  void searchPromotions(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByType(PromotionType? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredPromotions = _promotions.where((promotion) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          promotion.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          promotion.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (promotion.couponCode?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesType =
          _selectedType == null || promotion.type == _selectedType;

      return matchesSearch && matchesType;
    }).toList();

    // Sort by creation date (newest first)
    _filteredPromotions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Validate coupon code
  Promotion? validateCouponCode(String code) {
    try {
      return _promotions.firstWhere(
        (p) =>
            p.type == PromotionType.coupon &&
            p.couponCode?.toLowerCase() == code.toLowerCase() &&
            p.isValidNow(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get applicable promotions for products
  List<Promotion> getApplicablePromotions(
    List<String> productIds,
    List<String> categories,
  ) {
    return activePromotions.where((promotion) {
      // Check if promotion applies to any of the products
      if (promotion.applicableProductIds.isNotEmpty) {
        return promotion.applicableProductIds.any(
          (id) => productIds.contains(id),
        );
      }

      // Check if promotion applies to any of the categories
      if (promotion.applicableCategories.isNotEmpty) {
        return promotion.applicableCategories.any(
          (cat) => categories.contains(cat),
        );
      }

      // If no specific products or categories, applies to all
      return promotion.applicableProductIds.isEmpty &&
          promotion.applicableCategories.isEmpty;
    }).toList();
  }

  // Calculate best discount for a cart
  double calculateBestDiscount(
    double totalAmount,
    List<String> productIds,
    List<String> categories,
  ) {
    final applicablePromotions = getApplicablePromotions(
      productIds,
      categories,
    );

    double maxDiscount = 0.0;
    for (final promotion in applicablePromotions) {
      final discount = promotion.calculateDiscount(totalAmount);
      if (discount > maxDiscount) {
        maxDiscount = discount;
      }
    }

    return maxDiscount;
  }

  // Use coupon (increment usage count)
  Future<void> useCoupon(String promotionId) async {
    try {
      final promotion = _promotions.firstWhere((p) => p.id == promotionId);
      final updatedPromotion = promotion.copyWith(
        currentUsage: promotion.currentUsage + 1,
      );
      await updatePromotion(updatedPromotion);
    } catch (e) {
      debugPrint('Error using coupon: $e');
      rethrow;
    }
  }

  // Get promotion statistics
  Map<String, dynamic> getPromotionStats() {
    final now = DateTime.now();
    final activeCount = _promotions.where((p) => p.isValidNow()).length;
    final expiredCount = _promotions
        .where((p) => p.endDate.isBefore(now))
        .length;
    final upcomingCount = _promotions
        .where((p) => p.startDate.isAfter(now))
        .length;

    final totalUsage = _promotions.fold<int>(
      0,
      (sum, p) => sum + p.currentUsage,
    );
    final averageUsage = _promotions.isNotEmpty
        ? totalUsage / _promotions.length
        : 0.0;

    return {
      'total': _promotions.length,
      'active': activeCount,
      'expired': expiredCount,
      'upcoming': upcomingCount,
      'totalUsage': totalUsage,
      'averageUsage': averageUsage,
      'byType': {
        'discount': getPromotionsByType(PromotionType.discount).length,
        'coupon': getPromotionsByType(PromotionType.coupon).length,
        'happyHour': getPromotionsByType(PromotionType.happyHour).length,
        'bundle': getPromotionsByType(PromotionType.bundle).length,
      },
    };
  }

  // Create sample promotions for testing
  Future<void> createSamplePromotions() async {
    final samplePromotions = [
      // Percentage discount
      Promotion(
        id: const Uuid().v4(),
        name: 'Diskon Weekend 20%',
        description: 'Diskon 20% untuk semua produk di akhir pekan',
        type: PromotionType.discount,
        discountType: DiscountType.percentage,
        discountValue: 20.0,
        minimumPurchase: 50000.0,
        maxUsage: 100,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        applicableCategories: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Nominal discount
      Promotion(
        id: const Uuid().v4(),
        name: 'Potongan Rp 10.000',
        description:
            'Potongan langsung Rp 10.000 untuk pembelian minimal Rp 100.000',
        type: PromotionType.discount,
        discountType: DiscountType.nominal,
        discountValue: 10000.0,
        minimumPurchase: 100000.0,
        maxUsage: 50,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 15)),
        applicableCategories: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // BOGO promotion
      Promotion(
        id: const Uuid().v4(),
        name: 'BOGO Minuman',
        description: 'Beli 1 gratis 1 untuk semua minuman',
        type: PromotionType.discount,
        discountType: DiscountType.bogo,
        discountValue: 50.0, // 50% off for BOGO
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        applicableCategories: ['Minuman'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Coupon
      Promotion(
        id: const Uuid().v4(),
        name: 'New User',
        description: 'Kupon khusus pengguna baru dengan diskon 15%',
        type: PromotionType.coupon,
        discountType: DiscountType.percentage,
        discountValue: 15.0,
        minimumPurchase: 25000.0,
        maxUsage: 200,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 60)),
        couponCode: 'NEWUSER',
        applicableCategories: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Happy Hour
      Promotion(
        id: const Uuid().v4(),
        name: 'Happy Hour 17:00-19:00',
        description: 'Diskon 25% untuk semua makanan pada jam 17:00-19:00',
        type: PromotionType.happyHour,
        discountType: DiscountType.percentage,
        discountValue: 25.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        happyHourStart: DateTime(2024, 1, 1, 17, 0), // 5 PM
        happyHourEnd: DateTime(2024, 1, 1, 19, 0), // 7 PM
        applicableCategories: ['Makanan'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Bundle Deal
      Promotion(
        id: const Uuid().v4(),
        name: 'Paket Hemat Makan Siang',
        description: 'Paket nasi + lauk + minuman dengan harga spesial',
        type: PromotionType.bundle,
        discountType: DiscountType.nominal,
        discountValue: 15000.0, // Total bundle price
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        bundleItems: [
          BundleItem(productId: 'sample-rice-id', quantity: 1),
          BundleItem(productId: 'sample-dish-id', quantity: 1),
          BundleItem(productId: 'sample-drink-id', quantity: 1),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Air Mineral 100% Discount (Max 5 items)
      Promotion(
        id: const Uuid().v4(),
        name: 'Air Mineral Gratis',
        description: 'Diskon 100% untuk air mineral, maksimal 5 pembelian',
        type: PromotionType.discount,
        discountType: DiscountType.percentage,
        discountValue: 100.0, // 100% discount
        maxQuantityPerItem: 5, // Maximum 5 items get the discount
        startDate: DateTime.now(),
        endDate: DateTime.now().add(
          const Duration(days: 365),
        ), // Valid for 1 year
        applicableProductIds: ['prod-026'], // Air Mineral product ID
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final promotion in samplePromotions) {
      try {
        await addPromotion(promotion);
      } catch (e) {
        debugPrint('Error creating sample promotion: $e');
      }
    }
  }
}
