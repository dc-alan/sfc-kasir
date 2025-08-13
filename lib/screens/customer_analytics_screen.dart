import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/crm_provider.dart';
import '../providers/auth_provider.dart';
import '../models/customer.dart';
import '../models/customer_loyalty.dart';
import '../utils/responsive_helper.dart';
import '../widgets/custom_cards.dart';
import '../widgets/loading_widgets.dart';
import '../utils/app_theme.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() =>
      _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedStartDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final crmProvider = context.read<CRMProvider>();
    await crmProvider.loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.people), text: 'Customers'),
            Tab(icon: Icon(Icons.loyalty), text: 'Loyalty'),
          ],
        ),
      ),
      body: Consumer<CRMProvider>(
        builder: (context, crmProvider, child) {
          if (crmProvider.isLoading) {
            return const LoadingOverlay(
              isLoading: true,
              message: 'Memuat data customer...',
              child: SizedBox.expand(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAnalyticsTab(crmProvider),
              _buildCustomersTab(crmProvider),
              _buildLoyaltyTab(crmProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsTab(CRMProvider provider) {
    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Info
            _buildDateRangeCard(),
            const SizedBox(height: 16),

            // Customer Statistics
            _buildCustomerStats(provider),
            const SizedBox(height: 24),

            // Customer Growth Chart
            _buildCustomerGrowthChart(provider),
            const SizedBox(height: 24),

            // Customer Segmentation
            _buildCustomerSegmentation(provider),
            const SizedBox(height: 24),

            // Top Customers
            _buildTopCustomers(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return ModernCard(
      child: Row(
        children: [
          Icon(Icons.date_range, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Periode Analisis',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_selectedStartDate)} - ${DateFormat('dd MMM yyyy').format(_selectedEndDate)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showDateRangePicker,
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStats(CRMProvider provider) {
    // Mock analytics data since the methods don't exist in CRMProvider
    final mockAnalytics = {
      'customer_growth_rate': 12.5,
      'active_customers': (provider.customers.length * 0.8).round(),
      'new_customers': (provider.customers.length * 0.2).round(),
      'avg_transaction_value': 75000.0,
    };

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StatCard(
              title: 'Total Customer',
              value: '${provider.customers.length}',
              icon: Icons.people,
              color: Colors.blue,
              showTrend: true,
              trendValue:
                  (mockAnalytics['customer_growth_rate'])?.toDouble() ?? 0.0,
            ),
            StatCard(
              title: 'Customer Aktif',
              value: '${mockAnalytics['active_customers'] ?? 0}',
              icon: Icons.person_outline,
              color: Colors.green,
            ),
            StatCard(
              title: 'Customer Baru',
              value: '${mockAnalytics['new_customers'] ?? 0}',
              icon: Icons.person_add,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Avg. Transaksi',
              value: NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(mockAnalytics['avg_transaction_value'] ?? 0),
              icon: Icons.attach_money,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerGrowthChart(CRMProvider provider) {
    // Mock growth data
    final mockGrowthData = List.generate(
      6,
      (index) => {
        'date': DateTime.now().subtract(Duration(days: (5 - index) * 30)),
        'count': 50 + (index * 15) + (index * index * 2),
      },
    );

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pertumbuhan Customer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < mockGrowthData.length) {
                          return Text(
                            DateFormat('MMM').format(
                              mockGrowthData[value.toInt()]['date'] as DateTime,
                            ),
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: mockGrowthData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['count'] as int).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSegmentation(CRMProvider provider) {
    // Mock segmentation data
    final mockSegmentationData = {
      'Regular': provider.customers.isNotEmpty
          ? (provider.customers.length * 0.6).round()
          : 0,
      'Premium': provider.customers.isNotEmpty
          ? (provider.customers.length * 0.25).round()
          : 0,
      'VIP': provider.customers.isNotEmpty
          ? (provider.customers.length * 0.15).round()
          : 0,
    };

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Segmentasi Customer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ResponsiveBuilder(
            builder: (context, isMobile, isTablet, isDesktop) {
              if (isMobile) {
                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(
                            mockSegmentationData,
                          ),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSegmentationLegend(mockSegmentationData),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(
                              mockSegmentationData,
                            ),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildSegmentationLegend(mockSegmentationData),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildSegmentationLegend(Map<String, dynamic> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final index = data.keys.toList().indexOf(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(entry.key, style: const TextStyle(fontSize: 14)),
              ),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCustomers(CRMProvider provider) {
    // Sort customers by total spent and take top 10
    final sortedCustomers = List<Customer>.from(provider.customers)
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    final topCustomers = sortedCustomers.take(10).toList();

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top 10 Customer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topCustomers.length,
            itemBuilder: (context, index) {
              final customer = topCustomers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (customer.email != null)
                            Text(
                              customer.email!,
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
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(customer.totalSpent),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${customer.totalTransactions} transaksi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab(CRMProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadCustomers(),
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer List
            _buildCustomerList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(CRMProvider provider) {
    final customers = provider.customers;

    if (customers.isEmpty) {
      return const ModernCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada data customer'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return ModernCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customer.email != null) Text('Email: ${customer.email}'),
                if (customer.phone != null) Text('Phone: ${customer.phone}'),
                Text(
                  'Bergabung: ${DateFormat('dd MMM yyyy').format(customer.createdAt)}',
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(customer.totalSpent),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${customer.totalTransactions} transaksi',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            onTap: () => _showCustomerDetails(customer),
          ),
        );
      },
    );
  }

  Widget _buildLoyaltyTab(CRMProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadCustomers(),
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loyalty Statistics
            _buildLoyaltyStats(provider),
            const SizedBox(height: 24),

            // Loyalty Program Overview
            _buildLoyaltyProgramOverview(provider),
            const SizedBox(height: 24),

            // Customer Loyalty List
            _buildCustomerLoyaltyList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyStats(CRMProvider provider) {
    // Mock loyalty statistics
    final mockLoyaltyStats = {
      'total_members': (provider.customers.length * 0.7).round(),
      'total_points': provider.customers.length * 150,
      'redeemed_points': provider.customers.length * 50,
    };

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        int crossAxisCount = isMobile ? 2 : 3;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StatCard(
              title: 'Member Loyalty',
              value: '${mockLoyaltyStats['total_members'] ?? 0}',
              icon: Icons.card_membership,
              color: Colors.purple,
            ),
            StatCard(
              title: 'Total Poin',
              value: '${mockLoyaltyStats['total_points'] ?? 0}',
              icon: Icons.stars,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Poin Tertukar',
              value: '${mockLoyaltyStats['redeemed_points'] ?? 0}',
              icon: Icons.redeem,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoyaltyProgramOverview(CRMProvider provider) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.loyalty,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Program Loyalty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Sistem poin reward untuk customer setia:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildLoyaltyRule('Setiap pembelian Rp 10.000 = 1 poin'),
          _buildLoyaltyRule('100 poin = Diskon Rp 10.000'),
          _buildLoyaltyRule('Member Gold: Bonus 2x poin'),
          _buildLoyaltyRule('Member Platinum: Bonus 3x poin'),
        ],
      ),
    );
  }

  Widget _buildLoyaltyRule(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(rule, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildCustomerLoyaltyList(CRMProvider provider) {
    // Mock loyalty customers based on existing customers
    final mockLoyaltyCustomers = provider.customers.take(5).map((customer) {
      return {
        'customer': customer,
        'tier': [
          'Bronze',
          'Silver',
          'Gold',
          'Platinum',
        ][customer.name.length % 4],
        'points': (customer.totalSpent / 10000).round(),
        'totalPoints': (customer.totalSpent / 5000).round(),
      };
    }).toList();

    if (mockLoyaltyCustomers.isEmpty) {
      return const ModernCard(
        child: Center(
          child: Column(
            children: [
              Icon(Icons.loyalty_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tidak ada member loyalty'),
            ],
          ),
        ),
      );
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Member Loyalty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockLoyaltyCustomers.length,
            itemBuilder: (context, index) {
              final loyaltyData = mockLoyaltyCustomers[index];
              final customer = loyaltyData['customer'] as Customer;
              final tier = loyaltyData['tier'] as String;
              final points = loyaltyData['points'] as int;
              final totalPoints = loyaltyData['totalPoints'] as int;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getLoyaltyTierColors(tier),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        _getLoyaltyTierIcon(tier),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$tier Member',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$points poin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Total: $totalPoints',
                          style: const TextStyle(
                            color: Colors.white70,
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
        ],
      ),
    );
  }

  List<Color> _getLoyaltyTierColors(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return [Colors.brown.shade400, Colors.brown.shade600];
      case 'silver':
        return [Colors.grey.shade400, Colors.grey.shade600];
      case 'gold':
        return [Colors.amber.shade400, Colors.amber.shade600];
      case 'platinum':
        return [Colors.purple.shade400, Colors.purple.shade600];
      default:
        return [Colors.blue.shade400, Colors.blue.shade600];
    }
  }

  IconData _getLoyaltyTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.military_tech;
      case 'gold':
        return Icons.emoji_events;
      case 'platinum':
        return Icons.diamond;
      default:
        return Icons.card_membership;
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _loadData();
    }
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(customer.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.email != null)
              _buildDetailRow('Email', customer.email!),
            if (customer.phone != null)
              _buildDetailRow('Phone', customer.phone!),
            _buildDetailRow(
              'Total Spent',
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(customer.totalSpent),
            ),
            _buildDetailRow('Total Transaksi', '${customer.totalTransactions}'),
            _buildDetailRow(
              'Bergabung',
              DateFormat('dd MMM yyyy').format(customer.createdAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
