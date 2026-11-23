import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/frames_model.dart';
import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import '../../Repository/plan_repository.dart';
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

  bool _isInitialLoading = true;
  bool get isInitialLoading => _isInitialLoading;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> _initialize() async {
    try {
      final isBusiness = commonProvider.accountType?.toLowerCase() == 'business';

      // Personal -> frames only. Business -> frames + keywords + saved name,
      // all in parallel, each called exactly once.
      await Future.wait([
        loadFrames('static'),
        loadFrameCategories('static'),
        loadMyFrames(),
        if (isBusiness) loadKeyWords(),
        if (isBusiness) loadSavedBusinessName(),
      ]);
    } finally {
      _isInitialLoading = false;
      notifyListeners();
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

  Future<void> loadFrames(String type, {String? category}) async {
    _isFramesLoading = true;
    _framesError = null;
    notifyListeners();

    try {
      final result = await businessProfileRepository.frames(
        type,
        category: category,
      );

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

  // =========================================================
  // FRAME PURCHASE (creates a Razorpay order)
  // =========================================================

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  String? _purchaseError;
  String? get purchaseError => _purchaseError;

  /// POST frames/{frameUid}/purchase.
  /// Returns the order data
  /// {type, order_id, amount, currency, payment_uid, frame_uid} or null.
  Future<Map<String, dynamic>?> purchaseFrame(String frameUid) async {
    _isPurchasing = true;
    _purchaseError = null;
    notifyListeners();

    try {
      final result = await businessProfileRepository.purchaseFrame(frameUid);
      final dynamic body = result.data;

      if (body is Map) {
        final dynamic inner = body['data'];
        final order = Map<String, dynamic>.from(inner is Map ? inner : body);

        if ((order['order_id'] ?? '').toString().isNotEmpty) {
          return order;
        }
      }

      _purchaseError = 'Unable to create the order';
      return null;
    } catch (e, stackTrace) {
      _purchaseError = 'Failed to start payment';
      debugPrint('Frame purchase API error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// After Razorpay success: same verify API the plan payment uses
  /// (subscriptions/payment/verify).
  Future<bool> verifyFramePayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final result = await PlanRepository.instance.verify(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

      if (result.isSuccess) {
        // Reload so the purchased frame shows as unlocked.
        await loadFrames(
          _selectedFrameTab == 1 ? 'animated' : 'static',
          category: _selectedCategorySlug,
        );
        await loadMyFrames(forceRefresh: true);
        return true;
      }

      _purchaseError = result.error?.message ?? 'Payment verification failed';
      return false;
    } catch (e, stackTrace) {
      _purchaseError = 'Payment verification failed';
      debugPrint('Frame verify API error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  // =========================================================
  // MY BRAND FRAMES (frames/mine)
  // =========================================================

  List<dynamic> _mineFrames = [];
  List<dynamic> get mineFrames => _mineFrames;

  bool _isMineLoading = false;
  bool get isMineLoading => _isMineLoading;

  String? _mineError;
  String? get mineError => _mineError;

  /// What the bottom list shows for the selected tab.
  List<dynamic> get displayFrames =>
      _selectedFrameTab == 2 ? _mineFrames : selectedFrames;

  bool get isDisplayLoading =>
      _selectedFrameTab == 2 ? _isMineLoading : _isFramesLoading;

  String? get displayError =>
      _selectedFrameTab == 2 ? _mineError : _framesError;

  Future<void> loadMyFrames({bool forceRefresh = false}) async {
    if (_mineFrames.isNotEmpty && !forceRefresh) return;

    _isMineLoading = true;
    _mineError = null;
    notifyListeners();

    try {
      final result = await businessProfileRepository.framesMine();

      // MineFrames -> .data is the list.
      final dynamic body = result.data;
      final dynamic list = body?.data;

      if (list is List) {
        _mineFrames = list.map<dynamic>((e) {
          // Purchased rows may wrap the frame: {frame: {...}}.
          try {
            final dynamic inner = (e as dynamic).frame;
            return inner ?? e;
          } catch (_) {
            return e;
          }
        }).toList();
      } else {
        _mineFrames = [];
        _mineError = 'Unable to load your frames';
      }
    } catch (e, stackTrace) {
      _mineFrames = [];
      _mineError = 'Failed to load your frames';
      debugPrint('My frames API error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isMineLoading = false;
      notifyListeners();
    }
  }

  // Category filter (slug sent as `category` query param). null = all.
  String? _selectedCategorySlug;
  String? get selectedCategorySlug => _selectedCategorySlug;

  String get _currentFrameType => _selectedFrameTab == 1 ? 'animated' : 'static';

  void updateFrameTab(int index) {
    _selectedFrameTab = index;
    // A category filter belongs to one tab, so reset it and reload.
    _selectedCategorySlug = null;
    notifyListeners();

    // Tab 2 = My Brand Frames (purchased) - no category / type filter.
    if (index == 2) {
      loadMyFrames(forceRefresh: true);
      return;
    }

    loadFrames(_currentFrameType);
    loadFrameCategories(_currentFrameType);
  }

  /// Tap on a category chip. Pass null to show all frames again.
  Future<void> selectFrameCategory(String? slug) async {
    final value = (slug == null || slug.trim().isEmpty) ? null : slug.trim();
    _selectedCategorySlug = value;
    notifyListeners();

    await loadFrames(_currentFrameType, category: value);
  }

  // =========================================================
  // FRAME CATEGORIES (Branding / Promotional ...) - from API
  // =========================================================

  final Map<String, List<dynamic>> _frameCategories = {};

  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  String? _categoriesError;
  String? get categoriesError => _categoriesError;

  /// Categories of the currently selected tab (static / animated).
  List<dynamic> get selectedFrameCategories => _selectedFrameTab == 2
      ? const []
      : _frameCategories[_currentFrameType] ?? const [];

  Future<void> loadFrameCategories(
      String type, {
        bool forceRefresh = false,
      }) async {
    if ((_frameCategories[type]?.isNotEmpty ?? false) && !forceRefresh) return;

    _isCategoriesLoading = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final result = await businessProfileRepository.framesCategory(type);

      // FramesCategories -> .data is the category list.
      final dynamic body = result.data;
      final dynamic list = body?.data;

      if (list is List) {
        _frameCategories[type] = List<dynamic>.from(list);
      } else {
        _frameCategories[type] = [];
        _categoriesError = 'Unable to load $type categories';
      }
    } catch (e, stackTrace) {
      _frameCategories[type] = [];
      _categoriesError = 'Failed to load categories';
      debugPrint('Frame categories API error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
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

    if ((_keyWords.isNotEmpty || _isKeyWordsLoading) && !forceRefresh) {
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
  Map<String, dynamic>? _frameDetail;
  Map<String, dynamic>? get frameDetail => _frameDetail;

  String? _frameDetailUid;
  String? get frameDetailUid => _frameDetailUid;

  bool _isFrameDetailLoading = false;
  bool get isFrameDetailLoading => _isFrameDetailLoading;

  String? _frameDetailError;
  String? get frameDetailError => _frameDetailError;

  Future<void> loadFrameDetail(String frameUid) async {
    _frameDetailUid = frameUid;
    _frameDetail = null;
    _frameDetailError = null;
    _isFrameDetailLoading = true;
    notifyListeners();

    try {
      final result = await businessProfileRepository.frameDetail(frameUid);

      // User tapped another frame meanwhile -> ignore this response.
      if (_frameDetailUid != frameUid) return;

      final dynamic body = result.data;
      if (body is Map) {
        final dynamic inner = body['data'];
        _frameDetail = Map<String, dynamic>.from(inner is Map ? inner : body);
      } else {
        _frameDetailError = 'Unable to load frame';
      }
    } catch (e, stackTrace) {
      if (_frameDetailUid == frameUid) {
        _frameDetailError = 'Failed to load frame';
      }
      debugPrint('Frame detail API error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (_frameDetailUid == frameUid) {
        _isFrameDetailLoading = false;
        notifyListeners();
      }
    }
  }

  void clearFrameDetail() {
    _frameDetail = null;
    _frameDetailUid = null;
    _frameDetailError = null;
    _isFrameDetailLoading = false;
  }

// =========================================================
// STATIC FRAMES
// =========================================================

// =========================================================
// STATIC KEYWORDS
// =========================================================
}