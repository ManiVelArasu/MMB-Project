import 'package:flutter/cupertino.dart';

class SocialCalendarProvider extends ChangeNotifier {
  String selectedMonth = 'August';
  int postsPerWeek = 4;

  // Selected Social Media Platforms
  final Set<String> selectedPlatforms = {'Instagram'};

  // Selected Tone
  String selectedTone = 'Professional';

  // Master lists for options
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
      if (selectedPlatforms.length > 1) { // At least one should be selected
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
}