import 'package:flutter/material.dart';
import 'package:project_mmb/utils/constants.dart';


class CustomThemeProvider extends ChangeNotifier {
  CustomColors _colors = blueThemeColors;
  CustomColors get colors => _colors;

  CustomThemeProvider(){
    switchToBlue();
  }
  void switchToBlue() {
    _colors = blueThemeColors;
    notifyListeners();
  }

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}