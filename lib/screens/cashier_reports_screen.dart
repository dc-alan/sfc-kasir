import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/bluetooth_printer_provider.dart';
import '../providers/auth_provider.dart';
import '../services/reports_service.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';

class CashierReportsScreen extends StatefulWidget {
  const CashierReportsScreen({super.key});

  @override
  State<CashierReportsScreen> createState() => _CashierReportsScreenState();
}

class _CashierReportsScreenState extends State<CashierReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'Bulan Ini';
  final ReportsService _reportsService = ReportsService();
  bool _isExporting = false;
  bool _isLoading = false;
  Map<String, dynamic>? _cashierReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setDateRange('Bulan Ini');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCashierData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        case 'Minggu Ini':
          final weekday = now.weekday;
          _startDate = DateTime(now.year, now.month, now.day - weekday + 1);
          _endDate = _startDate!.add(const Duration(days: 7));
          break;
        case 'Bulan Ini':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 1);
          break;
        case '3 Bulan':
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = DateTime(now.year, now.month + 1, 1);
          break;
        case 'Tahun Ini':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year + 1, 1, 1);
          break;
      }
    });
  }

  void _loadCashierData() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Load transactions for this cashier (filtered by cashier ID)
      context.read<TransactionProvider>().loadTransactions(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _cashierReport = {
          'cashier_info': {
            'name': authProvider.currentUser!.name,
            'username': authProvider.currentUser!.username,
          },
          'period': {
            'start_date':
                _startDate?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            'end_date':
                _endDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
          },
        };
      });
    } catch (e) {
      _showSnackBar('Gagal memuat data laporan: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
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
          appBar: AppBar(
            title: const Text('Laporan Kasir'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(
                  text: 'Laporan Transaksi',
                  icon: Icon(Icons.receipt_long, size: 20),
                ),
                Tab(
                  text: 'Laporan Produk',
                  icon: Icon(Icons.inventory, size: 20),
                ),
              ],
            ),
            actions: [
              Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  if (_isLoading || provider.transactions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) =>
                        _handleMenuAction(value, provider, settingsProvider),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'print_transactions',
                        child: Row(
                          children: [
                            Icon(Icons.print, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Print Laporan Transaksi'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'print_products',
                        child: Row(
                          children: [
                            Icon(Icons.print, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Print Laporan Produk'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_pdf_transactions',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Export PDF Transaksi'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_pdf_products',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Export PDF Produk'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Bluetooth printer connection status
              Consumer<BluetoothPrinterProvider>(
                builder: (context, printerProvider, child) {
                  return IconButton(
                    icon: Icon(
                      printerProvider.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: printerProvider.isConnected
                          ? Colors.green
                          : Colors.white70,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/bluetooth-printer');
                    },
                    tooltip: printerProvider.isConnected
                        ? 'Printer Terhubung'
                        : 'Hubungkan Printer',
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildDateFilter(primaryColor),
              if (_isExporting) _buildExportingIndicator(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsTab(primaryColor),
                    _buildProductsTab(primaryColor),
                  ],
                ),
              ),
            ],
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                    'Hari Ini',
                    'Minggu Ini',
                    'Bulan Ini',
                    '3 Bulan',
                    'Tahun Ini',
                    'Custom',
                  ].map((period) {
                    final isSelected =
                        period == _selectedPeriod ||
                        (period == 'Custom' &&
                            ![
                              'Hari Ini',
                              'Minggu Ini',
                              'Bulan Ini',
                              '3 Bulan',
                              'Tahun Ini',
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
                            _showCustomDateTimePicker();
                          } else {
                            _setDateRange(period);
                            _loadCashierData();
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

  Widget _buildExportingIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Sedang memproses laporan...',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (_isLoading) {
          return _buildLoadingIndicator();
        }

        if (provider.transactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Tidak ada transaksi pada periode ini',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadCashierData(),
          color: primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
              vertical: 8,
            ),
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final transaction = provider.transactions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.receipt,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaksi #${transaction.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(transaction.createdAt),
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
                          ).format(transaction.total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getPaymentMethodIcon(
                              transaction.paymentMethod
                                  .toString()
                                  .split('.')
                                  .last,
                            ),
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getPaymentMethodText(
                              transaction.paymentMethod
                                  .toString()
                                  .split('.')
                                  .last,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${transaction.items.length} item',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsTab(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (_isLoading) {
          return _buildLoadingIndicator();
        }

        if (provider.transactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Tidak ada data produk pada periode ini',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Aggregate product sales data
        final productSales = <String, Map<String, dynamic>>{};
        for (final transaction in provider.transactions) {
          for (final item in transaction.items) {
            final productName = item.product.name;
            if (productSales.containsKey(productName)) {
              productSales[productName]!['quantity'] += item.quantity;
              productSales[productName]!['total'] +=
                  item.quantity * item.product.price;
            } else {
              productSales[productName] = {
                'product': item.product,
                'quantity': item.quantity,
                'total': item.quantity * item.product.price,
              };
            }
          }
        }

        final sortedProducts = productSales.entries.toList()
          ..sort((a, b) => b.value['quantity'].compareTo(a.value['quantity']));

        return RefreshIndicator(
          onRefresh: () async => _loadCashierData(),
          color: primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
              vertical: 8,
            ),
            itemCount: sortedProducts.length,
            itemBuilder: (context, index) {
              final entry = sortedProducts[index];
              final productName = entry.key;
              final data = entry.value;
              final product = data['product'];
              final quantity = data['quantity'];
              final total = data['total'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.defaultPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.fastfood,
                        color: AppTheme.defaultPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Terjual $quantity unit • ${product.category}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$quantity',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
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
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data laporan...'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    String action,
    TransactionProvider provider,
    SettingsProvider settingsProvider,
  ) async {
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Pilih periode laporan terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      switch (action) {
        case 'print_transactions':
          await _printTransactionsReport(provider, settingsProvider);
          break;
        case 'print_products':
          await _printProductsReport(provider, settingsProvider);
          break;
        case 'export_pdf_transactions':
          await _exportTransactionsPDF(provider, settingsProvider);
          break;
        case 'export_pdf_products':
          await _exportProductsPDF(provider, settingsProvider);
          break;
      }
    } catch (e) {
      _showSnackBar('Gagal memproses laporan: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _printTransactionsReport(
    TransactionProvider provider,
    SettingsProvider settingsProvider,
  ) async {
    final printerProvider = context.read<BluetoothPrinterProvider>();

    if (!printerProvider.isConnected) {
      _showSnackBar(
        'Printer tidak terhubung. Hubungkan printer terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final success = await _reportsService.printTransactionsReport(
      transactions: provider.transactions,
      startDate: _startDate!,
      endDate: _endDate!,
      settings: settingsProvider.settings,
    );

    if (success) {
      _showSnackBar('Laporan transaksi berhasil dicetak');
    } else {
      _showSnackBar('Gagal mencetak laporan transaksi', isError: true);
    }
  }

  Future<void> _printProductsReport(
    TransactionProvider provider,
    SettingsProvider settingsProvider,
  ) async {
    final printerProvider = context.read<BluetoothPrinterProvider>();

    if (!printerProvider.isConnected) {
      _showSnackBar(
        'Printer tidak terhubung. Hubungkan printer terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final success = await _reportsService.printProductsReport(
      transactions: provider.transactions,
      startDate: _startDate!,
      endDate: _endDate!,
      settings: settingsProvider.settings,
    );

    if (success) {
      _showSnackBar('Laporan produk berhasil dicetak');
    } else {
      _showSnackBar('Gagal mencetak laporan produk', isError: true);
    }
  }

  Future<void> _exportTransactionsPDF(
    TransactionProvider provider,
    SettingsProvider settingsProvider,
  ) async {
    final file = await _reportsService.generateTransactionsPDF(
      transactions: provider.transactions,
      startDate: _startDate!,
      endDate: _endDate!,
      settings: settingsProvider.settings,
    );

    await OpenFile.open(file.path);
    _showSnackBar('Laporan PDF transaksi berhasil dibuat');
  }

  Future<void> _exportProductsPDF(
    TransactionProvider provider,
    SettingsProvider settingsProvider,
  ) async {
    final file = await _reportsService.generateProductsPDF(
      transactions: provider.transactions,
      startDate: _startDate!,
      endDate: _endDate!,
      settings: settingsProvider.settings,
    );

    await OpenFile.open(file.path);
    _showSnackBar('Laporan PDF produk berhasil dibuat');
  }

  String _getDateRangeText() {
    if (_startDate == null || _endDate == null) {
      return 'Semua periode';
    }

    if (DateFormat('dd/MM/yyyy').format(_startDate!) ==
        DateFormat(
          'dd/MM/yyyy',
        ).format(_endDate!.subtract(const Duration(days: 1)))) {
      return DateFormat('dd/MM/yyyy').format(_startDate!);
    }

    return '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!.subtract(const Duration(days: 1)))}';
  }

  void _showCustomDateTimePicker() async {
    DateTimeRange? initialRange;
    if (_startDate != null && _endDate != null) {
      final now = DateTime.now();
      final endDate = _endDate!.subtract(const Duration(days: 1));

      final validEndDate = endDate.isAfter(now)
          ? DateTime(now.year, now.month, now.day)
          : endDate;

      final validStartDate = _startDate!.isAfter(validEndDate)
          ? validEndDate
          : _startDate!;

      initialRange = DateTimeRange(start: validStartDate, end: validEndDate);
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
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
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
          0,
          0,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
        );
      });
      _loadCashierData();
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'card':
        return 'Kartu';
      case 'digital':
        return 'Digital';
      case 'mixed':
        return 'Campuran';
      default:
        return method;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'digital':
        return Icons.qr_code;
      case 'mixed':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
