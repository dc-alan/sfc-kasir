class ServerException implements Exception {
  final String message;
  final int? code;

  const ServerException({required this.message, this.code});

  @override
  String toString() => 'ServerException: $message (Code: $code)';
}

class CacheException implements Exception {
  final String message;
  final int? code;

  const CacheException({required this.message, this.code});

  @override
  String toString() => 'CacheException: $message (Code: $code)';
}

class NetworkException implements Exception {
  final String message;
  final int? code;

  const NetworkException({required this.message, this.code});

  @override
  String toString() => 'NetworkException: $message (Code: $code)';
}

class DatabaseException implements Exception {
  final String message;
  final int? code;

  const DatabaseException({required this.message, this.code});

  @override
  String toString() => 'DatabaseException: $message (Code: $code)';
}

class DatabaseConnectionException extends DatabaseException {
  const DatabaseConnectionException({required super.message, super.code});

  @override
  String toString() => 'DatabaseConnectionException: $message (Code: $code)';
}

class DatabaseQueryException extends DatabaseException {
  const DatabaseQueryException({required super.message, super.code});

  @override
  String toString() => 'DatabaseQueryException: $message (Code: $code)';
}

class AuthenticationException implements Exception {
  final String message;
  final int? code;

  const AuthenticationException({required this.message, this.code});

  @override
  String toString() => 'AuthenticationException: $message (Code: $code)';
}

class InvalidCredentialsException extends AuthenticationException {
  const InvalidCredentialsException({
    super.message = 'Invalid username or password',
    super.code,
  });

  @override
  String toString() => 'InvalidCredentialsException: $message (Code: $code)';
}

class UnauthorizedException extends AuthenticationException {
  const UnauthorizedException({
    super.message = 'Unauthorized access',
    super.code,
  });

  @override
  String toString() => 'UnauthorizedException: $message (Code: $code)';
}

class PermissionDeniedException extends AuthenticationException {
  const PermissionDeniedException({
    super.message = 'Permission denied',
    super.code,
  });

  @override
  String toString() => 'PermissionDeniedException: $message (Code: $code)';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;
  final int? code;

  const ValidationException({
    required this.message,
    this.fieldErrors,
    this.code,
  });

  @override
  String toString() => 'ValidationException: $message (Code: $code)';
}

class InvalidInputException extends ValidationException {
  const InvalidInputException({
    required super.message,
    super.fieldErrors,
    super.code,
  });

  @override
  String toString() => 'InvalidInputException: $message (Code: $code)';
}

class DuplicateEntryException extends ValidationException {
  const DuplicateEntryException({
    required super.message,
    super.fieldErrors,
    super.code,
  });

  @override
  String toString() => 'DuplicateEntryException: $message (Code: $code)';
}

class BusinessLogicException implements Exception {
  final String message;
  final int? code;

  const BusinessLogicException({required this.message, this.code});

  @override
  String toString() => 'BusinessLogicException: $message (Code: $code)';
}

class InsufficientStockException extends BusinessLogicException {
  final int availableStock;
  final int requestedQuantity;

  const InsufficientStockException({
    required this.availableStock,
    required this.requestedQuantity,
    String? message,
    super.code,
  }) : super(
         message:
             message ??
             'Insufficient stock: requested $requestedQuantity, available $availableStock',
       );

  @override
  String toString() => 'InsufficientStockException: $message (Code: $code)';
}

class InvalidTransactionException extends BusinessLogicException {
  const InvalidTransactionException({required super.message, super.code});

  @override
  String toString() => 'InvalidTransactionException: $message (Code: $code)';
}

class PaymentException extends BusinessLogicException {
  const PaymentException({required super.message, super.code});

  @override
  String toString() => 'PaymentException: $message (Code: $code)';
}

class FileSystemException implements Exception {
  final String message;
  final String? path;
  final int? code;

  const FileSystemException({required this.message, this.path, this.code});

  @override
  String toString() =>
      'FileSystemException: $message${path != null ? ' (Path: $path)' : ''} (Code: $code)';
}

class FileNotFoundException extends FileSystemException {
  const FileNotFoundException({required super.message, super.path, super.code});

  @override
  String toString() =>
      'FileNotFoundException: $message${path != null ? ' (Path: $path)' : ''} (Code: $code)';
}

class FileWriteException extends FileSystemException {
  const FileWriteException({required super.message, super.path, super.code});

  @override
  String toString() =>
      'FileWriteException: $message${path != null ? ' (Path: $path)' : ''} (Code: $code)';
}

class BackupException extends FileSystemException {
  const BackupException({required super.message, super.path, super.code});

  @override
  String toString() =>
      'BackupException: $message${path != null ? ' (Path: $path)' : ''} (Code: $code)';
}

class RestoreException extends FileSystemException {
  const RestoreException({required super.message, super.path, super.code});

  @override
  String toString() =>
      'RestoreException: $message${path != null ? ' (Path: $path)' : ''} (Code: $code)';
}

class ExportException implements Exception {
  final String message;
  final String? format;
  final int? code;

  const ExportException({required this.message, this.format, this.code});

  @override
  String toString() =>
      'ExportException: $message${format != null ? ' (Format: $format)' : ''} (Code: $code)';
}

class ImportException implements Exception {
  final String message;
  final String? format;
  final int? line;
  final int? code;

  const ImportException({
    required this.message,
    this.format,
    this.line,
    this.code,
  });

  @override
  String toString() =>
      'ImportException: $message${format != null ? ' (Format: $format)' : ''}${line != null ? ' (Line: $line)' : ''} (Code: $code)';
}
