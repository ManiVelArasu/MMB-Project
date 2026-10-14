import 'package:flutter/material.dart';

import '../../Api Model/theme_screen_model.dart';
import '../../Repository/theme_repoaitory.dart';

class ThemesScreenProvider extends ChangeNotifier {
  bool _isLoadingPlans = false;
  bool _isFetchingPlans = false;

  // Full-screen loader is only shown during the first load.
  // Existing content stays visible during pull-to-refresh.
  bool get isLoadingPlans => _isLoadingPlans;

  ThemeApiResponse? _plansData;

  ThemeApiResponse? get plansData => _plansData;

  String? _plansErrorMessage;

  String? get plansErrorMessage => _plansErrorMessage;

  final ThemeRepository _repository = ThemeRepository.instance;

  Future<void> fetchPlans({bool forceRefresh = false}) async {
    if (_isFetchingPlans) return;
    if (_plansData != null && !forceRefresh) return;

    _isFetchingPlans = true;

    // Only show the full-screen loader when there is no cached data.
    _isLoadingPlans = _plansData == null;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.industry();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;
        _plansErrorMessage = null;
      } else if (_plansData == null) {
        // On first load, show the error. On refresh, retain existing data.
        _plansErrorMessage =
            result.error?.message ?? 'Something went wrong';
      }
    } catch (e) {
      if (_plansData == null) {
        _plansErrorMessage = e.toString();
      }
    } finally {
      _isFetchingPlans = false;
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchPlans(forceRefresh: true);

  List<ThemeItem> get groups {
    return _plansData?.data ?? [];
  }
}