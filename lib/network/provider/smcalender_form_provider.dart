import 'package:flutter/cupertino.dart';
import 'package:project_mmb/core/app_provider/my_notifier.dart';

class SocialCalendarProvider extends ChangeNotifier with MyNotifier {
  String selectedMonth = 'August';
  int postsPerWeek = 4;
  bool isCalendarGridVisible = false;
  final Set<String> selectedPlatforms = {'Instagram'};
  String selectedTone = 'Professional';
  int selectedWeekTab = 2;

  // 🚀 Track whether templates are generated or not
  bool isTemplatesGenerated = false;

  final List<String> months = ['August', 'September', 'October', 'November', 'December'];
  final List<String> platformsList = ['Facebook', 'Instagram', 'X (Twitter)', 'LinkedIn', 'WhatsApp'];
  final List<String> tonesList = ['Professional', 'Funny', 'Bold', 'Friendly', 'Casual', 'Trendy', 'Empathetic'];

  void setMonth(String month) {
    selectedMonth = month;
    notifyListeners();
  }

  void setPostsPerWeek(int count) {
    postsPerWeek = count;
    notifyListeners();
  }

  void togglePlatform(String platform) {
    if (selectedPlatforms.contains(platform)) {
      if (selectedPlatforms.length > 1) {
        selectedPlatforms.remove(platform);
      }
    } else {
      selectedPlatforms.add(platform);
    }
    notifyListeners();
  }

  void setTone(String tone) {
    selectedTone = tone;
    notifyListeners();
  }

  void setWeekTab(int week) {
    selectedWeekTab = week;
    notifyListeners();
  }

  // 🚀 Trigger template generation on the same screen
  void generateTemplates() {
    isTemplatesGenerated = true;
    notifyListeners();
  }
  void resetTemplates() {
    isTemplatesGenerated = false;
    notifyListeners();
  }
}