import 'package:flutter/material.dart';
import 'package:project_mmb/core/app_provider/my_notifier.dart';

class BottomNavProvider extends ChangeNotifier with MyNotifier {
  int _selectedIndex = 2;

  int get selectedIndex => _selectedIndex;

  void updateIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}