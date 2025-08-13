import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

class DatabaseConnectionFailure extends DatabaseFailure {
  const DatabaseConnectionFailure({required super.message, super.code});
}

class DatabaseQueryFailure extends DatabaseFailure {
  const DatabaseQueryFailure({required super.message, super.code});
}

// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.code});
}

class InvalidCredentialsFailure extends AuthenticationFailure {
  const InvalidCredentialsFailure({
    super.message = 'Invalid username or password',
    super.code,
  });
}

class UnauthorizedFailure extends AuthenticationFailure {
  const UnauthorizedFailure({
    super.message = 'Unauthorized access',
    super.code,
  });
}

class PermissionDeniedFailure extends AuthenticationFailure {
  const PermissionDeniedFailure({
    super.message = 'Permission denied',
    super.code,
  });
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class InvalidInputFailure extends ValidationFailure {
  const InvalidInputFailure({required super.message, super.code});
}

class DuplicateEntryFailure extends ValidationFailure {
  const DuplicateEntryFailure({required super.message, super.code});
}

// Business logic failures
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure({required super.message, super.code});
}

class InsufficientStockFailure extends BusinessLogicFailure {
  const InsufficientStockFailure({
    super.message = 'Insufficient stock available',
    super.code,
  });
}

class InvalidTransactionFailure extends BusinessLogicFailure {
  const InvalidTransactionFailure({required super.message, super.code});
}

class PaymentFailure extends BusinessLogicFailure {
  const PaymentFailure({required super.message, super.code});
}

// File system failures
class FileSystemFailure extends Failure {
  const FileSystemFailure({required super.message, super.code});
}

class FileNotFoundFailure extends FileSystemFailure {
  const FileNotFoundFailure({required super.message, super.code});
}

class FileWriteFailure extends FileSystemFailure {
  const FileWriteFailure({required super.message, super.code});
}

class BackupFailure extends FileSystemFailure {
  const BackupFailure({required super.message, super.code});
}

class RestoreFailure extends FileSystemFailure {
  const RestoreFailure({required super.message, super.code});
}

// Export/Import failures
class ExportFailure extends Failure {
  const ExportFailure({required super.message, super.code});
}

class ImportFailure extends Failure {
  const ImportFailure({required super.message, super.code});
}
