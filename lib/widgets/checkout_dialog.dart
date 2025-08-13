import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../providers/promotion_provider.dart';
import '../models/transaction.dart' as model;
import '../models/customer.dart';

class CheckoutDialog extends StatefulWidget {
  final Function({
    required model.PaymentMethod paymentMethod,
    required double amountPaid,
    Customer? customer,
    String? notes,
  })
  onCheckout;

  const CheckoutDialog({super.key, required this.onCheckout});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();

  model.PaymentMethod _selectedPaymentMethod = model.PaymentMethod.cash;
  Customer? _selectedCustomer;
  final double _taxRate = 0.0;
  final double _discountAmount = 0.0;
  String? _couponMessage;
  bool _isCouponValid = false;

  @override
  void initState() {
    super.initState();
    // Leave amount field empty initially
    _amountController.text = '';

    // Add listener to update change calculation in real-time
    _amountController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update the change calculation
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Dialog(
          child: Container(
            width: 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order summary
                          _buildOrderSummary(cartProvider),

                          const SizedBox(height: 20),

                          // Coupon code section
                          _buildCouponSection(cartProvider),

                          const SizedBox(height: 20),

                          // Payment method
                          const Text(
                            'Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPaymentMethodSelector(),

                          const SizedBox(height: 16),

                          // Amount paid
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah Bayar',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Jumlah bayar tidak boleh kosong';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null ||
                                  amount <
                                      cartProvider.promotionAdjustedTotal) {
                                return 'Jumlah bayar tidak mencukupi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Change calculation
                          _buildChangeCalculation(cartProvider),

                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Catatan (Opsional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed Action buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processCheckout,
                          child: const Text('Bayar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Items
          ...cartProvider.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.product.name} x${item.quantity}'),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(item.totalPrice),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Summary
          _buildSummaryRow('Subtotal', cartProvider.promotionAdjustedSubtotal),

          // Detailed discount breakdown
          ...cartProvider.discountBreakdown.entries.map(
            (entry) => _buildSummaryRow('${entry.key}', -entry.value),
          ),

          if (cartProvider.taxAmount > 0)
            _buildSummaryRow('Pajak', cartProvider.taxAmount),

          const Divider(),

          _buildSummaryRow(
            'Total',
            cartProvider.promotionAdjustedTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF2196F3) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Wrap(
      spacing: 8,
      children: model.PaymentMethod.values.map((method) {
        final isSelected = method == _selectedPaymentMethod;
        String label;
        IconData icon;

        switch (method) {
          case model.PaymentMethod.cash:
            label = 'Tunai';
            icon = Icons.money;
            break;
          case model.PaymentMethod.card:
            label = 'Kartu';
            icon = Icons.credit_card;
            break;
          case model.PaymentMethod.digital:
            label = 'Digital';
            icon = Icons.qr_code;
            break;
          case model.PaymentMethod.mixed:
            label = 'Campuran';
            icon = Icons.payment;
            break;
        }

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCouponSection(CartProvider cartProvider) {
    return Consumer<PromotionProvider>(
      builder: (context, promotionProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kode Promo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Coupon input field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan kode promo',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        suffixIcon: cartProvider.appliedCouponCode != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _couponController.clear();
                                  cartProvider.removeCoupon(promotionProvider);
                                  setState(() {
                                    _couponMessage = null;
                                    _isCouponValid = false;
                                  });
                                },
                              )
                            : null,
                      ),
                      enabled: cartProvider.appliedCouponCode == null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: cartProvider.appliedCouponCode != null
                        ? null
                        : () => _applyCoupon(cartProvider, promotionProvider),
                    child: Text(
                      cartProvider.appliedCouponCode != null
                          ? 'Diterapkan'
                          : 'Terapkan',
                    ),
                  ),
                ],
              ),

              // Coupon message
              if (_couponMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isCouponValid
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCouponValid ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: _isCouponValid
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _couponMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isCouponValid
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Applied promotions display
              if (cartProvider.appliedPromotions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Promo yang Diterapkan:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...cartProvider.appliedPromotions.map(
                  (appliedPromo) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appliedPromo.promotion.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        Text(
                          '-${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(appliedPromo.discountAmount)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangeCalculation(CartProvider cartProvider) {
    final amountPaid = double.tryParse(_amountController.text) ?? 0;
    final change = amountPaid - cartProvider.promotionAdjustedTotal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: change >= 0 ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Kembalian',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: change >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(change),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: change >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _applyCoupon(
    CartProvider cartProvider,
    PromotionProvider promotionProvider,
  ) {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) return;

    final result = cartProvider.applyCouponCode(couponCode, promotionProvider);

    setState(() {
      _couponMessage = result.message;
      _isCouponValid = result.isValid;
    });

    if (result.isValid) {
      _couponController.text = couponCode;
    }
  }

  void _processCheckout() {
    if (!_formKey.currentState!.validate()) return;

    final amountPaid = double.parse(_amountController.text);
    final notes = _notesController.text.trim();

    widget.onCheckout(
      paymentMethod: _selectedPaymentMethod,
      amountPaid: amountPaid,
      customer: _selectedCustomer,
      notes: notes.isEmpty ? null : notes,
    );

    Navigator.pop(context);
  }
}
