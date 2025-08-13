import '../utils/dummy_data_generator.dart';
import 'database_service.dart';

class DummyDataService {
  static final DatabaseService _databaseService = DatabaseService();
  static bool _isDataGenerated = false;

  /// Generate and insert dummy data into the database
  static Future<void> generateDummyData() async {
    if (_isDataGenerated) {
      print('Dummy data already generated');
      return;
    }

    try {
      print('🔄 Generating dummy data...');

      // Generate sample products
      final products = DummyDataGenerator.getSampleProducts();
      print('📦 Inserting ${products.length} sample products...');

      for (final product in products) {
        try {
          await _databaseService.insertProduct(product);
        } catch (e) {
          // Product might already exist, skip
          print('Product ${product.name} already exists, skipping...');
        }
      }

      // Generate sample customers
      final customers = DummyDataGenerator.getSampleCustomers();
      print('👥 Inserting ${customers.length} sample customers...');

      for (final customer in customers) {
        try {
          await _databaseService.insertCustomer(customer);
        } catch (e) {
          // Customer might already exist, skip
          print('Customer ${customer.name} already exists, skipping...');
        }
      }

      // Generate 50 dummy transactions
      final transactions = DummyDataGenerator.generateDummyTransactions(50);
      print('💰 Inserting ${transactions.length} dummy transactions...');

      for (final transaction in transactions) {
        try {
          await _databaseService.insertTransaction(transaction);
        } catch (e) {
          print('Error inserting transaction ${transaction.id}: $e');
        }
      }

      _isDataGenerated = true;
      print('✅ Dummy data generation completed successfully!');
      print('📊 Generated:');
      print('   - ${products.length} products');
      print('   - ${customers.length} customers');
      print('   - ${transactions.length} transactions');
    } catch (e) {
      print('❌ Error generating dummy data: $e');
      rethrow;
    }
  }

  /// Clear all dummy data from database (using reset database)
  static Future<void> clearDummyData() async {
    try {
      print('🗑️ Clearing dummy data...');

      // Use reset database to clear all data and restore sample data
      await _databaseService.resetDatabase();

      _isDataGenerated = false;
      print('✅ Dummy data cleared successfully!');
    } catch (e) {
      print('❌ Error clearing dummy data: $e');
      rethrow;
    }
  }

  /// Check if dummy data exists
  static Future<bool> hasDummyData() async {
    try {
      final products = await _databaseService.getProducts();
      final transactions = await _databaseService.getTransactions();

      return products.isNotEmpty && transactions.isNotEmpty;
    } catch (e) {
      print('Error checking dummy data: $e');
      return false;
    }
  }

  /// Get transaction statistics for reports
  static Future<Map<String, dynamic>> getTransactionStats() async {
    try {
      final transactions = await _databaseService.getTransactions();
      return DummyDataGenerator.generateSummaryStats(transactions);
    } catch (e) {
      print('Error getting transaction stats: $e');
      return {};
    }
  }

  /// Get cashier performance data
  static Future<Map<String, dynamic>> getCashierPerformance(
    String cashierId,
  ) async {
    try {
      final transactions = await _databaseService.getTransactions();
      return DummyDataGenerator.generateCashierPerformanceData(
        cashierId,
        transactions,
      );
    } catch (e) {
      print('Error getting cashier performance: $e');
      return {};
    }
  }

  /// Generate additional random products
  static Future<void> generateMoreProducts(int count) async {
    try {
      print('🔄 Generating $count additional products...');

      final products = DummyDataGenerator.generateRandomProducts(count);

      for (final product in products) {
        await _databaseService.insertProduct(product);
      }

      print('✅ Generated $count additional products successfully!');
    } catch (e) {
      print('❌ Error generating additional products: $e');
      rethrow;
    }
  }

  /// Generate additional random transactions
  static Future<void> generateMoreTransactions(int count) async {
    try {
      print('🔄 Generating $count additional transactions...');

      final transactions = DummyDataGenerator.generateDummyTransactions(count);

      for (final transaction in transactions) {
        await _databaseService.insertTransaction(transaction);
      }

      print('✅ Generated $count additional transactions successfully!');
    } catch (e) {
      print('❌ Error generating additional transactions: $e');
      rethrow;
    }
  }

  /// Reset and regenerate all dummy data
  static Future<void> resetDummyData() async {
    try {
      print('🔄 Resetting dummy data...');

      await clearDummyData();
      await generateDummyData();

      print('✅ Dummy data reset completed!');
    } catch (e) {
      print('❌ Error resetting dummy data: $e');
      rethrow;
    }
  }

  /// Initialize dummy data on app start
  static Future<void> initializeDummyData() async {
    try {
      final hasData = await hasDummyData();

      if (!hasData) {
        print('📊 No dummy data found, generating...');
        await generateDummyData();
      } else {
        print('📊 Dummy data already exists');
        _isDataGenerated = true;
      }
    } catch (e) {
      print('❌ Error initializing dummy data: $e');
    }
  }

  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      return await _databaseService.getDashboardData();
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {};
    }
  }

  /// Get all cashiers performance
  static Future<List<Map<String, dynamic>>> getAllCashiersPerformance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _databaseService.getAllCashiersPerformance(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error getting all cashiers performance: $e');
      return [];
    }
  }

  /// Get cashier ranking
  static Future<List<Map<String, dynamic>>> getCashierRanking({
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'revenue',
  }) async {
    try {
      return await _databaseService.getCashierRanking(
        startDate: startDate,
        endDate: endDate,
        sortBy: sortBy,
      );
    } catch (e) {
      print('Error getting cashier ranking: $e');
      return [];
    }
  }

  /// Get detailed cashier report
  static Future<Map<String, dynamic>> getDetailedCashierReport(
    String cashierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _databaseService.getCashierReport(
        cashierId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error getting detailed cashier report: $e');
      return {};
    }
  }
}
