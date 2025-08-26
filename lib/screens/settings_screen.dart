import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import 'bluetooth_printer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();

    // Load settings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      _userRole = context.read<AuthProvider>().currentUser?.role;
      _initializeTabController();
    });
  }

  void _initializeTabController() {
    final tabCount = _getTabsForRole(_userRole).length;
    _tabController?.dispose();
    _tabController = TabController(length: tabCount, vsync: this);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Tab> _getTabsForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        // Admin: Akses penuh semua tab
        return const [
          Tab(icon: Icon(Icons.palette), text: 'Tampilan'),
          Tab(icon: Icon(Icons.receipt), text: 'Nota'),
          Tab(icon: Icon(Icons.business), text: 'Bisnis'),
          Tab(icon: Icon(Icons.settings), text: 'Sistem'),
        ];
      case UserRole.owner:
        // Owner: Tanpa sistem (user management)
        return const [
          Tab(icon: Icon(Icons.palette), text: 'Tampilan'),
          Tab(icon: Icon(Icons.receipt), text: 'Nota'),
          Tab(icon: Icon(Icons.business), text: 'Bisnis'),
        ];
      case UserRole.cashier:
        // Kasir: Hanya tampilan dasar
        return const [Tab(icon: Icon(Icons.palette), text: 'Tampilan')];
      default:
        return const [Tab(icon: Icon(Icons.palette), text: 'Tampilan')];
    }
  }

  List<Widget> _getTabViewsForRole(UserRole? role, SettingsProvider provider) {
    switch (role) {
      case UserRole.admin:
        return [
          _buildAppearanceTab(provider),
          _buildReceiptTab(provider),
          _buildBusinessTab(provider),
          _buildSystemTab(provider),
        ];
      case UserRole.owner:
        return [
          _buildAppearanceTab(provider),
          _buildReceiptTab(provider),
          _buildBusinessTab(provider),
        ];
      case UserRole.cashier:
        return [_buildCashierAppearanceTab(provider)];
      default:
        return [_buildCashierAppearanceTab(provider)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AuthProvider>(
      builder: (context, settingsProvider, authProvider, child) {
        if (settingsProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pengaturan')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = authProvider.currentUser?.role;
        final tabs = _getTabsForRole(userRole);
        final tabViews = _getTabViewsForRole(userRole, settingsProvider);

        // Initialize tab controller if not done yet
        if (_userRole != userRole) {
          _userRole = userRole;
          _tabController?.dispose();
          _tabController = TabController(length: tabs.length, vsync: this);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Pengaturan - ${_getRoleDisplayName(userRole)}'),
            bottom: tabs.length > 1 && _tabController != null
                ? TabBar(
                    controller: _tabController!,
                    isScrollable: true,
                    tabs: tabs,
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveAllSettings(settingsProvider),
                tooltip: 'Simpan Semua Pengaturan',
              ),
            ],
          ),
          body: tabs.length > 1 && _tabController != null
              ? TabBarView(controller: _tabController!, children: tabViews)
              : tabViews.first,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _saveAllSettings(settingsProvider),
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
            tooltip: 'Simpan Semua Pengaturan',
          ),
        );
      },
    );
  }

  String _getRoleDisplayName(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.owner:
        return 'Pemilik';
      case UserRole.cashier:
        return 'Kasir';
      default:
        return 'User';
    }
  }

  Future<void> _saveAllSettings(SettingsProvider provider) async {
    try {
      // Settings are already saved automatically when changed
      // This method provides explicit save confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Semua pengaturan telah disimpan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menyimpan pengaturan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showTransactionStorageDialog(
    BuildContext context,
    SettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kapasitas Penyimpanan Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppSettings.transactionStorageOptions.entries
              .map(
                (entry) => RadioListTile<int>(
                  title: Text(entry.key),
                  subtitle: Text('${entry.value} hari'),
                  value: entry.value,
                  groupValue: provider.settings.transactionStorageDays,
                  onChanged: (value) async {
                    if (value != null) {
                      try {
                        await provider.updateTransactionStorageSettings(
                          transactionStorageDays: value,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Kapasitas penyimpanan diubah ke ${entry.key}',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllTransactionsDialog(
    BuildContext context,
    SettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Transaksi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus SEMUA data transaksi penjualan?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('⚠️ Peringatan:'),
            Text('• Semua riwayat transaksi akan dihapus permanen'),
            Text('• Data laporan penjualan akan hilang'),
            Text('• Tindakan ini TIDAK DAPAT dibatalkan'),
            SizedBox(height: 8),
            Text(
              'Pastikan Anda telah membuat backup data sebelum melanjutkan.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteAllTransactions(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAllTransactions(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menghapus semua transaksi...'),
          ],
        ),
      ),
    );

    try {
      // Import DatabaseService
      final databaseService = DatabaseService();
      final deletedCount = await databaseService.deleteAllTransactions();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Berhasil menghapus $deletedCount transaksi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menghapus transaksi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildAppearanceTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tema Aplikasi'),
          Card(
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      title: const Text('Mode Gelap'),
                      subtitle: const Text('Aktifkan tema gelap'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                        provider.updateSettings(
                          provider.settings.copyWith(isDarkMode: value),
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  title: const Text('Warna Utama'),
                  subtitle: Text(provider.settings.primaryColor),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(
                          provider.settings.primaryColor.replaceAll(
                            '#',
                            '0xFF',
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  onTap: () => _showColorPicker(
                    context,
                    'Pilih Warna Utama',
                    provider.settings.primaryColor,
                    (color) => provider.updateSettings(
                      provider.settings.copyWith(primaryColor: color),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Warna Sekunder'),
                  subtitle: Text(provider.settings.secondaryColor),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(
                          provider.settings.secondaryColor.replaceAll(
                            '#',
                            '0xFF',
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  onTap: () => _showColorPicker(
                    context,
                    'Pilih Warna Sekunder',
                    provider.settings.secondaryColor,
                    (color) => provider.updateSettings(
                      provider.settings.copyWith(secondaryColor: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Splash Screen'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tampilkan Splash Screen'),
                  subtitle: const Text(
                    'Tampilkan layar pembuka saat aplikasi dimulai',
                  ),
                  value: provider.settings.showSplashScreen,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(showSplashScreen: value),
                  ),
                ),
                ListTile(
                  title: const Text('Durasi Splash Screen'),
                  subtitle: Text(
                    '${provider.settings.splashScreenDuration} detik',
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: double.parse(
                        provider.settings.splashScreenDuration,
                      ),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${provider.settings.splashScreenDuration}s',
                      onChanged: (value) => provider.updateSettings(
                        provider.settings.copyWith(
                          splashScreenDuration: value.round().toString(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Font & Bahasa'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Ukuran Font'),
                  subtitle: Text('${provider.settings.fontSize.toInt()}px'),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: provider.settings.fontSize,
                      min: 12,
                      max: 20,
                      divisions: 8,
                      label: '${provider.settings.fontSize.toInt()}px',
                      onChanged: (value) => provider.updateSettings(
                        provider.settings.copyWith(fontSize: value),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Font Family'),
                  subtitle: Text(provider.settings.fontFamily),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showFontFamilyDialog(context, provider),
                ),
                ListTile(
                  title: const Text('Bahasa'),
                  subtitle: Text(
                    provider.settings.language == 'id'
                        ? 'Indonesia'
                        : 'English',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageDialog(context, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Header & Footer Nota'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Header Nota'),
                  subtitle: Text(provider.settings.receiptHeader),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showTextEditDialog(
                    context,
                    'Header Nota',
                    provider.settings.receiptHeader,
                    (value) => provider.updateSettings(
                      provider.settings.copyWith(receiptHeader: value),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Footer Nota'),
                  subtitle: Text(provider.settings.receiptFooter),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showTextEditDialog(
                    context,
                    'Footer Nota',
                    provider.settings.receiptFooter,
                    (value) => provider.updateSettings(
                      provider.settings.copyWith(receiptFooter: value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Pengaturan Cetak'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tampilkan Logo Bisnis'),
                  subtitle: const Text('Tampilkan logo pada nota'),
                  value: provider.settings.showBusinessLogo,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(showBusinessLogo: value),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Info Pelanggan'),
                  subtitle: const Text('Cetak informasi pelanggan'),
                  value: provider.settings.printCustomerInfo,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(printCustomerInfo: value),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Detail Item'),
                  subtitle: const Text('Cetak detail setiap item'),
                  value: provider.settings.printItemDetails,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(printItemDetails: value),
                  ),
                ),
                ListTile(
                  title: const Text('Ukuran Kertas'),
                  subtitle: Text(provider.settings.receiptPaperSize),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPaperSizeDialog(context, provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Printer Bluetooth'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Pengaturan Printer Bluetooth'),
                  subtitle: const Text('Kelola koneksi printer Bluetooth'),
                  leading: const Icon(Icons.bluetooth),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BluetoothPrinterScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informasi Bisnis'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Nama Bisnis'),
                  subtitle: Text(provider.settings.businessName),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showTextEditDialog(
                    context,
                    'Nama Bisnis',
                    provider.settings.businessName,
                    (value) => provider.updateSettings(
                      provider.settings.copyWith(businessName: value),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Alamat'),
                  subtitle: Text(provider.settings.businessAddress),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showTextEditDialog(
                    context,
                    'Alamat Bisnis',
                    provider.settings.businessAddress,
                    (value) => provider.updateSettings(
                      provider.settings.copyWith(businessAddress: value),
                    ),
                    maxLines: 3,
                  ),
                ),
                ListTile(
                  title: const Text('Nomor Telepon'),
                  subtitle: Text(provider.settings.businessPhone),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showTextEditDialog(
                    context,
                    'Nomor Telepon',
                    provider.settings.businessPhone,
                    (value) => provider.updateSettings(
                      provider.settings.copyWith(businessPhone: value),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(provider.settings.businessEmail),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showTextEditDialog(
                    context,
                    'Email Bisnis',
                    provider.settings.businessEmail,
                    (value) => provider.updateSettings(
                      provider.settings.copyWith(businessEmail: value),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Logo & Branding'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Logo Aplikasi'),
                  subtitle: Text(
                    provider.settings.logoPath.isEmpty
                        ? 'Belum ada logo'
                        : 'Logo tersimpan',
                  ),
                  trailing: const Icon(Icons.image, size: 20),
                  onTap: () => _showImagePickerDialog(context, provider),
                ),
                ListTile(
                  title: const Text('Nama Aplikasi'),
                  subtitle: Text(provider.settings.appName),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () => _showTextEditDialog(
                    context,
                    'Nama Aplikasi',
                    provider.settings.appName,
                    (value) => provider.updateSettings(
                      provider.settings.copyWith(appName: value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notifikasi'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Aktifkan Notifikasi'),
                  subtitle: const Text('Terima notifikasi dari aplikasi'),
                  value: provider.settings.enableNotifications,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(enableNotifications: value),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Suara Notifikasi'),
                  subtitle: const Text('Putar suara untuk notifikasi'),
                  value: provider.settings.enableSounds,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(enableSounds: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Backup & Sinkronisasi'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto Backup'),
                  subtitle: const Text('Backup otomatis data aplikasi'),
                  value: provider.settings.autoBackup,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(autoBackup: value),
                  ),
                ),
                ListTile(
                  title: const Text('Interval Backup'),
                  subtitle: Text(
                    'Setiap ${provider.settings.autoBackupInterval} jam',
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: provider.settings.autoBackupInterval.toDouble(),
                      min: 1,
                      max: 168, // 1 week
                      divisions: 23,
                      label: '${provider.settings.autoBackupInterval}h',
                      onChanged: (value) => provider.updateSettings(
                        provider.settings.copyWith(
                          autoBackupInterval: value.round(),
                        ),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Lokasi Backup'),
                  subtitle: Text(
                    provider.settings.backupLocation == 'local'
                        ? 'Penyimpanan Lokal'
                        : 'Cloud Storage',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showBackupLocationDialog(context, provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Manajemen Data Transaksi'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Kapasitas Penyimpanan Transaksi'),
                  subtitle: Text(
                    provider.settings.transactionStorageDisplayName,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTransactionStorageDialog(context, provider),
                ),
                ListTile(
                  title: const Text('Hapus Semua Transaksi Penjualan'),
                  subtitle: const Text(
                    'Hapus seluruh data transaksi penjualan',
                  ),
                  trailing: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: () =>
                      _showDeleteAllTransactionsDialog(context, provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Reset & Restore'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Reset Pengaturan'),
                  subtitle: const Text('Kembalikan ke pengaturan default'),
                  trailing: const Icon(Icons.refresh, color: Colors.orange),
                  onTap: () => _showResetConfirmDialog(context, provider),
                ),
                ListTile(
                  title: const Text('Versi Aplikasi'),
                  subtitle: Text('v${provider.settings.appVersion}'),
                  trailing: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simplified appearance tab for cashier (limited options)
  Widget _buildCashierAppearanceTab(SettingsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tema Aplikasi'),
          Card(
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      title: const Text('Mode Gelap'),
                      subtitle: const Text('Aktifkan tema gelap'),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                        provider.updateSettings(
                          provider.settings.copyWith(isDarkMode: value),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Font & Bahasa'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Ukuran Font'),
                  subtitle: Text('${provider.settings.fontSize.toInt()}px'),
                  trailing: SizedBox(
                    width: 100,
                    child: Slider(
                      value: provider.settings.fontSize,
                      min: 12,
                      max: 20,
                      divisions: 8,
                      label: '${provider.settings.fontSize.toInt()}px',
                      onChanged: (value) => provider.updateSettings(
                        provider.settings.copyWith(fontSize: value),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Bahasa'),
                  subtitle: Text(
                    provider.settings.language == 'id'
                        ? 'Indonesia'
                        : 'English',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageDialog(context, provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Notifikasi'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Suara Notifikasi'),
                  subtitle: const Text('Putar suara untuk notifikasi'),
                  value: provider.settings.enableSounds,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(enableSounds: value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    String title,
    String currentColor,
    Function(String) onColorSelected,
  ) {
    final colors = [
      '#2196F3',
      '#4CAF50',
      '#FF9800',
      '#F44336',
      '#9C27B0',
      '#607D8B',
      '#795548',
      '#E91E63',
      '#3F51B5',
      '#009688',
      '#CDDC39',
      '#FF5722',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected = color == currentColor;

              return GestureDetector(
                onTap: () {
                  onColorSelected(color);
                  Navigator.pop(context);
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Warna berhasil diubah'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showTextEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    Function(String) onSave, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Masukkan $title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showFontFamilyDialog(BuildContext context, SettingsProvider provider) {
    final fonts = [
      'Roboto',
      'Arial',
      'Times New Roman',
      'Helvetica',
      'Georgia',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Font'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fonts
              .map(
                (font) => RadioListTile<String>(
                  title: Text(font, style: TextStyle(fontFamily: font)),
                  value: font,
                  groupValue: provider.settings.fontFamily,
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateSettings(
                        provider.settings.copyWith(fontFamily: value),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    final languages = [
      {'code': 'id', 'name': 'Indonesia'},
      {'code': 'en', 'name': 'English'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages
              .map(
                (lang) => RadioListTile<String>(
                  title: Text(lang['name']!),
                  value: lang['code']!,
                  groupValue: provider.settings.language,
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateSettings(
                        provider.settings.copyWith(language: value),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showPaperSizeDialog(BuildContext context, SettingsProvider provider) {
    final sizes = ['58mm', '80mm', 'A4'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ukuran Kertas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes
              .map(
                (size) => RadioListTile<String>(
                  title: Text(size),
                  value: size,
                  groupValue: provider.settings.receiptPaperSize,
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateSettings(
                        provider.settings.copyWith(receiptPaperSize: value),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showBackupLocationDialog(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final locations = [
      {'code': 'local', 'name': 'Penyimpanan Lokal'},
      {'code': 'cloud', 'name': 'Cloud Storage'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lokasi Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: locations
              .map(
                (location) => RadioListTile<String>(
                  title: Text(location['name']!),
                  value: location['code']!,
                  groupValue: provider.settings.backupLocation,
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateSettings(
                        provider.settings.copyWith(backupLocation: value),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showImagePickerDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Logo'),
        content: const Text('Fitur upload logo akan segera tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(
    BuildContext context,
    SettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Pengaturan'),
        content: const Text(
          'Apakah Anda yakin ingin mengembalikan semua pengaturan ke default? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.resetSettings();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengaturan berhasil direset'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
