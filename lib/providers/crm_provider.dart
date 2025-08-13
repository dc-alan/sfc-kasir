import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/customer_loyalty.dart';
import '../services/database_service.dart';

class CRMProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final List<Customer> _customers = [];
  final List<CustomerLoyalty> _loyaltyPrograms = [];
  final List<CustomerHistory> _customerHistories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Customer> get customers => List.unmodifiable(_customers);
  List<CustomerLoyalty> get loyaltyPrograms =>
      List.unmodifiable(_loyaltyPrograms);
  List<CustomerHistory> get customerHistories =>
      List.unmodifiable(_customerHistories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered customers
  List<Customer> get vipCustomers =>
      _customers.where((c) => c.segment == CustomerSegment.vip).toList();
  List<Customer> get premiumCustomers =>
      _customers.where((c) => c.segment == CustomerSegment.premium).toList();
  List<Customer> get regularCustomers =>
      _customers.where((c) => c.segment == CustomerSegment.regular).toList();
  List<Customer> get newCustomers => _customers
      .where((c) => c.segment == CustomerSegment.new_customer)
      .toList();
  List<Customer> get inactiveCustomers =>
      _customers.where((c) => c.segment == CustomerSegment.inactive).toList();

  // Birthday and anniversary reminders
  List<Customer> get todayBirthdays =>
      _customers.where((c) => c.hasBirthday).toList();
  List<Customer> get todayAnniversaries =>
      _customers.where((c) => c.hasAnniversary).toList();
  List<Customer> get upcomingBirthdays =>
      _customers.where((c) => c.isUpcomingBirthday).toList();
  List<Customer> get upcomingAnniversaries =>
      _customers.where((c) => c.isUpcomingAnniversary).toList();

  // Statistics
  int get totalCustomers => _customers.length;
  int get activeCustomers =>
      _customers.where((c) => c.status == CustomerStatus.active).length;
  double get averageCustomerValue => _customers.isEmpty
      ? 0.0
      : _customers.map((c) => c.totalSpent).reduce((a, b) => a + b) /
            _customers.length;

  // Load data
  Future<void> loadCustomers() async {
    _setLoading(true);
    try {
      final customers = await _databaseService.getCustomers();
      _customers.clear();
      _customers.addAll(customers);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading customers: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLoyaltyPrograms() async {
    _setLoading(true);
    try {
      final programs = await _databaseService.getLoyaltyPrograms();
      _loyaltyPrograms.clear();
      _loyaltyPrograms.addAll(programs);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading loyalty programs: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCustomerHistory(String customerId) async {
    _setLoading(true);
    try {
      final history = await _databaseService.getCustomerHistory(customerId);
      _customerHistories.clear();
      _customerHistories.addAll(history);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading customer history: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Customer management
  Future<void> addCustomer(Customer customer) async {
    try {
      await _databaseService.insertCustomer(customer);
      _customers.add(customer);

      // Create loyalty program for new customer
      final loyalty = CustomerLoyalty(
        id: const Uuid().v4(),
        customerId: customer.id,
        totalPoints: 0,
        lifetimePoints: 0,
        tier: CustomerTier.bronze,
        joinDate: DateTime.now(),
        lastActivity: DateTime.now(),
        pointHistory: [],
      );
      await _databaseService.insertLoyaltyProgram(loyalty);
      _loyaltyPrograms.add(loyalty);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding customer: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _databaseService.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _databaseService.deleteCustomer(customerId);
      _customers.removeWhere((c) => c.id == customerId);
      _loyaltyPrograms.removeWhere((l) => l.customerId == customerId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting customer: $e');
      rethrow;
    }
  }

  // Loyalty program management
  Future<void> addPoints(
    String customerId,
    int points,
    String description, {
    String? transactionId,
  }) async {
    try {
      final loyaltyIndex = _loyaltyPrograms.indexWhere(
        (l) => l.customerId == customerId,
      );
      if (loyaltyIndex == -1) return;

      final loyalty = _loyaltyPrograms[loyaltyIndex];
      final pointTransaction = PointTransaction(
        id: const Uuid().v4(),
        customerId: customerId,
        points: points,
        type: PointTransactionType.earned,
        description: description,
        transactionId: transactionId,
        createdAt: DateTime.now(),
      );

      final updatedLoyalty = loyalty.copyWith(
        totalPoints: loyalty.totalPoints + points,
        lifetimePoints: loyalty.lifetimePoints + points,
        lastActivity: DateTime.now(),
        pointHistory: [...loyalty.pointHistory, pointTransaction],
        tier: _calculateTier(loyalty.lifetimePoints + points),
      );

      await _databaseService.updateLoyaltyProgram(updatedLoyalty);
      _loyaltyPrograms[loyaltyIndex] = updatedLoyalty;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding points: $e');
      rethrow;
    }
  }

  Future<void> redeemPoints(
    String customerId,
    int points,
    String description,
  ) async {
    try {
      final loyaltyIndex = _loyaltyPrograms.indexWhere(
        (l) => l.customerId == customerId,
      );
      if (loyaltyIndex == -1) return;

      final loyalty = _loyaltyPrograms[loyaltyIndex];
      if (loyalty.totalPoints < points) {
        throw Exception('Poin tidak mencukupi');
      }

      final pointTransaction = PointTransaction(
        id: const Uuid().v4(),
        customerId: customerId,
        points: -points,
        type: PointTransactionType.redeemed,
        description: description,
        createdAt: DateTime.now(),
      );

      final updatedLoyalty = loyalty.copyWith(
        totalPoints: loyalty.totalPoints - points,
        lastActivity: DateTime.now(),
        pointHistory: [...loyalty.pointHistory, pointTransaction],
      );

      await _databaseService.updateLoyaltyProgram(updatedLoyalty);
      _loyaltyPrograms[loyaltyIndex] = updatedLoyalty;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error redeeming points: $e');
      rethrow;
    }
  }

  // Customer segmentation
  Future<void> updateCustomerSegmentation() async {
    try {
      for (var customer in _customers) {
        final newSegment = _calculateSegment(customer);
        if (customer.segment != newSegment) {
          final updatedCustomer = customer.copyWith(segment: newSegment);
          await updateCustomer(updatedCustomer);
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating customer segmentation: $e');
    }
  }

  // Search and filter
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query.toLowerCase()) ||
          (customer.email?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (customer.phone?.contains(query) ?? false);
    }).toList();
  }

  List<Customer> filterCustomersBySegment(CustomerSegment segment) {
    return _customers.where((c) => c.segment == segment).toList();
  }

  List<Customer> filterCustomersByStatus(CustomerStatus status) {
    return _customers.where((c) => c.status == status).toList();
  }

  // Helper methods
  CustomerLoyalty? getLoyaltyProgram(String customerId) {
    try {
      return _loyaltyPrograms.firstWhere((l) => l.customerId == customerId);
    } catch (e) {
      return null;
    }
  }

  List<CustomerHistory> getCustomerPurchaseHistory(String customerId) {
    return _customerHistories.where((h) => h.customerId == customerId).toList();
  }

  CustomerTier _calculateTier(int lifetimePoints) {
    if (lifetimePoints >= CustomerTier.vip.requiredPoints) {
      return CustomerTier.vip;
    }
    if (lifetimePoints >= CustomerTier.platinum.requiredPoints) {
      return CustomerTier.platinum;
    }
    if (lifetimePoints >= CustomerTier.gold.requiredPoints) {
      return CustomerTier.gold;
    }
    if (lifetimePoints >= CustomerTier.silver.requiredPoints) {
      return CustomerTier.silver;
    }
    return CustomerTier.bronze;
  }

  CustomerSegment _calculateSegment(Customer customer) {
    final daysSinceCreated = DateTime.now()
        .difference(customer.createdAt)
        .inDays;
    final daysSinceLastVisit = customer.daysSinceLastVisit;

    // New customer (less than 30 days)
    if (daysSinceCreated <= 30) {
      return CustomerSegment.new_customer;
    }

    // Inactive customer (no visit in 90 days)
    if (daysSinceLastVisit > 90) {
      return CustomerSegment.inactive;
    }

    // VIP customer (high spending)
    if (customer.totalSpent >= 10000000) {
      // 10 million IDR
      return CustomerSegment.vip;
    }

    // Premium customer (regular high-value transactions)
    if (customer.totalSpent >= 5000000 && customer.totalTransactions >= 20) {
      return CustomerSegment.premium;
    }

    return CustomerSegment.regular;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Calculate points earned from transaction
  int calculatePointsFromTransaction(double transactionAmount) {
    // 1 point per 1000 IDR spent
    return (transactionAmount / 1000).floor();
  }

  // Calculate discount based on tier
  double calculateTierDiscount(CustomerTier tier, double amount) {
    return amount * (tier.discountPercentage / 100);
  }

  // Get customer statistics
  Map<String, dynamic> getCustomerStatistics() {
    return {
      'total_customers': totalCustomers,
      'active_customers': activeCustomers,
      'vip_customers': vipCustomers.length,
      'premium_customers': premiumCustomers.length,
      'regular_customers': regularCustomers.length,
      'new_customers': newCustomers.length,
      'inactive_customers': inactiveCustomers.length,
      'average_customer_value': averageCustomerValue,
      'today_birthdays': todayBirthdays.length,
      'today_anniversaries': todayAnniversaries.length,
      'upcoming_birthdays': upcomingBirthdays.length,
      'upcoming_anniversaries': upcomingAnniversaries.length,
    };
  }
}
