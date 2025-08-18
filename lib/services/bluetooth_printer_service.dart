import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_settings.dart';
import '../models/transaction.dart' as model;

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _autoReconnect = true;

  // Connection status stream
  final StreamController<BluetoothConnectionStatus>
  _connectionStatusController =
      StreamController<BluetoothConnectionStatus>.broadcast();
  Stream<BluetoothConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  // Getters
  bool get isConnected => _connectedDevice?.isConnected ?? false;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;

  /// Initialize Bluetooth and request permissions
  Future<bool> initialize() async {
    try {
      // Request Bluetooth permissions
      final bluetoothPermission = await Permission.bluetooth.request();
      final bluetoothScanPermission = await Permission.bluetoothScan.request();
      final bluetoothConnectPermission = await Permission.bluetoothConnect
          .request();
      final locationPermission = await Permission.location.request();

      if (bluetoothPermission != PermissionStatus.granted ||
          bluetoothScanPermission != PermissionStatus.granted ||
          bluetoothConnectPermission != PermissionStatus.granted ||
          locationPermission != PermissionStatus.granted) {
        debugPrint('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is supported and available
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('Bluetooth not supported by this device');
        return false;
      }

      // Turn on Bluetooth if it's off
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      return true;
    } catch (e) {
      debugPrint('Error initializing Bluetooth: $e');
      return false;
    }
  }

  /// Get list of bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      return bondedDevices
          .where(
            (device) =>
                device.platformName.toLowerCase().contains('printer') ||
                device.platformName.toLowerCase().contains('pos') ||
                device.platformName.toLowerCase().contains('thermal') ||
                device.platformName.toLowerCase().contains('receipt'),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      return [];
    }
  }

  /// Discover available Bluetooth devices
  Stream<BluetoothDevice> discoverDevices() {
    final StreamController<BluetoothDevice> controller =
        StreamController<BluetoothDevice>();

    _scanSubscription?.cancel();

    // Start scanning
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: false,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        final device = result.device;
        final deviceName = device.platformName.toLowerCase();

        // Filter for printer devices
        if (deviceName.contains('printer') ||
            deviceName.contains('pos') ||
            deviceName.contains('thermal') ||
            deviceName.contains('receipt')) {
          controller.add(device);
        }
      }
    });

    // Auto-close controller when scan completes
    Timer(const Duration(seconds: 16), () {
      FlutterBluePlus.stopScan();
      controller.close();
    });

    return controller.stream;
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return false;

    try {
      _isConnecting = true;
      _connectionStatusController.add(BluetoothConnectionStatus.connecting);

      // Disconnect existing connection
      await disconnect();

      debugPrint('Connecting to ${device.platformName} (${device.remoteId})');

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Listen for connection state changes
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleConnectionLost();
        }
      });

      // Discover services and find write characteristic
      final services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic == null) {
        debugPrint('No write characteristic found');
        await disconnect();
        _isConnecting = false;
        _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
        return false;
      }

      _isConnecting = false;
      _connectionStatusController.add(BluetoothConnectionStatus.connected);

      // Start auto-reconnect monitoring
      _startReconnectMonitoring();

      debugPrint('Successfully connected to ${device.platformName}');
      return true;
    } catch (e) {
      _isConnecting = false;
      _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
      debugPrint('Failed to connect to ${device.platformName}: $e');
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      _reconnectTimer?.cancel();
      _connectionSubscription?.cancel();

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _connectedDevice = null;
      _writeCharacteristic = null;
      _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
      debugPrint('Disconnected from Bluetooth device');
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Handle connection lost and attempt reconnection
  void _handleConnectionLost() {
    if (_connectedDevice != null && _autoReconnect) {
      _connectionStatusController.add(BluetoothConnectionStatus.reconnecting);
      _attemptReconnection();
    } else {
      _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
    }
  }

  /// Start monitoring connection and auto-reconnect
  void _startReconnectMonitoring() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isConnected && _connectedDevice != null && _autoReconnect) {
        _attemptReconnection();
      }
    });
  }

  /// Attempt to reconnect to the last connected device
  Future<void> _attemptReconnection() async {
    if (_connectedDevice == null || _isConnecting) return;

    debugPrint('Attempting to reconnect to ${_connectedDevice!.platformName}');
    final success = await connectToDevice(_connectedDevice!);

    if (!success) {
      // Wait before next attempt
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Print receipt
  Future<bool> printReceipt(
    model.Transaction transaction,
    AppSettings settings,
    String cashierName,
  ) async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('No printer connected or no write characteristic');
      return false;
    }

    try {
      final receiptData = _generateReceiptData(
        transaction,
        settings,
        cashierName,
      );

      // Split data into chunks if needed (some devices have MTU limits)
      const chunkSize = 20;
      for (int i = 0; i < receiptData.length; i += chunkSize) {
        final end = (i + chunkSize < receiptData.length)
            ? i + chunkSize
            : receiptData.length;
        final chunk = receiptData.sublist(i, end);

        await _writeCharacteristic!.write(chunk, withoutResponse: true);
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Small delay between chunks
      }

      debugPrint('Receipt printed successfully');
      return true;
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      return false;
    }
  }

  /// Generate receipt data for thermal printer
  Uint8List _generateReceiptData(
    model.Transaction transaction,
    AppSettings settings,
    String cashierName,
  ) {
    final List<int> bytes = [];

    // ESC/POS commands
    const esc = 0x1B;
    const gs = 0x1D;

    // Initialize printer
    bytes.addAll([esc, 0x40]); // Initialize
    bytes.addAll([esc, 0x61, 0x01]); // Center alignment

    // Receipt header
    bytes.addAll([esc, 0x21, 0x30]); // Double height and width
    bytes.addAll(settings.receiptHeader.codeUnits);
    bytes.addAll([0x0A, 0x0A]); // Line feeds

    // Business name
    bytes.addAll([esc, 0x21, 0x20]); // Double height
    bytes.addAll(settings.businessName.toUpperCase().codeUnits);
    bytes.addAll([0x0A]); // Line feed

    // Reset font size
    bytes.addAll([esc, 0x21, 0x00]); // Normal size

    // Business address
    bytes.addAll(settings.businessAddress.codeUnits);
    bytes.addAll([0x0A]);

    // Business phone
    if (settings.businessPhone.isNotEmpty) {
      bytes.addAll('Telp: ${settings.businessPhone}'.codeUnits);
      bytes.addAll([0x0A]);
    }

    // Business email
    if (settings.businessEmail.isNotEmpty) {
      bytes.addAll('Email: ${settings.businessEmail}'.codeUnits);
      bytes.addAll([0x0A]);
    }

    // Separator line
    bytes.addAll([0x0A]);
    bytes.addAll('================================'.codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    // Left alignment for transaction details
    bytes.addAll([esc, 0x61, 0x00]); // Left alignment

    // Transaction info
    bytes.addAll(
      'No. Transaksi: ${transaction.id.substring(0, 8).toUpperCase()}'
          .codeUnits,
    );
    bytes.addAll([0x0A]);

    final dateFormat =
        '${transaction.createdAt.day.toString().padLeft(2, '0')}/${transaction.createdAt.month.toString().padLeft(2, '0')}/${transaction.createdAt.year} ${transaction.createdAt.hour.toString().padLeft(2, '0')}:${transaction.createdAt.minute.toString().padLeft(2, '0')}';
    bytes.addAll('Tanggal: $dateFormat'.codeUnits);
    bytes.addAll([0x0A]);

    bytes.addAll('Kasir: $cashierName'.codeUnits);
    bytes.addAll([0x0A]);

    if (transaction.customer != null) {
      bytes.addAll('Pelanggan: ${transaction.customer!.name}'.codeUnits);
      bytes.addAll([0x0A]);
    }

    bytes.addAll(
      'Metode Bayar: ${_getPaymentMethodText(transaction.paymentMethod)}'
          .codeUnits,
    );
    bytes.addAll([0x0A, 0x0A]);

    // Items header
    bytes.addAll('DETAIL PEMBELIAN'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('--------------------------------'.codeUnits);
    bytes.addAll([0x0A]);

    // Items
    for (final item in transaction.items) {
      bytes.addAll(item.product.name.codeUnits);
      bytes.addAll([0x0A]);

      final itemLine = '${item.quantity} x ${_formatCurrency(item.unitPrice)}';
      final totalLine = _formatCurrency(item.totalPrice);
      final spaces = 32 - itemLine.length - totalLine.length;

      bytes.addAll(itemLine.codeUnits);
      bytes.addAll(List.filled(spaces > 0 ? spaces : 1, 0x20)); // Spaces
      bytes.addAll(totalLine.codeUnits);
      bytes.addAll([0x0A]);
    }

    // Separator
    bytes.addAll([0x0A]);
    bytes.addAll('--------------------------------'.codeUnits);
    bytes.addAll([0x0A]);

    // Summary
    _addSummaryLine(bytes, 'Subtotal', transaction.subtotal);

    // Discount breakdown
    if (transaction.discountBreakdown != null &&
        transaction.discountBreakdown!.isNotEmpty) {
      for (final entry in transaction.discountBreakdown!.entries) {
        _addSummaryLine(bytes, entry.key, -entry.value);
      }
    } else if (transaction.discount > 0) {
      _addSummaryLine(bytes, 'Diskon', -transaction.discount);
    }

    if (transaction.tax > 0) {
      _addSummaryLine(bytes, 'Pajak', transaction.tax);
    }

    // Total line
    bytes.addAll('================================'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll([esc, 0x21, 0x20]); // Double height
    _addSummaryLine(bytes, 'TOTAL', transaction.total);
    bytes.addAll([esc, 0x21, 0x00]); // Normal size

    _addSummaryLine(bytes, 'Bayar', transaction.amountPaid);
    _addSummaryLine(bytes, 'Kembalian', transaction.change);

    // Footer
    bytes.addAll([0x0A, 0x0A]);
    bytes.addAll([esc, 0x61, 0x01]); // Center alignment
    bytes.addAll([esc, 0x21, 0x10]); // Bold
    bytes.addAll(settings.receiptFooter.codeUnits);
    bytes.addAll([esc, 0x21, 0x00]); // Normal
    bytes.addAll([0x0A]);

    bytes.addAll('Barang yang sudah dibeli'.codeUnits);
    bytes.addAll([0x0A]);
    bytes.addAll('tidak dapat dikembalikan'.codeUnits);
    bytes.addAll([0x0A, 0x0A]);

    // Notes
    if (transaction.notes != null && transaction.notes!.isNotEmpty) {
      bytes.addAll('Catatan: ${transaction.notes}'.codeUnits);
      bytes.addAll([0x0A, 0x0A]);
    }

    // Cut paper
    bytes.addAll([gs, 0x56, 0x00]); // Full cut

    return Uint8List.fromList(bytes);
  }

  void _addSummaryLine(List<int> bytes, String label, double amount) {
    final amountStr = _formatCurrency(amount);
    final spaces = 32 - label.length - amountStr.length;

    bytes.addAll(label.codeUnits);
    bytes.addAll(List.filled(spaces > 0 ? spaces : 1, 0x20)); // Spaces
    bytes.addAll(amountStr.codeUnits);
    bytes.addAll([0x0A]);
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
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

  /// Test printer connection
  Future<bool> testPrint() async {
    if (!isConnected || _writeCharacteristic == null) return false;

    try {
      final List<int> testData = [];

      // ESC/POS commands
      const esc = 0x1B;
      const gs = 0x1D;

      // Initialize and center
      testData.addAll([esc, 0x40]); // Initialize
      testData.addAll([esc, 0x61, 0x01]); // Center alignment

      // Test message
      testData.addAll([esc, 0x21, 0x30]); // Double size
      testData.addAll('TEST PRINT'.codeUnits);
      testData.addAll([0x0A, 0x0A]);

      testData.addAll([esc, 0x21, 0x00]); // Normal size
      testData.addAll('Printer berhasil terhubung!'.codeUnits);
      testData.addAll([0x0A, 0x0A, 0x0A]);

      // Cut paper
      testData.addAll([gs, 0x56, 0x00]);

      // Write data in chunks
      const chunkSize = 20;
      final data = Uint8List.fromList(testData);
      for (int i = 0; i < data.length; i += chunkSize) {
        final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);

        await _writeCharacteristic!.write(chunk, withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      return true;
    } catch (e) {
      debugPrint('Error test printing: $e');
      return false;
    }
  }

  /// Enable/disable auto-reconnect
  void setAutoReconnect(bool enabled) {
    _autoReconnect = enabled;
    if (!enabled) {
      _reconnectTimer?.cancel();
    } else if (isConnected) {
      _startReconnectMonitoring();
    }
  }

  /// Dispose resources
  void dispose() {
    _reconnectTimer?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectionStatusController.close();
    disconnect();
  }
}

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}
