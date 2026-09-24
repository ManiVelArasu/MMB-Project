import 'package:flutter/material.dart';

import '../../Api Model/notification_model.dart';
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

  // ============================================================
  // TODAY
  // ============================================================

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

  // ============================================================
  // YESTERDAY
  // ============================================================

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

  // ============================================================
  // OLD NOTIFICATIONS
  // ============================================================

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

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  int get unreadCount {
    return notifications.where((item) => item.isRead != true).length;
  }

  // ============================================================
  // GET NOTIFICATIONS API
  // ============================================================

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result = await _repository.getNotification();

      if (result.isSuccess && result.data != null) {
        _notificationData = result.data;

        debugPrint('✅ Notifications fetched successfully');

        debugPrint('Total notifications: ${notifications.length}');

        debugPrint('Unread count: $unreadCount');
      } else {
        _errorMessage = result.error?.message ?? "Something went wrong";
      }
    } catch (e) {
      _errorMessage = "Failed to load notifications";

      debugPrint("❌ Notification API Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ============================================================

  Future<bool> markAsAllNotifications() async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      debugPrint('================================');

      debugPrint('🚀 MARK ALL NOTIFICATIONS API');

      // --------------------------------------------------------
      // 1. MARK ALL READ API
      // --------------------------------------------------------

      final result = await _repository.notificationReadAll();

      if (!result.isSuccess) {
        _errorMessage = result.error?.message ?? "Something went wrong";

        debugPrint('❌ Mark all notification failed');

        return false;
      }

      debugPrint('✅ Mark all notification API success');

      // --------------------------------------------------------
      // 2. GET NOTIFICATION API AGAIN
      // --------------------------------------------------------

      final notificationResult = await _repository.getNotification();

      if (notificationResult.isSuccess && notificationResult.data != null) {
        _notificationData = notificationResult.data;

        debugPrint('✅ Notification API called again');

        debugPrint('Unread count after mark all: $unreadCount');
      } else {
        _errorMessage =
            notificationResult.error?.message ??
            "Failed to refresh notifications";

        return false;
      }

      debugPrint('================================');

      return true;
    } catch (e) {
      _errorMessage = "Failed to mark notifications as read";

      debugPrint("❌ Mark All Notification Error: $e");

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markNotificationAsRead(String notificationUid) async {
    try {
      debugPrint('================================');
      debugPrint('🚀 MARK ONE NOTIFICATION AS READ');
      debugPrint('UID: $notificationUid');

      final result = await _repository.notificationReadOne(notificationUid);

      if (result.isSuccess) {
        if (_notificationData != null) {
          final index = _notificationData!.data.indexWhere(
            (item) => item.uid == notificationUid,
          );

          if (index != -1) {
            _notificationData!.data[index].isRead == true;
          }
        }

        notifyListeners();

        debugPrint('Unread count: $unreadCount');

        debugPrint('================================');

        return true;
      }

      _errorMessage =
          result.error?.message ?? "Failed to mark notification as read";

      debugPrint('❌ Mark notification failed: $_errorMessage');

      return false;
    } catch (e) {
      _errorMessage = "Failed to mark notification as read";

      debugPrint('❌ Mark notification error: $e');

      return false;
    }
  }
  // ============================================================
  // LOCAL MARK ALL AS READ
  // ============================================================

  /* void markAllAsRead() {
    if (_notificationData == null) return;

    for (final item
    in _notificationData!.data) {
      item.isRead = true;
    }

    notifyListeners();
  }*/

  // ============================================================
  // LOCAL MARK ONE AS READ
  // ============================================================

  /* void markAsRead(String uid) {
    if (_notificationData == null) return;

    final index =
    _notificationData!.data.indexWhere(
          (item) => item.uid == uid,
    );

    if (index == -1) return;

    _notificationData!
        .data[index]
        .isRead = true;

    notifyListeners();
  }*/

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}
