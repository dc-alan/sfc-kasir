import '../constants/app_constants.dart';

class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password minimal ${AppConstants.minPasswordLength} karakter';
    }

    return null;
  }

  // Username validation
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username tidak boleh kosong';
    }

    if (value.length > AppConstants.maxUsernameLength) {
      return 'Username maksimal ${AppConstants.maxUsernameLength} karakter';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username hanya boleh mengandung huruf, angka, dan underscore';
    }

    return null;
  }

  // Name validation
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }

    if (value.length > AppConstants.maxNameLength) {
      return 'Nama maksimal ${AppConstants.maxNameLength} karakter';
    }

    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }

    return null;
  }

  // Required field validation
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Field'} tidak boleh kosong';
    }
    return null;
  }

  // Phone number validation
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,13}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Format nomor telepon tidak valid';
    }

    return null;
  }

  // Numeric validation
  static String? numeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} tidak boleh kosong';
    }

    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Field'} harus berupa angka';
    }

    return null;
  }

  // Positive number validation
  static String? positiveNumber(String? value, [String? fieldName]) {
    final numericError = numeric(value, fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value!);
    if (number <= 0) {
      return '${fieldName ?? 'Field'} harus lebih besar dari 0';
    }

    return null;
  }

  // Integer validation
  static String? integer(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} tidak boleh kosong';
    }

    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'Field'} harus berupa bilangan bulat';
    }

    return null;
  }

  // Positive integer validation
  static String? positiveInteger(String? value, [String? fieldName]) {
    final integerError = integer(value, fieldName);
    if (integerError != null) return integerError;

    final number = int.parse(value!);
    if (number <= 0) {
      return '${fieldName ?? 'Field'} harus lebih besar dari 0';
    }

    return null;
  }

  // Price validation
  static String? price(String? value) {
    return positiveNumber(value, 'Harga');
  }

  // Stock validation
  static String? stock(String? value) {
    final integerError = integer(value, 'Stok');
    if (integerError != null) return integerError;

    final number = int.parse(value!);
    if (number < 0) {
      return 'Stok tidak boleh negatif';
    }

    return null;
  }

  // Discount validation
  static String? discount(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final numericError = numeric(value, 'Diskon');
    if (numericError != null) return numericError;

    final number = double.parse(value);
    if (number < 0 || number > AppConstants.maxDiscountPercentage) {
      return 'Diskon harus antara 0 dan ${AppConstants.maxDiscountPercentage}%';
    }

    return null;
  }

  // Barcode validation
  static String? barcode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // Basic barcode validation (can be extended based on barcode type)
    if (value.length < 8 || value.length > 18) {
      return 'Barcode harus antara 8-18 karakter';
    }

    final barcodeRegex = RegExp(r'^[0-9]+$');
    if (!barcodeRegex.hasMatch(value)) {
      return 'Barcode hanya boleh mengandung angka';
    }

    return null;
  }

  // SKU validation
  static String? sku(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length > 50) {
      return 'SKU maksimal 50 karakter';
    }

    final skuRegex = RegExp(r'^[A-Z0-9-_]+$');
    if (!skuRegex.hasMatch(value.toUpperCase())) {
      return 'SKU hanya boleh mengandung huruf kapital, angka, dash, dan underscore';
    }

    return null;
  }

  // Date validation
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal tidak boleh kosong';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Format tanggal tidak valid';
    }
  }

  // Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
