import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';

import 'package:provider/provider.dart';

import '../../Api Model/notification_model.dart';
import '../../component/custom_widget.dart';
import '../../model/notification_model.dart';
import '../../network/provider/notification_provider.dart';
import '../../widgets/notification_section.dart';
import '../../network/provider/custom_theme_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationProvider()..fetchNotifications(),

      child: Consumer2<NotificationProvider, CustomThemeProvider>(
        builder: (context, provider, themeProvider, child) {
          final isDark = themeProvider.isDarkMode;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,

            appBar: CustomAppBar(
              showTitle: true,
              title: "Notification",
              showActionText: true,
              actionText: "Mark as All Read",
              showRightIcon: false,

              onActionTextTap: () async {
                final success = await provider.markAsAllNotifications();

                if (!context.mounted) return;

                if (!success && provider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage!)),
                  );
                }
              },
            ),

            body: SafeArea(
              top: false,
              child: _buildNotificationBody(context, provider, isDark),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildNotificationBody(
    BuildContext context,
    NotificationProvider provider,
    bool isDark,
  ) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.redAccent : Colors.red,
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: isDark ? Colors.white54 : Colors.grey,
              ),

              const SizedBox(height: 12),

              AppText(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  provider.fetchNotifications();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 54,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            AppText(
              "No notifications yet",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.red,

      onRefresh: provider.refreshNotifications,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.symmetric(horizontal: 16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 20),

            // ==================================================
            // TODAY
            // ==================================================
            if (provider.todayNotifications.isNotEmpty)
              NotificationSection(
                title: "TODAY",
                notifications: _convertNotifications(
                  provider.todayNotifications,
                ),
                onNotificationTap: (notification) async {
                  print('${notification.uid}');
                  if (notification.isRead) {
                    return;
                  }

                  final uid = notification.uid;

                  if (uid == null || uid.isEmpty) {
                    debugPrint("❌ Notification UID is empty");
                    return;
                  }

                  await provider.markNotificationAsRead(uid);
                },
              ),

            if (provider.yesterdayNotifications.isNotEmpty)
              NotificationSection(
                title: "YESTERDAY",
                notifications: _convertNotifications(
                  provider.yesterdayNotifications,
                ),
                onNotificationTap: (notification) async {
                  if (notification.isRead) {
                    return;
                  }

                  final uid = notification.uid;

                  if (uid == null || uid.isEmpty) {
                    debugPrint("❌ Notification UID is empty");
                    return;
                  }

                  await provider.markNotificationAsRead(uid);
                },
              ),

            if (provider.oldNotifications.isNotEmpty)
              NotificationSection(
                title: "OLD",
                notifications: _convertNotifications(provider.oldNotifications),
                onNotificationTap: (notification) async {
                  if (notification.isRead) {
                    return;
                  }

                  final uid = notification.uid;

                  if (uid == null || uid.isEmpty) {
                    debugPrint("❌ Notification UID is empty");
                    return;
                  }

                  await provider.markNotificationAsRead(uid);
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<NotificationModels> _convertNotifications(List<NotificationList> items) {
    return items.map((item) {
      return NotificationModels(
        uid: item.uid,

        title: item.title ?? "",

        description: item.body ?? "",

        category: item.category?.name ?? "",

        avatarUrl: item.imageS3Key ?? "",

        dateTime: item.createdAt ?? DateTime.now(),

        isRead: item.isRead ?? false,
      );
    }).toList();
  }
}
