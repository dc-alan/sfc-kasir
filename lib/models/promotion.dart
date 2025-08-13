import 'package:flutter/material.dart';

enum DiscountType {
  percentage,
  nominal,
  bogo, // Buy One Get One
}

enum PromotionType { discount, coupon, happyHour, bundle }

class Promotion {
  final String id;
  final String name;
  final String description;
  final PromotionType type;
  final DiscountType discountType;
  final double discountValue;
  final double? minimumPurchase;
  final int? maxUsage;
  final int currentUsage;
  final int?
  maxQuantityPerItem; // Maximum quantity per item that gets the discount
  final DateTime startDate;
  final DateTime endDate;
  final List<String> applicableProductIds;
  final List<String> applicableCategories;
  final bool isActive;
  final DateTime? happyHourStart;
  final DateTime? happyHourEnd;
  final String? couponCode;
  final List<BundleItem>? bundleItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.discountType,
    required this.discountValue,
    this.minimumPurchase,
    this.maxUsage,
    this.currentUsage = 0,
    this.maxQuantityPerItem,
    required this.startDate,
    required this.endDate,
    this.applicableProductIds = const [],
    this.applicableCategories = const [],
    this.isActive = true,
    this.happyHourStart,
    this.happyHourEnd,
    this.couponCode,
    this.bundleItems,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: PromotionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      discountType: DiscountType.values.firstWhere(
        (e) => e.toString().split('.').last == map['discount_type'],
      ),
      discountValue: map['discount_value']?.toDouble() ?? 0.0,
      minimumPurchase: map['minimum_purchase']?.toDouble(),
      maxUsage: map['max_usage'],
      currentUsage: map['current_usage'] ?? 0,
      maxQuantityPerItem: map['max_quantity_per_item'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      applicableProductIds: map['applicable_product_ids'] != null
          ? List<String>.from(map['applicable_product_ids'].split(','))
          : [],
      applicableCategories: map['applicable_categories'] != null
          ? List<String>.from(map['applicable_categories'].split(','))
          : [],
      isActive: map['is_active'] == 1,
      happyHourStart: map['happy_hour_start'] != null
          ? DateTime.parse(map['happy_hour_start'])
          : null,
      happyHourEnd: map['happy_hour_end'] != null
          ? DateTime.parse(map['happy_hour_end'])
          : null,
      couponCode: map['coupon_code'],
      bundleItems: map['bundle_items'] != null
          ? (map['bundle_items'] as List)
                .map((item) => BundleItem.fromMap(item))
                .toList()
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'discount_type': discountType.toString().split('.').last,
      'discount_value': discountValue,
      'minimum_purchase': minimumPurchase,
      'max_usage': maxUsage,
      'current_usage': currentUsage,
      'max_quantity_per_item': maxQuantityPerItem,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'applicable_product_ids': applicableProductIds.join(','),
      'applicable_categories': applicableCategories.join(','),
      'is_active': isActive ? 1 : 0,
      'happy_hour_start': happyHourStart?.toIso8601String(),
      'happy_hour_end': happyHourEnd?.toIso8601String(),
      'coupon_code': couponCode,
      'bundle_items': bundleItems?.map((item) => item.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Promotion copyWith({
    String? name,
    String? description,
    PromotionType? type,
    DiscountType? discountType,
    double? discountValue,
    double? minimumPurchase,
    int? maxUsage,
    int? currentUsage,
    int? maxQuantityPerItem,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? applicableProductIds,
    List<String>? applicableCategories,
    bool? isActive,
    DateTime? happyHourStart,
    DateTime? happyHourEnd,
    String? couponCode,
    List<BundleItem>? bundleItems,
    DateTime? updatedAt,
  }) {
    return Promotion(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minimumPurchase: minimumPurchase ?? this.minimumPurchase,
      maxUsage: maxUsage ?? this.maxUsage,
      currentUsage: currentUsage ?? this.currentUsage,
      maxQuantityPerItem: maxQuantityPerItem ?? this.maxQuantityPerItem,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      applicableProductIds: applicableProductIds ?? this.applicableProductIds,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      isActive: isActive ?? this.isActive,
      happyHourStart: happyHourStart ?? this.happyHourStart,
      happyHourEnd: happyHourEnd ?? this.happyHourEnd,
      couponCode: couponCode ?? this.couponCode,
      bundleItems: bundleItems ?? this.bundleItems,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool isValidNow() {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (maxUsage == null || currentUsage < maxUsage!);
  }

  bool isHappyHourActive() {
    if (type != PromotionType.happyHour ||
        happyHourStart == null ||
        happyHourEnd == null) {
      return false;
    }

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final startTime = TimeOfDay.fromDateTime(happyHourStart!);
    final endTime = TimeOfDay.fromDateTime(happyHourEnd!);

    return _isTimeInRange(currentTime, startTime, endTime);
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Happy hour crosses midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  double calculateDiscount(double amount) {
    if (!isValidNow()) return 0.0;

    if (type == PromotionType.happyHour && !isHappyHourActive()) {
      return 0.0;
    }

    if (minimumPurchase != null && amount < minimumPurchase!) {
      return 0.0;
    }

    switch (discountType) {
      case DiscountType.percentage:
        return amount * (discountValue / 100);
      case DiscountType.nominal:
        return discountValue;
      case DiscountType.bogo:
        // BOGO logic would be handled differently in cart calculation
        return 0.0;
    }
  }
}

class BundleItem {
  final String productId;
  final int quantity;
  final double? specialPrice;

  BundleItem({
    required this.productId,
    required this.quantity,
    this.specialPrice,
  });

  factory BundleItem.fromMap(Map<String, dynamic> map) {
    return BundleItem(
      productId: map['product_id'],
      quantity: map['quantity'],
      specialPrice: map['special_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'special_price': specialPrice,
    };
  }
}
