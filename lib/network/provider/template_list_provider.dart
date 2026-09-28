import 'package:flutter/cupertino.dart';

import '../../Api Model/special_days.dart';
import '../../Repository/home_repository.dart';
import '../../core/api/models/api_result.dart';

class TemplateListProvider extends ChangeNotifier {
  final String? selectedDate;

  TemplateListProvider({this.selectedDate});

  bool isLoading = false;

  SpecialDays? _specialDays;
  SpecialDays? get specialDays => _specialDays;

  Future<void> loadSpecialDays( {String? type}) async {
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
        response = await HomeRepository.instance.specialDaysApi(type: type);
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
