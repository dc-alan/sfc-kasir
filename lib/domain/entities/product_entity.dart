import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? categoryId;
  final String? categoryName;
  final double price;
  final double? costPrice;
  final String? unit;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.categoryId,
    this.categoryName,
    required this.price,
    this.costPrice,
    this.unit,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  double get profitMargin {
    if (costPrice == null || costPrice == 0) return 0;
    return ((price - costPrice!) / costPrice!) * 100;
  }

  double get profit {
    if (costPrice == null) return 0;
    return price - costPrice!;
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasSku => sku != null && sku!.isNotEmpty;

  bool get hasBarcode => barcode != null && barcode!.isNotEmpty;

  bool get hasCategory => categoryId != null && categoryId!.isNotEmpty;

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    String? categoryId,
    String? categoryName,
    double? price,
    double? costPrice,
    String? unit,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    sku,
    barcode,
    categoryId,
    categoryName,
    price,
    costPrice,
    unit,
    imageUrl,
    isActive,
    createdAt,
    updatedAt,
    metadata,
  ];
}

class ProductCategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductCategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRootCategory => parentId == null;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  ProductCategoryEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    parentId,
    imageUrl,
    isActive,
    createdAt,
    updatedAt,
  ];
}
