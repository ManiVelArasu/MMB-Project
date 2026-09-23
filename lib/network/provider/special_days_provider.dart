import 'package:flutter/cupertino.dart';
import 'package:mmb_app/Repository/home_repository.dart';

import '../../Api Model/special_days.dart';
import '../../core/api/models/api_result.dart';

class SpecialDaysProvider extends ChangeNotifier {
  final String? selectedDate;

  SpecialDaysProvider({this.selectedDate});

  bool isLoading = false;

  SpecialDays? _specialDays;
  SpecialDays? get specialDays => _specialDays;

  Future<void> loadSpecialDays() async {
    isLoading = true;
    notifyListeners();

    try {
      late ApiResult<SpecialDays> response;

      if (selectedDate != null && selectedDate!.isNotEmpty) {
        response = await HomeRepository.instance.specialDaysApi(
          from: selectedDate!,
          to: selectedDate!,
        );
      } else {
        response = await HomeRepository.instance.specialDaysApi(range: 'all');
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
