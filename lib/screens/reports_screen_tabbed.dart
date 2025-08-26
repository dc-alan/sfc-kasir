import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_file/open_file.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/bluetooth_printer_provider.dart';
import '../services/reports_service.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';

class ReportsScreenTabbed extends StatefulWidget {
  const ReportsScreenTabbed({super.key});

  @override
  State<ReportsScreenTabbed> createState() => _ReportsScreenTabbedState();
}

class _ReportsScreenTabbedState extends State<ReportsScreenTabbed>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'Bulan Ini';
  final ReportsService _reportsService = ReportsService();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setDateRange('Bulan Ini');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
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

  void _loadData() {
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
          appBar: AppBar(
            title: const Text('Laporan Bisnis'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.analytics), text: 'Global Reports'),
                Tab(icon: Icon(Icons.list_alt), text: 'Detail Reports'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildGlobalReportsTab(primaryColor),
              _buildDetailReportsTab(primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlobalReportsTab(Color primaryColor) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildDateFilter(primaryColor),
            if (_isExporting) _buildExportingIndicator(),
            _buildOverviewCards(primaryColor),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailReportsTab(Color primaryColor) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildDateFilter(primaryColor),
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'Report per Transaksi'),
                Tab(text: 'Report per Produk'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTransactionReportsTab(primaryColor),
                _buildProductReportsTab(primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionReportsTab(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Export buttons
            Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.transactions.isEmpty
                          ? null
                          : () => _exportTransactionsPDF(provider),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.transactions.isEmpty
                          ? null
                          : () => _exportTransactionsExcel(provider),
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.transactions.isEmpty
                          ? null
                          : () => _printTransactionsReport(provider),
                      icon: const Icon(Icons.print, color: Colors.blue),
                      label: const Text('Cetak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.transactions.isEmpty
                  ? const Center(child: Text('Tidak ada data transaksi'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = provider.transactions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: primaryColor,
                              ),
                            ),
                            title: Text(
                              'ID: ${transaction.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(transaction.createdAt),
                                ),
                                Text('Kasir: ${transaction.cashierId}'),
                                Text(
                                  'Metode: ${_getPaymentMethodText(transaction.paymentMethod.toString().split('.').last)}',
                                ),
                              ],
                            ),
                            trailing: Text(
                              _formatCurrency(transaction.total),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductReportsTab(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calculate product sales
        final Map<String, Map<String, dynamic>> productSales = {};
        for (var transaction in provider.transactions) {
          for (var item in transaction.items) {
            final productName = item.product.name;
            if (productSales.containsKey(productName)) {
              productSales[productName]!['quantity'] += item.quantity;
              productSales[productName]!['total'] += item.totalPrice;
            } else {
              productSales[productName] = {
                'quantity': item.quantity,
                'price': item.unitPrice,
                'total': item.totalPrice,
              };
            }
          }
        }

        final sortedProducts = productSales.entries.toList()
          ..sort((a, b) => b.value['quantity'].compareTo(a.value['quantity']));

        return Column(
          children: [
            // Export buttons
            Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.transactions.isEmpty
                          ? null
                          : () => _exportProductsPDF(provider),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.transactions.isEmpty
                          ? null
                          : () => _exportProductsExcel(provider),
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.transactions.isEmpty
                          ? null
                          : () => _printProductsReport(provider),
                      icon: const Icon(Icons.print, color: Colors.blue),
                      label: const Text('Cetak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product list
            Expanded(
              child: sortedProducts.isEmpty
                  ? const Center(child: Text('Tidak ada data produk'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedProducts.length,
                      itemBuilder: (context, index) {
                        final entry = sortedProducts[index];
                        final productName = entry.key;
                        final data = entry.value;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.fastfood, color: primaryColor),
                            ),
                            title: Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Qty Terjual: ${data['quantity']}'),
                                Text(
                                  'Harga Satuan: ${_formatCurrency(data['price'])}',
                                ),
                              ],
                            ),
                            trailing: Text(
                              _formatCurrency(data['total']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // Export and print methods
  Future<void> _exportTransactionsPDF(TransactionProvider provider) async {
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Pilih periode laporan terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final file = await _reportsService.generateTransactionsPDF(
        transactions: provider.transactions,
        startDate: _startDate!,
        endDate: _endDate!,
        settings: settingsProvider.settings,
      );
      await OpenFile.open(file.path);
      _showSnackBar('Laporan PDF transaksi berhasil dibuat');
    } catch (e) {
      _showSnackBar('Gagal mengekspor laporan: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportProductsPDF(TransactionProvider provider) async {
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Pilih periode laporan terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final file = await _reportsService.generateProductsPDF(
        transactions: provider.transactions,
        startDate: _startDate!,
        endDate: _endDate!,
        settings: settingsProvider.settings,
      );
      await OpenFile.open(file.path);
      _showSnackBar('Laporan PDF produk berhasil dibuat');
    } catch (e) {
      _showSnackBar('Gagal mengekspor laporan: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportTransactionsExcel(TransactionProvider provider) async {
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Pilih periode laporan terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final file = await _reportsService.generateTransactionsExcel(
        transactions: provider.transactions,
        startDate: _startDate!,
        endDate: _endDate!,
        settings: settingsProvider.settings,
      );
      await OpenFile.open(file.path);
      _showSnackBar('Laporan Excel transaksi berhasil dibuat');
    } catch (e) {
      _showSnackBar('Gagal mengekspor laporan: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportProductsExcel(TransactionProvider provider) async {
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Pilih periode laporan terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final file = await _reportsService.generateProductsExcel(
        transactions: provider.transactions,
        startDate: _startDate!,
        endDate: _endDate!,
        settings: settingsProvider.settings,
      );
      await OpenFile.open(file.path);
      _showSnackBar('Laporan Excel produk berhasil dibuat');
    } catch (e) {
      _showSnackBar('Gagal mengekspor laporan: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _printTransactionsReport(TransactionProvider provider) async {
    final printerProvider = context.read<BluetoothPrinterProvider>();

    if (!printerProvider.isConnected) {
      _showSnackBar(
        'Printer tidak terhubung. Hubungkan printer terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final settingsProvider = context.read<SettingsProvider>();
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
    } catch (e) {
      _showSnackBar('Gagal mencetak laporan: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _printProductsReport(TransactionProvider provider) async {
    final printerProvider = context.read<BluetoothPrinterProvider>();

    if (!printerProvider.isConnected) {
      _showSnackBar(
        'Printer tidak terhubung. Hubungkan printer terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final settingsProvider = context.read<SettingsProvider>();
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
    } catch (e) {
      _showSnackBar('Gagal mencetak laporan: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
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

          // Period selection
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
                            _loadData();
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
            'Sedang mengekspor laporan...',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            margin: const EdgeInsets.all(16),
            height: 120,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final totalRevenue = provider.getTotalRevenue();
        final totalTransactions = provider.getTotalTransactions();
        final avgTransaction = totalTransactions > 0
            ? totalRevenue / totalTransactions
            : 0;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
            vertical: ResponsiveHelper.isMobile(context) ? 4 : 8,
          ),
          child: Column(
            children: [
              // First row - main metrics
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      'Total Pendapatan',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(totalRevenue),
                      Icons.attach_money,
                      AppTheme.successColor,
                      'Total penjualan periode ini',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOverviewCard(
                      'Total Transaksi',
                      NumberFormat.decimalPattern(
                        'id_ID',
                      ).format(totalTransactions),
                      Icons.receipt_long,
                      primaryColor,
                      'Jumlah transaksi',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row - additional metrics
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      'Rata-rata Transaksi',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(avgTransaction),
                      Icons.trending_up,
                      AppTheme.warningColor,
                      'Nilai rata-rata per transaksi',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOverviewCard(
                      'Periode',
                      _selectedPeriod,
                      Icons.calendar_today,
                      Colors.purple,
                      'Periode laporan',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.grey.shade400, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  // Helper methods
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
    // Prepare initial date range, ensuring end date is not after today
    DateTimeRange? initialRange;
    if (_startDate != null && _endDate != null) {
      final now = DateTime.now();
      final endDate = _endDate!.subtract(const Duration(days: 1));

      // Ensure end date is not after today
      final validEndDate = endDate.isAfter(now)
          ? DateTime(now.year, now.month, now.day)
          : endDate;

      // Ensure start date is not after end date
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
      // Show time picker for start date
      final TimeOfDay? startTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

      if (startTime != null) {
        // Show time picker for end date
        final TimeOfDay? endTime = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 23, minute: 59),
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

        if (endTime != null) {
          setState(() {
            _selectedPeriod = 'Custom';
            _startDate = DateTime(
              picked.start.year,
              picked.start.month,
              picked.start.day,
              startTime.hour,
              startTime.minute,
            );
            _endDate = DateTime(
              picked.end.year,
              picked.end.month,
              picked.end.day,
              endTime.hour,
              endTime.minute,
            );
          });
          _loadData();
        }
      }
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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}
