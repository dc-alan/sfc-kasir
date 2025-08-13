class AppConstants {
  // Database
  static const String databaseName = 'sfc_mobile.db';
  static const int databaseVersion = 1;

  // Default Admin Credentials
  static const String defaultAdminUsername = 'admin';
  static const String defaultAdminPassword = '2025GAJI';
  static const String defaultAdminName = 'Administrator';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);
  static const Duration shortCacheExpiration = Duration(minutes: 15);

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 50;
  static const int maxNameLength = 100;

  // Business Rules
  static const double defaultTaxRate = 0.1; // 10%
  static const int maxDiscountPercentage = 100;
  static const int minStockAlert = 10;

  // File Paths
  static const String backupDirectory = 'backups';
  static const String exportDirectory = 'exports';
  static const String tempDirectory = 'temp';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Currency
  static const String currencySymbol = 'Rp';
  static const String currencyCode = 'IDR';
}
