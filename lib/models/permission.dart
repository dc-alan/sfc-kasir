import 'user.dart';

enum Permission {
  // Dashboard permissions
  viewDashboard,

  // POS permissions
  accessPOS,
  processTransaction,
  applyDiscount,
  voidTransaction,

  // Product permissions
  viewProducts,
  addProduct,
  editProduct,
  deleteProduct,
  manageStock,
  viewLowStock,

  // Transaction permissions
  viewTransactions,
  viewAllTransactions,
  editTransaction,
  deleteTransaction,
  refundTransaction,

  // Report permissions
  viewReports,
  viewSalesReports,
  viewInventoryReports,
  viewUserReports,
  exportReports,

  // User management permissions
  viewUsers,
  addUser,
  editUser,
  deleteUser,
  manageUserRoles,
  viewUserActivity,

  // System permissions
  accessSettings,
  manageBackup,
  viewSystemLogs,
  manageIntegrations,

  // Financial permissions
  viewRevenue,
  viewProfit,
  managePricing,
  viewPaymentMethods,
}

class UserPermissions {
  final Set<Permission> permissions;

  const UserPermissions(this.permissions);

  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<Permission> permissionList) {
    return permissionList.any((permission) => permissions.contains(permission));
  }

  bool hasAllPermissions(List<Permission> permissionList) {
    return permissionList.every(
      (permission) => permissions.contains(permission),
    );
  }

  static UserPermissions fromRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const UserPermissions({
          // All permissions for admin
          Permission.viewDashboard,
          Permission.accessPOS,
          Permission.processTransaction,
          Permission.applyDiscount,
          Permission.voidTransaction,
          Permission.viewProducts,
          Permission.addProduct,
          Permission.editProduct,
          Permission.deleteProduct,
          Permission.manageStock,
          Permission.viewLowStock,
          Permission.viewTransactions,
          Permission.viewAllTransactions,
          Permission.editTransaction,
          Permission.deleteTransaction,
          Permission.refundTransaction,
          Permission.viewReports,
          Permission.viewSalesReports,
          Permission.viewInventoryReports,
          Permission.viewUserReports,
          Permission.exportReports,
          Permission.viewUsers,
          Permission.addUser,
          Permission.editUser,
          Permission.deleteUser,
          Permission.manageUserRoles,
          Permission.viewUserActivity,
          Permission.accessSettings,
          Permission.manageBackup,
          Permission.viewSystemLogs,
          Permission.manageIntegrations,
          Permission.viewRevenue,
          Permission.viewProfit,
          Permission.managePricing,
          Permission.viewPaymentMethods,
        });

      case UserRole.owner:
        return const UserPermissions({
          // Owner permissions (all except user management)
          Permission.viewDashboard,
          Permission.viewProducts,
          Permission.addProduct,
          Permission.editProduct,
          Permission.deleteProduct,
          Permission.manageStock,
          Permission.viewLowStock,
          Permission.viewTransactions,
          Permission.viewAllTransactions,
          Permission.editTransaction,
          Permission.refundTransaction,
          Permission.viewReports,
          Permission.viewSalesReports,
          Permission.viewInventoryReports,
          Permission.viewUserReports,
          Permission.exportReports,
          Permission.accessSettings,
          Permission.manageBackup,
          Permission.viewSystemLogs,
          Permission.viewRevenue,
          Permission.viewProfit,
          Permission.managePricing,
          Permission.viewPaymentMethods,
        });

      case UserRole.cashier:
        return const UserPermissions({
          // Limited permissions for cashier
          Permission.accessPOS,
          Permission.processTransaction,
          Permission.viewProducts,
          Permission.viewLowStock,
          Permission.viewTransactions, // Only own transactions
        });
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'permissions': permissions
          .map((p) => p.toString().split('.').last)
          .toList(),
    };
  }

  factory UserPermissions.fromMap(Map<String, dynamic> map) {
    final permissionStrings = List<String>.from(map['permissions'] ?? []);
    final permissions = permissionStrings
        .map(
          (str) => Permission.values.firstWhere(
            (p) => p.toString().split('.').last == str,
            orElse: () => Permission.viewDashboard,
          ),
        )
        .toSet();
    return UserPermissions(permissions);
  }
}

