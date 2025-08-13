class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final String? barcode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? promotionId;
  final double? discountPrice;
  final bool hasPromotion;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    this.barcode,
    required this.createdAt,
    required this.updatedAt,
    this.promotionId,
    this.discountPrice,
    this.hasPromotion = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'barcode': barcode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'promotion_id': promotionId,
      'discount_price': discountPrice,
      'has_promotion': hasPromotion ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'].toDouble(),
      stock: map['stock'],
      category: map['category'],
      barcode: map['barcode'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      promotionId: map['promotion_id'],
      discountPrice: map['discount_price']?.toDouble(),
      hasPromotion: (map['has_promotion'] ?? 0) == 1,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? promotionId,
    double? discountPrice,
    bool? hasPromotion,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      promotionId: promotionId ?? this.promotionId,
      discountPrice: discountPrice ?? this.discountPrice,
      hasPromotion: hasPromotion ?? this.hasPromotion,
    );
  }

  // Helper method to get effective price (with promotion if available)
  double get effectivePrice =>
      hasPromotion && discountPrice != null ? discountPrice! : price;

  // Helper method to get discount percentage
  double get discountPercentage {
    if (!hasPromotion || discountPrice == null) return 0.0;
    return ((price - discountPrice!) / price) * 100;
  }
}
