import 'package:flutter/material.dart';
import 'package:project_mmb/model/notification_model.dart';

class NotificationProvider extends ChangeNotifier {

  final List<NotificationModel> _notifications = [

    NotificationModel(
      title: "THEMES",
      description: "New themes are available now.",
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),


    NotificationModel(
      title: "POSTS",
      description: "Your post received 10 likes.",
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),

    NotificationModel(
      title: "NEAR BY",
      description: "A new shop opened near your location.",
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),

    NotificationModel(
      title: "POSTS",
      description: "Your post has new comments.",
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),

    NotificationModel(
      title: "POSTS",
      description: "Weekly report is ready.",
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
    ),
  ];

  List<NotificationModel> get notifications => _notifications;

  List<NotificationModel> get todayNotifications {
    return _notifications.where((item) {
      return item.dateTime.day == DateTime.now().day &&
          item.dateTime.month == DateTime.now().month &&
          item.dateTime.year == DateTime.now().year;
    }).toList();
  }

  List<NotificationModel> get yesterdayNotifications {
    DateTime yesterday =
    DateTime.now().subtract(const Duration(days: 1));

    return _notifications.where((item) {
      return item.dateTime.day == yesterday.day &&
          item.dateTime.month == yesterday.month &&
          item.dateTime.year == yesterday.year;
    }).toList();
  }

  List<NotificationModel> get oldNotifications {
    DateTime today = DateTime.now();

    DateTime yesterday =
    DateTime.now().subtract(const Duration(days: 1));

    return _notifications.where((item) {

      bool isToday =
          item.dateTime.day == today.day &&
              item.dateTime.month == today.month &&
              item.dateTime.year == today.year;

      bool isYesterday =
          item.dateTime.day == yesterday.day &&
              item.dateTime.month == yesterday.month &&
              item.dateTime.year == yesterday.year;

      return !isToday && !isYesterday;

    }).toList();
  }

  void markAsRead(int index) {
    _notifications[index].isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (var item in _notifications) {
      item.isRead = true;
    }
    notifyListeners();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void deleteNotification(int index) {
    _notifications.removeAt(index);
    notifyListeners();
  }

  int get unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }
}
