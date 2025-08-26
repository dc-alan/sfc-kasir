import 'package:get_it/get_it.dart';
import '../../services/bluetooth_printer_service_refactored.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Register Bluetooth printer service as singleton
  getIt.registerSingleton<BluetoothPrinterService>(BluetoothPrinterService());
}
