import 'cart_item.dart';
import 'customer.dart';

enum PaymentMethod { cash, card, digital, mixed }

class Transaction {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;
  final Customer? customer;
  final String cashierId;
  final DateTime createdAt;
  final String? notes;
  final Map<String, double>?
  discountBreakdown; // New field for detailed discounts

  Transaction({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    this.customer,
    required this.cashierId,
    required this.createdAt,
    this.notes,
    this.discountBreakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod.toString().split('.').last,
      'amount_paid': amountPaid,
      'change': change,
      'customer_id': customer?.id,
      'cashier_id': cashierId,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Transaction.fromMap(
    Map<String, dynamic> map,
    List<CartItem> items,
    Customer? customer,
  ) {
    return Transaction(
      id: map['id'],
      items: items,
      subtotal: map['subtotal'].toDouble(),
      tax: map['tax'].toDouble(),
      discount: map['discount'].toDouble(),
      total: map['total'].toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['payment_method'],
      ),
      amountPaid: map['amount_paid'].toDouble(),
      change: map['change'].toDouble(),
      customer: customer,
      cashierId: map['cashier_id'],
      createdAt: DateTime.parse(map['created_at']),
      notes: map['notes'],
    );
  }
}
