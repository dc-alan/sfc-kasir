import '../../../models/product.dart';

class PosState {
  final List<Product> products;
  final List<CartItem> cartItems;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const PosState({
    this.products = const [],
    this.cartItems = const [],
    this.totalAmount = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  PosState copyWith({
    List<Product>? products,
    List<CartItem>? cartItems,
    double? totalAmount,
    double? taxAmount,
    double? discountAmount,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return PosState(
      products: products ?? this.products,
      cartItems: cartItems ?? this.cartItems,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;
  final double subtotal;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.subtotal,
  });

  CartItem copyWith({Product? product, int? quantity, double? subtotal}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
