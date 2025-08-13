enum NotificationType {
  info,
  warning,
  error,
  success,
  lowStock,
  newTransaction,
  systemUpdate,
  userActivity,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? userId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.actionUrl,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'data': data?.toString(),
      'action_url': actionUrl,
      'user_id': userId,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      createdAt: DateTime.parse(map['created_at']),
      isRead: map['is_read'] == 1,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      actionUrl: map['action_url'],
      userId: map['user_id'],
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? userId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      userId: userId ?? this.userId,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.info:
        return 'Informasi';
      case NotificationType.warning:
        return 'Peringatan';
      case NotificationType.error:
        return 'Error';
      case NotificationType.success:
        return 'Berhasil';
      case NotificationType.lowStock:
        return 'Stok Menipis';
      case NotificationType.newTransaction:
        return 'Transaksi Baru';
      case NotificationType.systemUpdate:
        return 'Update Sistem';
      case NotificationType.userActivity:
        return 'Aktivitas User';
    }
  }

  String get typeColor {
    switch (type) {
      case NotificationType.info:
        return '#3B82F6'; // Blue
      case NotificationType.warning:
        return '#F59E0B'; // Amber
      case NotificationType.error:
        return '#EF4444'; // Red
      case NotificationType.success:
        return '#10B981'; // Green
      case NotificationType.lowStock:
        return '#F59E0B'; // Amber
      case NotificationType.newTransaction:
        return '#10B981'; // Green
      case NotificationType.systemUpdate:
        return '#6366F1'; // Indigo
      case NotificationType.userActivity:
        return '#8B5CF6'; // Purple
    }
  }
}
