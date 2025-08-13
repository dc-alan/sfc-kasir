class CustomerLoyalty {
  final String id;
  final String customerId;
  final int totalPoints;
  final int lifetimePoints;
  final CustomerTier tier;
  final DateTime joinDate;
  final DateTime lastActivity;
  final List<PointTransaction> pointHistory;

  CustomerLoyalty({
    required this.id,
    required this.customerId,
    required this.totalPoints,
    required this.lifetimePoints,
    required this.tier,
    required this.joinDate,
    required this.lastActivity,
    required this.pointHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'total_points': totalPoints,
      'lifetime_points': lifetimePoints,
      'tier': tier.toString(),
      'join_date': joinDate.toIso8601String(),
      'last_activity': lastActivity.toIso8601String(),
      'point_history': pointHistory.map((x) => x.toMap()).toList(),
    };
  }

  factory CustomerLoyalty.fromMap(Map<String, dynamic> map) {
    return CustomerLoyalty(
      id: map['id'],
      customerId: map['customer_id'],
      totalPoints: map['total_points'],
      lifetimePoints: map['lifetime_points'],
      tier: CustomerTier.values.firstWhere(
        (e) => e.toString() == map['tier'],
        orElse: () => CustomerTier.regular,
      ),
      joinDate: DateTime.parse(map['join_date']),
      lastActivity: DateTime.parse(map['last_activity']),
      pointHistory: List<PointTransaction>.from(
        map['point_history']?.map((x) => PointTransaction.fromMap(x)) ?? [],
      ),
    );
  }

  CustomerLoyalty copyWith({
    String? id,
    String? customerId,
    int? totalPoints,
    int? lifetimePoints,
    CustomerTier? tier,
    DateTime? joinDate,
    DateTime? lastActivity,
    List<PointTransaction>? pointHistory,
  }) {
    return CustomerLoyalty(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      totalPoints: totalPoints ?? this.totalPoints,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      tier: tier ?? this.tier,
      joinDate: joinDate ?? this.joinDate,
      lastActivity: lastActivity ?? this.lastActivity,
      pointHistory: pointHistory ?? this.pointHistory,
    );
  }
}

enum CustomerTier { bronze, silver, gold, platinum, vip, regular }

extension CustomerTierExtension on CustomerTier {
  String get displayName {
    switch (this) {
      case CustomerTier.bronze:
        return 'Bronze';
      case CustomerTier.silver:
        return 'Silver';
      case CustomerTier.gold:
        return 'Gold';
      case CustomerTier.platinum:
        return 'Platinum';
      case CustomerTier.vip:
        return 'VIP';
      case CustomerTier.regular:
        return 'Regular';
    }
  }

  int get requiredPoints {
    switch (this) {
      case CustomerTier.bronze:
        return 0;
      case CustomerTier.silver:
        return 1000;
      case CustomerTier.gold:
        return 5000;
      case CustomerTier.platinum:
        return 15000;
      case CustomerTier.vip:
        return 50000;
      case CustomerTier.regular:
        return 0;
    }
  }

  double get discountPercentage {
    switch (this) {
      case CustomerTier.bronze:
        return 2.0;
      case CustomerTier.silver:
        return 5.0;
      case CustomerTier.gold:
        return 8.0;
      case CustomerTier.platinum:
        return 12.0;
      case CustomerTier.vip:
        return 20.0;
      case CustomerTier.regular:
        return 0.0;
    }
  }
}

class PointTransaction {
  final String id;
  final String customerId;
  final int points;
  final PointTransactionType type;
  final String description;
  final String? transactionId;
  final DateTime createdAt;

  PointTransaction({
    required this.id,
    required this.customerId,
    required this.points,
    required this.type,
    required this.description,
    this.transactionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'points': points,
      'type': type.toString(),
      'description': description,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PointTransaction.fromMap(Map<String, dynamic> map) {
    return PointTransaction(
      id: map['id'],
      customerId: map['customer_id'],
      points: map['points'],
      type: PointTransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      description: map['description'],
      transactionId: map['transaction_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

enum PointTransactionType { earned, redeemed, expired, bonus, adjustment }

extension PointTransactionTypeExtension on PointTransactionType {
  String get displayName {
    switch (this) {
      case PointTransactionType.earned:
        return 'Diperoleh';
      case PointTransactionType.redeemed:
        return 'Ditukar';
      case PointTransactionType.expired:
        return 'Kedaluwarsa';
      case PointTransactionType.bonus:
        return 'Bonus';
      case PointTransactionType.adjustment:
        return 'Penyesuaian';
    }
  }
}
