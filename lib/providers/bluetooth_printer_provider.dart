import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_printer_service.dart';
import '../models/app_settings.dart';
import '../models/transaction.dart' as model;

class BluetoothPrinterProvider with ChangeNotifier {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();

  final List<BluetoothDevice> _availableDevices = [];
  List<BluetoothDevice> _bondedDevices = [];
  BluetoothDevice? _selectedDevice;
  BluetoothConnectionStatus _connectionStatus =
      BluetoothConnectionStatus.disconnected;
  bool _isScanning = false;
  bool _autoReconnectEnabled = true;
  String? _lastError;

  // Getters
  List<BluetoothDevice> get availableDevices => _availableDevices;
  List<BluetoothDevice> get bondedDevices => _bondedDevices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  BluetoothDevice? get connectedDevice => _printerService.connectedDevice;
  BluetoothConnectionStatus get connectionStatus => _connectionStatus;
  bool get isConnected => _printerService.isConnected;
  bool get isConnecting => _printerService.isConnecting;
  bool get isScanning => _isScanning;
  bool get autoReconnectEnabled => _autoReconnectEnabled;
  String? get lastError => _lastError;

  BluetoothPrinterProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Listen to connection status changes
    _printerService.connectionStatusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });

    // Initialize Bluetooth service
    final initialized = await _printerService.initialize();
    if (!initialized) {
      _lastError = 'Gagal menginisialisasi Bluetooth';
      notifyListeners();
      return;
    }

    // Load bonded devices
    await loadBondedDevices();
  }

  /// Load bonded (paired) devices
  Future<void> loadBondedDevices() async {
    try {
      _bondedDevices = await _printerService.getBondedDevices();
      notifyListeners();
    } catch (e) {
      _lastError = 'Gagal memuat perangkat yang dipasangkan: $e';
      notifyListeners();
    }
  }

  /// Start scanning for devices
  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _availableDevices.clear();
      _lastError = null;
      notifyListeners();

      await for (final device in _printerService.discoverDevices()) {
        if (!_availableDevices.any(
          (existingDevice) => existingDevice.remoteId == device.remoteId,
        )) {
          _availableDevices.add(device);
          notifyListeners();
        }
      }
    } catch (e) {
      _lastError = 'Gagal memindai perangkat: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  void stopScanning() {
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _lastError = null;
      _selectedDevice = device;
      notifyListeners();

      final success = await _printerService.connectToDevice(device);

      if (success) {
        _lastError = null;
      } else {
        _lastError = 'Gagal terhubung ke ${device.name}';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Error koneksi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _printerService.disconnect();
      _selectedDevice = null;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Error disconnect: $e';
      notifyListeners();
    }
  }

  /// Print receipt with enhanced error handling
  Future<bool> printReceipt(
    model.Transaction transaction,
    AppSettings settings,
    String cashierName,
  ) async {
    if (!isConnected) {
      _lastError =
          'Printer tidak terhubung. Silakan hubungkan printer terlebih dahulu.';
      notifyListeners();
      return false;
    }

    try {
      _lastError = null;
      notifyListeners();

      // Add a small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await _printerService.printReceipt(
        transaction,
        settings,
        cashierName,
      );

      if (!success) {
        _lastError =
            'Gagal mencetak struk. Periksa koneksi printer dan coba lagi.';
      } else {
        _lastError = null;
      }

      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Error saat mencetak: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Test print with enhanced error handling
  Future<bool> testPrint() async {
    if (!isConnected) {
      _lastError =
          'Printer tidak terhubung. Silakan hubungkan printer terlebih dahulu.';
      notifyListeners();
      return false;
    }

    try {
      _lastError = null;
      notifyListeners();

      // Add a small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await _printerService.testPrint();

      if (!success) {
        _lastError = 'Test print gagal. Periksa koneksi printer dan coba lagi.';
      } else {
        _lastError = null;
      }

      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Error saat test print: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Get detailed printer status
  String getPrinterStatusText() {
    if (!isConnected) {
      return 'Printer tidak terhubung';
    }

    switch (_connectionStatus) {
      case BluetoothConnectionStatus.connected:
        return 'Printer siap digunakan';
      case BluetoothConnectionStatus.connecting:
        return 'Menghubungkan ke printer...';
      case BluetoothConnectionStatus.reconnecting:
        return 'Menghubungkan ulang ke printer...';
      case BluetoothConnectionStatus.disconnected:
        return 'Printer terputus';
    }
  }

  /// Check if printer is ready for printing
  bool get isPrinterReady =>
      isConnected && _connectionStatus == BluetoothConnectionStatus.connected;

  /// Toggle auto-reconnect
  void toggleAutoReconnect() {
    _autoReconnectEnabled = !_autoReconnectEnabled;
    _printerService.setAutoReconnect(_autoReconnectEnabled);
    notifyListeners();
  }

  /// Set auto-reconnect
  void setAutoReconnect(bool enabled) {
    _autoReconnectEnabled = enabled;
    _printerService.setAutoReconnect(enabled);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Get connection status text
  String getConnectionStatusText() {
    switch (_connectionStatus) {
      case BluetoothConnectionStatus.disconnected:
        return 'Terputus';
      case BluetoothConnectionStatus.connecting:
        return 'Menghubungkan...';
      case BluetoothConnectionStatus.connected:
        return 'Terhubung';
      case BluetoothConnectionStatus.reconnecting:
        return 'Menghubungkan ulang...';
    }
  }

  /// Get connection status color
  Color getConnectionStatusColor() {
    switch (_connectionStatus) {
      case BluetoothConnectionStatus.disconnected:
        return Colors.red;
      case BluetoothConnectionStatus.connecting:
      case BluetoothConnectionStatus.reconnecting:
        return Colors.orange;
      case BluetoothConnectionStatus.connected:
        return Colors.green;
    }
  }

  @override
  void dispose() {
    _printerService.dispose();
    super.dispose();
  }
}
