import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/special_days.dart';
import '../../Repository/home_repository.dart';
import '../../core/api/models/api_result.dart';

class SpecialDaysProvider extends ChangeNotifier {
  final String? selectedDate;

  SpecialDaysProvider({this.selectedDate});

  bool isLoading = false;

  SpecialDays? _specialDays;
  SpecialDays? get specialDays => _specialDays;

  Future<void> loadSpecialDays({
    String? type,
    String? range,
    String? fromDate,
    String? toDate,
    bool showLoader = true,
  }) async {
    if (showLoader) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguages =
          prefs.getStringList('selected_language_codes') ?? ['en'];

      final language = savedLanguages.isNotEmpty ? savedLanguages.first : 'en';
      late ApiResult<SpecialDays> response;

      // Calendar date range selected
      if (fromDate != null &&
          fromDate.isNotEmpty &&
          toDate != null &&
          toDate.isNotEmpty) {
        response = await HomeRepository.instance.specialDaysApi(
          from: fromDate,
          to: toDate,
          language: language,
        );
      } else if (selectedDate != null && selectedDate!.isNotEmpty) {
        response = await HomeRepository.instance.specialDaysApi(
          from: selectedDate!,
          to: selectedDate!,
          language: language,
        );
      } else if (type == 'festival') {
        response = await HomeRepository.instance.specialDaysApi(
          type: type,
          range: range,
          language: language,
        );
      } else {
        response = await HomeRepository.instance.specialDaysApi(
          range: range ?? 'year',
          language: language,
        );
      }

      if (response.data != null) {
        _specialDays = response.data;
      }
    } catch (e) {
      debugPrint('Special Days API Error: $e');
    } finally {
      if (showLoader) {
        isLoading = false;
      }

      // Always notify when data loading finishes.
      notifyListeners();
    }
  }
}
