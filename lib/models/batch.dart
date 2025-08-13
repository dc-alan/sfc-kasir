class Batch {
  final String id;
  final String productId;
  final String batchNumber;
  final String? lotNumber;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int initialQuantity;
  final int currentQuantity;
  final double unitCost;
  final String? supplierId;
  final String? notes;
  final BatchStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isNearExpiry =>
      expiryDate != null &&
      DateTime.now().add(const Duration(days: 30)).isAfter(expiryDate!);
  int get soldQuantity => initialQuantity - currentQuantity;
  double get totalValue => currentQuantity * unitCost;

  Batch({
    required this.id,
    required this.productId,
    required this.batchNumber,
    this.lotNumber,
    this.manufactureDate,
    this.expiryDate,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.unitCost,
    this.supplierId,
    this.notes,
    this.status = BatchStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'batch_number': batchNumber,
      'lot_number': lotNumber,
      'manufacture_date': manufactureDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'initial_quantity': initialQuantity,
      'current_quantity': currentQuantity,
      'unit_cost': unitCost,
      'supplier_id': supplierId,
      'notes': notes,
      'status': status.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      productId: map['product_id'],
      batchNumber: map['batch_number'],
      lotNumber: map['lot_number'],
      manufactureDate: map['manufacture_date'] != null
          ? DateTime.parse(map['manufacture_date'])
          : null,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'])
          : null,
      initialQuantity: map['initial_quantity'] ?? 0,
      currentQuantity: map['current_quantity'] ?? 0,
      unitCost: map['unit_cost']?.toDouble() ?? 0.0,
      supplierId: map['supplier_id'],
      notes: map['notes'],
      status: BatchStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => BatchStatus.active,
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Batch copyWith({
    String? id,
    String? productId,
    String? batchNumber,
    String? lotNumber,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    int? initialQuantity,
    int? currentQuantity,
    double? unitCost,
    String? supplierId,
    String? notes,
    BatchStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Batch(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      batchNumber: batchNumber ?? this.batchNumber,
      lotNumber: lotNumber ?? this.lotNumber,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      unitCost: unitCost ?? this.unitCost,
      supplierId: supplierId ?? this.supplierId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum BatchStatus { active, expired, recalled, damaged, sold }

extension BatchStatusExtension on BatchStatus {
  String get displayName {
    switch (this) {
      case BatchStatus.active:
        return 'Aktif';
      case BatchStatus.expired:
        return 'Kadaluarsa';
      case BatchStatus.recalled:
        return 'Ditarik';
      case BatchStatus.damaged:
        return 'Rusak';
      case BatchStatus.sold:
        return 'Terjual';
    }
  }
}

class BatchMovement {
  final String id;
  final String batchId;
  final String locationId;
  final String? fromLocationId;
  final String? toLocationId;
  final BatchMovementType type;
  final int quantity;
  final String? reference;
  final String? notes;
  final String userId;
  final DateTime createdAt;

  BatchMovement({
    required this.id,
    required this.batchId,
    required this.locationId,
    this.fromLocationId,
    this.toLocationId,
    required this.type,
    required this.quantity,
    this.reference,
    this.notes,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batch_id': batchId,
      'location_id': locationId,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'type': type.toString(),
      'quantity': quantity,
      'reference': reference,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BatchMovement.fromMap(Map<String, dynamic> map) {
    return BatchMovement(
      id: map['id'],
      batchId: map['batch_id'],
      locationId: map['location_id'],
      fromLocationId: map['from_location_id'],
      toLocationId: map['to_location_id'],
      type: BatchMovementType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => BatchMovementType.adjusted,
      ),
      quantity: map['quantity'],
      reference: map['reference'],
      notes: map['notes'],
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

enum BatchMovementType {
  received,
  sold,
  transferred,
  adjusted,
  expired,
  damaged,
  recalled,
}

extension BatchMovementTypeExtension on BatchMovementType {
  String get displayName {
    switch (this) {
      case BatchMovementType.received:
        return 'Diterima';
      case BatchMovementType.sold:
        return 'Terjual';
      case BatchMovementType.transferred:
        return 'Transfer';
      case BatchMovementType.adjusted:
        return 'Penyesuaian';
      case BatchMovementType.expired:
        return 'Kadaluarsa';
      case BatchMovementType.damaged:
        return 'Rusak';
      case BatchMovementType.recalled:
        return 'Ditarik';
    }
  }
}
