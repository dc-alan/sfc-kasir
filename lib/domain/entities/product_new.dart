import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_new.freezed.dart';
part 'product_new.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    required String category,
    required String imageUrl,
    required int stock,
    String? description,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
