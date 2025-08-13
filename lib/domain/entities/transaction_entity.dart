import 'package:equatable/equatable.dart';

enum TransactionStatus {
  pending,
  completed,
  cancelled,
  refunded,
  partiallyRefunded,
}

enum PaymentMethod { cash, card, digitalWallet, bankTransfer, credit }

class TransactionEntity extends Equatable {
  final String id;
  final String transactionNumber;
  final DateTime transactionDate;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String cashierId;
  final String cashierName;
  final List<TransactionItemEntity> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const TransactionEntity({
    required this.id,
    required this.transactionNumber,
    required this.transactionDate,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.cashierId,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  bool get hasCustomer => customerId != null && customerId!.isNotEmpty;

  bool get isCompleted => status == TransactionStatus.completed;

  bool get isCancelled => status == TransactionStatus.cancelled;

  bool get isRefunded =>
      status == TransactionStatus.refunded ||
      status == TransactionStatus.partiallyRefunded;

  bool get canBeRefunded => isCompleted && !isRefunded;

  bool get canBeCancelled => status == TransactionStatus.pending;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalProfit =>
      items.fold(0.0, (sum, item) => sum + item.totalProfit);

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Menunggu';
      case TransactionStatus.completed:
        return 'Selesai';
      case TransactionStatus.cancelled:
        return 'Dibatalkan';
      case TransactionStatus.refunded:
        return 'Dikembalikan';
      case TransactionStatus.partiallyRefunded:
        return 'Dikembalikan Sebagian';
    }
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.card:
        return 'Kartu';
      case PaymentMethod.digitalWallet:
        return 'Dompet Digital';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.credit:
        return 'Kredit';
    }
  }

  TransactionEntity copyWith({
    String? id,
    String? transactionNumber,
    DateTime? transactionDate,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? cashierId,
    String? cashierName,
    List<TransactionItemEntity>? items,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? changeAmount,
    PaymentMethod? paymentMethod,
    TransactionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    transactionNumber,
    transactionDate,
    customerId,
    customerName,
    customerPhone,
    cashierId,
    cashierName,
    items,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    paidAmount,
    changeAmount,
    paymentMethod,
    status,
    notes,
    createdAt,
    updatedAt,
    metadata,
  ];
}

class TransactionItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productSku;
  final double unitPrice;
  final double? costPrice;
  final int quantity;
  final double discountAmount;
  final double totalPrice;
  final String? notes;

  const TransactionItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.unitPrice,
    this.costPrice,
    required this.quantity,
    required this.discountAmount,
    required this.totalPrice,
    this.notes,
  });

  double get subtotal => unitPrice * quantity;

  double get totalAfterDiscount => subtotal - discountAmount;

  double get unitProfit {
    if (costPrice == null) return 0;
    return unitPrice - costPrice!;
  }

  double get totalProfit {
    if (costPrice == null) return 0;
    return (unitPrice - costPrice!) * quantity;
  }

  double get discountPercentage {
    if (subtotal == 0) return 0;
    return (discountAmount / subtotal) * 100;
  }

  TransactionItemEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    double? unitPrice,
    double? costPrice,
    int? quantity,
    double? discountAmount,
    double? totalPrice,
    String? notes,
  }) {
    return TransactionItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    productSku,
    unitPrice,
    costPrice,
    quantity,
    discountAmount,
    totalPrice,
    notes,
  ];
}

class RefundEntity extends Equatable {
  final String id;
  final String transactionId;
  final String transactionNumber;
  final List<RefundItemEntity> items;
  final double refundAmount;
  final String reason;
  final String processedBy;
  final DateTime processedAt;
  final String? notes;

  const RefundEntity({
    required this.id,
    required this.transactionId,
    required this.transactionNumber,
    required this.items,
    required this.refundAmount,
    required this.reason,
    required this.processedBy,
    required this.processedAt,
    this.notes,
  });

  bool get isPartialRefund =>
      items.any((item) => item.quantity < item.originalQuantity);

  int get totalRefundedItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  RefundEntity copyWith({
    String? id,
    String? transactionId,
    String? transactionNumber,
    List<RefundItemEntity>? items,
    double? refundAmount,
    String? reason,
    String? processedBy,
    DateTime? processedAt,
    String? notes,
  }) {
    return RefundEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      items: items ?? this.items,
      refundAmount: refundAmount ?? this.refundAmount,
      reason: reason ?? this.reason,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    transactionId,
    transactionNumber,
    items,
    refundAmount,
    reason,
    processedBy,
    processedAt,
    notes,
  ];
}

class RefundItemEntity extends Equatable {
  final String transactionItemId;
  final String productId;
  final String productName;
  final int originalQuantity;
  final int quantity;
  final double unitPrice;
  final double refundAmount;

  const RefundItemEntity({
    required this.transactionItemId,
    required this.productId,
    required this.productName,
    required this.originalQuantity,
    required this.quantity,
    required this.unitPrice,
    required this.refundAmount,
  });

  bool get isPartialRefund => quantity < originalQuantity;

  RefundItemEntity copyWith({
    String? transactionItemId,
    String? productId,
    String? productName,
    int? originalQuantity,
    int? quantity,
    double? unitPrice,
    double? refundAmount,
  }) {
    return RefundItemEntity(
      transactionItemId: transactionItemId ?? this.transactionItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      originalQuantity: originalQuantity ?? this.originalQuantity,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      refundAmount: refundAmount ?? this.refundAmount,
    );
  }

  @override
  List<Object?> get props => [
    transactionItemId,
    productId,
    productName,
    originalQuantity,
    quantity,
    unitPrice,
    refundAmount,
  ];
}
