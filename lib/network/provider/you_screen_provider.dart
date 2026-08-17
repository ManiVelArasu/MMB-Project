import 'package:flutter/material.dart';

import '../../model/you_screen_model.dart';

class ProfileScreenProvider extends ChangeNotifier {
  bool isDarkMode = false;
  bool isWatermarkEnabled = false;

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void toggleWatermark(bool value) {
    isWatermarkEnabled = value;
    notifyListeners();
  }

  final List<QuickActionModel> quickActions = [
    QuickActionModel(
      title: "Business\nProfile",
      iconPath: "assets/images/business_profile.png",
      backgroundColor: const Color(0xFFE0F7FA),
      onTap: (context) {
        Navigator.pushNamed(context, '/BusinessProfileScreen');
      },
    ),
    QuickActionModel(
      title: "My\nDownloads",
      iconPath: "assets/images/my_downloads.png",
      backgroundColor: const Color(0xFFEDE7F6),
      onTap: (context) {
        Navigator.pushNamed(context, "/MyDownloadsScreen");
      },
    ),
    QuickActionModel(
      title: "SM\nCalendar",
      iconPath: "assets/images/sm_calendar.png",
      backgroundColor: const Color(0xFFFFECB3),
      onTap: (context) {
        Navigator.pushNamed(context, "/SmCalendarScreen");
      },
    ),
  ];
}
