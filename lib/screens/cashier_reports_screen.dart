import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class CashierReportsScreen extends StatefulWidget {
  const CashierReportsScreen({super.key});

  @override
  State<CashierReportsScreen> createState() => _CashierReportsScreenState();
}

class _CashierReportsScreenState extends State<CashierReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();

  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, dynamic>? _selectedCashierReport;
  List<Map<String, dynamic>> _allCashiersPerformance = [];
  List<Map<String, dynamic>> _cashierRanking = [];

  bool _isLoading = true;
  String _selectedCashierId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 1);

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all cashiers performance
      final performance = await _databaseService.getAllCashiersPerformance(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Load cashier ranking
      final ranking = await _databaseService.getCashierRanking(
        startDate: _startDate,
        endDate: _endDate,
        sortBy: 'revenue',
      );

      setState(() {
        _allCashiersPerformance = performance;
        _cashierRanking = ranking;

        // Set default selected cashier to current user if available
        final currentUser = context.read<AuthProvider>().currentUser;
        if (currentUser != null && performance.isNotEmpty) {
          _selectedCashierId = currentUser.id;
          _loadCashierReport(_selectedCashierId);
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCashierReport(String cashierId) async {
    try {
      final report = await _databaseService.getCashierReport(
        cashierId,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _selectedCashierReport = report;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cashier report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Individual'),
            Tab(text: 'Perbandingan'),
            Tab(text: 'Ranking'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getDateRangeText(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIndividualTab(),
                      _buildComparisonTab(),
                      _buildRankingTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cashier Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Kasir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCashierId.isEmpty
                        ? null
                        : _selectedCashierId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _allCashiersPerformance.map((cashier) {
                      return DropdownMenuItem<String>(
                        value: cashier['id'],
                        child: Text(cashier['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCashierId = value;
                        });
                        _loadCashierReport(value);
                      }
                    },
                    hint: const Text('Pilih kasir...'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Individual Report
          if (_selectedCashierReport != null) ...[
            _buildCashierSummaryCards(),
            const SizedBox(height: 16),
            _buildDailyPerformanceChart(),
            const SizedBox(height: 16),
            _buildTopProductsList(),
            const SizedBox(height: 16),
            _buildPaymentMethodsChart(),
          ] else
            const Center(child: Text('Pilih kasir untuk melihat laporan')),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perbandingan Performa Kasir',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Comparison Cards
          ..._allCashiersPerformance.map(
            (cashier) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            cashier['name'].substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cashier['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '@${cashier['username']}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'Transaksi',
                            '${cashier['total_transactions']}',
                            Icons.receipt_long,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'Pendapatan',
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(
                              (cashier['total_revenue'] ?? 0).toDouble(),
                            ),
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'Rata-rata',
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(
                              (cashier['avg_transaction_value'] ?? 0)
                                  .toDouble(),
                            ),
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'Hari Aktif',
                            '${cashier['active_days']}',
                            Icons.calendar_today,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ranking Kasir',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Ranking List
          ..._cashierRanking.asMap().entries.map((entry) {
            final index = entry.key;
            final cashier = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getRankColor(index),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  cashier['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${cashier['total_transactions']} transaksi'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format((cashier['total_revenue'] ?? 0).toDouble()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (index == 0)
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCashierSummaryCards() {
    final summary = _selectedCashierReport!['summary'];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Total Transaksi',
          '${summary['total_transactions'] ?? 0}',
          Icons.receipt_long,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Total Pendapatan',
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format((summary['total_revenue'] ?? 0).toDouble()),
          Icons.attach_money,
          Colors.green,
        ),
        _buildSummaryCard(
          'Rata-rata Transaksi',
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format((summary['avg_transaction_value'] ?? 0).toDouble()),
          Icons.trending_up,
          Colors.orange,
        ),
        _buildSummaryCard(
          'Transaksi Tertinggi',
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format((summary['max_transaction'] ?? 0).toDouble()),
          Icons.star,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDailyPerformanceChart() {
    final dailyPerformance =
        _selectedCashierReport!['daily_performance'] as List;

    if (dailyPerformance.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Tidak ada data performa harian')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performa Harian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < dailyPerformance.length) {
                            final date = DateTime.parse(
                              dailyPerformance[value.toInt()]['date'],
                            );
                            return Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyPerformance.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['daily_revenue'].toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    final topProducts = _selectedCashierReport!['top_products'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produk Terlaris',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topProducts.isEmpty)
              const Center(child: Text('Tidak ada data penjualan produk'))
            else
              ...topProducts
                  .take(5)
                  .map(
                    (product) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.fastfood,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(product['product_name']),
                      subtitle: Text(product['category']),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${product['total_quantity']} terjual',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsChart() {
    final paymentMethods = _selectedCashierReport!['payment_methods'] as List;

    if (paymentMethods.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Tidak ada data metode pembayaran')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...paymentMethods.map(
              (method) => ListTile(
                leading: Icon(_getPaymentMethodIcon(method['payment_method'])),
                title: Text(_getPaymentMethodText(method['payment_method'])),
                subtitle: Text('${method['count']} transaksi'),
                trailing: Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format((method['total_amount'] ?? 0).toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return AppTheme.primaryColor;
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

  String _getDateRangeText() {
    if (_startDate == null || _endDate == null) {
      return 'Semua periode';
    }

    final formatter = DateFormat('dd/MM/yyyy');
    final start = formatter.format(_startDate!);
    final end = formatter.format(_endDate!.subtract(const Duration(days: 1)));

    return '$start - $end';
  }

  void _showDateRangePicker() async {
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
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(days: 1));
      });

      _loadData();
    }
  }
}
