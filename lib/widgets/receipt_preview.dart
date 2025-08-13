import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as model;

class ReceiptPreview extends StatelessWidget {
  final model.Transaction transaction;
  final String cashierName;
  final VoidCallback? onPrint;

  const ReceiptPreview({
    super.key,
    required this.transaction,
    required this.cashierName,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Preview Struk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Receipt Content
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildReceiptContent(),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (onPrint != null) {
                          onPrint!();
                        }
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Store Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'TOKO SERBAGUNA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Jl. Contoh No. 123, Kota',
                  style: TextStyle(fontSize: 12),
                ),
                Text('Telp: (021) 1234-5678', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),

          // Transaction Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReceiptRow(
                  'No. Transaksi',
                  transaction.id.substring(0, 8),
                ),
                _buildReceiptRow(
                  'Tanggal',
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                ),
                _buildReceiptRow('Kasir', cashierName),
                if (transaction.customer != null)
                  _buildReceiptRow('Pelanggan', transaction.customer!.name),
                _buildReceiptRow(
                  'Metode Bayar',
                  _getPaymentMethodText(transaction.paymentMethod),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Items
                const Text(
                  'DETAIL PEMBELIAN',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...transaction.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity} x ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.unitPrice)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(),

                // Summary
                _buildSummaryRow('Subtotal', transaction.subtotal),

                // Detailed discount breakdown (if available)
                ..._buildDiscountBreakdown(),

                if (transaction.tax > 0)
                  _buildSummaryRow('Pajak', transaction.tax),

                const Divider(thickness: 2),

                _buildSummaryRow('TOTAL', transaction.total, isTotal: true),
                _buildSummaryRow('Bayar', transaction.amountPaid),
                _buildSummaryRow(
                  'Kembalian',
                  transaction.change,
                  isChange: true,
                ),

                const SizedBox(height: 16),

                // Footer
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'TERIMA KASIH',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Barang yang sudah dibeli tidak dapat dikembalikan',
                        style: TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                if (transaction.notes != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Text(
                    'Catatan: ${transaction.notes}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isChange = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
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
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal || isChange
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isTotal
                  ? Colors.blue.shade700
                  : isChange
                  ? Colors.green.shade700
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Build detailed discount breakdown
  List<Widget> _buildDiscountBreakdown() {
    List<Widget> discountWidgets = [];

    // Use stored discount breakdown if available
    if (transaction.discountBreakdown != null &&
        transaction.discountBreakdown!.isNotEmpty) {
      for (final entry in transaction.discountBreakdown!.entries) {
        discountWidgets.add(_buildSummaryRow(entry.key, -entry.value));
      }
    } else if (transaction.discount > 0) {
      // Fallback to old logic if no breakdown is stored
      discountWidgets.add(_buildSummaryRow('Diskon', -transaction.discount));
    }

    return discountWidgets;
  }

  String _getPaymentMethodText(model.PaymentMethod method) {
    switch (method) {
      case model.PaymentMethod.cash:
        return 'Tunai';
      case model.PaymentMethod.card:
        return 'Kartu';
      case model.PaymentMethod.digital:
        return 'Digital';
      case model.PaymentMethod.mixed:
        return 'Campuran';
    }
  }
}
