import 'package:flutter/foundation.dart';
import 'package:mmb_app/Api%20Model/key_words_model.dart';

import '../../Api Model/me_api.dart';
import '../../Api Model/business_model.dart';
import '../../Api Model/un_read_count.dart';
import '../../Repository/get_me_repository.dart';
import '../../Repository/business_repository.dart';
import '../../Repository/notification_repository.dart';

class CommonProvider extends ChangeNotifier {
  CommonProvider._();

  static final CommonProvider instance = CommonProvider._();

  // =========================================================
  // ME
  // =========================================================

  Language? _me;

  Language? get me => _me;

  bool _isMeLoading = false;

  bool get isMeLoading => _isMeLoading;

  String? _meError;

  String? get meError => _meError;

  // =========================================================
  // ACCOUNT TYPE
  // =========================================================

  String? _accountType;

  String? get accountType => _accountType;

  bool get isPersonal => _accountType?.trim().toLowerCase() == 'personal';

  bool get isBusiness => _accountType?.trim().toLowerCase() == 'business';

  // =========================================================
  // BUSINESS
  // =========================================================

  BusinessApiModel? _business;

  BusinessApiModel? get business => _business;

  bool _isBusinessLoading = false;

  bool get isBusinessLoading => _isBusinessLoading;

  String? _businessError;

  String? get businessError => _businessError;

  // =========================================================
  // KEYWORDS
  // =========================================================

  List<KeyWordsData> _keyWords = [];

  List<KeyWordsData> get keyWords => _keyWords;

  bool _isKeyWordsLoading = false;

  bool get isKeyWordsLoading => _isKeyWordsLoading;

  String? _keyWordsError;

  String? get keyWordsError => _keyWordsError;

  UnReadCount? _unReadCount;

  UnReadCount? get unReadCount => _unReadCount;

  String get unreadCount {
    return _unReadCount?.data?.unreadCount ?? "0";
  }

  bool _isUnreadLoading = false;

  bool get isUnreadLoading => _isUnreadLoading;

  String? _unreadError;

  String? get unreadError => _unreadError;

  // =========================================================
  // LOAD ME
  // =========================================================

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

      // Update actual ME object
      _me = data;

      // Update account type
      _accountType = data.data.accountType?.trim().toLowerCase();

      debugPrint("================================");

      debugPrint("👤 ME LOADED");

      debugPrint("ACCOUNT TYPE : $_accountType");

      debugPrint("IS PERSONAL  : $isPersonal");

      debugPrint("IS BUSINESS  : $isBusiness");

      debugPrint("================================");

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

  // =========================================================
  // SET / UPDATE ME
  // =========================================================
  //
  // IMPORTANT:
  // PATCH /users/me success response வந்ததும்
  // இந்த method-ஐ call செய்ய வேண்டும்.
  //
  // இதுதான் பழைய "business" value-ஐ
  // புதிய "personal" value-ஆ replace செய்யும்.
  // =========================================================

  void setMe(Language data) {
    _me = data;

    _accountType = data.data.accountType?.trim().toLowerCase();

    debugPrint("================================");

    debugPrint("✅ COMMON PROVIDER ME UPDATED");

    debugPrint("ACCOUNT TYPE : $_accountType");

    debugPrint("IS PERSONAL  : $isPersonal");

    debugPrint("IS BUSINESS  : $isBusiness");

    debugPrint("================================");

    notifyListeners();
  }

  // =========================================================
  // FORCE REFRESH ME
  // =========================================================
  // =========================================================
  // LOAD UNREAD COUNT
  // =========================================================

  Future<bool> loadUnreadCount({bool forceRefresh = false}) async {
    if (_unReadCount != null && !forceRefresh) {
      return true;
    }

    _isUnreadLoading = true;
    _unreadError = null;

    notifyListeners();

    try {
      final result = await NotificationRepository.instance
          .notificationUnReadCount();

      final data = result.data;

      if (data == null) {
        _unreadError = "Unread count data not found";
        return false;
      }

      _unReadCount = data;

      debugPrint("================================");

      debugPrint("✅ UNREAD COUNT API SUCCESS");

      debugPrint("Unread Count : ${_unReadCount?.data?.unreadCount}");

      for (final category in _unReadCount?.data?.byCategory ?? []) {
        debugPrint("${category.name} : ${category.count}");
      }

      debugPrint("================================");

      return true;
    } catch (e, stackTrace) {
      _unreadError = e.toString();

      debugPrint("❌ Unread Count API failed: $e");

      debugPrint("$stackTrace");

      return false;
    } finally {
      _isUnreadLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshMe() async {
    return await loadMe(forceRefresh: true);
  }

  // =========================================================
  // LOAD BUSINESS
  // =========================================================

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

      debugPrint(
        "Industry : "
        "${_business?.businessCategory?.name}",
      );

      debugPrint(
        "Industry Slug : "
        "${_business?.businessCategory?.slug}",
      );

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

  // =========================================================
  // LOAD KEYWORDS
  // =========================================================

  Future<bool> loadKeyWords({bool forceRefresh = false}) async {
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

      _keyWords = data.data;

      debugPrint("================================");

      debugPrint("✅ KEYWORDS API SUCCESS");

      debugPrint(
        "Total Keywords : "
        "${_keyWords.length}",
      );

      for (final keyword in _keyWords) {
        debugPrint(
          "Keyword : ${keyword.name} | "
          "Slug : ${keyword.slug}",
        );
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

  // =========================================================
  // CLEAR ME
  // =========================================================

  void clearMe() {
    _me = null;

    _accountType = null;

    _meError = null;

    notifyListeners();
  }

  // =========================================================
  // CLEAR BUSINESS
  // =========================================================

  void clearBusiness() {
    _business = null;

    _businessError = null;

    notifyListeners();
  }

  // =========================================================
  // CLEAR ALL
  // =========================================================

  void clearAll() {
    _me = null;

    _accountType = null;

    _meError = null;

    _business = null;

    _businessError = null;

    _keyWords = [];

    _keyWordsError = null;

    notifyListeners();
  }
}
