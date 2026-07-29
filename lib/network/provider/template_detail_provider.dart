import 'package:flutter/cupertino.dart';

class TemplateDetailProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  String _selectedResizeSize = "Post Square (1:1)";
  String get selectedResizeSize => _selectedResizeSize;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setResizeSize(String size) {
    _selectedResizeSize = size;
    notifyListeners();
  }
}