import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/bluetooth_printer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/bluetooth_printer_service.dart';
import '../utils/app_theme.dart';

class BluetoothPrinterScreen extends StatefulWidget {
  const BluetoothPrinterScreen({super.key});

  @override
  State<BluetoothPrinterScreen> createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load bonded devices when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothPrinterProvider>().loadBondedDevices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          appBar: AppBar(
            title: const Text('Pengaturan Printer Bluetooth'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.bluetooth), text: 'Koneksi'),
                Tab(icon: Icon(Icons.settings), text: 'Pengaturan'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildConnectionTab(primaryColor),
              _buildSettingsTab(primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionTab(Color primaryColor) {
    return Consumer<BluetoothPrinterProvider>(
      builder: (context, printerProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await printerProvider.loadBondedDevices();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                _buildConnectionStatusCard(printerProvider, primaryColor),
                const SizedBox(height: 16),

                // Quick Actions
                _buildQuickActionsCard(printerProvider, primaryColor),
                const SizedBox(height: 16),

                // Bonded Devices
                _buildBondedDevicesSection(printerProvider, primaryColor),
                const SizedBox(height: 16),

                // Available Devices
                _buildAvailableDevicesSection(printerProvider, primaryColor),

                // Error Display
                if (printerProvider.lastError != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(printerProvider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatusCard(
    BluetoothPrinterProvider provider,
    Color primaryColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bluetooth, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Status Koneksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: provider.getConnectionStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.getConnectionStatusText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: provider.getConnectionStatusColor(),
                  ),
                ),
              ],
            ),

            if (provider.connectedDevice != null) ...[
              const SizedBox(height: 8),
              Text(
                'Perangkat: ${provider.connectedDevice!.platformName.isNotEmpty ? provider.connectedDevice!.platformName : 'Unknown'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Alamat: ${provider.connectedDevice!.remoteId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(
    BluetoothPrinterProvider provider,
    Color primaryColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aksi Cepat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected
                        ? () => _testPrint(provider)
                        : null,
                    icon: const Icon(Icons.print),
                    label: const Text('Test Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected
                        ? () => _disconnect(provider)
                        : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Putuskan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isScanning
                    ? () => provider.stopScanning()
                    : () => provider.startScanning(),
                icon: Icon(provider.isScanning ? Icons.stop : Icons.search),
                label: Text(
                  provider.isScanning ? 'Berhenti Scan' : 'Cari Perangkat',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBondedDevicesSection(
    BluetoothPrinterProvider provider,
    Color primaryColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Perangkat Terpasang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (provider.bondedDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Tidak ada perangkat printer yang terpasang',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...provider.bondedDevices.map(
                (device) =>
                    _buildDeviceListTile(device, provider, primaryColor, true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDevicesSection(
    BluetoothPrinterProvider provider,
    Color primaryColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Perangkat Tersedia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (provider.isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (provider.availableDevices.isEmpty && !provider.isScanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Tidak ada perangkat ditemukan\nTekan "Cari Perangkat" untuk memindai',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...provider.availableDevices.map(
                (device) =>
                    _buildDeviceListTile(device, provider, primaryColor, false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListTile(
    BluetoothDevice device,
    BluetoothPrinterProvider provider,
    Color primaryColor,
    bool isBonded,
  ) {
    final isConnected = provider.connectedDevice?.remoteId == device.remoteId;
    final isConnecting =
        provider.isConnecting &&
        provider.selectedDevice?.remoteId == device.remoteId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected
              ? Colors.green
              : isBonded
              ? primaryColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.print,
            color: isConnected
                ? Colors.white
                : isBonded
                ? primaryColor
                : Colors.grey,
          ),
        ),
        title: Text(
          device.platformName.isNotEmpty
              ? device.platformName
              : 'Unknown Device',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.remoteId.toString()),
            if (isConnected)
              const Text(
                'Terhubung',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (isConnecting)
              const Text(
                'Menghubungkan...',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isConnected
            ? IconButton(
                icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
                onPressed: () => _disconnect(provider),
              )
            : IconButton(
                icon: Icon(Icons.bluetooth, color: primaryColor),
                onPressed: () => _connectToDevice(device, provider),
              ),
        onTap: isConnected ? null : () => _connectToDevice(device, provider),
      ),
    );
  }

  Widget _buildErrorCard(BluetoothPrinterProvider provider) {
    return Card(
      color: Colors.red.shade50,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.lastError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => provider.clearError(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(Color primaryColor) {
    return Consumer<BluetoothPrinterProvider>(
      builder: (context, printerProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto Reconnect Settings
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.autorenew, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Koneksi Otomatis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Auto Reconnect'),
                        subtitle: const Text(
                          'Otomatis menghubungkan ulang jika koneksi terputus',
                        ),
                        value: printerProvider.autoReconnectEnabled,
                        onChanged: (value) =>
                            printerProvider.setAutoReconnect(value),
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Printer Information
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Informasi Printer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Printer yang Didukung:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      const Text('• Thermal Printer 58mm'),
                      const Text('• Thermal Printer 80mm'),
                      const Text('• POS Printer dengan ESC/POS'),
                      const Text('• Bluetooth Printer lainnya'),

                      const SizedBox(height: 16),

                      const Text(
                        'Tips Koneksi:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      const Text('• Pastikan printer dalam mode pairing'),
                      const Text('• Jarak maksimal 10 meter'),
                      const Text('• Aktifkan Auto Reconnect untuk stabilitas'),
                      const Text('• Test print setelah terhubung'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _connectToDevice(
    BluetoothDevice device,
    BluetoothPrinterProvider provider,
  ) async {
    final success = await provider.connectToDevice(device);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Berhasil terhubung ke ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}'
                : 'Gagal terhubung ke ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect(BluetoothPrinterProvider provider) async {
    await provider.disconnect();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koneksi terputus'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _testPrint(BluetoothPrinterProvider provider) async {
    final success = await provider.testPrint();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Test print berhasil!' : 'Test print gagal'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
