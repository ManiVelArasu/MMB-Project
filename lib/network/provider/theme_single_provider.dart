import 'package:flutter/foundation.dart';
import '../../Api Model/theme_single_model.dart';
import '../../Repository/theme_repoaitory.dart';

class ThemeSingleItemProvider extends ChangeNotifier {
  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  void toggleFavorite() {
    _isFavorite = !_isFavorite;
    notifyListeners();
  }

  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  ThemeDetailView? _plansData;
  ThemeDetailView? get plansData => _plansData;

  String? _plansErrorMessage;
  String? get plansErrorMessage => _plansErrorMessage;

  final ThemeRepository _repository = ThemeRepository.instance;

  Future<void> fetchPlans(String variantId) async {
    _isLoadingPlans = true;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.themeSingleView(variantId);

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;
      } else {
        _plansErrorMessage = result.error?.message ?? "Something went wrong";
      }
    } catch (e) {
      _plansErrorMessage = e.toString();
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }
}