// Permission groups for easier management
class PermissionGroups {
  static const Map<String, List<Permission>> groups = {
    'Dashboard': [Permission.viewDashboard],
    'Point of Sale': [
      Permission.accessPOS,
      Permission.processTransaction,
      Permission.applyDiscount,
      Permission.voidTransaction,
    ],
    'Product Management': [
      Permission.viewProducts,
      Permission.addProduct,
      Permission.editProduct,
      Permission.deleteProduct,
      Permission.manageStock,
      Permission.viewLowStock,
    ],
    'Transaction Management': [
      Permission.viewTransactions,
      Permission.viewAllTransactions,
      Permission.editTransaction,
      Permission.deleteTransaction,
      Permission.refundTransaction,
    ],
    'Reports & Analytics': [
      Permission.viewReports,
      Permission.viewSalesReports,
      Permission.viewInventoryReports,
      Permission.viewUserReports,
      Permission.exportReports,
    ],
    'User Management': [
      Permission.viewUsers,
      Permission.addUser,
      Permission.editUser,
      Permission.deleteUser,
      Permission.manageUserRoles,
      Permission.viewUserActivity,
    ],
    'System Administration': [
      Permission.accessSettings,
      Permission.manageBackup,
      Permission.viewSystemLogs,
      Permission.manageIntegrations,
    ],
    'Financial': [
      Permission.viewRevenue,
      Permission.viewProfit,
      Permission.managePricing,
      Permission.viewPaymentMethods,
    ],
  };

  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.viewDashboard:
        return 'Melihat dashboard utama';
      case Permission.accessPOS:
        return 'Mengakses sistem kasir';
      case Permission.processTransaction:
        return 'Memproses transaksi penjualan';
      case Permission.applyDiscount:
        return 'Memberikan diskon';
      case Permission.voidTransaction:
        return 'Membatalkan transaksi';
      case Permission.viewProducts:
        return 'Melihat daftar produk';
      case Permission.addProduct:
        return 'Menambah produk baru';
      case Permission.editProduct:
        return 'Mengedit informasi produk';
      case Permission.deleteProduct:
        return 'Menghapus produk';
      case Permission.manageStock:
        return 'Mengelola stok produk';
      case Permission.viewLowStock:
        return 'Melihat peringatan stok menipis';
      case Permission.viewTransactions:
        return 'Melihat transaksi';
      case Permission.viewAllTransactions:
        return 'Melihat semua transaksi';
      case Permission.editTransaction:
        return 'Mengedit transaksi';
      case Permission.deleteTransaction:
        return 'Menghapus transaksi';
      case Permission.refundTransaction:
        return 'Melakukan refund';
      case Permission.viewReports:
        return 'Melihat laporan';
      case Permission.viewSalesReports:
        return 'Melihat laporan penjualan';
      case Permission.viewInventoryReports:
        return 'Melihat laporan inventori';
      case Permission.viewUserReports:
        return 'Melihat laporan pengguna';
      case Permission.exportReports:
        return 'Mengekspor laporan';
      case Permission.viewUsers:
        return 'Melihat daftar pengguna';
      case Permission.addUser:
        return 'Menambah pengguna baru';
      case Permission.editUser:
        return 'Mengedit informasi pengguna';
      case Permission.deleteUser:
        return 'Menghapus pengguna';
      case Permission.manageUserRoles:
        return 'Mengelola peran pengguna';
      case Permission.viewUserActivity:
        return 'Melihat aktivitas pengguna';
      case Permission.accessSettings:
        return 'Mengakses pengaturan sistem';
      case Permission.manageBackup:
        return 'Mengelola backup data';
      case Permission.viewSystemLogs:
        return 'Melihat log sistem';
      case Permission.manageIntegrations:
        return 'Mengelola integrasi';
      case Permission.viewRevenue:
        return 'Melihat pendapatan';
      case Permission.viewProfit:
        return 'Melihat keuntungan';
      case Permission.managePricing:
        return 'Mengelola harga';
      case Permission.viewPaymentMethods:
        return 'Melihat metode pembayaran';
    }
  }
}
