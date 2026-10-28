import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/frames_model.dart';
import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import 'common_provider.dart';

class BusinessProfileProvider extends ChangeNotifier {
  BusinessProfileProvider() {
    _initialize();
  }

  final CommonProvider commonProvider = CommonProvider.instance;

  final BusinessProfileRepository businessProfileRepository =
      BusinessProfileRepository.instance;

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> _initialize() async {
    await loadSavedBusinessName();

    // Load default Static Frames
    await loadFrames('static');

    if (commonProvider.accountType?.toLowerCase() == 'personal') {
      return;
    }

    if (commonProvider.accountType?.toLowerCase() == 'business') {
      await loadKeyWords();
    }

    // Personal account என்றால் keywords API call வேண்டாம்
    if (commonProvider.accountType?.toLowerCase() == 'personal') {
      debugPrint("👤 PERSONAL ACCOUNT → Keywords API SKIPPED");

      return;
    }

    // Business account மட்டும்
    if (commonProvider.accountType?.toLowerCase() == 'business') {
      debugPrint("🏢 BUSINESS ACCOUNT → Loading Keywords");

      await loadKeyWords();
    }
  }

  // =========================================================
  // REFRESH PROFILE AFTER EDIT
  // =========================================================
  //
  // EditProfileScreen returns true after a successful save.
  // The previous profile screen calls this method so the
  // latest profile/business data is loaded before the user
  // continues using this screen.
  // =========================================================
  List<FramesList> _staticFrames = [];
  List<FramesList> _animatedFrames = [];

  bool _isFramesLoading = false;
  String? _framesError;

  bool get isFramesLoading => _isFramesLoading;
  String? get framesError => _framesError;

  List<FramesList> get staticFrames => _staticFrames;
  List<FramesList> get animatedFrames => _animatedFrames;

  List<FramesList> get selectedFrames =>
      _selectedFrameTab == 0 ? _staticFrames : _animatedFrames;

  Future<void> loadFrames(String type) async {
    _isFramesLoading = true;
    _framesError = null;
    notifyListeners();

    try {
      final result = await businessProfileRepository.frames(type);

      // ApiResult-ல் data என்பது FramesData object என்று கருதப்பட்டுள்ளது.
      final framesData = result.data;

      if (framesData != null && framesData.success == true) {
        if (type == 'static') {
          _staticFrames = framesData.data;
        } else if (type == 'animated') {
          _animatedFrames = framesData.data;
        }
      } else {
        _framesError = 'Unable to load $type frames';
      }
    } catch (e, stackTrace) {
      _framesError = 'Failed to load frames';
      debugPrint('Frames API error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isFramesLoading = false;
      notifyListeners();
    }
  }
  void updateFrameTab(int index) {
    _selectedFrameTab = index;
    notifyListeners();

    if (index == 0) {
      if (_staticFrames.isEmpty) {
        loadFrames('static');
      }
    } else {
      if (_animatedFrames.isEmpty) {
        loadFrames('animated');
      }
    }
  }
  Future<bool> refreshProfileAfterEdit() async {
    try {
      final accountType = commonProvider.me?.data.accountType
          ?.toString()
          .trim()
          .toLowerCase();

      debugPrint("================================");
      debugPrint("🔄 PROFILE REFRESH AFTER EDIT");
      debugPrint("Account Type: $accountType");
      debugPrint("================================");

      if (accountType == 'personal') {
        debugPrint("👤 PERSONAL → Calling GetMe API");

        final success = await commonProvider.loadMe(forceRefresh: true);

        debugPrint("👤 PERSONAL GetMe refresh: $success");

        return success;
      }

      if (accountType == 'business') {
        debugPrint("🏢 BUSINESS → Calling Business API");

        final success = await commonProvider.loadBusiness(forceRefresh: true);

        debugPrint("🏢 BUSINESS refresh: $success");

        // Keep the provider's displayed business name in sync.
        await loadSavedBusinessName();

        return success;
      }

      debugPrint("⚠️ Unknown account type → Profile API skipped");

      return false;
    } catch (e, stackTrace) {
      debugPrint("❌ Profile refresh failed: $e");
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // =========================================================
  // MOBILE NUMBER
  // =========================================================

  String _mobileNumber = "+91 9876543210";

  String get mobileNumber => _mobileNumber;

  void updateMobileNumber(String newNumber) {
    _mobileNumber = newNumber;
    notifyListeners();
  }

  // =========================================================
  // KEYWORDS
  // =========================================================

  List<KeyWordsData> _keyWords = [];

  List<KeyWordsData> get keyWords => _keyWords;

  bool _isKeyWordsLoading = false;

  bool get isKeyWordsLoading => _isKeyWordsLoading;

  String? _keyWordsError;

  String? get keyWordsError => _keyWordsError;

  Future<bool> loadKeyWords({bool forceRefresh = false}) async {
    // =======================================================
    // PERSONAL → DO NOT CALL API
    // =======================================================

    if (commonProvider.accountType?.toLowerCase() == 'personal') {
      debugPrint("👤 PERSONAL ACCOUNT → loadKeyWords SKIPPED");

      return false;
    }

    // =======================================================
    // BUSINESS ONLY
    // =======================================================

    if (commonProvider.accountType?.toLowerCase() != 'business') {
      debugPrint("⚠️ Unknown account type → Keywords API SKIPPED");

      return false;
    }

    if (_keyWords.isNotEmpty && !forceRefresh) {
      return true;
    }

    _isKeyWordsLoading = true;
    _keyWordsError = null;

    notifyListeners();

    try {
      final categorySlug =
          commonProvider.business?.businessCategory?.parent?.slug ?? '';

      // Category slug இல்லையென்றால் API call வேண்டாம்
      if (categorySlug.isEmpty) {
        _keyWordsError = "Business category slug not found";

        debugPrint("⚠️ Category slug empty → Keywords API SKIPPED");

        return false;
      }

      debugPrint("🏢 BUSINESS → Calling Keywords API");

      debugPrint("Category Slug: $categorySlug");

      final result = await businessProfileRepository.industryKeyWords(
        categorySlug,
      );

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
  // BANNER
  // =========================================================

  bool _isSolidBanner = true;

  bool get isSolidBanner => _isSolidBanner;

  void toggleBannerStyle(bool isSolid) {
    _isSolidBanner = isSolid;

    notifyListeners();
  }

  // =========================================================
  // FRAME TAB
  // =========================================================

  int _selectedFrameTab = 0;

  int get selectedFrameTab => _selectedFrameTab;


  // =========================================================
  // BUSINESS NAME
  // =========================================================

  String _businessName = "";

  String get businessName => _businessName;

  Future<void> loadSavedBusinessName() async {
    final prefs = await SharedPreferences.getInstance();

    _businessName = prefs.getString('saved_business_name') ?? "";

    notifyListeners();
  }

  void setBusinessName(String name) {
    _businessName = name;

    notifyListeners();
  }

  // =========================================================
  // STATIC FRAMES
  // =========================================================

  // =========================================================
  // STATIC KEYWORDS
  // =========================================================
}
