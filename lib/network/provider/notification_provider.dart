import 'package:flutter/material.dart';
import 'package:project_mmb/Api%20Model/notification_model.dart';
import 'package:project_mmb/model/notification_model.dart';

import '../../Repository/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository.instance;

  NotificationModel? _notificationData;

  NotificationModel? get notificationData => _notificationData;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<NotificationList> get notifications => _notificationData?.data ?? [];

  List<NotificationList> get todayNotifications {
    final now = DateTime.now();

    return notifications.where((item) {
      final date = item.createdAt;

      if (date == null) return false;

      return date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;
    }).toList();
  }

  List<NotificationList> get yesterdayNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return notifications.where((item) {
      final date = item.createdAt;

      if (date == null) return false;

      return date.day == yesterday.day &&
          date.month == yesterday.month &&
          date.year == yesterday.year;
    }).toList();
  }

  List<NotificationList> get oldNotifications {
    final now = DateTime.now();

    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return notifications.where((item) {
      final date = item.createdAt;

      if (date == null) return false;

      final isToday =
          date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;

      final isYesterday =
          date.day == yesterday.day &&
          date.month == yesterday.month &&
          date.year == yesterday.year;

      return !isToday && !isYesterday;
    }).toList();
  }

  int get unreadCount {
    return notifications.where((item) => item.isRead != true).length;
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _repository.getNotification();

      if (result.isSuccess && result.data != null) {
        _notificationData = result.data;
      } else {
        _errorMessage = result.error?.message ?? "Something went wrong";
      }
    } catch (e) {
      _errorMessage = "Failed to load notifications";
      debugPrint("Notification API Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    if (_notificationData == null) return;

    for (final item in _notificationData!.data) {
      item.isRead == true;
    }

    notifyListeners();
  }

  void markAsRead(String uid) {
    if (_notificationData == null) return;

    final index = _notificationData!.data.indexWhere((item) => item.uid == uid);

    if (index == -1) return;

    _notificationData!.data[index].isRead == true;

    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}
