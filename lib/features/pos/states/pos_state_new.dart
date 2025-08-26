import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/product_new.dart';
import '../../../domain/entities/cart_item_new.dart';

part 'pos_state_new.freezed.dart';

@freezed
class PosState with _$PosState {
  const factory PosState({
    @Default([]) List<Product> products,
    @Default([]) List<String> categories,
    @Default('Semua') String selectedCategory,
    @Default('') String searchQuery,
    @Default([]) List<CartItem> cartItems,
    @Default(0.0) double totalAmount,
  }) = _PosState;
}
