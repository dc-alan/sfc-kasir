import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_settings.dart';
import '../models/transaction.dart' as model;

// Enums for text formatting
enum TextAlignment { left, center, right }

enum TextSize { normal, doubleHeight, doubleWidth, doubleHeightWidth }

enum CutType { full, partial }

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

// Abstract class for print commands
abstract class PrintCommand {
  List<int> toBytes();
}

// Text print command
class TextPrintCommand extends PrintCommand {
  final String text;
  final TextAlignment alignment;
  final TextSize size;
  final bool bold;

  TextPrintCommand({
    required this.text,
    this.alignment = TextAlignment.left,
    this.size = TextSize.normal,
    this.bold = false,
  });

  @override
  List<int> toBytes() {
    final List<int> bytes = [];
    const esc = 0x1B;

    // Set alignment
    switch (alignment) {
      case TextAlignment.left:
        bytes.addAll([esc, 0x61, 0x00]);
        break;
      case TextAlignment.center:
        bytes.addAll([esc, 0x61, 0x01]);
        break;
      case TextAlignment.right:
        bytes.addAll([esc, 0x61, 0x02]);
        break;
    }

    // Set text size and style
    int sizeCommand = 0x00;
    if (size == TextSize.doubleHeight) sizeCommand = 0x10;
    if (size == TextSize.doubleWidth) sizeCommand = 0x20;
    if (size == TextSize.doubleHeightWidth) sizeCommand = 0x30;
    if (bold) sizeCommand |= 0x08;

    bytes.addAll([esc, 0x21, sizeCommand]);

    // Add text
    bytes.addAll(utf8.encode(text));

    return bytes;
  }
}

// Line feed command
class LineFeedCommand extends PrintCommand {
  final int lines;

  LineFeedCommand({this.lines = 1});

  @override
  List<int> toBytes() {
    return List.filled(lines, 0x0A);
  }
}

// Line separator command
class LineSeparatorCommand extends PrintCommand {
  final String character;
  final int length;
  final TextAlignment alignment;

  LineSeparatorCommand({
    this.character = '-',
    this.length = 32,
    this.alignment = TextAlignment.left,
  });

  @override
  List<int> toBytes() {
    final List<int> bytes = [];
    const esc = 0x1B;

    // Set alignment
    switch (alignment) {
      case TextAlignment.left:
        bytes.addAll([esc, 0x61, 0x00]);
        break;
      case TextAlignment.center:
        bytes.addAll([esc, 0x61, 0x01]);
        break;
      case TextAlignment.right:
        bytes.addAll([esc, 0x61, 0x02]);
        break;
    }

    // Add separator line
    bytes.addAll(utf8.encode(character * length));

    return bytes;
  }
}

// Cut paper command
class CutPaperCommand extends PrintCommand {
  final CutType cutType;

  CutPaperCommand({this.cutType = CutType.partial});

  @override
  List<int> toBytes() {
    const gs = 0x1D;
    if (cutType == CutType.full) {
      return [gs, 0x56, 0x00]; // Full cut
    } else {
      return [gs, 0x56, 0x42, 0x00]; // Partial cut
    }
  }
}

// Raw command
class RawCommand extends PrintCommand {
  final List<int> command;

  RawCommand(this.command);

