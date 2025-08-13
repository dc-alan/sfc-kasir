import 'package:equatable/equatable.dart';

enum CustomerType { regular, vip, wholesale }

enum LoyaltyTier { bronze, silver, gold, platinum }

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final CustomerType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CustomerLoyaltyEntity? loyalty;
  final Map<String, dynamic>? metadata;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    required this.type,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.loyalty,
    this.metadata,
  });

  bool get hasEmail => email != null && email!.isNotEmpty;

  bool get hasPhone => phone != null && phone!.isNotEmpty;

  bool get hasAddress => address != null && address!.isNotEmpty;

  bool get hasLoyalty => loyalty != null;

  String get typeDisplayName {
    switch (type) {
      case CustomerType.regular:
        return 'Reguler';
      case CustomerType.vip:
        return 'VIP';
      case CustomerType.wholesale:
        return 'Grosir';
    }
  }

  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    CustomerType? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    CustomerLoyaltyEntity? loyalty,
    Map<String, dynamic>? metadata,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      loyalty: loyalty ?? this.loyalty,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    address,
    dateOfBirth,
    type,
    isActive,
    createdAt,
    updatedAt,
    loyalty,
    metadata,
  ];
}

class CustomerLoyaltyEntity extends Equatable {
  final String id;
  final String customerId;
  final int points;
  final LoyaltyTier tier;
  final double totalSpent;
  final int totalTransactions;
  final DateTime lastTransactionDate;
  final DateTime? tierUpgradeDate;
  final DateTime updatedAt;

  const CustomerLoyaltyEntity({
    required this.id,
    required this.customerId,
    required this.points,
    required this.tier,
    required this.totalSpent,
    required this.totalTransactions,
    required this.lastTransactionDate,
    this.tierUpgradeDate,
    required this.updatedAt,
  });

  String get tierDisplayName {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
    }
  }

  double get averageTransactionValue {
    if (totalTransactions == 0) return 0;
    return totalSpent / totalTransactions;
  }

  bool get canUpgradeTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return totalSpent >= 1000000; // 1 juta
      case LoyaltyTier.silver:
        return totalSpent >= 5000000; // 5 juta
      case LoyaltyTier.gold:
        return totalSpent >= 10000000; // 10 juta
      case LoyaltyTier.platinum:
        return false; // Already at highest tier
    }
  }

  LoyaltyTier get nextTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return LoyaltyTier.silver;
      case LoyaltyTier.silver:
        return LoyaltyTier.gold;
      case LoyaltyTier.gold:
        return LoyaltyTier.platinum;
      case LoyaltyTier.platinum:
        return LoyaltyTier.platinum;
    }
  }

  double get progressToNextTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return (totalSpent / 1000000).clamp(0.0, 1.0);
      case LoyaltyTier.silver:
        return (totalSpent / 5000000).clamp(0.0, 1.0);
      case LoyaltyTier.gold:
        return (totalSpent / 10000000).clamp(0.0, 1.0);
      case LoyaltyTier.platinum:
        return 1.0;
    }
  }

  CustomerLoyaltyEntity copyWith({
    String? id,
    String? customerId,
    int? points,
    LoyaltyTier? tier,
    double? totalSpent,
    int? totalTransactions,
    DateTime? lastTransactionDate,
    DateTime? tierUpgradeDate,
    DateTime? updatedAt,
  }) {
    return CustomerLoyaltyEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      points: points ?? this.points,
      tier: tier ?? this.tier,
      totalSpent: totalSpent ?? this.totalSpent,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      tierUpgradeDate: tierUpgradeDate ?? this.tierUpgradeDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    points,
    tier,
    totalSpent,
    totalTransactions,
    lastTransactionDate,
    tierUpgradeDate,
    updatedAt,
  ];
}

class CustomerAnalyticsEntity extends Equatable {
  final String customerId;
  final String customerName;
  final int totalTransactions;
  final double totalSpent;
  final double averageTransactionValue;
  final DateTime firstTransactionDate;
  final DateTime lastTransactionDate;
  final int daysSinceLastTransaction;
  final List<String> favoriteProducts;
  final List<String> favoriteCategories;
  final Map<String, int> monthlyTransactionCount;
  final Map<String, double> monthlySpending;
  final CustomerSegment segment;

  const CustomerAnalyticsEntity({
    required this.customerId,
    required this.customerName,
    required this.totalTransactions,
    required this.totalSpent,
    required this.averageTransactionValue,
    required this.firstTransactionDate,
    required this.lastTransactionDate,
    required this.daysSinceLastTransaction,
    required this.favoriteProducts,
    required this.favoriteCategories,
    required this.monthlyTransactionCount,
    required this.monthlySpending,
    required this.segment,
  });

  bool get isActiveCustomer => daysSinceLastTransaction <= 30;

  bool get isChurnRisk => daysSinceLastTransaction > 90;

  String get segmentDisplayName {
    switch (segment) {
      case CustomerSegment.newCustomer:
        return 'Pelanggan Baru';
      case CustomerSegment.regularCustomer:
        return 'Pelanggan Reguler';
      case CustomerSegment.loyalCustomer:
        return 'Pelanggan Setia';
      case CustomerSegment.vipCustomer:
        return 'Pelanggan VIP';
      case CustomerSegment.churnRisk:
        return 'Risiko Churn';
      case CustomerSegment.dormantCustomer:
        return 'Pelanggan Tidak Aktif';
    }
  }

  CustomerAnalyticsEntity copyWith({
    String? customerId,
    String? customerName,
    int? totalTransactions,
    double? totalSpent,
    double? averageTransactionValue,
    DateTime? firstTransactionDate,
    DateTime? lastTransactionDate,
    int? daysSinceLastTransaction,
    List<String>? favoriteProducts,
    List<String>? favoriteCategories,
    Map<String, int>? monthlyTransactionCount,
    Map<String, double>? monthlySpending,
    CustomerSegment? segment,
  }) {
    return CustomerAnalyticsEntity(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalSpent: totalSpent ?? this.totalSpent,
      averageTransactionValue:
          averageTransactionValue ?? this.averageTransactionValue,
      firstTransactionDate: firstTransactionDate ?? this.firstTransactionDate,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      daysSinceLastTransaction:
          daysSinceLastTransaction ?? this.daysSinceLastTransaction,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      monthlyTransactionCount:
          monthlyTransactionCount ?? this.monthlyTransactionCount,
      monthlySpending: monthlySpending ?? this.monthlySpending,
      segment: segment ?? this.segment,
    );
  }

  @override
  List<Object?> get props => [
    customerId,
    customerName,
    totalTransactions,
    totalSpent,
    averageTransactionValue,
    firstTransactionDate,
    lastTransactionDate,
    daysSinceLastTransaction,
    favoriteProducts,
    favoriteCategories,
    monthlyTransactionCount,
    monthlySpending,
    segment,
  ];
}

enum CustomerSegment {
  newCustomer,
  regularCustomer,
  loyalCustomer,
  vipCustomer,
  churnRisk,
  dormantCustomer,
}
