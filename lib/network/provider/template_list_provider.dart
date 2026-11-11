import 'package:flutter/material.dart';

import '../../Api Model/special_days.dart';
import '../../Repository/home_repository.dart';
import '../../core/api/models/api_result.dart';

class TemplateListProvider extends ChangeNotifier {
  final String? selectedDate;

  TemplateListProvider({this.selectedDate});

  bool isLoading = false;

  // True once data has been loaded successfully at least once.
  bool _hasLoadedOnce = false;
  // Whether the current load should show the loader on top of the screen.
  bool _showOverlayLoader = true;
  bool _disposed = false;

  SpecialDays? _specialDays;
  SpecialDays? get specialDays => _specialDays;

  /// First load: nothing to show yet, so the screen shows a full-screen loader.
  bool get isInitialLoading => isLoading && !_hasLoadedOnce;

  /// Refresh / date filter: the screen stays visible and a loader is drawn on
  /// top of it. Pull-to-refresh passes [showOverlayLoader] = false because the
  /// RefreshIndicator already shows its own spinner.
  bool get isRefreshing => isLoading && _hasLoadedOnce && _showOverlayLoader;

  Future<void> loadSpecialDays({
    String? type,
    String? range,
    String? fromDate,
    String? toDate,
    bool showOverlayLoader = true,
  }) async {
    _showOverlayLoader = showOverlayLoader;
    isLoading = true;
    _safeNotify();

    try {
      final ApiResult<SpecialDays> response;

      // Date range selected: send only from and to dates.
      if (fromDate != null && toDate != null) {
        response = await HomeRepository.instance.specialDaysApi(
          from: fromDate,
          to: toDate,
        );
      } else if (type == 'festival') {
        response = await HomeRepository.instance.specialDaysApi(
          type: type,
          range: range,
        );
      } else if (selectedDate != null && selectedDate!.isNotEmpty) {
        response = await HomeRepository.instance.specialDaysApi(
          from: selectedDate!,
          to: selectedDate!,
        );
      } else {
        response = await HomeRepository.instance.specialDaysApi(
          type: type,
          range: range,
        );
      }

      if (response.data != null) {
        _specialDays = response.data;
        _hasLoadedOnce = true;
      }
    } catch (e) {
      debugPrint('Special Days API Error: $e');
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  // The user can leave the screen while a request is still running.
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}