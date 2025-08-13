class Supplier {
  final String id;
  final String name;
  final String code;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? taxId;
  final SupplierType type;
  final SupplierStatus status;
  final PaymentTerms paymentTerms;
  final int creditDays;
  final double creditLimit;
  final double currentBalance;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isActive => status == SupplierStatus.active;
  bool get isOverCreditLimit => currentBalance > creditLimit;
  double get availableCredit => creditLimit - currentBalance;

  Supplier({
    required this.id,
    required this.name,
    required this.code,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.taxId,
    this.type = SupplierType.regular,
    this.status = SupplierStatus.active,
    this.paymentTerms = PaymentTerms.net30,
    this.creditDays = 30,
    this.creditLimit = 0.0,
    this.currentBalance = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'contact_person': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'tax_id': taxId,
      'type': type.toString(),
      'status': status.toString(),
      'payment_terms': paymentTerms.toString(),
      'credit_days': creditDays,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      contactPerson: map['contact_person'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      taxId: map['tax_id'],
      type: SupplierType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SupplierType.regular,
      ),
      status: SupplierStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => SupplierStatus.active,
      ),
      paymentTerms: PaymentTerms.values.firstWhere(
        (e) => e.toString() == map['payment_terms'],
        orElse: () => PaymentTerms.net30,
      ),
      creditDays: map['credit_days'] ?? 30,
      creditLimit: map['credit_limit']?.toDouble() ?? 0.0,
      currentBalance: map['current_balance']?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? code,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? taxId,
    SupplierType? type,
    SupplierStatus? status,
    PaymentTerms? paymentTerms,
    int? creditDays,
    double? creditLimit,
    double? currentBalance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      taxId: taxId ?? this.taxId,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      creditDays: creditDays ?? this.creditDays,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum SupplierType { regular, preferred, exclusive, dropship }

extension SupplierTypeExtension on SupplierType {
  String get displayName {
    switch (this) {
      case SupplierType.regular:
        return 'Regular';
      case SupplierType.preferred:
        return 'Preferred';
      case SupplierType.exclusive:
        return 'Eksklusif';
      case SupplierType.dropship:
        return 'Dropship';
    }
  }
}

enum SupplierStatus { active, inactive, suspended, blacklisted }

extension SupplierStatusExtension on SupplierStatus {
  String get displayName {
    switch (this) {
      case SupplierStatus.active:
        return 'Aktif';
      case SupplierStatus.inactive:
        return 'Tidak Aktif';
      case SupplierStatus.suspended:
        return 'Ditangguhkan';
      case SupplierStatus.blacklisted:
        return 'Blacklist';
    }
  }
}

enum PaymentTerms {
  cod, // Cash on Delivery
  net7, // Net 7 days
  net15, // Net 15 days
  net30, // Net 30 days
  net60, // Net 60 days
  net90, // Net 90 days
}

extension PaymentTermsExtension on PaymentTerms {
  String get displayName {
    switch (this) {
      case PaymentTerms.cod:
        return 'Cash on Delivery';
      case PaymentTerms.net7:
        return 'Net 7 Hari';
      case PaymentTerms.net15:
        return 'Net 15 Hari';
      case PaymentTerms.net30:
        return 'Net 30 Hari';
      case PaymentTerms.net60:
        return 'Net 60 Hari';
      case PaymentTerms.net90:
        return 'Net 90 Hari';
    }
  }

  int get days {
    switch (this) {
      case PaymentTerms.cod:
        return 0;
      case PaymentTerms.net7:
        return 7;
      case PaymentTerms.net15:
        return 15;
      case PaymentTerms.net30:
        return 30;
      case PaymentTerms.net60:
        return 60;
      case PaymentTerms.net90:
        return 90;
    }
  }
}

class PurchaseOrder {
  final String id;
  final String orderNumber;
  final String supplierId;
  final String locationId;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final PurchaseOrderStatus status;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? notes;
  final String createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final List<PurchaseOrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  bool get isOverdue =>
      expectedDate != null &&
      DateTime.now().isAfter(expectedDate!) &&
      status != PurchaseOrderStatus.received;
  bool get canBeReceived => status == PurchaseOrderStatus.approved;
  bool get canBeCancelled =>
      status == PurchaseOrderStatus.draft ||
      status == PurchaseOrderStatus.pending;

  PurchaseOrder({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.locationId,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    this.status = PurchaseOrderStatus.draft,
    required this.subtotal,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    this.notes,
    required this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'supplier_id': supplierId,
      'location_id': locationId,
      'order_date': orderDate.toIso8601String(),
      'expected_date': expectedDate?.toIso8601String(),
      'received_date': receivedDate?.toIso8601String(),
      'status': status.toString(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'notes': notes,
      'created_by': createdBy,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseOrder.fromMap(
    Map<String, dynamic> map, [
    List<PurchaseOrderItem>? items,
  ]) {
    return PurchaseOrder(
      id: map['id'],
      orderNumber: map['order_number'],
      supplierId: map['supplier_id'],
      locationId: map['location_id'],
      orderDate: DateTime.parse(map['order_date']),
      expectedDate: map['expected_date'] != null
          ? DateTime.parse(map['expected_date'])
          : null,
      receivedDate: map['received_date'] != null
          ? DateTime.parse(map['received_date'])
          : null,
      status: PurchaseOrderStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => PurchaseOrderStatus.draft,
      ),
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      tax: map['tax']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdBy: map['created_by'],
      approvedBy: map['approved_by'],
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'])
          : null,
      items: items ?? [],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class PurchaseOrderItem {
  final String id;
  final String purchaseOrderId;
  final String productId;
  final int quantity;
  final int receivedQuantity;
  final double unitPrice;
  final double discount;
  final double total;
  final String? notes;

  // Computed properties
  int get pendingQuantity => quantity - receivedQuantity;
  bool get isFullyReceived => receivedQuantity >= quantity;
  double get lineTotal => (quantity * unitPrice) - discount;

  PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.quantity,
    this.receivedQuantity = 0,
    required this.unitPrice,
    this.discount = 0.0,
    required this.total,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'product_id': productId,
      'quantity': quantity,
      'received_quantity': receivedQuantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total': total,
      'notes': notes,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'],
      purchaseOrderId: map['purchase_order_id'],
      productId: map['product_id'],
      quantity: map['quantity'] ?? 0,
      receivedQuantity: map['received_quantity'] ?? 0,
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      notes: map['notes'],
    );
  }
}

enum PurchaseOrderStatus {
  draft,
  pending,
  approved,
  partiallyReceived,
  received,
  cancelled,
}

extension PurchaseOrderStatusExtension on PurchaseOrderStatus {
  String get displayName {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.pending:
        return 'Menunggu Persetujuan';
      case PurchaseOrderStatus.approved:
        return 'Disetujui';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Sebagian Diterima';
      case PurchaseOrderStatus.received:
        return 'Diterima';
      case PurchaseOrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}
