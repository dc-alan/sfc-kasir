import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transaction_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_helper.dart';
import '../widgets/custom_cards.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'Bulan Ini';

  @override
  void initState() {
    super.initState();
    _setDateRange('Bulan Ini');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
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
          body: RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildDateFilter(primaryColor),
                  _buildOverviewCards(primaryColor),
                  _buildRevenueSection(primaryColor),
                  _buildPaymentMethodSection(primaryColor),
                  _buildTopProductsSection(primaryColor),
                  const SizedBox(height: 20),
                ],
              ),
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
              Icon(Icons.analytics, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Laporan Bisnis',
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
                            _showCustomDatePicker();
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
        final activeDays = _getActiveDays(provider);

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
                      'Hari Aktif',
                      '$activeDays hari',
                      Icons.calendar_today,
                      Colors.purple,
                      'Hari dengan transaksi',
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

  Widget _buildRevenueSection(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const SizedBox.shrink();

        final dailyRevenue = provider.getDailyRevenue();
        if (dailyRevenue.isEmpty) return const SizedBox.shrink();

        final sortedEntries = dailyRevenue.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
            vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
          ),
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
                  Icon(Icons.show_chart, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tren Pendapatan Harian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Simple bar chart representation
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: sortedEntries.take(7).map((entry) {
                    final maxRevenue = sortedEntries
                        .map((e) => e.value)
                        .reduce((a, b) => a > b ? a : b);
                    final height = (entry.value / maxRevenue * 100).clamp(
                      10.0,
                      100.0,
                    );
                    final date = DateTime.parse(entry.key);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.8),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildPaymentMethodSection(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const SizedBox.shrink();

        final revenueByPayment = provider.getRevenueByPaymentMethod();
        final transactionsByPayment = provider.getTransactionsByPaymentMethod();

        if (revenueByPayment.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
            vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
          ),
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
                  Icon(Icons.payment, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...revenueByPayment.entries.map((entry) {
                final transactionCount = transactionsByPayment[entry.key] ?? 0;
                final color = _getPaymentMethodColor(entry.key);
                final totalRevenue = revenueByPayment.values.fold(
                  0.0,
                  (sum, value) => sum + value,
                );
                final percentage = totalRevenue > 0
                    ? (entry.value / totalRevenue * 100)
                    : 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getPaymentMethodIcon(entry.key),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPaymentMethodText(entry.key),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$transactionCount transaksi • ${percentage.toStringAsFixed(1)}%',
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
                        ).format(entry.value),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildTopProductsSection(Color primaryColor) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const SizedBox.shrink();

        final topProducts = provider.getTopSellingProducts();
        if (topProducts.isEmpty) return const SizedBox.shrink();

        final sortedProducts = topProducts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
            vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
          ),
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
                  Icon(Icons.star, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Produk Terlaris',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Top ${sortedProducts.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ...sortedProducts.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                final rankColors = [
                  Colors.amber,
                  Colors.grey.shade400,
                  Colors.brown.shade300,
                  primaryColor,
                  primaryColor,
                ];
                final rankColor = rankColors[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: rankColor,
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
                              product.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Terjual ${product.value} unit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          '${product.value}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }

  String _getDateRangeText() {
    if (_startDate == null || _endDate == null) {
      return 'Semua periode';
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
      _loadData();
    }
  }

  int _getActiveDays(TransactionProvider provider) {
    final dailyRevenue = provider.getDailyRevenue();
    return dailyRevenue.keys.length;
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

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'cash':
        return AppTheme.successColor;
      case 'card':
        return AppTheme.defaultPrimaryColor;
      case 'digital':
        return Colors.purple;
      case 'mixed':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }
}
