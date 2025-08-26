import 'package:flutter/material.dart';

class AppSettings {
  final String appName;
  final String appVersion;
  final String primaryColor;
  final String secondaryColor;
  final String logoPath;
  final String splashScreenDuration;
  final bool showSplashScreen;

  // Receipt/Nota Settings
  final String receiptHeader;
  final String receiptFooter;
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final bool showBusinessLogo;
  final bool printCustomerInfo;
  final bool printItemDetails;
  final String receiptPaperSize; // 'A4', '80mm', '58mm'

  // Theme Settings
  final bool isDarkMode;
  final String fontFamily;
  final double fontSize;
  final String language; // 'id', 'en'

  // System Settings
  final bool enableNotifications;
  final bool enableSounds;
  final bool autoBackup;
  final int autoBackupInterval; // in hours
  final String backupLocation;
  final int transactionStorageDays; // Storage duration for transactions in days

  const AppSettings({
    this.appName = 'SFC Mobile',
    this.appVersion = '1.0.0',
    this.primaryColor = '#2196F3',
    this.secondaryColor = '#03DAC6',
    this.logoPath = '',
    this.splashScreenDuration = '3',
    this.showSplashScreen = true,

    // Receipt defaults
    this.receiptHeader = 'STRUK PEMBELIAN',
    this.receiptFooter = 'Terima kasih atas kunjungan Anda',
    this.businessName = 'Shella Fried Chicken',
    this.businessAddress = 'Jl. Contoh No. 123, Kota',
    this.businessPhone = '0812-3456-7890',
    this.businessEmail = 'info@sfc.com',
    this.showBusinessLogo = true,
    this.printCustomerInfo = true,
    this.printItemDetails = true,
    this.receiptPaperSize = '80mm',

    // Theme defaults
    this.isDarkMode = false,
    this.fontFamily = 'Roboto',
    this.fontSize = 14.0,
    this.language = 'id',

    // System defaults
    this.enableNotifications = true,
    this.enableSounds = true,
    this.autoBackup = false,
    this.autoBackupInterval = 24,
    this.backupLocation = 'local',
    this.transactionStorageDays = 30, // Default 1 month
  });

  Map<String, dynamic> toMap() {
    return {
      'app_name': appName,
      'app_version': appVersion,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'logo_path': logoPath,
      'splash_screen_duration': splashScreenDuration,
      'show_splash_screen': showSplashScreen ? 1 : 0,

      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'business_name': businessName,
      'business_address': businessAddress,
      'business_phone': businessPhone,
      'business_email': businessEmail,
      'show_business_logo': showBusinessLogo ? 1 : 0,
      'print_customer_info': printCustomerInfo ? 1 : 0,
      'print_item_details': printItemDetails ? 1 : 0,
      'receipt_paper_size': receiptPaperSize,

      'is_dark_mode': isDarkMode ? 1 : 0,
      'font_family': fontFamily,
      'font_size': fontSize,
      'language': language,

      'enable_notifications': enableNotifications ? 1 : 0,
      'enable_sounds': enableSounds ? 1 : 0,
      'auto_backup': autoBackup ? 1 : 0,
      'auto_backup_interval': autoBackupInterval,
      'backup_location': backupLocation,
      'transaction_storage_days': transactionStorageDays,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      appName: map['app_name'] ?? 'SFC Mobile',
      appVersion: map['app_version'] ?? '1.0.0',
      primaryColor: map['primary_color'] ?? '#2196F3',
      secondaryColor: map['secondary_color'] ?? '#03DAC6',
      logoPath: map['logo_path'] ?? '',
      splashScreenDuration: map['splash_screen_duration'] ?? '3',
      showSplashScreen: (map['show_splash_screen'] ?? 1) == 1,

      receiptHeader: map['receipt_header'] ?? 'STRUK PEMBELIAN',
      receiptFooter:
          map['receipt_footer'] ?? 'Terima kasih atas kunjungan Anda',
      businessName: map['business_name'] ?? 'Shella Fried Chicken',
      businessAddress: map['business_address'] ?? 'Jl. Contoh No. 123, Kota',
      businessPhone: map['business_phone'] ?? '0812-3456-7890',
      businessEmail: map['business_email'] ?? 'info@sfc.com',
      showBusinessLogo: (map['show_business_logo'] ?? 1) == 1,
      printCustomerInfo: (map['print_customer_info'] ?? 1) == 1,
      printItemDetails: (map['print_item_details'] ?? 1) == 1,
      receiptPaperSize: map['receipt_paper_size'] ?? '80mm',

      isDarkMode: (map['is_dark_mode'] ?? 0) == 1,
      fontFamily: map['font_family'] ?? 'Roboto',
      fontSize: (map['font_size'] ?? 14.0).toDouble(),
      language: map['language'] ?? 'id',

      enableNotifications: (map['enable_notifications'] ?? 1) == 1,
      enableSounds: (map['enable_sounds'] ?? 1) == 1,
      autoBackup: (map['auto_backup'] ?? 0) == 1,
      autoBackupInterval: map['auto_backup_interval'] ?? 24,
      backupLocation: map['backup_location'] ?? 'local',
      transactionStorageDays: map['transaction_storage_days'] ?? 30,
    );
  }

