import 'package:flutter/cupertino.dart';

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
      late ApiResult<SpecialDays> response;

      // Calendar date range selected
      if (fromDate != null &&
          fromDate.isNotEmpty &&
          toDate != null &&
          toDate.isNotEmpty) {
        response = await HomeRepository.instance.specialDaysApi(
          from: fromDate,
          to: toDate,
        );
      } else if (selectedDate != null && selectedDate!.isNotEmpty) {
        response = await HomeRepository.instance.specialDaysApi(
          from: selectedDate!,
          to: selectedDate!,
        );
      } else if (type == 'festival') {
        response = await HomeRepository.instance.specialDaysApi(
          type: type,
          range: range,
        );
      } else {
        response = await HomeRepository.instance.specialDaysApi(
          range: range ?? 'year',
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