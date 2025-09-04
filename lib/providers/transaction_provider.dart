import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as model;
import '../services/database_service.dart';

class TransactionProvider with ChangeNotifier {
  List<model.Transaction> _transactions = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  List<model.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId, // tambahin parameter opsional
  }) async {
    _isLoading = true;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();

    try {
      _transactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: endDate,
        cashierId: cashierId, // oper ke service
      );
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    try {
      await _databaseService.insertTransaction(transaction);
      await loadTransactions(startDate: _startDate, endDate: _endDate);
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    try {
      await _databaseService.updateTransaction(transaction);
      await loadTransactions(startDate: _startDate, endDate: _endDate);
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _databaseService.deleteTransaction(transactionId);
      await loadTransactions(startDate: _startDate, endDate: _endDate);
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<model.Transaction?> getTransactionById(String transactionId) async {
    try {
      return await _databaseService.getTransactionById(transactionId);
    } catch (e) {
      debugPrint('Error getting transaction by id: $e');
      return null;
    }
  }

  double getTotalRevenue() {
    return _transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.total,
    );
  }

  int getTotalTransactions() {
    return _transactions.length;
  }

  Map<String, double> getRevenueByPaymentMethod() {
    final Map<String, double> revenue = {};

    for (var transaction in _transactions) {
      final method = transaction.paymentMethod.toString().split('.').last;
      revenue[method] = (revenue[method] ?? 0.0) + transaction.total;
    }

    return revenue;
  }

  Map<String, int> getTransactionsByPaymentMethod() {
    final Map<String, int> count = {};

    for (var transaction in _transactions) {
      final method = transaction.paymentMethod.toString().split('.').last;
      count[method] = (count[method] ?? 0) + 1;
    }

    return count;
  }

  List<model.Transaction> getTodayTransactions() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _transactions.where((transaction) {
      return transaction.createdAt.isAfter(startOfDay) &&
          transaction.createdAt.isBefore(endOfDay);
    }).toList();
  }

  double getTodayRevenue() {
    return getTodayTransactions().fold(
      0.0,
      (sum, transaction) => sum + transaction.total,
    );
  }

  Map<String, double> getDailyRevenue() {
    final Map<String, double> dailyRevenue = {};

    for (var transaction in _transactions) {
      final dateKey =
          '${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}-${transaction.createdAt.day.toString().padLeft(2, '0')}';
      dailyRevenue[dateKey] =
          (dailyRevenue[dateKey] ?? 0.0) + transaction.total;
    }

    return dailyRevenue;
  }

  Map<String, int> getTopSellingProducts() {
    final Map<String, int> productSales = {};

    for (var transaction in _transactions) {
      for (var item in transaction.items) {
        productSales[item.product.name] =
            (productSales[item.product.name] ?? 0) + item.quantity;
      }
    }

    // Sort by quantity and return top 10
    final sortedEntries = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(10));
  }
}
