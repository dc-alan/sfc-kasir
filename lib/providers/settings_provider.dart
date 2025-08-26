import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';

class SettingsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  AppSettings _settings = const AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settingsData = await _databaseService.getAppSettings();
      if (settingsData != null) {
        _settings = AppSettings.fromMap(settingsData);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Public method to reload settings
  Future<void> loadSettings() async {
    await _loadSettings();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      await _databaseService.updateAppSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating settings: $e');
      rethrow;
    }
  }

  // App Info Settings
  Future<void> updateAppInfo({
    String? appName,
    String? appVersion,
    String? logoPath,
  }) async {
    final updatedSettings = _settings.copyWith(
      appName: appName,
      appVersion: appVersion,
      logoPath: logoPath,
    );
    await updateSettings(updatedSettings);
  }

  // Theme Settings
  Future<void> updateThemeSettings({
    String? primaryColor,
    String? secondaryColor,
    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    String? language,
  }) async {
    final updatedSettings = _settings.copyWith(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      isDarkMode: isDarkMode,
      fontFamily: fontFamily,
      fontSize: fontSize,
      language: language,
    );
    await updateSettings(updatedSettings);
  }

  // Splash Screen Settings
  Future<void> updateSplashSettings({
    bool? showSplashScreen,
    String? splashScreenDuration,
  }) async {
    final updatedSettings = _settings.copyWith(
      showSplashScreen: showSplashScreen,
      splashScreenDuration: splashScreenDuration,
    );
    await updateSettings(updatedSettings);
  }

  // Business/Receipt Settings
  Future<void> updateBusinessSettings({
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
  }) async {
    final updatedSettings = _settings.copyWith(
      receiptHeader: receiptHeader,
      receiptFooter: receiptFooter,
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      businessEmail: businessEmail,
      showBusinessLogo: showBusinessLogo,
      printCustomerInfo: printCustomerInfo,
      printItemDetails: printItemDetails,
      receiptPaperSize: receiptPaperSize,
    );
    await updateSettings(updatedSettings);
  }

  // System Settings
  Future<void> updateSystemSettings({
    bool? enableNotifications,
    bool? enableSounds,
    bool? autoBackup,
    int? autoBackupInterval,
    String? backupLocation,
    int? transactionStorageDays,
  }) async {
    final updatedSettings = _settings.copyWith(
      enableNotifications: enableNotifications,
      enableSounds: enableSounds,
      autoBackup: autoBackup,
      autoBackupInterval: autoBackupInterval,
      backupLocation: backupLocation,
      transactionStorageDays: transactionStorageDays,
    );
    await updateSettings(updatedSettings);
  }

  // Transaction Storage Settings
  Future<void> updateTransactionStorageSettings({
    int? transactionStorageDays,
  }) async {
    final updatedSettings = _settings.copyWith(
      transactionStorageDays: transactionStorageDays,
    );
    await updateSettings(updatedSettings);
  }

  // Quick access methods
  Future<void> toggleDarkMode() async {
    await updateThemeSettings(isDarkMode: !_settings.isDarkMode);
  }

  Future<void> toggleNotifications() async {
    await updateSystemSettings(
      enableNotifications: !_settings.enableNotifications,
    );
  }

  Future<void> toggleSounds() async {
    await updateSystemSettings(enableSounds: !_settings.enableSounds);
  }

  Future<void> toggleAutoBackup() async {
    await updateSystemSettings(autoBackup: !_settings.autoBackup);
  }

  Future<void> toggleSplashScreen() async {
    await updateSplashSettings(showSplashScreen: !_settings.showSplashScreen);
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    const defaultSettings = AppSettings();
    await updateSettings(defaultSettings);
  }

  // Reset settings (alias for resetToDefaults)
  Future<void> resetSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.resetAppSettings();
      _settings = const AppSettings(); // Reset to default

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting settings: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Export/Import settings
  Map<String, dynamic> exportSettings() {
    return _settings.toMap();
  }

  Future<void> importSettings(Map<String, dynamic> settingsMap) async {
    try {
      final importedSettings = AppSettings.fromMap(settingsMap);
      await updateSettings(importedSettings);
    } catch (e) {
      debugPrint('Error importing settings: $e');
      rethrow;
    }
  }

  // Validation methods
  bool isValidColor(String colorString) {
    try {
      Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isValidDuration(String duration) {
    try {
      final parsed = int.parse(duration);
      return parsed > 0 && parsed <= 10;
    } catch (e) {
      return false;
    }
  }

  bool isValidFontSize(double fontSize) {
    return fontSize >= 10.0 && fontSize <= 24.0;
  }

  // Helper methods for UI
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }

  String getPaperSizeDisplayName(String paperSize) {
    switch (paperSize) {
      case '58mm':
        return '58mm (Mini)';
      case '80mm':
        return '80mm (Standard)';
      case 'A4':
        return 'A4 (Letter)';
      default:
        return paperSize;
    }
  }

  String getBackupLocationDisplayName(String location) {
    switch (location) {
      case 'local':
        return 'Penyimpanan Lokal';
      case 'cloud':
        return 'Cloud Storage';
      case 'external':
        return 'Penyimpanan Eksternal';
      default:
        return location;
    }
  }
}
