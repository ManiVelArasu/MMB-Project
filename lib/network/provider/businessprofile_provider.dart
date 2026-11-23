import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/frames_model.dart';
import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import '../../Repository/business_repository.dart';
import '../../Repository/get_me_repository.dart';
import '../../Repository/image_upload_repository.dart';
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
  // LOGO / PROFILE PHOTO  ->  presign -> upload -> confirm
  //                           -> PUT /businesses/me (business)
  //                           -> update personal detail (personal)
  // =========================================================

  final ImagePicker _picker = ImagePicker();

  File? _selectedLogoFile;
  File? get selectedLogoFile => _selectedLogoFile;

  String? _logoS3Key;
  String? get logoS3Key => _logoS3Key;

  String? _profileS3Key;
  String? get profileS3Key => _profileS3Key;

  // true only when an image was uploaded successfully and not yet
  // sent to the update API.
  bool _isNewLogoSelected = false;
  bool _isNewProfileSelected = false;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  String? _updateError;
  String? get updateError => _updateError;

  // Latest values saved with the update API. The frame preview
  // (phone / website / logo slots) reads these.
  String _savedPhone = '';
  String _savedWebsite = '';
  String get savedPhone => _savedPhone;
  String get savedWebsite => _savedWebsite;

  String? get _accountType =>
      commonProvider.me?.data.accountType?.toString().trim().toLowerCase() ??
          commonProvider.accountType?.toString().trim().toLowerCase();

  /// Gallery / camera picker. Returns the picked file (or null).
  Future<File?> pickLogo({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return null;

      _selectedLogoFile = File(image.path);
      notifyListeners();

      return _selectedLogoFile;
    } catch (e) {
      debugPrint('pickLogo error: $e');
      return null;
    }
  }

  /// Use this if the image comes from somewhere else
  /// (crop screen, bg-remove sheet, library ...).
  void setLogoFile(File file) {
    _selectedLogoFile = file;
    notifyListeners();
  }

  /// Handles every confirm response format:
  /// {key}, {uploads:[{key}]}, {keys:[..]}, {results:[{key}]},
  /// {files:[{key}]}, {data:{...}}
  String? _extractS3Key(dynamic data) {
    if (data is! Map) return null;

    final direct = data['key']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    for (final listKey in const ['uploads', 'keys', 'results', 'files']) {
      final list = data[listKey];

      if (list is List && list.isNotEmpty) {
        final first = list.first;

        if (first is Map) {
          final v = first['key']?.toString().trim();
          if (v != null && v.isNotEmpty) return v;
        } else if (first != null && first.toString().trim().isNotEmpty) {
          return first.toString().trim();
        }
      }
    }

    if (data['data'] is Map) return _extractS3Key(data['data']);

    return null;
  }

  /// STEP 1: presign -> S3 upload -> confirm  (only uploads, no update API)
  Future<bool> uploadLogo([File? file]) async {
    final imageFile = file ?? _selectedLogoFile;

    if (imageFile == null || !await imageFile.exists()) {
      _updateError = 'Please select an image';
      notifyListeners();
      return false;
    }

    final accountType = _accountType;

    final String slot;
    if (accountType == 'personal') {
      slot = 'profile_photo';
    } else if (accountType == 'business') {
      slot = 'business_logo';
    } else {
      _updateError = 'Invalid account type: $accountType';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _updateError = null;
    notifyListeners();

    try {
      final filename = imageFile.path.split(Platform.pathSeparator).last;

      debugPrint('======================================');
      debugPrint('🚀 MEDIA UPLOAD  | $accountType | $slot | $filename');
      debugPrint('======================================');

      final uploadResult = await MediaUploadRepository.instance
          .uploadImageAndConfirm(
        imageFile: imageFile,
        filename: filename,
        width: 1080,
        height: 1080,
        slot: slot,
      );

      bool success = false;

      await uploadResult.when(
        success: (data) async {
          final key = _extractS3Key(data);

          if (key == null || key.isEmpty) {
            _updateError = 'Image uploaded but S3 key not found';
            debugPrint('❌ Upload response without key: $data');
            return;
          }

          final prefs = await SharedPreferences.getInstance();

          if (accountType == 'personal') {
            _profileS3Key = key;
            _logoS3Key = null;
            _isNewProfileSelected = true;
            _isNewLogoSelected = false;

            await prefs.remove('logo_s3_key');
            await prefs.setString('profile_s3_key', key);
            await prefs.setString('profile_photo_s3_key', key);
          } else {
            _logoS3Key = key;
            _profileS3Key = null;
            _isNewLogoSelected = true;
            _isNewProfileSelected = false;

            await prefs.remove('profile_s3_key');
            await prefs.remove('profile_photo_s3_key');
            await prefs.setString('logo_s3_key', key);
          }

          _selectedLogoFile = imageFile;
          await prefs.setString('saved_business_image_path', imageFile.path);

          debugPrint('✅ UPLOAD SUCCESS  S3 KEY: $key');
          success = true;
        },
        failure: (error) {
          _updateError = error.message;
          debugPrint('❌ Image upload failed: ${error.message}');
        },
      );

      return success;
    } catch (e, stackTrace) {
      _updateError = e.toString();
      debugPrint('❌ uploadLogo error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Website is always sent as https://...
  ///  "mysite.com"          -> "https://mysite.com"
  ///  "www.mysite.com"      -> "https://www.mysite.com"
  ///  "http://mysite.com"   -> "https://mysite.com"
  ///  "https://mysite.com"  -> "https://mysite.com"
  ///  "https:\\mysite.com"   -> "https://mysite.com"
  ///  ""                    -> ""  (nothing to send)
  String normalizeWebsite(String raw) {
    var w = raw.trim();
    if (w.isEmpty) return '';

    // remove any existing scheme (even a mistyped one) and leading slashes
    w = w.replaceFirst(RegExp(r'^[a-zA-Z]+:[\\/]+'), '');
    w = w.replaceFirst(RegExp(r'^[\\/]+'), '').trim();

    if (w.isEmpty) return '';

    return 'https://$w';
  }

  String _formatPhone(String raw) {
    final p = raw.trim().replaceAll(' ', '');

    if (p.isEmpty) return p;
    if (p.startsWith('+')) return p;

    return '+91$p';
  }

  Future<String?> _resolveBusinessUid() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString('business_uid');
    if (saved != null && saved.isNotEmpty) return saved;

    try {
      final dynamic business = commonProvider.business;
      final uid = business?.uid?.toString();
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}

    return null;
  }

  /// STEP 2 (business): PUT /businesses/me
  /// body: logo_s3_key (only if new), name, phone, website
  Future<bool> updateBusiness({
    required String name,
    required String phone,
    String? website,
    String? email,
  }) async {
    _isUpdatingProfile = true;
    _updateError = null;
    notifyListeners();

    try {
      final businessUid = await _resolveBusinessUid() ?? '';

      final String? finalLogoKey =
      (_isNewLogoSelected && (_logoS3Key?.trim().isNotEmpty ?? false))
          ? _logoS3Key!.trim()
          : null;

      final cleanWebsite = normalizeWebsite(website ?? '');
      final cleanEmail = (email ?? '').trim();

      debugPrint('======================================');
      debugPrint('🚀 PUT /businesses/me');
      debugPrint('Name     : ${name.trim()}');
      debugPrint('Phone    : ${_formatPhone(phone)}');
      debugPrint('Website  : $cleanWebsite');
      debugPrint('Logo key : $finalLogoKey');
      debugPrint('======================================');

      final result = await BusinessProfileRepository.instance.updateBusinessFramesDetails(
        businessUid: businessUid,
        name: name.trim(),
        phone: _formatPhone(phone),
        website: cleanWebsite.isEmpty ? null : cleanWebsite,
        email: cleanEmail.isEmpty ? null : cleanEmail,
        logo_s3_key: finalLogoKey,
      );

      bool ok = false;

      await result.when(
        success: (data) async {
          final prefs = await SharedPreferences.getInstance();

          if (finalLogoKey != null) {
            await prefs.setString('logo_s3_key', finalLogoKey);
          }

          await prefs.setString('saved_business_name', name.trim());
          await prefs.setString('saved_business_phone', _formatPhone(phone));
          await prefs.setString('saved_business_website', cleanWebsite);

          _isNewLogoSelected = false;
          _businessName = name.trim();
          _savedPhone = _formatPhone(phone);
          _savedWebsite = cleanWebsite;

          debugPrint('✅ BUSINESS UPDATE SUCCESS');
          ok = true;
        },
        failure: (error) {
          _updateError = error.message;
          debugPrint('❌ Business update failed: ${error.message}');
        },
      );

      if (ok) {
        // Reload latest business data so the profile screen refreshes.
        await commonProvider.loadBusiness(forceRefresh: true);
      }

      return ok;
    } catch (e, stackTrace) {
      _updateError = e.toString();
      debugPrint('❌ updateBusiness error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  /// STEP 2 (personal): update me
  Future<bool> updatePersonal({
    required String name,
    String email = '',
  }) async {
    _isUpdatingProfile = true;
    _updateError = null;
    notifyListeners();

    try {
      final String? finalProfileKey =
      (_isNewProfileSelected &&
          (_profileS3Key?.trim().isNotEmpty ?? false))
          ? _profileS3Key!.trim()
          : null;

      final result = await GetMeRepository.instance.updatePersonalDetail(
        name.trim(),
        email.trim(),
        finalProfileKey,
      );

      bool ok = false;

      await result.when(
        success: (data) async {
          final prefs = await SharedPreferences.getInstance();

          if (finalProfileKey != null) {
            await prefs.setString('profile_s3_key', finalProfileKey);
            await prefs.setString('profile_photo_s3_key', finalProfileKey);
            await prefs.remove('logo_s3_key');
          }

          _isNewProfileSelected = false;
          ok = true;
        },
        failure: (error) {
          _updateError = error.message;
        },
      );

      if (ok) {
        await commonProvider.loadMe(forceRefresh: true);
      }

      return ok;
    } catch (e, stackTrace) {
      _updateError = e.toString();
      debugPrint('❌ updatePersonal error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  /// ONE CALL FOR THE SAVE BUTTON
  ///
  /// 1. image select pannirundha -> presign + upload + confirm
  /// 2. upload success aana -> business update API (PUT /businesses/me)
  ///    (personal account -> personal update API)
  ///
  /// Returns true only if everything succeeded.
  Future<bool> saveProfile({
    required String name,
    required String phone,
    String? website,
    String? email,
    File? newImage,
  }) async {
    // ---- 1. UPLOAD (only when the user picked a new image) ----
    if (newImage != null) {
      final uploaded = await uploadLogo(newImage);

      // upload fail aana update API call pannadhu
      if (!uploaded) return false;
    }

    // ---- 2. UPDATE ----
    if (_accountType == 'personal') {
      return updatePersonal(name: name, email: email ?? '');
    }

    return updateBusiness(
      name: name,
      phone: phone,
      website: website,
      email: email,
    );
  }

  void clearUpdateError() {
    _updateError = null;
    notifyListeners();
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
        final success = await commonProvider.loadMe(forceRefresh: true);

        debugPrint("👤 PERSONAL GetMe refresh: $success");

        return success;
      }

      if (accountType == 'business') {
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
    // PERSONAL → DO NOT CALL API
    if (commonProvider.accountType?.toLowerCase() == 'personal') {
      debugPrint("👤 PERSONAL ACCOUNT → loadKeyWords SKIPPED");

      return false;
    }

    // BUSINESS ONLY
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

      if (categorySlug.isEmpty) {
        _keyWordsError = "Business category slug not found";

        debugPrint("⚠️ Category slug empty → Keywords API SKIPPED");

        return false;
      }

      debugPrint("🏢 BUSINESS → Calling Keywords API: $categorySlug");

      final result = await businessProfileRepository.industryKeyWords(
        categorySlug,
      );

      final KeyWordsModel? data = result.data;

      if (data == null) {
        _keyWordsError = "Keywords data not found";

        return false;
      }

      _keyWords = data.data;

      debugPrint("✅ KEYWORDS API SUCCESS | Total: ${_keyWords.length}");

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
    _savedPhone = prefs.getString('saved_business_phone') ?? "";
    _savedWebsite = prefs.getString('saved_business_website') ?? "";

    // logo key of the current account type (needed by the frame preview)
    final type = commonProvider.accountType?.toLowerCase();
    if (type == 'business') {
      _logoS3Key ??= prefs.getString('logo_s3_key');
    } else if (type == 'personal') {
      _profileS3Key ??= prefs.getString('profile_s3_key');
    }

    notifyListeners();
  }

  void setBusinessName(String name) {
    _businessName = name;

    notifyListeners();
  }

  // =========================================================
  // FRAME DETAIL
  // =========================================================

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

      // result.data is the FramesDetailScreen model (not a Map), so convert
      // it back to a Map. `content` (Fabric JSON string) is inside it.
      final dynamic body = result.data;
      Map<String, dynamic>? detail;

      if (body is Map) {
        final dynamic inner = body['data'];
        detail = Map<String, dynamic>.from(inner is Map ? inner : body);
      } else if (body != null) {
        try {
          final dynamic json = (body as dynamic).data?.toJson();
          if (json is Map) detail = Map<String, dynamic>.from(json);
        } catch (e) {
          debugPrint('Frame detail convert error: $e');
        }
      }

      if (detail != null) {
        _frameDetail = detail;
        debugPrint(
          'FRAME DETAIL loaded | uid=$frameUid | '
              'content length=${detail['content']?.toString().length ?? 0}',
        );
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
}