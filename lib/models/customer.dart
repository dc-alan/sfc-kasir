class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? birthDate;
  final DateTime? anniversaryDate;
  final CustomerSegment segment;
  final CustomerStatus status;
  final String? notes;
  final double totalSpent;
  final int totalTransactions;
  final DateTime? lastVisit;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.birthDate,
    this.anniversaryDate,
    this.segment = CustomerSegment.regular,
    this.status = CustomerStatus.active,
    this.notes,
    this.totalSpent = 0.0,
    this.totalTransactions = 0,
    this.lastVisit,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'birth_date': birthDate?.toIso8601String(),
      'anniversary_date': anniversaryDate?.toIso8601String(),
      'segment': segment.toString(),
      'status': status.toString(),
      'notes': notes,
      'total_spent': totalSpent,
      'total_transactions': totalTransactions,
      'last_visit': lastVisit?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'])
          : null,
      anniversaryDate: map['anniversary_date'] != null
          ? DateTime.parse(map['anniversary_date'])
          : null,
      segment: CustomerSegment.values.firstWhere(
        (e) => e.toString() == map['segment'],
        orElse: () => CustomerSegment.regular,
      ),
      status: CustomerStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => CustomerStatus.active,
      ),
      notes: map['notes'],
      totalSpent: map['total_spent']?.toDouble() ?? 0.0,
      totalTransactions: map['total_transactions'] ?? 0,
      lastVisit: map['last_visit'] != null
          ? DateTime.parse(map['last_visit'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? birthDate,
    DateTime? anniversaryDate,
    CustomerSegment? segment,
    CustomerStatus? status,
    String? notes,
    double? totalSpent,
    int? totalTransactions,
    DateTime? lastVisit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      segment: segment ?? this.segment,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      totalSpent: totalSpent ?? this.totalSpent,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get hasBirthday {
    if (birthDate == null) return false;
    final now = DateTime.now();
    return birthDate!.month == now.month && birthDate!.day == now.day;
  }

  bool get hasAnniversary {
    if (anniversaryDate == null) return false;
    final now = DateTime.now();
    return anniversaryDate!.month == now.month &&
        anniversaryDate!.day == now.day;
  }

  bool get isUpcomingBirthday {
    if (birthDate == null) return false;
    final now = DateTime.now();
    final thisYearBirthday = DateTime(
      now.year,
      birthDate!.month,
      birthDate!.day,
    );
    final daysDifference = thisYearBirthday.difference(now).inDays;
    return daysDifference >= 0 && daysDifference <= 7;
  }

  bool get isUpcomingAnniversary {
    if (anniversaryDate == null) return false;
    final now = DateTime.now();
    final thisYearAnniversary = DateTime(
      now.year,
      anniversaryDate!.month,
      anniversaryDate!.day,
    );
    final daysDifference = thisYearAnniversary.difference(now).inDays;
    return daysDifference >= 0 && daysDifference <= 7;
  }

  double get averageTransactionValue {
    return totalTransactions > 0 ? totalSpent / totalTransactions : 0.0;
  }

  int get daysSinceLastVisit {
    if (lastVisit == null) return -1;
    return DateTime.now().difference(lastVisit!).inDays;
  }
}

enum CustomerSegment { vip, premium, regular, new_customer, inactive }

extension CustomerSegmentExtension on CustomerSegment {
  String get displayName {
    switch (this) {
      case CustomerSegment.vip:
        return 'VIP';
      case CustomerSegment.premium:
        return 'Premium';
      case CustomerSegment.regular:
        return 'Regular';
      case CustomerSegment.new_customer:
        return 'Pelanggan Baru';
      case CustomerSegment.inactive:
        return 'Tidak Aktif';
    }
  }

  String get description {
    switch (this) {
      case CustomerSegment.vip:
        return 'Pelanggan dengan nilai transaksi tinggi';
      case CustomerSegment.premium:
        return 'Pelanggan setia dengan transaksi rutin';
      case CustomerSegment.regular:
        return 'Pelanggan biasa';
      case CustomerSegment.new_customer:
        return 'Pelanggan baru dalam 30 hari terakhir';
      case CustomerSegment.inactive:
        return 'Tidak bertransaksi > 90 hari';
    }
  }
}

enum CustomerStatus { active, inactive, blocked, vip }

extension CustomerStatusExtension on CustomerStatus {
  String get displayName {
    switch (this) {
      case CustomerStatus.active:
        return 'Aktif';
      case CustomerStatus.inactive:
        return 'Tidak Aktif';
      case CustomerStatus.blocked:
        return 'Diblokir';
      case CustomerStatus.vip:
        return 'VIP';
    }
  }
}

class CustomerHistory {
  final String id;
  final String customerId;
  final String transactionId;
  final double amount;
  final List<String> items;
  final DateTime date;
  final String? notes;

  CustomerHistory({
    required this.id,
    required this.customerId,
    required this.transactionId,
    required this.amount,
    required this.items,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'transaction_id': transactionId,
      'amount': amount,
      'items': items,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory CustomerHistory.fromMap(Map<String, dynamic> map) {
    return CustomerHistory(
      id: map['id'],
      customerId: map['customer_id'],
      transactionId: map['transaction_id'],
      amount: map['amount']?.toDouble() ?? 0.0,
      items: List<String>.from(map['items'] ?? []),
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }
}
