import 'package:flutter/material.dart';

import '../../Api Model/notification_model.dart';
import '../../Repository/notification_repository.dart';
import 'common_provider.dart';

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

  Future<bool> markAsAllNotifications() async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      debugPrint('================================');
      debugPrint('🚀 MARK ALL NOTIFICATIONS API');

      final result = await _repository.notificationReadAll();

      if (!result.isSuccess) {
        _errorMessage = result.error?.message ?? "Something went wrong";

        debugPrint('❌ Mark all notification failed');

        return false;
      }

      debugPrint('✅ Mark all notification API success');

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

      await CommonProvider.instance.loadUnreadCount(forceRefresh: true);

      debugPrint(
        "🔔 HOME UNREAD COUNT UPDATED: "
        "${CommonProvider.instance.unreadCount}",
      );

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

      if (!result.isSuccess) {
        _errorMessage =
            result.error?.message ?? "Failed to mark notification as read";

        debugPrint('❌ Mark notification failed: $_errorMessage');

        return false;
      }

      debugPrint('✅ Mark notification API success');

      if (_notificationData != null) {
        final index = _notificationData!.data.indexWhere(
          (item) => item.uid == notificationUid,
        );

        if (index != -1) {
          _notificationData!.data[index] = _notificationData!.data[index]
              .copyWith(isRead: true);

          debugPrint(
            '✅ ${_notificationData!.data[index].uid} '
            'marked as read locally',
          );
        }
      }

      notifyListeners();

      debugPrint(
        '🔔 Notification screen unread count: '
        '$unreadCount',
      );

      final commonProvider = CommonProvider.instance;

      debugPrint(
        '🔔 OLD HOME UNREAD COUNT: '
        '${commonProvider.unreadCount}',
      );

      await commonProvider.loadUnreadCount(forceRefresh: true);

      debugPrint(
        '🔔 NEW HOME UNREAD COUNT: '
        '${commonProvider.unreadCount}',
      );

      debugPrint('================================');

      return true;
    } catch (e) {
      _errorMessage = "Failed to mark notification as read";

      debugPrint('❌ Mark notification error: $e');

      return false;
    }
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}
