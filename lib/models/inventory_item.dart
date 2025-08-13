class InventoryItem {
  final String id;
  final String productId;
  final String locationId;
  final int currentStock;
  final int reservedStock;
  final int availableStock;
  final int minStock;
  final int maxStock;
  final int reorderPoint;
  final int reorderQuantity;
  final double averageCost;
  final DateTime? lastRestocked;
  final DateTime? lastSold;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isLowStock => availableStock <= reorderPoint;
  bool get isOutOfStock => availableStock <= 0;
  bool get needsReorder => availableStock <= reorderPoint && reorderPoint > 0;
  int get stockValue => (currentStock * averageCost).round();

  InventoryItem({
    required this.id,
    required this.productId,
    required this.locationId,
    required this.currentStock,
    this.reservedStock = 0,
    this.minStock = 0,
    this.maxStock = 0,
    this.reorderPoint = 0,
    this.reorderQuantity = 0,
    this.averageCost = 0.0,
    this.lastRestocked,
    this.lastSold,
    required this.createdAt,
    required this.updatedAt,
  }) : availableStock = currentStock - reservedStock;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'location_id': locationId,
      'current_stock': currentStock,
      'reserved_stock': reservedStock,
      'min_stock': minStock,
      'max_stock': maxStock,
      'reorder_point': reorderPoint,
      'reorder_quantity': reorderQuantity,
      'average_cost': averageCost,
      'last_restocked': lastRestocked?.toIso8601String(),
      'last_sold': lastSold?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      productId: map['product_id'],
      locationId: map['location_id'],
      currentStock: map['current_stock'] ?? 0,
      reservedStock: map['reserved_stock'] ?? 0,
      minStock: map['min_stock'] ?? 0,
      maxStock: map['max_stock'] ?? 0,
      reorderPoint: map['reorder_point'] ?? 0,
      reorderQuantity: map['reorder_quantity'] ?? 0,
      averageCost: map['average_cost']?.toDouble() ?? 0.0,
      lastRestocked: map['last_restocked'] != null
          ? DateTime.parse(map['last_restocked'])
          : null,
      lastSold: map['last_sold'] != null
          ? DateTime.parse(map['last_sold'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  InventoryItem copyWith({
    String? id,
    String? productId,
    String? locationId,
    int? currentStock,
    int? reservedStock,
    int? minStock,
    int? maxStock,
    int? reorderPoint,
    int? reorderQuantity,
    double? averageCost,
    DateTime? lastRestocked,
    DateTime? lastSold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      locationId: locationId ?? this.locationId,
      currentStock: currentStock ?? this.currentStock,
      reservedStock: reservedStock ?? this.reservedStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      averageCost: averageCost ?? this.averageCost,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      lastSold: lastSold ?? this.lastSold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StockMovement {
  final String id;
  final String productId;
  final String locationId;
  final String? fromLocationId;
  final String? toLocationId;
  final StockMovementType type;
  final int quantity;
  final double unitCost;
  final String? batchNumber;
  final String? reference;
  final String? notes;
  final String userId;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.locationId,
    this.fromLocationId,
    this.toLocationId,
    required this.type,
    required this.quantity,
    this.unitCost = 0.0,
    this.batchNumber,
    this.reference,
    this.notes,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'location_id': locationId,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'type': type.toString(),
      'quantity': quantity,
      'unit_cost': unitCost,
      'batch_number': batchNumber,
      'reference': reference,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['product_id'],
      locationId: map['location_id'],
      fromLocationId: map['from_location_id'],
      toLocationId: map['to_location_id'],
      type: StockMovementType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => StockMovementType.adjustment,
      ),
      quantity: map['quantity'],
      unitCost: map['unit_cost']?.toDouble() ?? 0.0,
      batchNumber: map['batch_number'],
      reference: map['reference'],
      notes: map['notes'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

enum StockMovementType {
  stockIn, // Barang masuk
  stockOut, // Barang keluar
  transfer, // Transfer antar lokasi
  adjustment, // Penyesuaian stok
  sale, // Penjualan
  stockReturn, // Retur
  damaged, // Rusak
  expired, // Kadaluarsa
}

extension StockMovementTypeExtension on StockMovementType {
  String get displayName {
    switch (this) {
      case StockMovementType.stockIn:
        return 'Barang Masuk';
      case StockMovementType.stockOut:
        return 'Barang Keluar';
      case StockMovementType.transfer:
        return 'Transfer';
      case StockMovementType.adjustment:
        return 'Penyesuaian';
      case StockMovementType.sale:
        return 'Penjualan';
      case StockMovementType.stockReturn:
        return 'Retur';
      case StockMovementType.damaged:
        return 'Rusak';
      case StockMovementType.expired:
        return 'Kadaluarsa';
    }
  }

  bool get isInbound {
    return this == StockMovementType.stockIn ||
        this == StockMovementType.stockReturn ||
        (this == StockMovementType.adjustment);
  }

  bool get isOutbound {
    return this == StockMovementType.stockOut ||
        this == StockMovementType.sale ||
        this == StockMovementType.damaged ||
        this == StockMovementType.expired;
  }
}
