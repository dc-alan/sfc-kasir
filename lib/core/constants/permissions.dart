enum AppPermission {
  // User Management
  viewUsers,
  createUser,
  editUser,
  deleteUser,
  manageUserRoles,

  // Product Management
  viewProducts,
  createProduct,
  editProduct,
  deleteProduct,
  manageProductCategories,

  // Inventory Management
  viewInventory,
  createInventoryItem,
  editInventoryItem,
  deleteInventoryItem,
  adjustStock,
  viewStockHistory,

  // Transaction Management
  viewTransactions,
  createTransaction,
  editTransaction,
  deleteTransaction,
  processRefunds,
  viewTransactionHistory,

  // Customer Management
  viewCustomers,
  createCustomer,
  editCustomer,
  deleteCustomer,
  manageLoyalty,
  viewCustomerAnalytics,

  // Supplier Management
  viewSuppliers,
  createSupplier,
  editSupplier,
  deleteSupplier,

  // Promotion Management
  viewPromotions,
  createPromotion,
  editPromotion,
  deletePromotion,

  // Reports and Analytics
  viewReports,
  viewAnalytics,
  exportData,
  viewFinancialReports,
  viewInventoryReports,
  viewSalesReports,

  // System Management
  manageSettings,
  viewSystemLogs,
  performBackup,
  restoreBackup,
  manageModules,

  // POS Operations
  accessPOS,
  processPayments,
  applyDiscounts,
  voidTransactions,

  // Advanced Features
  bulkOperations,
  dataImport,
  apiAccess,
  advancedReporting,
}

class PermissionGroups {
  static const Map<String, List<AppPermission>> rolePermissions = {
    'admin': [
      // All permissions for admin
      AppPermission.viewUsers,
      AppPermission.createUser,
      AppPermission.editUser,
      AppPermission.deleteUser,
      AppPermission.manageUserRoles,
      AppPermission.viewProducts,
      AppPermission.createProduct,
      AppPermission.editProduct,
      AppPermission.deleteProduct,
      AppPermission.manageProductCategories,
      AppPermission.viewInventory,
      AppPermission.createInventoryItem,
      AppPermission.editInventoryItem,
      AppPermission.deleteInventoryItem,
      AppPermission.adjustStock,
      AppPermission.viewStockHistory,
      AppPermission.viewTransactions,
      AppPermission.createTransaction,
      AppPermission.editTransaction,
      AppPermission.deleteTransaction,
      AppPermission.processRefunds,
      AppPermission.viewTransactionHistory,
      AppPermission.viewCustomers,
      AppPermission.createCustomer,
      AppPermission.editCustomer,
      AppPermission.deleteCustomer,
      AppPermission.manageLoyalty,
      AppPermission.viewCustomerAnalytics,
      AppPermission.viewSuppliers,
      AppPermission.createSupplier,
      AppPermission.editSupplier,
      AppPermission.deleteSupplier,
      AppPermission.viewPromotions,
      AppPermission.createPromotion,
      AppPermission.editPromotion,
      AppPermission.deletePromotion,
      AppPermission.viewReports,
      AppPermission.viewAnalytics,
      AppPermission.exportData,
      AppPermission.viewFinancialReports,
      AppPermission.viewInventoryReports,
      AppPermission.viewSalesReports,
      AppPermission.manageSettings,
      AppPermission.viewSystemLogs,
      AppPermission.performBackup,
      AppPermission.restoreBackup,
      AppPermission.manageModules,
      AppPermission.accessPOS,
      AppPermission.processPayments,
      AppPermission.applyDiscounts,
      AppPermission.voidTransactions,
      AppPermission.bulkOperations,
      AppPermission.dataImport,
      AppPermission.apiAccess,
      AppPermission.advancedReporting,
    ],
    'owner': [
      // Most permissions for owner (excluding user management)
      AppPermission.viewUsers,
      AppPermission.viewProducts,
      AppPermission.createProduct,
      AppPermission.editProduct,
      AppPermission.deleteProduct,
      AppPermission.manageProductCategories,
      AppPermission.viewInventory,
      AppPermission.createInventoryItem,
      AppPermission.editInventoryItem,
      AppPermission.deleteInventoryItem,
      AppPermission.adjustStock,
      AppPermission.viewStockHistory,
      AppPermission.viewTransactions,
      AppPermission.createTransaction,
      AppPermission.editTransaction,
      AppPermission.processRefunds,
      AppPermission.viewTransactionHistory,
      AppPermission.viewCustomers,
      AppPermission.createCustomer,
      AppPermission.editCustomer,
      AppPermission.deleteCustomer,
      AppPermission.manageLoyalty,
      AppPermission.viewCustomerAnalytics,
      AppPermission.viewSuppliers,
      AppPermission.createSupplier,
      AppPermission.editSupplier,
      AppPermission.deleteSupplier,
      AppPermission.viewPromotions,
      AppPermission.createPromotion,
      AppPermission.editPromotion,
      AppPermission.deletePromotion,
      AppPermission.viewReports,
      AppPermission.viewAnalytics,
      AppPermission.exportData,
      AppPermission.viewFinancialReports,
      AppPermission.viewInventoryReports,
      AppPermission.viewSalesReports,
      AppPermission.manageSettings,
      AppPermission.performBackup,
      AppPermission.restoreBackup,
      AppPermission.accessPOS,
      AppPermission.processPayments,
      AppPermission.applyDiscounts,
      AppPermission.voidTransactions,
      AppPermission.bulkOperations,
      AppPermission.exportData,
    ],
    'cashier': [
      // Basic permissions for cashier
      AppPermission.viewProducts,
      AppPermission.viewInventory,
      AppPermission.viewTransactions,
      AppPermission.createTransaction,
      AppPermission.viewCustomers,
      AppPermission.createCustomer,
      AppPermission.editCustomer,
      AppPermission.accessPOS,
      AppPermission.processPayments,
      AppPermission.applyDiscounts,
    ],
  };

  static List<AppPermission> getPermissionsForRole(String role) {
    return rolePermissions[role.toLowerCase()] ?? [];
  }

  static bool hasPermission(String role, AppPermission permission) {
    final permissions = getPermissionsForRole(role);
    return permissions.contains(permission);
  }
}
