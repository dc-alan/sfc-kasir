import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double discount;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get totalPrice => (unitPrice * quantity) - discount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': product.id,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
    };
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? discount,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
    );
  }
}
