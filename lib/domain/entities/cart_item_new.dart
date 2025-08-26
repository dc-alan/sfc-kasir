import 'package:freezed_annotation/freezed_annotation.dart';
import 'product_new.dart';

part 'cart_item_new.freezed.dart';
part 'cart_item_new.g.dart';

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required Product product,
    required int quantity,
    double? discount,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}

extension CartItemExtension on CartItem {
  double get subtotal {
    final discountAmount = discount ?? 0.0;
    final discountedPrice = product.price * (1 - discountAmount / 100);
    return discountedPrice * quantity;
  }
}
