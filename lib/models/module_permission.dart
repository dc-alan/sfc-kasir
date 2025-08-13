class ModulePermission {
  final String id;
  final String moduleName;
  final String moduleKey;
  final String description;
  final List<String> allowedRoles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModulePermission({
    required this.id,
    required this.moduleName,
    required this.moduleKey,
    required this.description,
    required this.allowedRoles,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module_name': moduleName,
      'module_key': moduleKey,
      'description': description,
      'allowed_roles': allowedRoles.join(','),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ModulePermission.fromMap(Map<String, dynamic> map) {
    return ModulePermission(
      id: map['id'],
      moduleName: map['module_name'],
      moduleKey: map['module_key'],
      description: map['description'],
      allowedRoles: map['allowed_roles']
          .toString()
          .split(',')
          .where((role) => role.isNotEmpty)
          .toList(),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  ModulePermission copyWith({
    String? id,
    String? moduleName,
    String? moduleKey,
    String? description,
    List<String>? allowedRoles,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModulePermission(
      id: id ?? this.id,
      moduleName: moduleName ?? this.moduleName,
      moduleKey: moduleKey ?? this.moduleKey,
      description: description ?? this.description,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isAllowedForRole(String userRole) {
    return isActive && allowedRoles.contains(userRole);
  }
}

// Enum untuk modul-modul yang tersedia
enum AppModule {
  dashboard,
  pos,
  products,
  customers,
  transactions,
  reports,
  userManagement,
  settings,
  backup,
  crm,
  loyalty,
  promotions,
  inventory,
  analytics,
}

extension AppModuleExtension on AppModule {
  String get key {
    switch (this) {
      case AppModule.dashboard:
        return 'dashboard';
      case AppModule.pos:
        return 'pos';
      case AppModule.products:
        return 'products';
      case AppModule.customers:
        return 'customers';
      case AppModule.transactions:
        return 'transactions';
      case AppModule.reports:
        return 'reports';
      case AppModule.userManagement:
        return 'user_management';
      case AppModule.settings:
        return 'settings';
      case AppModule.backup:
        return 'backup';
      case AppModule.crm:
        return 'crm';
      case AppModule.loyalty:
        return 'loyalty';
      case AppModule.promotions:
        return 'promotions';
      case AppModule.inventory:
        return 'inventory';
      case AppModule.analytics:
        return 'analytics';
    }
  }

  String get displayName {
    switch (this) {
      case AppModule.dashboard:
        return 'Dashboard';
      case AppModule.pos:
        return 'Point of Sale';
      case AppModule.products:
        return 'Manajemen Produk';
      case AppModule.customers:
        return 'Manajemen Pelanggan';
      case AppModule.transactions:
        return 'Transaksi';
      case AppModule.reports:
        return 'Laporan';
      case AppModule.userManagement:
        return 'Manajemen User';
      case AppModule.settings:
        return 'Pengaturan';
      case AppModule.backup:
        return 'Backup & Restore';
      case AppModule.crm:
        return 'Customer Relationship Management';
      case AppModule.loyalty:
        return 'Program Loyalitas';
      case AppModule.promotions:
        return 'Promosi & Diskon';
      case AppModule.inventory:
        return 'Manajemen Inventori';
      case AppModule.analytics:
        return 'Analytics & Insights';
    }
  }

  String get description {
    switch (this) {
      case AppModule.dashboard:
        return 'Tampilan ringkasan dan statistik bisnis';
      case AppModule.pos:
        return 'Sistem kasir untuk penjualan';
      case AppModule.products:
        return 'Kelola produk, kategori, dan stok';
      case AppModule.customers:
        return 'Kelola data pelanggan';
      case AppModule.transactions:
        return 'Riwayat dan detail transaksi';
      case AppModule.reports:
        return 'Laporan penjualan dan kinerja';
      case AppModule.userManagement:
        return 'Kelola pengguna dan hak akses';
      case AppModule.settings:
        return 'Pengaturan aplikasi dan sistem';
      case AppModule.backup:
        return 'Backup dan restore data';
      case AppModule.crm:
        return 'Manajemen hubungan pelanggan';
      case AppModule.loyalty:
        return 'Program poin dan reward pelanggan';
      case AppModule.promotions:
        return 'Kelola promosi dan diskon';
      case AppModule.inventory:
        return 'Manajemen stok dan inventori';
      case AppModule.analytics:
        return 'Analisis data dan insights bisnis';
    }
  }

  List<String> get defaultRoles {
    switch (this) {
      case AppModule.dashboard:
        return ['admin', 'owner', 'manager'];
      case AppModule.pos:
        return ['admin', 'cashier', 'owner', 'manager'];
      case AppModule.products:
        return ['admin', 'owner', 'manager'];
      case AppModule.customers:
        return ['admin', 'owner', 'manager', 'cashier'];
      case AppModule.transactions:
        return ['admin', 'owner', 'manager'];
      case AppModule.reports:
        return ['admin', 'owner', 'manager'];
      case AppModule.userManagement:
        return ['admin', 'owner'];
      case AppModule.settings:
        return ['admin', 'owner'];
      case AppModule.backup:
        return ['admin', 'owner'];
      case AppModule.crm:
        return ['admin', 'owner', 'manager'];
      case AppModule.loyalty:
        return ['admin', 'owner', 'manager', 'cashier'];
      case AppModule.promotions:
        return ['admin', 'owner', 'manager'];
      case AppModule.inventory:
        return ['admin', 'owner', 'manager'];
      case AppModule.analytics:
        return ['admin', 'owner', 'manager'];
    }
  }
}
