import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../component/status_widget.dart';
import '../model/notification_model.dart';

import 'package:provider/provider.dart';

import '../../network/provider/custom_theme_provider.dart';

class NotificationSection extends StatelessWidget {
  final String title;
  final List<NotificationModel> notifications;

  const NotificationSection({
    super.key,
    required this.title,
    required this.notifications,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      if (difference.inHours > 0) {
        return '${difference.inHours}hr ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}min ago';
      }
      return 'Just now';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.day == yesterday.day &&
        dateTime.month == yesterday.month &&
        dateTime.year == yesterday.year) {
      return '${difference.inHours}hr ago';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateTime.day}${months[dateTime.month - 1]},${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) return const SizedBox.shrink();

    final isDark = context.select<CustomThemeProvider, bool>((p) => p.isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        ...notifications.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _NotificationItem(
            notification: item,
            timeText: _formatTime(item.dateTime),
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final String timeText;

  const _NotificationItem({
    required this.notification,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<CustomThemeProvider, bool>((p) => p.isDarkMode);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE6EAFE),
              child: ClipOval(
                child: notification.avatarUrl != null
                    ? Image.network(
                  notification.avatarUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _defaultAvatar(isDark),
                )
                    : _defaultAvatar(isDark),
              ),
            ),
            if (!notification.isRead)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF222222),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.description,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusWidget(
                    status: notification.category,
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE6EAFE),
                    textStyle: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF1F2937),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE6EAFE),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          notification.category.isNotEmpty
              ? notification.category[0]
              : 'N',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}