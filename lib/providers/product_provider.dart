import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/promotion_service.dart';
import 'promotion_provider.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  final DatabaseService _databaseService = DatabaseService();

  List<String> get categories {
    final categories = _products.map((p) => p.category).toSet().toList();
    categories.insert(0, 'Semua');
    return categories;
  }

  Future<void> loadProducts([PromotionProvider? promotionProvider]) async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _databaseService.getProducts();

      // Apply promotions to products if promotionProvider is available
      if (promotionProvider != null) {
        _applyPromotionsToProducts(promotionProvider);
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    try {
      await _databaseService.insertProduct(product);
      await loadProducts();
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _databaseService.updateProduct(product);
      await loadProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _databaseService.deleteProduct(productId);
      await loadProducts();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.barcode?.contains(_searchQuery) ?? false);

      final matchesCategory =
          _selectedCategory == 'Semua' || product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> getLowStockProducts() {
    return _products.where((product) => product.stock < 10).toList();
  }

  /// Apply active promotions to products
  void _applyPromotionsToProducts(PromotionProvider promotionProvider) {
    for (int i = 0; i < _products.length; i++) {
      final product = _products[i];
      final promotionResult = PromotionService.instance
          .calculateProductDiscount(product, promotionProvider);

      if (promotionResult.discount > 0 && promotionResult.promotion != null) {
        // Apply promotion to product
        _products[i] = product.copyWith(
          hasPromotion: true,
          discountPrice: promotionResult.finalPrice,
          promotionId: promotionResult.promotion!.id,
        );
      } else {
        // Only reset promotion data if product currently has promotion
        // This prevents overwriting products that should maintain their original state
        if (product.hasPromotion) {
          _products[i] = product.copyWith(
            hasPromotion: false,
            discountPrice: null,
            promotionId: null,
          );
        }
        // If product doesn't have promotion, leave it unchanged
      }
    }
  }

  /// Refresh products with current promotions
  void refreshWithPromotions(PromotionProvider promotionProvider) {
    _applyPromotionsToProducts(promotionProvider);
    _applyFilters();
    notifyListeners();
  }

  /// Test method to create sample promotions and apply them
  Future<void> testPromotions() async {
    try {
      // This method can be called from the UI to test promotions
      debugPrint('Testing promotion system...');

      // Count products with promotions
      final productsWithPromotions = _products
          .where((p) => p.hasPromotion)
          .length;
      debugPrint('Products with promotions: $productsWithPromotions');

      // Log some product details
      for (final product in _products.take(5)) {
        debugPrint('Product: ${product.name}');
        debugPrint('  - Has promotion: ${product.hasPromotion}');
        debugPrint('  - Original price: ${product.price}');
        debugPrint('  - Effective price: ${product.effectivePrice}');
        debugPrint('  - Discount percentage: ${product.discountPercentage}%');
      }
    } catch (e) {
      debugPrint('Error testing promotions: $e');
    }
  }
}
