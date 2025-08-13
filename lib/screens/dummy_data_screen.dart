import 'package:flutter/material.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_theme.dart';

class DummyDataScreen extends StatefulWidget {
  const DummyDataScreen({super.key});

  @override
  State<DummyDataScreen> createState() => _DummyDataScreenState();
}

class _DummyDataScreenState extends State<DummyDataScreen> {
  bool _isLoading = false;
  bool _hasData = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _checkDummyData();
  }

  Future<void> _checkDummyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasData = await DummyDataService.hasDummyData();
      final stats = await DummyDataService.getDashboardStats();

      setState(() {
        _hasData = hasData;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error checking dummy data: $e');
    }
  }

  Future<void> _generateDummyData() async {
    final confirmed = await _showConfirmDialog(
      'Generate Dummy Data',
      'Ini akan membuat 50 transaksi dummy untuk testing laporan. Lanjutkan?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DummyDataService.generateDummyData();
      await _checkDummyData();
      _showSuccessSnackBar('✅ Dummy data berhasil dibuat!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error generating dummy data: $e');
    }
  }

  Future<void> _clearDummyData() async {
    final confirmed = await _showConfirmDialog(
      'Clear Dummy Data',
      'Ini akan menghapus semua data dummy dan reset database. Lanjutkan?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DummyDataService.clearDummyData();
      await _checkDummyData();
      _showSuccessSnackBar('✅ Dummy data berhasil dihapus!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error clearing dummy data: $e');
    }
  }

  Future<void> _resetDummyData() async {
    final confirmed = await _showConfirmDialog(
      'Reset Dummy Data',
      'Ini akan menghapus data lama dan membuat data dummy baru. Lanjutkan?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DummyDataService.resetDummyData();
      await _checkDummyData();
      _showSuccessSnackBar('✅ Dummy data berhasil direset!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error resetting dummy data: $e');
    }
  }

  Future<void> _generateMoreTransactions() async {
    final result = await _showNumberInputDialog(
      'Generate More Transactions',
      'Berapa transaksi tambahan yang ingin dibuat?',
      defaultValue: 25,
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DummyDataService.generateMoreTransactions(result);
      await _checkDummyData();
      _showSuccessSnackBar('✅ $result transaksi tambahan berhasil dibuat!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error generating more transactions: $e');
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<int?> _showNumberInputDialog(
    String title,
    String content, {
    int defaultValue = 10,
  }) async {
    final controller = TextEditingController(text: defaultValue.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.getSuccessColor(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.getErrorColor(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dummy Data Manager'), elevation: 2),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing dummy data...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _hasData ? Icons.check_circle : Icons.warning,
                                color: _hasData
                                    ? AppTheme.getSuccessColor(context)
                                    : AppTheme.getWarningColor(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status Dummy Data',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _hasData
                                ? '✅ Dummy data tersedia'
                                : '⚠️ Belum ada dummy data',
                            style: TextStyle(
                              color: _hasData
                                  ? AppTheme.getSuccessColor(context)
                                  : AppTheme.getWarningColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_hasData && _stats.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Statistik Data',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                              'Total Transaksi Hari Ini',
                              '${_stats['todayTransactions'] ?? 0}',
                            ),
                            _buildStatRow(
                              'Revenue Hari Ini',
                              'Rp ${(_stats['todayRevenue'] ?? 0).toStringAsFixed(0)}',
                            ),
                            _buildStatRow(
                              'Total Produk',
                              '${_stats['totalProducts'] ?? 0}',
                            ),
                            _buildStatRow(
                              'Produk Stok Rendah',
                              '${_stats['lowStockProducts'] ?? 0}',
                            ),
                            _buildStatRow(
                              'Total Customer',
                              '${_stats['totalCustomers'] ?? 0}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Section
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Generate Dummy Data
                  if (!_hasData)
                    _buildActionCard(
                      icon: Icons.add_circle,
                      title: 'Generate Dummy Data',
                      subtitle: 'Buat 50 transaksi dummy untuk testing laporan',
                      color: AppTheme.getSuccessColor(context),
                      onTap: _generateDummyData,
                    ),

                  // Generate More Transactions
                  if (_hasData)
                    _buildActionCard(
                      icon: Icons.add,
                      title: 'Generate More Transactions',
                      subtitle: 'Tambah transaksi dummy lebih banyak',
                      color: Colors.blue,
                      onTap: _generateMoreTransactions,
                    ),

                  // Reset Dummy Data
                  if (_hasData)
                    _buildActionCard(
                      icon: Icons.refresh,
                      title: 'Reset Dummy Data',
                      subtitle: 'Hapus data lama dan buat data baru',
                      color: AppTheme.getWarningColor(context),
                      onTap: _resetDummyData,
                    ),

                  // Clear Dummy Data
                  if (_hasData)
                    _buildActionCard(
                      icon: Icons.delete_sweep,
                      title: 'Clear Dummy Data',
                      subtitle: 'Hapus semua dummy data dan reset database',
                      color: AppTheme.getErrorColor(context),
                      onTap: _clearDummyData,
                    ),

                  const SizedBox(height: 24),

                  // Info Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Informasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Dummy data berguna untuk testing fitur laporan\n'
                            '• Data yang dibuat mencakup produk, customer, dan transaksi\n'
                            '• Transaksi dibuat dengan tanggal random dalam 30 hari terakhir\n'
                            '• Setiap transaksi memiliki 1-5 item dengan quantity random\n'
                            '• Payment method dan customer juga dipilih secara random',
                            style: TextStyle(fontSize: 14),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade600,
        ),
        onTap: onTap,
      ),
    );
  }
}
