import 'package:flutter/foundation.dart';
import 'package:mmb_app/Api%20Model/key_words_model.dart';

import '../../Api Model/me_api.dart';
import '../../Api Model/business_model.dart';
import '../../Repository/get_me_repository.dart';
import '../../Repository/business_repository.dart';

class CommonProvider extends ChangeNotifier {
  CommonProvider._();

  static final CommonProvider instance = CommonProvider._();

  // =========================
  // ME
  // =========================

  Language? _me;
  Language? get me => _me;

  bool _isMeLoading = false;
  bool get isMeLoading => _isMeLoading;

  String? _meError;
  String? get meError => _meError;

  BusinessApiModel? _business;
  BusinessApiModel? get business => _business;

  bool _isBusinessLoading = false;
  bool get isBusinessLoading => _isBusinessLoading;

  String? _businessError;
  String? get businessError => _businessError;

  List<KeyWordsData> _keyWords = [];

  List<KeyWordsData> get keyWords => _keyWords;

  bool _isKeyWordsLoading = false;
  bool get isKeyWordsLoading => _isKeyWordsLoading;

  String? _keyWordsError;
  String? get keyWordsError => _keyWordsError;

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

  Future<bool> loadBusiness({bool forceRefresh = false}) async {
    if (_business != null && !forceRefresh) {
      return true;
    }

    _isBusinessLoading = true;
    _businessError = null;
    notifyListeners();

    try {
      final result = await GetMeRepository.instance.businessApi();

      final data = result.data;

      if (data == null || data.data.isEmpty) {
        _businessError = "Business data not found";
        return false;
      }
      _business = data.data.first;

      debugPrint("================================");
      debugPrint("✅ BUSINESS PROVIDER LOADED");
      debugPrint("Business UID : ${_business?.uid}");
      debugPrint("Business Name : ${_business?.name}");
      debugPrint("Logo S3 Key : ${_business?.logoS3Key}");
      debugPrint("Industry : ${_business?.businessCategory?.name}");
      debugPrint("Industry Slug : ${_business?.businessCategory?.slug}");
      debugPrint("================================");

      return true;
    } catch (e, stackTrace) {
      _businessError = e.toString();

      debugPrint("❌ Business API failed: $e");
      debugPrint("$stackTrace");

      return false;
    } finally {
      _isBusinessLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadKeyWords({bool forceRefresh = false}) async {
    // Already loaded
    if (_keyWords.isNotEmpty && !forceRefresh) {
      return true;
    }

    _isKeyWordsLoading = true;
    _keyWordsError = null;
    notifyListeners();

    try {
      final result = await GetMeRepository.instance.keyWords();

      final KeyWordsModel? data = result.data;

      if (data == null) {
        _keyWordsError = "Keywords data not found";
        return false;
      }

      // API model -> List<KeyWordsData>
      _keyWords = data.data;

      debugPrint("================================");
      debugPrint("✅ KEYWORDS API SUCCESS");
      debugPrint("Total Keywords : ${_keyWords.length}");

      for (final keyword in _keyWords) {
        debugPrint("Keyword : ${keyword.name} | Slug : ${keyword.slug}");
      }

      debugPrint("================================");

      return true;
    } catch (e, stackTrace) {
      _keyWordsError = e.toString();

      debugPrint("❌ Keywords API failed: $e");
      debugPrint("$stackTrace");

      return false;
    } finally {
      _isKeyWordsLoading = false;
      notifyListeners();
    }
  }

  void clearMe() {
    _me = null;
    _meError = null;

    notifyListeners();
  }

  void clearBusiness() {
    _business = null;
    _businessError = null;

    notifyListeners();
  }

  void clearAll() {
    _me = null;
    _meError = null;

    _business = null;
    _businessError = null;

    notifyListeners();
  }
}
