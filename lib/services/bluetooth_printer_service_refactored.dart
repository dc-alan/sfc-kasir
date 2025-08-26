import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Enums
enum TextAlignment { left, center, right }

enum TextSize { normal, doubleHeight, doubleWidth, doubleHeightWidth }

enum CutType { full, partial }

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

// Abstract interfaces for better testability
abstract class PrinterConnectionManager {
  Future<bool> initialize();
  Future<bool> connectToDevice(BluetoothDevice device);
  Future<void> disconnect();
  Stream<BluetoothConnectionStatus> get connectionStatusStream;
  bool get isConnected;
}

abstract class PrintCommandExecutor {
  Future<bool> executeCommands(List<PrintCommand> commands);
  Future<bool> printRawData(Uint8List data);
}

// Print command interfaces
abstract class PrintCommand {
  List<int> toBytes();
}

// Value objects for print configuration
class PrintTextConfig {
  final TextAlignment alignment;
  final TextSize size;
  final bool bold;
  final int lineFeeds;

  const PrintTextConfig({
    this.alignment = TextAlignment.left,
    this.size = TextSize.normal,
    this.bold = false,
    this.lineFeeds = 1,
  });
}

class PrintLineConfig {
  final String character;
  final int length;
  final TextAlignment alignment;

  const PrintLineConfig({
    this.character = '-',
    this.length = 32,
    this.alignment = TextAlignment.left,
  });
}

// Print commands implementations
class TextPrintCommand implements PrintCommand {
  final String text;
  final PrintTextConfig config;

  TextPrintCommand(this.text, {PrintTextConfig? config})
    : config = config ?? const PrintTextConfig();

  @override
  List<int> toBytes() {
    final bytes = <int>[];
    const esc = 0x1B;

    // Set alignment
    bytes.addAll(_getAlignmentBytes(esc, config.alignment));

    // Set text size and style
    bytes.addAll(_getStyleBytes(esc, config.size, config.bold));

    // Add text
    bytes.addAll(utf8.encode(text));

    // Add line feeds
    if (config.lineFeeds > 0) {
      bytes.addAll(List.filled(config.lineFeeds, 0x0A));
    }

    return bytes;
  }

  List<int> _getAlignmentBytes(int esc, TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.left:
        return [esc, 0x61, 0x00];
      case TextAlignment.center:
        return [esc, 0x61, 0x01];
      case TextAlignment.right:
        return [esc, 0x61, 0x02];
    }
  }

  List<int> _getStyleBytes(int esc, TextSize size, bool bold) {
    int sizeCommand = 0x00;
    switch (size) {
      case TextSize.doubleHeight:
        sizeCommand = 0x10;
        break;
      case TextSize.doubleWidth:
        sizeCommand = 0x20;
        break;
      case TextSize.doubleHeightWidth:
        sizeCommand = 0x30;
        break;
      case TextSize.normal:
        sizeCommand = 0x00;
        break;
    }
    if (bold) sizeCommand |= 0x08;
    return [esc, 0x21, sizeCommand];
  }
}

class LineSeparatorCommand implements PrintCommand {
  final PrintLineConfig config;

  const LineSeparatorCommand({PrintLineConfig? config})
    : config = config ?? const PrintLineConfig();

  @override
  List<int> toBytes() {
    final bytes = <int>[];
    const esc = 0x1B;

    // Set alignment
    bytes.addAll(_getAlignmentBytes(esc, config.alignment));

    // Add separator line
    bytes.addAll(utf8.encode(config.character * config.length));

    return bytes;
  }

  List<int> _getAlignmentBytes(int esc, TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.left:
        return [esc, 0x61, 0x00];
      case TextAlignment.center:
        return [esc, 0x61, 0x01];
      case TextAlignment.right:
        return [esc, 0x61, 0x02];
    }
  }
}

class CutPaperCommand implements PrintCommand {
  final CutType cutType;

  const CutPaperCommand({this.cutType = CutType.partial});

  @override
  List<int> toBytes() {
    const gs = 0x1D;
    return cutType == CutType.full ? [gs, 0x56, 0x00] : [gs, 0x56, 0x42, 0x00];
  }
}

class RawDataCommand implements PrintCommand {
  final List<int> data;

  const RawDataCommand(this.data);

  @override
  List<int> toBytes() => data;
}

// Connection manager implementation
class BluetoothConnectionManager implements PrinterConnectionManager {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final _connectionStatusController =
      StreamController<BluetoothConnectionStatus>.broadcast();

  @override
  Stream<BluetoothConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  @override
  bool get isConnected => _connectedDevice?.isConnected ?? false;

  @override
  Future<bool> initialize() async {
    try {
      final permissionsGranted = await _requestBluetoothPermissions();
      if (!permissionsGranted) return false;

      final bluetoothSupported = await _checkBluetoothSupport();
      if (!bluetoothSupported) return false;

      await _ensureBluetoothEnabled();
      return true;
    } catch (error) {
      debugPrint('Error initializing Bluetooth: $error');
      return false;
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    final results = await Future.wait(permissions.map((p) => p.request()));
    return results.every((status) => status == PermissionStatus.granted);
  }

  Future<bool> _checkBluetoothSupport() async {
    return await FlutterBluePlus.isSupported ?? false;
  }

  Future<void> _ensureBluetoothEnabled() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connectionStatusController.add(BluetoothConnectionStatus.connecting);

      await disconnect();

      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      _setupConnectionMonitoring(device);
      await _discoverServices(device);

      _connectionStatusController.add(BluetoothConnectionStatus.connected);
      return true;
    } catch (error) {
      _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
      debugPrint('Failed to connect: $error');
      return false;
    }
  }

  void _setupConnectionMonitoring(BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
      }
    });
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.writeWithoutResponse) {
          _writeCharacteristic = characteristic;
          return;
        } else if (characteristic.properties.write) {
          _writeCharacteristic = characteristic;
        }
      }
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _connectionSubscription?.cancel();

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _connectedDevice = null;
      _writeCharacteristic = null;
      _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
    } catch (error) {
      debugPrint('Error disconnecting: $error');
    }
  }

  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;
}

