import 'package:flutter/material.dart';
import 'package:project_mmb/Repository/theme_repoaitory.dart';
import '../../Api Model/theme_screen_model.dart';

class ThemesScreenProvider extends ChangeNotifier {
  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  ThemeApiResponse? _plansData;
  ThemeApiResponse? get plansData => _plansData;

  String? _plansErrorMessage;
  String? get plansErrorMessage => _plansErrorMessage;

  final ThemeRepository _repository = ThemeRepository.instance;

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

  List<ThemeItem> get groups {
    return _plansData?.data ?? [];
  }
}
