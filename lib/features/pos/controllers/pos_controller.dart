import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/pos_state.dart';
import '../../../models/product.dart';

final posControllerProvider = StateNotifierProvider<PosController, PosState>((
  ref,
) {
  return PosController();
});

class PosController extends StateNotifier<PosState> {
  PosController() : super(const PosState());

  void loadProducts(List<Product> products) {
    state = state.copyWith(products: products);
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
        subtotal: (existingItem.quantity + 1) * product.price,
      );
      state = state.copyWith(cartItems: updatedItems);
    } else {
      final newItem = CartItem(
        product: product,
        quantity: 1,
        subtotal: product.price,
      );
      state = state.copyWith(cartItems: [...state.cartItems, newItem]);
    }
    _calculateTotals();
  }

  void removeFromCart(String productId) {
    final updatedItems = state.cartItems
        .where((item) => item.product.id != productId)
        .toList();
    state = state.copyWith(cartItems: updatedItems);
    _calculateTotals();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final updatedItems = state.cartItems.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(
          quantity: newQuantity,
          subtotal: newQuantity * item.product.price,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(cartItems: updatedItems);
    _calculateTotals();
  }

  void clearCart() {
    state = state.copyWith(
      cartItems: [],
      totalAmount: 0.0,
      taxAmount: 0.0,
      discountAmount: 0.0,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  List<Product> getFilteredProducts() {
    if (state.searchQuery.isEmpty) return state.products;

    return state.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(
                state.searchQuery.toLowerCase(),
              ) ||
              (product.barcode?.toLowerCase().contains(
                    state.searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              product.category.toLowerCase().contains(
                state.searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    for (final item in state.cartItems) {
      subtotal += item.subtotal;
    }

    const taxRate = 0.1; // 10% tax
    final taxAmount = subtotal * taxRate;
    final totalAmount = subtotal + taxAmount - state.discountAmount;

    state = state.copyWith(totalAmount: totalAmount, taxAmount: taxAmount);
  }

  void applyDiscount(double discountAmount) {
    state = state.copyWith(discountAmount: discountAmount);
    _calculateTotals();
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}