// Device discovery service
class BluetoothDeviceDiscovery {
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Stream<BluetoothDevice> discoverDevices() {
    final controller = StreamController<BluetoothDevice>.broadcast();

    _scanSubscription?.cancel();

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: false,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final device = result.device;
        if (device.platformName.isNotEmpty ||
            device.remoteId.toString().isNotEmpty) {
          controller.add(device);
        }
      }
    });

    Timer(const Duration(seconds: 16), () {
      FlutterBluePlus.stopScan();
      controller.close();
    });

    return controller.stream;
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      return bondedDevices.where(_isPrinterDevice).toList();
    } catch (error) {
      debugPrint('Error getting bonded devices: $error');
      return [];
    }
  }

  bool _isPrinterDevice(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    return name.contains('printer') ||
        name.contains('pos') ||
        name.contains('thermal') ||
        name.contains('receipt');
  }

  void dispose() {
    _scanSubscription?.cancel();
  }
}

// Print executor implementation
class ThermalPrintExecutor implements PrintCommandExecutor {
  final BluetoothConnectionManager _connectionManager;
  final List<int> _wakeUpCommands = [0x1B, 0x40]; // ESC @ - Initialize printer
  final List<int> _completionCommands = [0x0A, 0x0A, 0x0A]; // Line feeds

  ThermalPrintExecutor(this._connectionManager);

  @override
  Future<bool> executeCommands(List<PrintCommand> commands) async {
    final data = commands.expand((cmd) => cmd.toBytes()).toList();
    return printRawData(Uint8List.fromList(data));
  }

  @override
  Future<bool> printRawData(Uint8List data) async {
    if (!_connectionManager.isConnected) {
      debugPrint('No printer connected');
      return false;
    }

    try {
      await _sendWakeUpCommands();
      final success = await _sendDataToPrinter(data);

      if (success) {
        await _sendCompletionCommands();
        return true;
      }

      return false;
    } catch (error) {
      debugPrint('Error printing: $error');
      return false;
    }
  }

  Future<void> _sendWakeUpCommands() async {
    final characteristic = _getWriteCharacteristic();
    if (characteristic != null) {
      await characteristic.write(_wakeUpCommands);
    }
  }

  Future<bool> _sendDataToPrinter(Uint8List data) async {
    final characteristic = _getWriteCharacteristic();
    if (characteristic == null) return false;

    const chunkSize = 512;
    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      try {
        await characteristic.write(chunk);
      } catch (error) {
        debugPrint('Error sending chunk: $error');
        return false;
      }
    }

    return true;
  }

  Future<void> _sendCompletionCommands() async {
    final characteristic = _getWriteCharacteristic();
    if (characteristic != null) {
      await characteristic.write(_completionCommands);
    }
  }

  BluetoothCharacteristic? _getWriteCharacteristic() {
    final manager = _connectionManager;
    return manager.writeCharacteristic;
  }
}

// Main service class
class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final BluetoothConnectionManager _connectionManager =
      BluetoothConnectionManager();
  final BluetoothDeviceDiscovery _deviceDiscovery = BluetoothDeviceDiscovery();
  final ThermalPrintExecutor _printExecutor = ThermalPrintExecutor(
    BluetoothConnectionManager(),
  );

  final bool _autoReconnect = true;
  Timer? _reconnectTimer;

  // Public interface
  Future<bool> initialize() => _connectionManager.initialize();

  Stream<BluetoothConnectionStatus> get connectionStatusStream =>
      _connectionManager.connectionStatusStream;

  bool get isConnected => _connectionManager.isConnected;

  Stream<BluetoothDevice> discoverDevices() =>
      _deviceDiscovery.discoverDevices();

  Future<List<BluetoothDevice>> getBondedDevices() =>
      _deviceDiscovery.getBondedDevices();

  Future<bool> connectToDevice(BluetoothDevice device) async {
    final success = await _connectionManager.connectToDevice(device);
    if (success && _autoReconnect) {
      _startReconnectMonitoring();
    }
    return success;
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _connectionManager.disconnect();
  }

  Future<bool> printRawData(Uint8List data) =>
      _printExecutor.printRawData(data);

  Future<bool> printText(
    String text, {
    TextAlignment alignment = TextAlignment.left,
    TextSize size = TextSize.normal,
    bool bold = false,
    int lineFeeds = 1,
  }) {
    final config = PrintTextConfig(
      alignment: alignment,
      size: size,
      bold: bold,
      lineFeeds: lineFeeds,
    );

    final command = TextPrintCommand(text, config: config);
    return _printExecutor.executeCommands([command]);
  }

  Future<bool> printLine({
    String character = '-',
    int length = 32,
    TextAlignment alignment = TextAlignment.left,
  }) {
    final config = PrintLineConfig(
      character: character,
      length: length,
      alignment: alignment,
    );

    final command = LineSeparatorCommand(config: config);
    return _printExecutor.executeCommands([command]);
  }

  Future<bool> printReceipt(List<PrintCommand> commands) =>
      _printExecutor.executeCommands(commands);

  Future<bool> cutPaper({CutType cutType = CutType.partial}) {
    final command = CutPaperCommand(cutType: cutType);
    return _printExecutor.executeCommands([command]);
  }

  void _startReconnectMonitoring() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Reconnection logic would go here
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _deviceDiscovery.dispose();
  }
}
