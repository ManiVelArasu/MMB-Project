import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:provider/provider.dart';

import '../../network/provider/notification_provider.dart';
import '../../widgets/notification_section.dart';
import '../../network/provider/custom_theme_provider.dart';


class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationProvider(),
      child: Consumer2<NotificationProvider, CustomThemeProvider>(
        builder: (context, provider, themeProvider, child) {
          final isDark = themeProvider.isDarkMode;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 72,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFF1F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Center(
                            child: AppText(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () => provider.markAllAsRead(),
                          child: Text(
                            'Mark all as Read',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.blueAccent : const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      NotificationSection(
                        title: "TODAY",
                        notifications: provider.todayNotifications,
                      ),

                      NotificationSection(
                        title: "YESTERDAY",
                        notifications: provider.yesterdayNotifications,
                      ),

                      NotificationSection(
                        title: "OLD",
                        notifications: provider.oldNotifications,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}