  AppSettings copyWith({
    String? appName,
    String? appVersion,
    String? primaryColor,
    String? secondaryColor,
    String? logoPath,
    String? splashScreenDuration,
    bool? showSplashScreen,

    String? receiptHeader,
    String? receiptFooter,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    bool? showBusinessLogo,
    bool? printCustomerInfo,
    bool? printItemDetails,
    String? receiptPaperSize,

    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    String? language,

    bool? enableNotifications,
    bool? enableSounds,
    bool? autoBackup,
    int? autoBackupInterval,
    String? backupLocation,
    int? transactionStorageDays,
  }) {
    return AppSettings(
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      logoPath: logoPath ?? this.logoPath,
      splashScreenDuration: splashScreenDuration ?? this.splashScreenDuration,
      showSplashScreen: showSplashScreen ?? this.showSplashScreen,

      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      showBusinessLogo: showBusinessLogo ?? this.showBusinessLogo,
      printCustomerInfo: printCustomerInfo ?? this.printCustomerInfo,
      printItemDetails: printItemDetails ?? this.printItemDetails,
      receiptPaperSize: receiptPaperSize ?? this.receiptPaperSize,

      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      language: language ?? this.language,

      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSounds: enableSounds ?? this.enableSounds,
      autoBackup: autoBackup ?? this.autoBackup,
      autoBackupInterval: autoBackupInterval ?? this.autoBackupInterval,
      backupLocation: backupLocation ?? this.backupLocation,
      transactionStorageDays:
          transactionStorageDays ?? this.transactionStorageDays,
    );
  }

  // Helper methods
  Color get primaryColorValue {
    try {
      return Color(int.parse(primaryColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF2196F3);
    }
  }

  Color get secondaryColorValue {
    try {
      return Color(int.parse(secondaryColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF03DAC6);
    }
  }

  int get splashDurationMs {
    try {
      return int.parse(splashScreenDuration) * 1000;
    } catch (e) {
      return 3000;
    }
  }

  List<String> get availablePaperSizes => ['58mm', '80mm', 'A4'];
  List<String> get availableLanguages => ['id', 'en'];
  List<String> get availableFontFamilies => [
    'Roboto',
    'Open Sans',
    'Lato',
    'Poppins',
  ];

  // Transaction storage options
  static const Map<String, int> transactionStorageOptions = {
    '3 Hari': 3,
    '1 Minggu': 7,
    '1 Bulan': 30,
    '2 Bulan': 60,
    '3 Bulan': 90,
    '6 Bulan': 180,
    '1 Tahun': 365,
  };

  String get transactionStorageDisplayName {
    for (var entry in transactionStorageOptions.entries) {
      if (entry.value == transactionStorageDays) {
        return entry.key;
      }
    }
    return '$transactionStorageDays Hari';
  }
}
