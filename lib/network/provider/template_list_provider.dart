import 'package:flutter/material.dart';

import '../../Api Model/special_days.dart';
import '../../Repository/home_repository.dart';
import '../../core/api/models/api_result.dart';

class TemplateListProvider extends ChangeNotifier {
  final String? selectedDate;

  TemplateListProvider({this.selectedDate});

  bool isLoading = false;

  SpecialDays? _specialDays;
  SpecialDays? get specialDays => _specialDays;

  Future<void> loadSpecialDays({
    String? type,
    String? range,
    String? fromDate,
    String? toDate,
  }) async {
    isLoading = true;
    notifyListeners();

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
      }
    } catch (e) {
      debugPrint('Special Days API Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}