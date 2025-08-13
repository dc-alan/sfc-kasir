import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id);
  Future<Either<Failure, CustomerEntity?>> getCustomerByPhone(String phone);
  Future<Either<Failure, CustomerEntity?>> getCustomerByEmail(String email);
  Future<Either<Failure, List<CustomerEntity>>> getAllCustomers({
    PaginationParams? params,
  });
  Future<Either<Failure, List<CustomerEntity>>> getCustomersByType(
    CustomerType type, {
    PaginationParams? params,
  });
  Future<Either<Failure, CustomerEntity>> createCustomer(
    CustomerEntity customer,
  );
  Future<Either<Failure, CustomerEntity>> updateCustomer(
    CustomerEntity customer,
  );
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(
    String query, {
    PaginationParams? params,
  });
  Future<Either<Failure, bool>> isPhoneExists(
    String phone, {
    String? excludeId,
  });
  Future<Either<Failure, bool>> isEmailExists(
    String email, {
    String? excludeId,
  });
  Future<Either<Failure, int>> getCustomerCount();
  Future<Either<Failure, List<CustomerEntity>>> getActiveCustomers();
  Future<Either<Failure, List<CustomerEntity>>> getTopCustomers({
    int limit = 10,
  });
  Future<Either<Failure, void>> toggleCustomerStatus(
    String customerId,
    bool isActive,
  );
  Stream<Either<Failure, List<CustomerEntity>>> watchCustomers();
  Stream<Either<Failure, CustomerEntity?>> watchCustomer(String id);
}

abstract class CustomerLoyaltyRepository {
  Future<Either<Failure, CustomerLoyaltyEntity>> getLoyaltyById(String id);
  Future<Either<Failure, CustomerLoyaltyEntity?>> getLoyaltyByCustomerId(
    String customerId,
  );
  Future<Either<Failure, List<CustomerLoyaltyEntity>>> getAllLoyalty({
    PaginationParams? params,
  });
  Future<Either<Failure, List<CustomerLoyaltyEntity>>> getLoyaltyByTier(
    LoyaltyTier tier, {
    PaginationParams? params,
  });
  Future<Either<Failure, CustomerLoyaltyEntity>> createLoyalty(
    CustomerLoyaltyEntity loyalty,
  );
  Future<Either<Failure, CustomerLoyaltyEntity>> updateLoyalty(
    CustomerLoyaltyEntity loyalty,
  );
  Future<Either<Failure, void>> deleteLoyalty(String id);
  Future<Either<Failure, void>> addPoints(String customerId, int points);
  Future<Either<Failure, void>> deductPoints(String customerId, int points);
  Future<Either<Failure, void>> updateTotalSpent(
    String customerId,
    double amount,
  );
  Future<Either<Failure, void>> updateTransactionCount(String customerId);
  Future<Either<Failure, void>> checkAndUpgradeTier(String customerId);
  Future<Either<Failure, Map<LoyaltyTier, int>>> getTierDistribution();
  Future<Either<Failure, double>> getTotalLoyaltyValue();
  Stream<Either<Failure, List<CustomerLoyaltyEntity>>> watchLoyalty();
  Stream<Either<Failure, CustomerLoyaltyEntity?>> watchLoyaltyByCustomerId(
    String customerId,
  );
}

abstract class CustomerAnalyticsRepository {
  Future<Either<Failure, CustomerAnalyticsEntity>> getCustomerAnalytics(
    String customerId,
  );
  Future<Either<Failure, List<CustomerAnalyticsEntity>>>
  getAllCustomerAnalytics({PaginationParams? params});
  Future<Either<Failure, List<CustomerAnalyticsEntity>>> getCustomersBySegment(
    CustomerSegment segment, {
    PaginationParams? params,
  });
  Future<Either<Failure, Map<CustomerSegment, int>>> getSegmentDistribution();
  Future<Either<Failure, List<CustomerAnalyticsEntity>>>
  getChurnRiskCustomers();
  Future<Either<Failure, List<CustomerAnalyticsEntity>>> getHighValueCustomers({
    int limit = 10,
  });
  Future<Either<Failure, List<CustomerAnalyticsEntity>>>
  getMostActiveCustomers({int limit = 10});
  Future<Either<Failure, double>> getCustomerLifetimeValue(String customerId);
  Future<Either<Failure, double>> getAverageCustomerValue();
  Future<Either<Failure, int>> getNewCustomersCount(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, int>> getReturningCustomersCount(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, double>> getCustomerRetentionRate(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, Map<String, int>>> getCustomerAcquisitionTrend(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getCustomerBehaviorInsights();
  Stream<Either<Failure, List<CustomerAnalyticsEntity>>>
  watchCustomerAnalytics();
}
