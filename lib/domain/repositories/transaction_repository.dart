import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);
  Future<Either<Failure, TransactionEntity?>> getTransactionByNumber(
    String transactionNumber,
  );
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions({
    PaginationParams? params,
  });
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByStatus(
    TransactionStatus status, {
    PaginationParams? params,
  });
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByCustomer(
    String customerId, {
    PaginationParams? params,
  });
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByCashier(
    String cashierId, {
    PaginationParams? params,
  });
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    PaginationParams? params,
  });
  Future<Either<Failure, TransactionEntity>> createTransaction(
    TransactionEntity transaction,
  );
  Future<Either<Failure, TransactionEntity>> updateTransaction(
    TransactionEntity transaction,
  );
  Future<Either<Failure, void>> deleteTransaction(String id);
  Future<Either<Failure, List<TransactionEntity>>> searchTransactions(
    String query, {
    PaginationParams? params,
  });
  Future<Either<Failure, String>> generateTransactionNumber();
  Future<Either<Failure, void>> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  );
  Future<Either<Failure, int>> getTransactionCount();
  Future<Either<Failure, double>> getTotalSales(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, double>> getTotalProfit(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, Map<PaymentMethod, double>>> getSalesByPaymentMethod(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, Map<String, double>>> getDailySales(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, Map<String, double>>> getMonthlySales(int year);
  Future<Either<Failure, List<TransactionEntity>>> getTopTransactions({
    int limit = 10,
  });
  Future<Either<Failure, List<TransactionEntity>>> getRecentTransactions({
    int limit = 10,
  });
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions();
  Stream<Either<Failure, TransactionEntity?>> watchTransaction(String id);
}

abstract class RefundRepository {
  Future<Either<Failure, RefundEntity>> getRefundById(String id);
  Future<Either<Failure, List<RefundEntity>>> getAllRefunds({
    PaginationParams? params,
  });
  Future<Either<Failure, List<RefundEntity>>> getRefundsByTransaction(
    String transactionId,
  );
  Future<Either<Failure, List<RefundEntity>>> getRefundsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    PaginationParams? params,
  });
  Future<Either<Failure, RefundEntity>> createRefund(RefundEntity refund);
  Future<Either<Failure, void>> deleteRefund(String id);
  Future<Either<Failure, List<RefundEntity>>> searchRefunds(
    String query, {
    PaginationParams? params,
  });
  Future<Either<Failure, double>> getTotalRefundAmount(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, int>> getRefundCount(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, Map<String, double>>> getDailyRefunds(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<RefundEntity>>> getRecentRefunds({
    int limit = 10,
  });
  Stream<Either<Failure, List<RefundEntity>>> watchRefunds();
  Stream<Either<Failure, RefundEntity?>> watchRefund(String id);
}

abstract class SalesAnalyticsRepository {
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<Map<String, dynamic>>>> getTopSellingProducts(
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  });
  Future<Either<Failure, List<Map<String, dynamic>>>> getTopCustomers(
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  });
  Future<Either<Failure, Map<String, double>>> getHourlySales(DateTime date);
  Future<Either<Failure, Map<String, double>>> getWeeklySales(
    DateTime startDate,
  );
  Future<Either<Failure, Map<String, double>>> getCategorySales(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, Map<String, int>>> getPaymentMethodDistribution(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, double>> getAverageTransactionValue(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, int>> getCustomerCount(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, double>> getCustomerRetentionRate(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, Map<String, dynamic>>> getSalesGrowth(
    DateTime currentStart,
    DateTime currentEnd,
    DateTime previousStart,
    DateTime previousEnd,
  );
  Future<Either<Failure, List<Map<String, dynamic>>>> getSalesTrends(
    DateTime startDate,
    DateTime endDate,
    String period,
  );
}
