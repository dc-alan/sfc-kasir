import 'package:equatable/equatable.dart';

class BluetoothDeviceEntity extends Equatable {
  final String id;
  final String name;
  final int? rssi;
  final bool isConnected;

  const BluetoothDeviceEntity({
    required this.id,
    required this.name,
    this.rssi,
    this.isConnected = false,
  });

  @override
  List<Object?> get props => [id, name, rssi, isConnected];

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'rssi': rssi, 'isConnected': isConnected};
  }

  factory BluetoothDeviceEntity.fromJson(Map<String, dynamic> json) {
    return BluetoothDeviceEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      rssi: json['rssi'] as int?,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }
}
