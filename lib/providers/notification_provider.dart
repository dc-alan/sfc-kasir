import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/notification.dart';
import '../services/database_service.dart';

class NotificationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notifications = await _databaseService.getNotifications(
        userId: userId,
      );
      _notifications.clear();
      _notifications.addAll(notifications);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? userId,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      data: data,
      actionUrl: actionUrl,
      userId: userId,
    );

    try {
      await _databaseService.insertNotification(notification);
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _databaseService.markNotificationAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead({String? userId}) async {
    try {
      await _databaseService.markAllNotificationsAsRead(userId: userId);

      for (int i = 0; i < _notifications.length; i++) {
        if (userId == null || _notifications[i].userId == userId) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _databaseService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications({String? userId}) async {
    try {
      await _databaseService.clearAllNotifications(userId: userId);

      if (userId == null) {
        _notifications.clear();
      } else {
        _notifications.removeWhere((n) => n.userId == userId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Helper methods untuk membuat notifikasi spesifik
  Future<void> notifyLowStock(String productName, int currentStock) async {
    await addNotification(
      title: 'Stok Menipis',
      message: '$productName tersisa $currentStock unit',
      type: NotificationType.lowStock,
      data: {'product_name': productName, 'stock': currentStock},
    );
  }

  Future<void> notifyNewTransaction(String transactionId, double amount) async {
    await addNotification(
      title: 'Transaksi Baru',
      message: 'Transaksi baru sebesar Rp ${amount.toStringAsFixed(0)}',
      type: NotificationType.newTransaction,
      data: {'transaction_id': transactionId, 'amount': amount},
    );
  }

  Future<void> notifyUserActivity(String activity, String userName) async {
    await addNotification(
      title: 'Aktivitas User',
      message: '$userName $activity',
      type: NotificationType.userActivity,
      data: {'activity': activity, 'user_name': userName},
    );
  }

  Future<void> notifySystemUpdate(String updateMessage) async {
    await addNotification(
      title: 'Update Sistem',
      message: updateMessage,
      type: NotificationType.systemUpdate,
    );
  }

  Future<void> notifyError(String errorMessage) async {
    await addNotification(
      title: 'Error',
      message: errorMessage,
      type: NotificationType.error,
    );
  }

  Future<void> notifySuccess(String successMessage) async {
    await addNotification(
      title: 'Berhasil',
      message: successMessage,
      type: NotificationType.success,
    );
  }
}
