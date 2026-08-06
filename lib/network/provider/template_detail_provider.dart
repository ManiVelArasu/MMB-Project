import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemplateDetailProvider extends ChangeNotifier {
  TemplateDetailProvider() {
    loadSavedImage();
  }

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  String _selectedResizeSize = "Post Square (1:1)";
  String get selectedResizeSize => _selectedResizeSize;

  String? _savedImagePath;
  String? get savedImagePath => _savedImagePath;
  Future<void> loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    _savedImagePath = prefs.getString('saved_business_image_path');
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setResizeSize(String size) {
    _selectedResizeSize = size;
    notifyListeners();
  }
}
