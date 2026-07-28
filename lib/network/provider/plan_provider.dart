import 'package:flutter/cupertino.dart';
import 'package:project_mmb/Repository/plan_repository.dart';

import '../../Api Model/plans_type.dart';


class PlanProvider extends ChangeNotifier {
  final PlanRepository _repository = PlanRepository.instance;

  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  PlanResponse? _plansData;
  PlanResponse? get plansData => _plansData;

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
        _plansErrorMessage =
            result.error?.message ?? "Something went wrong";
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }
}
