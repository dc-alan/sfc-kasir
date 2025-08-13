import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart' as model;
import '../widgets/receipt_preview.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'Hari Ini';

  @override
  void initState() {
    super.initState();
    _setDateRange('Hari Ini');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  void _setDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Hari Ini':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate!.add(const Duration(days: 1));
          break;
        case 'Kemarin':
          _startDate = DateTime(now.year, now.month, now.day - 1);
          _endDate = _startDate!.add(const Duration(days: 1));
          break;
        case '7 Hari':
          _startDate = DateTime(now.year, now.month, now.day - 6);
          _endDate = DateTime(now.year, now.month, now.day + 1);
          break;
        case '30 Hari':
          _startDate = DateTime(now.year, now.month, now.day - 29);
          _endDate = DateTime(now.year, now.month, now.day + 1);
          break;
        case 'Bulan Ini':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 1);
          break;
      }
    });
  }

  void _loadTransactions() {
    context.read<TransactionProvider>().loadTransactions(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final primaryColor = Color(
          int.parse(
            settingsProvider.settings.primaryColor.replaceAll('#', '0xFF'),
          ),
        );

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: RefreshIndicator(
            onRefresh: () async => _loadTransactions(),
            color: primaryColor,
            child: Column(
              children: [
                _buildDateFilter(primaryColor),
                _buildSummaryCards(primaryColor),
                Expanded(child: _buildTransactionList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateFilter(Color primaryColor) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
        vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Filter Periode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                _getDateRangeText(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick period buttons
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                    'Hari Ini',
                    'Kemarin',
                    '7 Hari',
                    '30 Hari',
                    'Bulan Ini',
                    'Custom',
                  ].map((period) {
                    final isSelected =
                        period == _selectedPeriod ||
                        (period == 'Custom' &&
                            ![
                              'Hari Ini',
                              'Kemarin',
                              '7 Hari',
                              '30 Hari',
                              'Bulan Ini',
                            ].contains(_selectedPeriod));

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          period,
                          style: TextStyle(
                            color: isSelected ? Colors.white : primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? primaryColor
                              : primaryColor.withOpacity(0.3),
                        ),
                        onSelected: (selected) {
                          if (period == 'Custom') {
                            _showCustomDatePicker();
                          } else {
                            _setDateRange(period);
                            _loadTransactions();
                          }
                        },
                        elevation: isSelected ? 2 : 0,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final totalTransactions = provider.transactions.length;
        final totalRevenue = provider.getTotalRevenue();
        final totalItems = provider.transactions.fold<int>(
          0,
          (sum, transaction) =>
              sum +
              transaction.items.fold<int>(
                0,
                (itemSum, item) => itemSum + item.quantity,
              ),
        );

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
            vertical: ResponsiveHelper.isMobile(context) ? 4 : 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Transaksi',
                  totalTransactions.toString(),
                  Icons.receipt_long,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Pendapatan',
                  NumberFormat.compact(locale: 'id_ID').format(totalRevenue),
                  Icons.attach_money,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Item Terjual',
                  totalItems.toString(),
                  Icons.shopping_cart,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transaksi akan muncul di sini',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
          ),
          child: ListView.builder(
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final transaction = provider.transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(model.Transaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showTransactionDetail(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.receipt,
                  color: AppTheme.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi #${transaction.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(transaction.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPaymentMethodColor(
                              transaction.paymentMethod,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPaymentMethodText(transaction.paymentMethod),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getPaymentMethodColor(
                                transaction.paymentMethod,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${transaction.items.length} item',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(transaction.total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                  if (transaction.customer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.customer!.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateRangeText() {
    if (_startDate == null || _endDate == null) {
      return 'Semua transaksi';
    }

    final formatter = DateFormat('dd/MM/yyyy');
    final start = formatter.format(_startDate!);
    final end = formatter.format(_endDate!.subtract(const Duration(days: 1)));

    if (start == end) {
      return start;
    }

    return '$start - $end';
  }

  void _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(
              start: _startDate!,
              end: _endDate!.subtract(const Duration(days: 1)),
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Color(
                int.parse(
                  context
                      .read<SettingsProvider>()
                      .settings
                      .primaryColor
                      .replaceAll('#', '0xFF'),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom';
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(days: 1));
      });
      _loadTransactions();
    }
  }

  void _showTransactionDetail(model.Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: ResponsiveHelper.isMobile(context) ? null : 500,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Detail Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Transaction info
                _buildDetailRow(
                  'ID Transaksi',
                  '#${transaction.id.substring(0, 8).toUpperCase()}',
                ),
                _buildDetailRow(
                  'Tanggal',
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                ),
                _buildDetailRow(
                  'Metode Pembayaran',
                  _getPaymentMethodText(transaction.paymentMethod),
                ),
                if (transaction.customer != null)
                  _buildDetailRow('Pelanggan', transaction.customer!.name),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  _buildDetailRow('Catatan', transaction.notes!),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Items
                const Text(
                  'Item Pembelian',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ...transaction.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.product.price)} x ${item.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item.totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Summary
                _buildSummaryRow('Subtotal', transaction.subtotal),

                // Detailed discount breakdown
                ..._buildDiscountBreakdown(transaction),

                if (transaction.tax > 0)
                  _buildSummaryRow('Pajak', transaction.tax),
                const Divider(),
                _buildSummaryRow('Total', transaction.total, isTotal: true),
                _buildSummaryRow('Bayar', transaction.amountPaid),
                _buildSummaryRow('Kembalian', transaction.change),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showReceiptPreview(transaction);
                        },
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Ulang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
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
              fontSize: 12,
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
              color: isTotal ? AppTheme.successColor : null,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build detailed discount breakdown for transaction detail
  List<Widget> _buildDiscountBreakdown(model.Transaction transaction) {
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

  void _showReceiptPreview(model.Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => ReceiptPreview(
        transaction: transaction,
        cashierName: 'Kasir',
        onPrint: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Struk berhasil dicetak ulang'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
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

  Color _getPaymentMethodColor(model.PaymentMethod method) {
    switch (method) {
      case model.PaymentMethod.cash:
        return AppTheme.successColor;
      case model.PaymentMethod.card:
        return AppTheme.defaultPrimaryColor;
      case model.PaymentMethod.digital:
        return Colors.purple;
      case model.PaymentMethod.mixed:
        return AppTheme.warningColor;
    }
  }
}
