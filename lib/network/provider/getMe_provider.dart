import 'package:flutter/foundation.dart';
import '../../Api Model/me_api.dart';
import '../../Repository/get_me_repository.dart';

class CommonProvider extends ChangeNotifier {
  CommonProvider._();

  static final CommonProvider instance = CommonProvider._();

  Language? _me;
  Language? get me => _me;

  bool _isMeLoading = false;
  bool get isMeLoading => _isMeLoading;

  String? _meError;
  String? get meError => _meError;

  Future<bool> loadMe({bool forceRefresh = false}) async {
    if (_me != null && !forceRefresh) {
      return true;
    }

    _isMeLoading = true;
    _meError = null;
    notifyListeners();

    try {
      final result = await GetMeRepository.instance.getMe();

      final data = result.data;

      if (data == null) {
        _meError = 'User data not found';
        return false;
      }

      _me = data;

      debugPrint('✅ GetMe data loaded');

      return true;
    } catch (e, stackTrace) {
      _meError = e.toString();

      debugPrint('❌ GetMe failed: $e');
      debugPrint('$stackTrace');

      return false;
    } finally {
      _isMeLoading = false;
      notifyListeners();
    }
  }

  void clearMe() {
    _me = null;
    _meError = null;
    notifyListeners();
  }
}
