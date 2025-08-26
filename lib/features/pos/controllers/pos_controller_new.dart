import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/pos_state_new.dart';
import '../../../domain/entities/product_new.dart';
import '../../../domain/entities/cart_item_new.dart';

class PosController extends StateNotifier<PosState> {
  PosController() : super(const PosState()) {
    _initializeProducts();
  }

  void _initializeProducts() {
    final products = [
      Product(
        id: '1',
        name: 'Nasi Goreng',
        price: 15000,
        category: 'Makanan',
        imageUrl: '',
        stock: 50,
      ),
      Product(
        id: '2',
        name: 'Mie Goreng',
        price: 12000,
        category: 'Makanan',
        imageUrl: '',
        stock: 30,
      ),
      Product(
        id: '3',
        name: 'Es Teh',
        price: 5000,
        category: 'Minuman',
        imageUrl: '',
        stock: 100,
      ),
      Product(
        id: '4',
        name: 'Kopi',
        price: 8000,
        category: 'Minuman',
        imageUrl: '',
        stock: 50,
      ),
    ];

    final categories = ['Semua', 'Makanan', 'Minuman'];

    state = state.copyWith(products: products, categories: categories);
  }

  void searchProducts(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void addToCart(Product product) {
    final existingItemIndex = state.cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.cartItems);
      final existingItem = updatedItems[existingItemIndex];
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      state = state.copyWith(cartItems: updatedItems);
    } else {
      final newItem = CartItem(product: product, quantity: 1);
      state = state.copyWith(cartItems: [...state.cartItems, newItem]);
    }

    _calculateTotal();
  }

  void removeFromCart(String productId) {
    final updatedItems = state.cartItems
        .where((item) => item.product.id != productId)
        .toList();

    state = state.copyWith(cartItems: updatedItems);
    _calculateTotal();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final updatedItems = state.cartItems.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(cartItems: updatedItems);
    _calculateTotal();
  }

  void applyDiscount(String productId, double discount) {
    final updatedItems = state.cartItems.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(discount: discount);
      }
      return item;
    }).toList();

    state = state.copyWith(cartItems: updatedItems);
    _calculateTotal();
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
    _calculateTotal();
  }

  void _calculateTotal() {
    final total = state.cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

    state = state.copyWith(totalAmount: total);
  }

  List<Product> get filteredProducts {
    var products = state.products;

    if (state.selectedCategory != 'Semua') {
      products = products
          .where((product) => product.category == state.selectedCategory)
          .toList();
    }

    if (state.searchQuery.isNotEmpty) {
      products = products
          .where(
            (product) => product.name.toLowerCase().contains(
              state.searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    return products;
  }
}

final posControllerProvider = StateNotifierProvider<PosController, PosState>(
  (ref) => PosController(),
);
