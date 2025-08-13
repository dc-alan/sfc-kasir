import 'package:equatable/equatable.dart';

enum StockMovementType {
  stockIn,
  stockOut,
  adjustment,
  sale,
  return_,
  damaged,
  expired,
  transfer,
}

class InventoryEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productSku;
  final String? productBarcode;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final String? locationId;
  final String? locationName;
  final double? averageCost;
  final DateTime lastUpdated;
  final String? notes;

  const InventoryEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productBarcode,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    this.locationId,
    this.locationName,
    this.averageCost,
    required this.lastUpdated,
    this.notes,
  });

  bool get isLowStock => currentStock <= minStock;

  bool get isOutOfStock => currentStock <= 0;

  bool get isOverStock => maxStock > 0 && currentStock > maxStock;

  bool get isInStock => currentStock > 0;

  StockStatus get stockStatus {
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.lowStock;
    if (isOverStock) return StockStatus.overStock;
    return StockStatus.inStock;
  }

  double get stockValue {
    if (averageCost == null) return 0;
    return currentStock * averageCost!;
  }

  int get availableStock => currentStock > 0 ? currentStock : 0;

  InventoryEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    String? productBarcode,
    int? currentStock,
    int? minStock,
    int? maxStock,
    String? locationId,
    String? locationName,
    double? averageCost,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return InventoryEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      productBarcode: productBarcode ?? this.productBarcode,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      averageCost: averageCost ?? this.averageCost,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    productSku,
    productBarcode,
    currentStock,
    minStock,
    maxStock,
    locationId,
    locationName,
    averageCost,
    lastUpdated,
    notes,
  ];
}

enum StockStatus { inStock, lowStock, outOfStock, overStock }

class StockMovementEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final double? unitCost;
  final double? totalCost;
  final String? referenceId;
  final String? referenceType;
  final String? locationId;
  final String? locationName;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const StockMovementEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.unitCost,
    this.totalCost,
    this.referenceId,
    this.referenceType,
    this.locationId,
    this.locationName,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.notes,
    this.metadata,
  });

  bool get isStockIncrease =>
      [
        StockMovementType.stockIn,
        StockMovementType.return_,
        StockMovementType.adjustment,
      ].contains(type) &&
      quantity > 0;

  bool get isStockDecrease =>
      [
        StockMovementType.stockOut,
        StockMovementType.sale,
        StockMovementType.damaged,
        StockMovementType.expired,
        StockMovementType.adjustment,
      ].contains(type) &&
      quantity > 0;

  String get typeDisplayName {
    switch (type) {
      case StockMovementType.stockIn:
        return 'Stok Masuk';
      case StockMovementType.stockOut:
        return 'Stok Keluar';
      case StockMovementType.adjustment:
        return 'Penyesuaian';
      case StockMovementType.sale:
        return 'Penjualan';
      case StockMovementType.return_:
        return 'Retur';
      case StockMovementType.damaged:
        return 'Rusak';
      case StockMovementType.expired:
        return 'Kadaluarsa';
      case StockMovementType.transfer:
        return 'Transfer';
    }
  }

  double get totalValue {
    if (totalCost != null) return totalCost!;
    if (unitCost != null) return unitCost! * quantity;
    return 0;
  }

  StockMovementEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    StockMovementType? type,
    int? quantity,
    int? previousStock,
    int? newStock,
    double? unitCost,
    double? totalCost,
    String? referenceId,
    String? referenceType,
    String? locationId,
    String? locationName,
    String? userId,
    String? userName,
    DateTime? createdAt,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return StockMovementEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    type,
    quantity,
    previousStock,
    newStock,
    unitCost,
    totalCost,
    referenceId,
    referenceType,
    locationId,
    locationName,
    userId,
    userName,
    createdAt,
    notes,
    metadata,
  ];
}

class LocationEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocationEntity({
    required this.id,
    required this.name,
    this.description,
    this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  LocationEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
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
    address,
    isActive,
    createdAt,
    updatedAt,
  ];
}
