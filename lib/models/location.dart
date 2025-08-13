class Location {
  final String id;
  final String name;
  final String code;
  final String address;
  final String? phone;
  final String? email;
  final LocationType type;
  final bool isActive;
  final String? managerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    this.phone,
    this.email,
    this.type = LocationType.branch,
    this.isActive = true,
    this.managerId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'type': type.toString(),
      'is_active': isActive ? 1 : 0,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      type: LocationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => LocationType.branch,
      ),
      isActive: map['is_active'] == 1,
      managerId: map['manager_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Location copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    String? email,
    LocationType? type,
    bool? isActive,
    String? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum LocationType { headquarters, branch, warehouse, outlet }

extension LocationTypeExtension on LocationType {
  String get displayName {
    switch (this) {
      case LocationType.headquarters:
        return 'Kantor Pusat';
      case LocationType.branch:
        return 'Cabang';
      case LocationType.warehouse:
        return 'Gudang';
      case LocationType.outlet:
        return 'Outlet';
    }
  }

  String get code {
    switch (this) {
      case LocationType.headquarters:
        return 'HQ';
      case LocationType.branch:
        return 'BR';
      case LocationType.warehouse:
        return 'WH';
      case LocationType.outlet:
        return 'OT';
    }
  }
}