  @override
  List<int> toBytes() {
    return command;
  }
}

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

        // Show all devices for now, let user choose
        // We can filter later or add device name patterns
        if (device.platformName.isNotEmpty) {
          controller.add(device);
        } else if (device.remoteId.toString().isNotEmpty) {
          // Include devices without names but with valid IDs
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
      debugPrint('Found ${services.length} services');

      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? writeWithoutResponseChar;

      for (BluetoothService service in services) {
        debugPrint('Service UUID: ${service.uuid}');
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          debugPrint(
            'Characteristic UUID: ${characteristic.uuid}, Properties: write=${characteristic.properties.write}, writeWithoutResponse=${characteristic.properties.writeWithoutResponse}',
          );

          // Prefer writeWithoutResponse for thermal printers
          if (characteristic.properties.writeWithoutResponse) {
            writeWithoutResponseChar = characteristic;
          } else if (characteristic.properties.write) {
            writeChar = characteristic;
          }
        }
      }

      // Use writeWithoutResponse if available, otherwise use write
      _writeCharacteristic = writeWithoutResponseChar ?? writeChar;

      if (_writeCharacteristic == null) {
        debugPrint('No write characteristic found in any service');
        await disconnect();
        _isConnecting = false;
        _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
        return false;
      }

      debugPrint(
        'Using characteristic: ${_writeCharacteristic!.uuid} with writeWithoutResponse: ${_writeCharacteristic!.properties.writeWithoutResponse}',
      );

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

  /// Print raw data directly to thermal printer
  Future<bool> printRawData(Uint8List data) async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('No printer connected or no write characteristic');
      return false;
    }

    try {
      debugPrint('Starting raw data print process...');

      // Send printer wake-up commands first
      await _sendWakeUpCommands();

      debugPrint('Sending raw data: ${data.length} bytes');

      // Send data with improved transmission method
      final success = await _sendDataToprinter(data);

      if (success) {
        // Send completion commands to ensure printing
        await _sendCompletionCommands();
        debugPrint('Raw data printed successfully');
        return true;
      } else {
        debugPrint('Failed to send raw data to printer');
        return false;
      }
    } catch (e) {
      debugPrint('Error printing raw data: $e');
      return false;
    }
  }

  /// Print formatted text with alignment and styling
  Future<bool> printText(
    String text, {
    TextAlignment alignment = TextAlignment.left,
    TextSize size = TextSize.normal,
    bool bold = false,
    int lineFeeds = 1,
  }) async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('No printer connected or no write characteristic');
      return false;
    }

    try {
      final List<int> bytes = [];

      // Create text command
      final textCommand = TextPrintCommand(
        text: text,
        alignment: alignment,
        size: size,
        bold: bold,
      );

      // Add text bytes
      bytes.addAll(textCommand.toBytes());

      // Add line feeds
      if (lineFeeds > 0) {
        final lineFeedCommand = LineFeedCommand(lines: lineFeeds);
        bytes.addAll(lineFeedCommand.toBytes());
      }

      return await printRawData(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('Error printing text: $e');
      return false;
    }
  }

  /// Print separator line
  Future<bool> printLine({
    String character = '-',
    int length = 32,
    TextAlignment alignment = TextAlignment.left,
    int lineFeeds = 1,
  }) async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('No printer connected or no write characteristic');
      return false;
    }

    try {
      final List<int> bytes = [];

      // Create line separator command
      final lineCommand = LineSeparatorCommand(
        character: character,
        length: length,
        alignment: alignment,
      );

      // Add line bytes
      bytes.addAll(lineCommand.toBytes());

      // Add line feeds
      if (lineFeeds > 0) {
        final lineFeedCommand = LineFeedCommand(lines: lineFeeds);
        bytes.addAll(lineFeedCommand.toBytes());
      }

      return await printRawData(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('Error printing line: $e');
      return false;
    }
  }

  /// Send raw ESC/POS command
  Future<bool> sendRawCommand(List<int> command) async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('No printer connected or no write characteristic');
      return false;
    }

    try {
      return await printRawData(Uint8List.fromList(command));
    } catch (e) {
      debugPrint('Error sending raw command: $e');
      return false;
    }
  }

  /// Print using a list of print commands
  Future<bool> printCustomReceipt(List<PrintCommand> commands) async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('No printer connected or no write characteristic');
      return false;
    }

    try {
      final List<int> bytes = [];

      // Initialize printer
      bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize printer

      // Process all commands
      for (final command in commands) {
        bytes.addAll(command.toBytes());
      }

      return await printRawData(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('Error printing custom receipt: $e');
      return false;
    }
  }

  /// Cut paper
  Future<bool> cutPaper({CutType cutType = CutType.partial}) async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('No printer connected or no write characteristic');
      return false;
    }

    try {
      final cutCommand = CutPaperCommand(cutType: cutType);
      return await printRawData(Uint8List.fromList(cutCommand.toBytes()));
    } catch (e) {
      debugPrint('Error cutting paper: $e');
      return false;
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
      debugPrint('Starting receipt print process...');

      // Send printer wake-up commands first
      await _sendWakeUpCommands();

      final receiptData = _generateReceiptData(
        transaction,
        settings,
        cashierName,
      );

      debugPrint('Generated receipt data: ${receiptData.length} bytes');

      // Send data with improved transmission method
      final success = await _sendDataToprinter(receiptData);

      if (success) {
        // Send completion commands to ensure printing
        await _sendCompletionCommands();
        debugPrint('Receipt printed successfully');
        return true;
      } else {
        debugPrint('Failed to send data to printer');
        return false;
      }
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

    // Enhanced initialization sequence
    bytes.addAll([esc, 0x40]); // Initialize printer
    bytes.addAll([esc, 0x74, 0x00]); // Select character code table (CP437)
    bytes.addAll([esc, 0x52, 0x00]); // Select international character set
    bytes.addAll([esc, 0x61, 0x01]); // Center alignment

    // Receipt header with proper encoding
    bytes.addAll([esc, 0x21, 0x30]); // Double height and width
    bytes.addAll(utf8.encode(settings.receiptHeader));
    bytes.addAll([0x0A, 0x0A]); // Line feeds

    // Business name with proper encoding
    bytes.addAll([esc, 0x21, 0x20]); // Double height
    bytes.addAll(utf8.encode(settings.businessName.toUpperCase()));
    bytes.addAll([0x0A]); // Line feed

    // Reset font size
    bytes.addAll([esc, 0x21, 0x00]); // Normal size

    // Business address with proper encoding
    bytes.addAll(utf8.encode(settings.businessAddress));
    bytes.addAll([0x0A]);

    // Business phone
    if (settings.businessPhone.isNotEmpty) {
      bytes.addAll(utf8.encode('Telp: ${settings.businessPhone}'));
      bytes.addAll([0x0A]);
    }

    // Business email
    if (settings.businessEmail.isNotEmpty) {
      bytes.addAll(utf8.encode('Email: ${settings.businessEmail}'));
      bytes.addAll([0x0A]);
    }

    // Separator line
    bytes.addAll([0x0A]);
    bytes.addAll(utf8.encode('================================'));
    bytes.addAll([0x0A, 0x0A]);

    // Left alignment for transaction details
    bytes.addAll([esc, 0x61, 0x00]); // Left alignment

    // Transaction info with proper encoding
    bytes.addAll(
      utf8.encode(
        'No. Transaksi: ${transaction.id.substring(0, 8).toUpperCase()}',
      ),
    );
    bytes.addAll([0x0A]);

    final dateFormat =
        '${transaction.createdAt.day.toString().padLeft(2, '0')}/${transaction.createdAt.month.toString().padLeft(2, '0')}/${transaction.createdAt.year} ${transaction.createdAt.hour.toString().padLeft(2, '0')}:${transaction.createdAt.minute.toString().padLeft(2, '0')}';
    bytes.addAll(utf8.encode('Tanggal: $dateFormat'));
    bytes.addAll([0x0A]);

    bytes.addAll(utf8.encode('Kasir: $cashierName'));
    bytes.addAll([0x0A]);

    if (transaction.customer != null) {
      bytes.addAll(utf8.encode('Pelanggan: ${transaction.customer!.name}'));
      bytes.addAll([0x0A]);
    }

    bytes.addAll(
      utf8.encode(
        'Metode Bayar: ${_getPaymentMethodText(transaction.paymentMethod)}',
      ),
    );
    bytes.addAll([0x0A, 0x0A]);

    // Items header
    bytes.addAll(utf8.encode('DETAIL PEMBELIAN'));
    bytes.addAll([0x0A]);
    bytes.addAll(utf8.encode('--------------------------------'));
    bytes.addAll([0x0A]);

    // Items with proper encoding
    for (final item in transaction.items) {
      // Product name with proper encoding
      bytes.addAll(utf8.encode(item.product.name));
      bytes.addAll([0x0A]);

      final itemLine = '${item.quantity} x ${_formatCurrency(item.unitPrice)}';
      final totalLine = _formatCurrency(item.totalPrice);
      final spaces = 32 - itemLine.length - totalLine.length;

      bytes.addAll(utf8.encode(itemLine));
      bytes.addAll(List.filled(spaces > 0 ? spaces : 1, 0x20)); // Spaces
      bytes.addAll(utf8.encode(totalLine));
      bytes.addAll([0x0A]);
    }

    // Separator
    bytes.addAll([0x0A]);
    bytes.addAll(utf8.encode('--------------------------------'));
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
    bytes.addAll(utf8.encode('================================'));
    bytes.addAll([0x0A]);
    bytes.addAll([esc, 0x21, 0x20]); // Double height
    _addSummaryLine(bytes, 'TOTAL', transaction.total);
    bytes.addAll([esc, 0x21, 0x00]); // Normal size

    _addSummaryLine(bytes, 'Bayar', transaction.amountPaid);
    _addSummaryLine(bytes, 'Kembalian', transaction.change);

    // Footer with proper encoding
    bytes.addAll([0x0A, 0x0A]);
    bytes.addAll([esc, 0x61, 0x01]); // Center alignment
    bytes.addAll([esc, 0x21, 0x10]); // Bold
    bytes.addAll(utf8.encode(settings.receiptFooter));
    bytes.addAll([esc, 0x21, 0x00]); // Normal
    bytes.addAll([0x0A]);

    bytes.addAll(utf8.encode('Barang yang sudah dibeli'));
    bytes.addAll([0x0A]);
    bytes.addAll(utf8.encode('tidak dapat dikembalikan'));
    bytes.addAll([0x0A, 0x0A]);

    // Notes with proper encoding
    if (transaction.notes != null && transaction.notes!.isNotEmpty) {
      bytes.addAll(utf8.encode('Catatan: ${transaction.notes}'));
      bytes.addAll([0x0A, 0x0A]);
    }

    // Enhanced paper cutting sequence
    bytes.addAll([0x0A, 0x0A]); // Extra line feeds before cut
    bytes.addAll([gs, 0x56, 0x42, 0x00]); // Partial cut (more reliable)
    bytes.addAll([0x0A]); // Final line feed

    return Uint8List.fromList(bytes);
  }

  void _addSummaryLine(List<int> bytes, String label, double amount) {
    final amountStr = _formatCurrency(amount);
    final spaces = 32 - label.length - amountStr.length;

    bytes.addAll(utf8.encode(label));
    bytes.addAll(List.filled(spaces > 0 ? spaces : 1, 0x20)); // Spaces
    bytes.addAll(utf8.encode(amountStr));
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

  /// Send wake-up commands to printer
  Future<void> _sendWakeUpCommands() async {
    if (_writeCharacteristic == null) return;

    try {
      debugPrint('Sending wake-up commands to printer...');

      // Wake-up sequence for thermal printers
      final wakeUpCommands = <int>[
        // Multiple wake-up attempts
        0x10, 0x04, 0x01, // DLE EOT n (Real-time status transmission)
        0x10, 0x04, 0x02, // DLE EOT n (Real-time status transmission)
        0x1B, 0x40, // ESC @ (Initialize printer)
        0x1B, 0x3D, 0x01, // ESC = n (Select peripheral device)
        0x1D, 0x61, 0x00, // GS a n (Enable/disable Automatic Status Back)
      ];

      // Send wake-up commands in small chunks
      await _writeCharacteristic!.write(wakeUpCommands, withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('Wake-up commands sent successfully');
    } catch (e) {
      debugPrint('Error sending wake-up commands: $e');
    }
  }

  /// Send data to printer with improved transmission
  Future<bool> _sendDataToprinter(Uint8List data) async {
    if (_writeCharacteristic == null) return false;

    try {
      debugPrint('Sending ${data.length} bytes to printer...');

      // Use smaller, more reliable chunk size for thermal printers
      const chunkSize = 20; // Back to 20 bytes for better compatibility
      int totalChunks = (data.length / chunkSize).ceil();

      // Determine write method based on characteristic properties
      final useWriteWithoutResponse =
          _writeCharacteristic!.properties.writeWithoutResponse;
      debugPrint('Using writeWithoutResponse: $useWriteWithoutResponse');

      for (int i = 0; i < data.length; i += chunkSize) {
        final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);
        final chunkNumber = (i / chunkSize).floor() + 1;

        debugPrint(
          'Sending chunk $chunkNumber/$totalChunks (${chunk.length} bytes)',
        );

        // Send chunk with retry mechanism
        bool chunkSent = false;
        int retryCount = 0;
        const maxRetries = 3;

        while (!chunkSent && retryCount < maxRetries) {
          try {
            if (useWriteWithoutResponse) {
              await _writeCharacteristic!.write(chunk, withoutResponse: true);
            } else {
              await _writeCharacteristic!.write(chunk, withoutResponse: false);
            }
            chunkSent = true;

            // Longer delay for better reliability
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            retryCount++;
            debugPrint('Chunk $chunkNumber failed (attempt $retryCount): $e');
            if (retryCount < maxRetries) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        }

        if (!chunkSent) {
          debugPrint(
            'Failed to send chunk $chunkNumber after $maxRetries attempts',
          );
          return false;
        }
      }

      debugPrint('All data sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error sending data to printer: $e');
      return false;
    }
  }

  /// Send completion commands to ensure printing
  Future<void> _sendCompletionCommands() async {
    if (_writeCharacteristic == null) return;

    try {
      debugPrint('Sending completion commands...');

      // Completion sequence to ensure printing
      final completionCommands = <int>[
        0x0A, 0x0A, // Extra line feeds
        0x1D, 0x56, 0x00, // GS V m (Cut paper - full cut)
        0x1B, 0x64, 0x02, // ESC d n (Print and feed n lines)
        0x10, 0x14, 0x01, 0x00, 0x05, // DLE DC4 (Generate pulse)
      ];

      await _writeCharacteristic!.write(
        completionCommands,
        withoutResponse: true,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('Completion commands sent successfully');
    } catch (e) {
      debugPrint('Error sending completion commands: $e');
    }
  }

  /// Test printer connection with simple, reliable approach
  Future<bool> testPrint() async {
    if (!isConnected || _writeCharacteristic == null) {
      debugPrint('Test print failed: No connection or characteristic');
      return false;
    }

    try {
      debugPrint('Starting simple test print...');

      // Very simple test data that should work with most thermal printers
      final List<int> testData = [];

      // Basic ESC/POS commands
      const esc = 0x1B;

      // Minimal initialization
      testData.addAll([esc, 0x40]); // ESC @ - Initialize printer
      testData.addAll([0x0A]); // Line feed

      // Simple test message using basic ASCII
      testData.addAll('TEST PRINT'.codeUnits);
      testData.addAll([0x0A, 0x0A]); // Two line feeds

      testData.addAll('Printer OK!'.codeUnits);
      testData.addAll([0x0A, 0x0A, 0x0A]); // Three line feeds

      // Add timestamp in simple format
      final now = DateTime.now();
      final timeStr = '${now.hour}:${now.minute}:${now.second}';
      testData.addAll(timeStr.codeUnits);
      testData.addAll([
        0x0A,
        0x0A,
        0x0A,
        0x0A,
      ]); // Four line feeds to advance paper

      debugPrint('Test data prepared: ${testData.length} bytes');

      // Send data in very small chunks for maximum compatibility
      const chunkSize = 10; // Very small chunks
      final useWriteWithoutResponse =
          _writeCharacteristic!.properties.writeWithoutResponse;

      for (int i = 0; i < testData.length; i += chunkSize) {
        final end = (i + chunkSize < testData.length)
            ? i + chunkSize
            : testData.length;
        final chunk = testData.sublist(i, end);

        try {
          if (useWriteWithoutResponse) {
            await _writeCharacteristic!.write(chunk, withoutResponse: true);
          } else {
            await _writeCharacteristic!.write(chunk, withoutResponse: false);
          }

          // Wait between chunks
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (e) {
          debugPrint('Failed to send test chunk: $e');
          return false;
        }
      }

      debugPrint('Test print data sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error in test print: $e');
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
