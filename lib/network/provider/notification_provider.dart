import 'package:flutter/material.dart';
import 'package:project_mmb/model/notification_model.dart';

class NotificationProvider extends ChangeNotifier {

  final List<NotificationModel> _notifications = [

    NotificationModel(
      title: "New theme added to the library.",
      description: "Check now and design your SM posts",
      category: "THEMES",
      avatarUrl: "https://picsum.photos/seed/theme1/44",
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),

    NotificationModel(
      title: "Your post received 10 likes.",
      description: "Great engagement on your latest post",
      category: "POSTS",
      avatarUrl: "https://picsum.photos/seed/post1/44",
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),

    NotificationModel(
      title: "A new shop opened near you.",
      description: "Visit and explore new offers nearby",
      category: "NEAR BY",
      avatarUrl: "https://picsum.photos/seed/near1/44",
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),

    NotificationModel(
      title: "Your post has new comments.",
      description: "Check what people are saying",
      category: "POSTS",
      avatarUrl: "https://picsum.photos/seed/post2/44",
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),

    NotificationModel(
      title: "Weekly report is ready.",
      description: "View your weekly performance summary",
      category: "POSTS",
      avatarUrl: "https://picsum.photos/seed/post3/44",
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
    ),
  ];

  List<NotificationModel> get notifications => _notifications;

  List<NotificationModel> get todayNotifications {
    final now = DateTime.now();
    return _notifications.where((item) {
      return item.dateTime.day == now.day &&
          item.dateTime.month == now.month &&
          item.dateTime.year == now.year;
    }).toList();
  }

  List<NotificationModel> get yesterdayNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((item) {
      return item.dateTime.day == yesterday.day &&
          item.dateTime.month == yesterday.month &&
          item.dateTime.year == yesterday.year;
    }).toList();
  }

  List<NotificationModel> get oldNotifications {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((item) {
      final isToday = item.dateTime.day == now.day &&
          item.dateTime.month == now.month &&
          item.dateTime.year == now.year;
      final isYesterday = item.dateTime.day == yesterday.day &&
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
