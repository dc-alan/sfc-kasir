import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  // Currency formatter
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final NumberFormat _currencyFormatterWithDecimals =
      NumberFormat.currency(
        locale: 'id_ID',
        symbol: AppConstants.currencySymbol,
        decimalDigits: 2,
      );

  // Date formatters
  static final DateFormat _dateFormatter = DateFormat(AppConstants.dateFormat);
  static final DateFormat _dateTimeFormatter = DateFormat(
    AppConstants.dateTimeFormat,
  );
  static final DateFormat _timeFormatter = DateFormat(AppConstants.timeFormat);

  // Number formatters
  static final NumberFormat _numberFormatter = NumberFormat('#,##0', 'id_ID');
  static final NumberFormat _decimalFormatter = NumberFormat(
    '#,##0.00',
    'id_ID',
  );
  static final NumberFormat _percentageFormatter = NumberFormat.percentPattern(
    'id_ID',
  );

  // Currency formatting
  static String currency(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _currencyFormatterWithDecimals.format(amount);
    }
    return _currencyFormatter.format(amount);
  }

  static String currencyCompact(double amount) {
    if (amount >= 1000000000) {
      return '${AppConstants.currencySymbol}${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return '${AppConstants.currencySymbol}${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return currency(amount);
  }

  // Date formatting
  static String date(DateTime dateTime) {
    return _dateFormatter.format(dateTime);
  }

  static String dateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  static String time(DateTime dateTime) {
    return _timeFormatter.format(dateTime);
  }

  static String dateRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return date(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  static String dateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return date(startDate);
    }
    return '${date(startDate)} - ${date(endDate)}';
  }

  // Number formatting
  static String number(num value) {
    return _numberFormatter.format(value);
  }

  static String decimal(double value, {int decimalPlaces = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalPlaces}', 'id_ID');
    return formatter.format(value);
  }

  static String percentage(double value, {int decimalPlaces = 1}) {
    final formatter = NumberFormat.percentPattern('id_ID');
    formatter.minimumFractionDigits = decimalPlaces;
    formatter.maximumFractionDigits = decimalPlaces;
    return formatter.format(value / 100);
  }

  // Phone number formatting
  static String phoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('62')) {
      // International format
      if (digits.length >= 10) {
        return '+${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)} ${digits.substring(9)}';
      }
    } else if (digits.startsWith('0')) {
      // Local format
      if (digits.length >= 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
      }
    }

    return phoneNumber; // Return original if can't format
  }

  // File size formatting
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Duration formatting
  static String duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}j ${minutes}m ${seconds}d';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}d';
    } else {
      return '${seconds}d';
    }
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Title case
  static String titleCase(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Truncate text
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  // Format barcode for display
  static String barcode(String barcode) {
    if (barcode.length == 13) {
      // EAN-13 format
      return '${barcode.substring(0, 1)} ${barcode.substring(1, 7)} ${barcode.substring(7, 13)}';
    } else if (barcode.length == 12) {
      // UPC-A format
      return '${barcode.substring(0, 1)} ${barcode.substring(1, 6)} ${barcode.substring(6, 11)} ${barcode.substring(11, 12)}';
    }
    return barcode;
  }

  // Format SKU for display
  static String sku(String sku) {
    return sku.toUpperCase();
  }

  // Format quantity with unit
  static String quantity(int quantity, String unit) {
    return '${number(quantity)} $unit';
  }

  // Format stock status
  static String stockStatus(int currentStock, int minStock) {
    if (currentStock <= 0) {
      return 'Habis';
    } else if (currentStock <= minStock) {
      return 'Stok Rendah';
    } else {
      return 'Tersedia';
    }
  }

  // Format transaction status
  static String transactionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'refunded':
        return 'Dikembalikan';
      default:
        return titleCase(status);
    }
  }

  // Format user role
  static String userRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'owner':
        return 'Pemilik';
      case 'cashier':
        return 'Kasir';
      default:
        return titleCase(role);
    }
  }
}
