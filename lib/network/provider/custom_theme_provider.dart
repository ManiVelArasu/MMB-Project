import 'package:flutter/material.dart';
import 'package:project_mmb/utils/constants.dart';

import '../../Api Model/template_size_model.dart';
import '../../Repository/custom_theme_repository.dart';

class CustomThemeProvider extends ChangeNotifier {
  CustomColors _colors = blueThemeColors;
  CustomColors get colors => _colors;
  final CustomThemeRepository _repository = CustomThemeRepository.instance;
  CustomThemeProvider() {
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

  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  TemplateSizeModel? _plansData;
  TemplateSizeModel? get plansData => _plansData;

  String? _plansErrorMessage;
  String? get plansErrorMessage => _plansErrorMessage;
  Future<void> fetchPlans() async {
    _isLoadingPlans = true;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.industry();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;
      } else {
        _plansErrorMessage = result.error?.message ?? "Something went wrong";
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }
}
