import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_settings.dart';

class AppTheme {
  // Default Color Palette - Light Theme
  static const Color defaultPrimaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color defaultSecondaryColor = Color(0xFF10B981); // Emerald
  static const Color secondaryVariant = Color(0xFF059669);
  static const Color tertiaryColor = Color(0xFFF59E0B); // Amber

  static const Color surfaceColor = Color(0xFFFAFBFC);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF818CF8);
  static const Color darkPrimaryVariant = Color(0xFF6366F1);
  static const Color darkSecondaryColor = Color(0xFF34D399);
  static const Color darkSecondaryVariant = Color(0xFF10B981);
  static const Color darkTertiaryColor = Color(0xFFFBBF24);

  static const Color darkSurfaceColor = Color(0xFF1F2937);
  static const Color darkBackgroundColor = Color(0xFF111827);
  static const Color darkCardColor = Color(0xFF374151);

  // Semantic Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Neutral Colors
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Shadows
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [defaultPrimaryColor, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successColor, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningColor, Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorColor, Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // Method to create theme with custom colors
  static ThemeData getLightTheme([AppSettings? settings]) {
    final Color customPrimary = settings != null
        ? Color(int.parse(settings.primaryColor.replaceAll('#', '0xFF')))
        : defaultPrimaryColor;

    final Color customSecondary = settings != null
        ? Color(int.parse(settings.secondaryColor.replaceAll('#', '0xFF')))
        : defaultSecondaryColor;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: customPrimary,
        brightness: Brightness.light,
        primary: customPrimary,
        secondary: customSecondary,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      appBarTheme: AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: customPrimary,
        foregroundColor: Colors.white,
        shadowColor: Colors.black26,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: customPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: customPrimary,
          side: BorderSide(color: customPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: customPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: customPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: customPrimary.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: customPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: customPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData getDarkTheme([AppSettings? settings]) {
    final Color customPrimary = settings != null
        ? Color(int.parse(settings.primaryColor.replaceAll('#', '0xFF')))
        : darkPrimaryColor;

    final Color customSecondary = settings != null
        ? Color(int.parse(settings.secondaryColor.replaceAll('#', '0xFF')))
        : darkSecondaryColor;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: customPrimary,
        brightness: Brightness.dark,
        primary: customPrimary,
        secondary: customSecondary,
        error: errorColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: darkSurfaceColor,
        foregroundColor: Colors.white,
        shadowColor: Colors.black54,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: customPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: customPrimary,
          side: BorderSide(color: customPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: customPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: customPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: darkSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade800,
        selectedColor: customPrimary.withOpacity(0.3),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: customPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: customPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkSurfaceColor,
        elevation: 8,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkSurfaceColor,
        elevation: 4,
      ),
    );
  }

  // Backward compatibility getters
  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  // Dynamic primary color getter for backward compatibility
  static Color primaryColor = defaultPrimaryColor;
  static Color secondaryColor = defaultSecondaryColor;

  // Typography
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
    );
  }

  // Helper methods for consistent colors across the app
  static Color getSuccessColor(BuildContext context) {
    return successColor;
  }

  static Color getWarningColor(BuildContext context) {
    return warningColor;
  }

  static Color getInfoColor(BuildContext context) {
    return infoColor;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  // Status colors for different states
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktif':
      case 'success':
      case 'berhasil':
        return successColor;
      case 'warning':
      case 'peringatan':
      case 'low_stock':
        return warningColor;
      case 'error':
      case 'gagal':
      case 'inactive':
      case 'nonaktif':
        return errorColor;
      case 'info':
      case 'informasi':
        return infoColor;
      default:
        return Colors.grey;
    }
  }

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // System UI Overlay Styles
  static SystemUiOverlayStyle get lightSystemUiOverlay {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  static SystemUiOverlayStyle get darkSystemUiOverlay {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: darkSurfaceColor,
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }

  // Custom Decorations
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: shadowSmall,
    );
  }

  static BoxDecoration get elevatedCardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: shadowMedium,
    );
  }

  // Input Decorations
  static InputDecoration getInputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool isError = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: isError ? errorColor : neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: isError ? errorColor : neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(
          color: isError ? errorColor : primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
      filled: true,
      fillColor: neutral50,
    );
  }

  // Button Styles
  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle get secondaryButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: defaultPrimaryColor,
      side: const BorderSide(color: defaultPrimaryColor, width: 1.5),
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle get dangerButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: errorColor,
      foregroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
