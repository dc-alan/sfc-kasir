import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Create full database backup
  Future<String> createBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'sfc_backup_$timestamp.json';
      final backupFile = File('${directory.path}/$backupFileName');

      // Get all data from database
      final backupData = await _getAllDatabaseData();

      // Write to file
      await backupFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      return backupFile.path;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  // Restore database from backup file
  Future<void> restoreBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      final backupContent = await backupFile.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;

      // Validate backup data structure
      _validateBackupData(backupData);

      // Clear existing data and restore
      await _restoreAllData(backupData);
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  // Get all available backup files
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFiles = <Map<String, dynamic>>[];

      await for (final entity in directory.list()) {
        if (entity is File && entity.path.contains('sfc_backup_')) {
          final fileName = entity.path.split('/').last;
          final fileSize = await entity.length();
          final lastModified = await entity.lastModified();

          backupFiles.add({
            'fileName': fileName,
            'filePath': entity.path,
            'fileSize': fileSize,
            'lastModified': lastModified,
            'formattedSize': _formatFileSize(fileSize),
            'formattedDate': DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(lastModified),
          });
        }
      }

      // Sort by last modified (newest first)
      backupFiles.sort(
        (a, b) => (b['lastModified'] as DateTime).compareTo(
          a['lastModified'] as DateTime,
        ),
      );

      return backupFiles;
    } catch (e) {
      throw Exception('Failed to get backup files: $e');
    }
  }

  // Delete backup file
  Future<void> deleteBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  // Auto backup (can be called periodically)
  Future<String?> createAutoBackup() async {
    try {
      // Check if auto backup is needed (e.g., daily)
      final lastBackup = await _getLastAutoBackupDate();
      final now = DateTime.now();

      if (lastBackup == null || now.difference(lastBackup).inDays >= 1) {
        final backupPath = await createBackup();
        await _saveLastAutoBackupDate(now);

        // Clean old auto backups (keep only last 7)
        await _cleanOldAutoBackups();

        return backupPath;
      }

      return null;
    } catch (e) {
      print('Auto backup failed: $e');
      return null;
    }
  }

  // Private methods
  Future<Map<String, dynamic>> _getAllDatabaseData() async {
    final db = await _databaseService.database;

    // Get all tables data
    final products = await db.query('products');
    final users = await db.query('users');
    final customers = await db.query('customers');
    final transactions = await db.query('transactions');
    final transactionItems = await db.query('transaction_items');

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'products': products,
        'users': users,
        'customers': customers,
        'transactions': transactions,
        'transaction_items': transactionItems,
      },
    };
  }

  void _validateBackupData(Map<String, dynamic> backupData) {
    if (!backupData.containsKey('version') ||
        !backupData.containsKey('timestamp') ||
        !backupData.containsKey('data')) {
      throw Exception('Invalid backup file format');
    }

    final data = backupData['data'] as Map<String, dynamic>;
    final requiredTables = [
      'products',
      'users',
      'customers',
      'transactions',
      'transaction_items',
    ];

    for (final table in requiredTables) {
      if (!data.containsKey(table)) {
        throw Exception('Missing table in backup: $table');
      }
    }
  }

  Future<void> _restoreAllData(Map<String, dynamic> backupData) async {
    final db = await _databaseService.database;
    final data = backupData['data'] as Map<String, dynamic>;

    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('transaction_items');
      await txn.delete('transactions');
      await txn.delete('customers');
      await txn.delete('products');
      await txn.delete('users');

      // Restore data
      final products = data['products'] as List;
      for (final product in products) {
        await txn.insert('products', product as Map<String, dynamic>);
      }

      final users = data['users'] as List;
      for (final user in users) {
        await txn.insert('users', user as Map<String, dynamic>);
      }

      final customers = data['customers'] as List;
      for (final customer in customers) {
        await txn.insert('customers', customer as Map<String, dynamic>);
      }

      final transactions = data['transactions'] as List;
      for (final transaction in transactions) {
        await txn.insert('transactions', transaction as Map<String, dynamic>);
      }

      final transactionItems = data['transaction_items'] as List;
      for (final item in transactionItems) {
        await txn.insert('transaction_items', item as Map<String, dynamic>);
      }
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<DateTime?> _getLastAutoBackupDate() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/backup_config.json');

      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final config = jsonDecode(content) as Map<String, dynamic>;

        if (config.containsKey('lastAutoBackup')) {
          return DateTime.parse(config['lastAutoBackup']);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveLastAutoBackupDate(DateTime date) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/backup_config.json');

      final config = {'lastAutoBackup': date.toIso8601String()};

      await configFile.writeAsString(jsonEncode(config));
    } catch (e) {
      print('Failed to save backup config: $e');
    }
  }

  Future<void> _cleanOldAutoBackups() async {
    try {
      final backups = await getAvailableBackups();
      final autoBackups = backups
          .where(
            (backup) => backup['fileName'].toString().contains('sfc_backup_'),
          )
          .toList();

      // Keep only last 7 auto backups
      if (autoBackups.length > 7) {
        final oldBackups = autoBackups.skip(7);
        for (final backup in oldBackups) {
          await deleteBackup(backup['filePath']);
        }
      }
    } catch (e) {
      print('Failed to clean old backups: $e');
    }
  }
}
