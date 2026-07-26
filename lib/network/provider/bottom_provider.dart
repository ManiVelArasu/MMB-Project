import 'package:flutter/material.dart';

class BottomNavProvider extends ChangeNotifier {
  int _selectedIndex = 2;

  int get selectedIndex => _selectedIndex;

  void updateIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}