import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmb_app/network/provider/common_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Api Model/me_api.dart';
import '../../Repository/business_repository.dart';
import '../../Repository/get_me_repository.dart';
import '../../Repository/image_upload_repository.dart';
import '../../ui/industry/edit_photo_screen.dart';
import '../../ui/industry/widgets/bg_remove_sheet.dart';
import '../../ui/industry/widgets/crop_sheet.dart';

class BusinessProvider extends ChangeNotifier {
  BusinessProvider() {
    requestPermissionIfNeeded();
    loadSavedData();
    loadSavedBusinessImage();
  }

  String? _savedImagePath;
  String? get savedImagePath => _savedImagePath;

  int _currentIndex = 0;
  String selectedCategory = "";
  String query = "";

  String _businessName = "";
  String _email = "";
  String _mobileNumber = "";

  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  File? _originalImage;

  String _selectedTool = "";
  String _selectedAspect = "Original";

  final editorKey = GlobalKey<ExtendedImageEditorState>();

  bool _hasChanges = false;
  bool _isApplied = false;

  static const platform = MethodChannel(
    'com.mobile.mmb.project_mmb/background_removal',
  );

  bool _isImageSelected = false;
  Uint8List? _processedImageBytes;
  bool _isProcessingBackground = false;

  double _liveRotationAngle = 0.0;
  double _liveScaleValue = 1.0;

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------

  int get currentIndex => _currentIndex;

  File? get selectedImage => _selectedImage;

  File? get originalImage => _originalImage;

  String get businessName => _businessName;

  String get email => _email;

  String get mobileNumber => _mobileNumber;

  String get selectedTool => _selectedTool;

  String get selectedAspect => _selectedAspect;

  double get rotationAngle => _liveRotationAngle;

  double get scaleValue => _liveScaleValue;

  bool get isApplied => _isApplied;

  bool get hasChanges => _hasChanges;

  Uint8List? get processedImageBytes => _processedImageBytes;

  bool get isProcessingBackground => _isProcessingBackground;

  bool get isImageSelected => _isImageSelected;

  String? _nameError;
  String? _emailError;
  String? _mobileError;
  String? _imageError;

  String? get nameError => _nameError;
  String? get emailError => _emailError;
  String? get mobileError => _mobileError;
  String? get imageError => _imageError;

  final mobileController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  String? _businessUid;
  String? get businessUid => _businessUid;

  String? _logoS3Key;
  String? get logoS3Key => _logoS3Key;
  String? _profileS3Key;

  String? get profileS3Key => _profileS3Key;

  final CommonProvider provider = CommonProvider.instance;

  // ------------------------------------------------------------
  // ACCOUNT TYPE
  // ------------------------------------------------------------

  bool _isAccountTypeUpdating = false;

  bool get isAccountTypeUpdating => _isAccountTypeUpdating;

  Future<bool> updateAccountType() async {
    _isAccountTypeUpdating = true;
    notifyListeners();

    try {
      final selectedTitle = accountTypeList[currentIndex].title;

      final accountType = selectedTitle == "Personal Use"
          ? "personal"
          : "business";

      final result = await GetMeRepository.instance.updateMe(accountType);

      return await result.when(
        success: (data) async {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('selected_account_type', selectedTitle);

          await prefs.setBool('is_personal_use', accountType == "personal");

          try {
            if (data is Map<String, dynamic>) {
              final meData = data['data'];

              if (meData is Map<String, dynamic>) {
                final language = Language.fromJson({
                  "success": true,
                  "data": meData,
                });

                setGetMeData(language);

                debugPrint(
                  "✅ ACCOUNT TYPE UPDATED = "
                      "${language.data.accountType}",
                );
              }
            }
          } catch (e) {
            debugPrint("⚠️ Failed to update local me after account type: $e");
          }

          _isAccountTypeUpdating = false;
          notifyListeners();

          return true;
        },
        failure: (error) {
          _errorMessage = error.message;

          _isAccountTypeUpdating = false;
          notifyListeners();

          return false;
        },
      );
    } catch (e) {
      debugPrint("❌ updateAccountType error: $e");

      _errorMessage = e.toString();

      _isAccountTypeUpdating = false;
      notifyListeners();

      return false;
    }
  }

  // ------------------------------------------------------------
  // BUSINESS UID
  // ------------------------------------------------------------

  void setBusinessUid(String uid) {
    _businessUid = uid;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // CLEAR BUSINESS DATA
  // ------------------------------------------------------------

  Future<void> clearBusinessDataForNewLogin() async {
    _businessName = "";
    _email = "";
    _mobileNumber = "";

    _selectedImage = null;
    _originalImage = null;

    _savedImagePath = null;
    _isImageSelected = false;
    _processedImageBytes = null;

    nameController.clear();
    emailController.clear();
    mobileController.clear();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('is_business_completed');
    await prefs.remove('saved_business_name');
    await prefs.remove('saved_email');
    await prefs.remove('saved_mobile_number');
    await prefs.remove('saved_business_image_path');
    await prefs.remove('profile_s3_key');
    await prefs.remove('profile_photo_s3_key');
    await prefs.remove('logo_s3_key');

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOAD SAVED IMAGE
  // ------------------------------------------------------------

  Future<void> loadSavedBusinessImage() async {
    final prefs = await SharedPreferences.getInstance();

    final String? imagePath = prefs.getString('saved_business_image_path');

    // Restore the S3 key that belongs to the current account type.
    final accountType = provider.me?.data.accountType?.trim().toLowerCase();

    if (accountType == 'personal') {
      _profileS3Key = prefs.getString('profile_s3_key');
      _logoS3Key = null;
    } else if (accountType == 'business') {
      _logoS3Key = prefs.getString('logo_s3_key');
      _profileS3Key = null;
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      _savedImagePath = imagePath;
      _originalImage = File(imagePath);

      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPLOAD IMAGE
  // ------------------------------------------------------------

  Future<bool> uploadCurrentImage() async {
    final imageFile = _selectedImage;

    if (imageFile == null || !imageFile.existsSync()) {
      debugPrint("❌ No image available for upload");
      return false;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ============================================================
      // 1. FIRST GET ACCOUNT TYPE
      // ============================================================

      final String? accountType = provider.me?.data.accountType
          ?.trim()
          .toLowerCase();

      debugPrint("======================================");
      debugPrint("ACCOUNT TYPE = $accountType");
      debugPrint("======================================");

      if (accountType == null || accountType.isEmpty) {
        _errorMessage = "Account type not found";
        _isUploading = false;
        notifyListeners();
        return false;
      }

      // ============================================================
      // 2. DETERMINE UPLOAD SLOT FROM ACCOUNT TYPE
      // ============================================================

      late final String uploadSlot;

      switch (accountType) {
        case 'personal':
        // Personal -> users/{uid}/profile/...
          uploadSlot = 'profile_photo';
          break;

        case 'business':
        // Business -> users/{uid}/logo/...
          uploadSlot = 'business_logo';
          break;

        default:
          debugPrint("❌ Invalid account type: $accountType");

          _errorMessage = "Invalid account type: $accountType";
          _isUploading = false;
          notifyListeners();
          return false;
      }

      // ============================================================
      // 3. DEBUG
      // ============================================================

      final filename = imageFile.path.split(Platform.pathSeparator).last;

      debugPrint("======================================");
      debugPrint("🚀 MEDIA UPLOAD");
      debugPrint("Account Type : $accountType");
      debugPrint("Slot         : $uploadSlot");
      debugPrint("Filename     : $filename");
      debugPrint("======================================");

      // ============================================================
      // 4. UPLOAD + CONFIRM
      // ============================================================

      final uploadResult = await MediaUploadRepository.instance
          .uploadImageAndConfirm(
        imageFile: imageFile,
        filename: filename,
        width: 1080,
        height: 1080,
        slot: uploadSlot,
      );

      bool success = false;

      await uploadResult.when(
        success: (data) async {
          String? key;

          // --------------------------------------------------------
          // Response can be:
          // {key: "..."}
          // OR
          // {keys: ["..."]}
          // OR
          // {results: [{key: "..."}]}
          // --------------------------------------------------------

          // Supports all confirm response formats:
          // {key: "..."}
          // {keys: ["..."]}
          // {results: [{key: "..."}]}
          // {data: {key/keys/results: ...}}
          key = data['key']?.toString();

          if ((key == null || key.trim().isEmpty) &&
              data['keys'] is List &&
              (data['keys'] as List).isNotEmpty) {
            key = (data['keys'] as List).first?.toString();
          }

          if ((key == null || key.trim().isEmpty) &&
              data['results'] is List &&
              (data['results'] as List).isNotEmpty) {
            final result = (data['results'] as List).first;

            if (result is Map) {
              key = result['key']?.toString();
            }
          }

          // Some repository implementations return the complete API
          // response, so the actual upload data can be nested under data.
          if ((key == null || key.trim().isEmpty) &&
              data['data'] is Map) {
            final nested = data['data'] as Map;

            key = nested['key']?.toString();

            if ((key == null || key.trim().isEmpty) &&
                nested['keys'] is List &&
                (nested['keys'] as List).isNotEmpty) {
              key = (nested['keys'] as List).first?.toString();
            }

            if ((key == null || key.trim().isEmpty) &&
                nested['results'] is List &&
                (nested['results'] as List).isNotEmpty) {
              final result = (nested['results'] as List).first;

              if (result is Map) {
                key = result['key']?.toString();
              }
            }
          }

          // --------------------------------------------------------
          // Validate S3 key
          // --------------------------------------------------------

          if (key == null || key.trim().isEmpty) {
            _errorMessage = "Image uploaded but S3 key not found";

            debugPrint("❌ Upload response did not contain S3 key: $data");

            return;
          }

          key = key.trim();

          // --------------------------------------------------------
          // Save uploaded key
          // --------------------------------------------------------

          final prefs = await SharedPreferences.getInstance();

          // ========================================================
          // PERSONAL
          // ========================================================

          if (accountType == 'personal') {
            _profileS3Key = key;

            // Remove old business key
            await prefs.remove('logo_s3_key');

            // Save personal key
            await prefs.setString('profile_s3_key', key);
            await prefs.setString('profile_photo_s3_key', key);

            debugPrint("👤 PERSONAL → profile_photo_s3_key");
            debugPrint("📁 S3 KEY → $key");
          }
          // ========================================================
          // BUSINESS
          // ========================================================
          else if (accountType == 'business') {
            _logoS3Key = key;

            // Remove old personal key
            await prefs.remove('profile_photo_s3_key');

            // Save business key
            await prefs.setString('logo_s3_key', key);

            debugPrint("🏢 BUSINESS → logo_s3_key");
            debugPrint("📁 S3 KEY → $key");
          }

          // ========================================================
          // SUCCESS
          // ========================================================

          success = true;

          debugPrint("======================================");
          debugPrint("✅ IMAGE UPLOAD SUCCESS");
          debugPrint("Account Type : $accountType");
          debugPrint("Slot         : $uploadSlot");
          debugPrint("S3 Key       : $key");
          debugPrint("======================================");
        },

        failure: (error) {
          success = false;
          _errorMessage = error.message;

          debugPrint("❌ Image upload failed: ${error.message}");
        },
      );

      _isUploading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isUploading = false;
      _errorMessage = e.toString();

      debugPrint("❌ uploadCurrentImage error: $e");

      notifyListeners();

      return false;
    }
  }

  // ------------------------------------------------------------
  // SAVE BUSINESS DETAILS
  // ------------------------------------------------------------

  Future<bool> uploadAndSaveBusinessDetails(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('is_business_completed', true);

      await prefs.setString('saved_business_name', _businessName);

      await prefs.setString('saved_email', _email);

      await prefs.setString('saved_mobile_number', _mobileNumber);

      if (_savedImagePath != null && _savedImagePath!.isNotEmpty) {
        await prefs.setString('saved_business_image_path', _savedImagePath!);
      }

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("❌ Exception in uploadAndSaveBusinessDetails: $e");

      return false;
    }
  }

  // ------------------------------------------------------------
  // CROP SAVED
  // ------------------------------------------------------------

  Future<bool> onCropSaved(BuildContext context) async {
    final uploaded = await uploadCurrentImage();

    if (!uploaded || !context.mounted) {
      return false;
    }

    await bgRemoveSheet(context);

    return true;
  }

  // ------------------------------------------------------------
  // ERROR
  // ------------------------------------------------------------

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  String _savedCategorySlug = "";

  String get savedCategorySlug => _savedCategorySlug;

  // ------------------------------------------------------------
  // BUSINESS UPDATE API
  // ------------------------------------------------------------

  Future<Map<String, dynamic>?> businessUpdateApi(
      BuildContext context,
      String subIndustry,
      ) async {
    _isUploading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      _savedCategorySlug = prefs.getString('saved_category_slug') ?? '';

      final mobileNumber = prefs.getString('saved_mobile_number') ?? '';

      if (mobileNumber.isEmpty) {
        _isUploading = false;
        _errorMessage = "Saved mobile number not found";

        notifyListeners();

        return null;
      }

      final result = await BusinessRepository.instance.businessUpdate(
        _savedCategorySlug,
        subIndustry,
        mobileNumber,
      );

      return await result.when(
        success: (data) async {
          final uid = data['uid']?.toString();

          if (uid == null || uid.isEmpty) {
            _errorMessage = "Business UID not found";

            _isUploading = false;
            notifyListeners();

            return null;
          }

          await prefs.setString('business_uid', uid);

          _isUploading = false;

          notifyListeners();

          if (context.mounted) {
            Navigator.pushNamed(
              context,
              "/BusinessDetailsScreen",
              arguments: uid,
            );
          }

          return data;
        },
        failure: (error) {
          _errorMessage = error.message;

          _isUploading = false;

          notifyListeners();

          return null;
        },
      );
    } catch (e) {
      _isUploading = false;
      _errorMessage = e.toString();

      notifyListeners();

      debugPrint("❌ businessUpdateApi error: $e");

      return null;
    }
  }

  // ------------------------------------------------------------
  // UPDATE BUSINESS DETAILS
  // ------------------------------------------------------------

  Future<bool> updateBusinessDetails(
      BuildContext context,
      String businessUid,
      ) async {
    _isUploading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final phone = mobileController.text.trim();

      final logoS3Key = _logoS3Key?.trim() ?? '';

      final result = await BusinessRepository.instance.updateBusinessDetails(
        businessUid: businessUid,
        name: name,
        email: email,
        phone: phone,
        logo_s3_key: logoS3Key,
      );

      return await result.when(
        success: (data) async {
          _isUploading = false;

          final prefs = await SharedPreferences.getInstance();

          if (logoS3Key.isNotEmpty) {
            await prefs.setString('logo_s3_key', logoS3Key);
          }

          await prefs.setString('business_uid', businessUid);

          debugPrint("✅ BUSINESS UPDATE SUCCESS");

          notifyListeners();

          return true;
        },
        failure: (error) {
          _isUploading = false;
          _errorMessage = error.message;

          debugPrint("❌ Business update failed: ${error.message}");

          notifyListeners();

          return false;
        },
      );
    } catch (e, stackTrace) {
      _isUploading = false;
      _errorMessage = e.toString();

      debugPrint("❌ Update business details error: $e");

      debugPrintStack(stackTrace: stackTrace);

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // UPDATE PERSONAL DETAILS
  // ============================================================

  Future<bool> updatePersonalDetails(BuildContext context) async {
    _isUploading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final phone = mobileController.text.trim();

      // PERSONAL account always uses the profile S3 key.
      final profileS3Key = _profileS3Key?.trim() ?? '';

      debugPrint("======================================");
      debugPrint("🚀 UPDATE PERSONAL DETAILS");
      debugPrint("Name           : $name");
      debugPrint("Email          : $email");
      debugPrint("Phone          : $phone");
      debugPrint("Profile S3 Key : $profileS3Key");
      debugPrint("======================================");

      final result = await GetMeRepository.instance.updatePersonalDetail(
        name,
        email,
        profileS3Key,
      );

      return await result.when(
        success: (data) async {
          debugPrint("================================");
          debugPrint("✅ PERSONAL UPDATE SUCCESS");
          debugPrint("API RESPONSE = $data");
          debugPrint("================================");

          try {
            if (data is Map && data['data'] is Map) {
              final language = Language.fromJson({
                "success": true,
                "data": Map<String, dynamic>.from(data['data']),
              });

              // Update CommonProvider._me.
              setGetMeData(language);
            }
          } catch (e, stackTrace) {
            debugPrint("❌ Failed to update ME: $e");
            debugPrintStack(stackTrace: stackTrace);
          }

          final prefs = await SharedPreferences.getInstance();

          if (profileS3Key.isNotEmpty) {
            await prefs.setString('profile_s3_key', profileS3Key);

            // Keep this key for compatibility with previous code.
            await prefs.setString('profile_photo_s3_key', profileS3Key);

            // Personal account must not keep a business logo key.
            await prefs.remove('logo_s3_key');
          }

          _isUploading = false;
          notifyListeners();

          return true;
        },
        failure: (error) {
          _isUploading = false;
          _errorMessage = error.message;

          debugPrint("❌ Personal update failed: ${error.message}");

          notifyListeners();

          return false;
        },
      );
    } catch (e, stackTrace) {
      _isUploading = false;
      _errorMessage = e.toString();

      debugPrint("❌ Update personal details error: $e");
      debugPrintStack(stackTrace: stackTrace);

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // LOAD SAVED DATA
  // ============================================================

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedNumber = prefs.getString('saved_mobile_number');

    if (savedNumber != null && savedNumber.isNotEmpty) {
      _mobileNumber = savedNumber;
      mobileController.text = savedNumber;
    }

    _savedImagePath = prefs.getString('saved_business_image_path');

    final savedLogoKey = prefs.getString('logo_s3_key');
    final savedProfileKey =
        prefs.getString('profile_s3_key') ??
            prefs.getString('profile_photo_s3_key');

    if (savedLogoKey != null && savedLogoKey.trim().isNotEmpty) {
      _logoS3Key = savedLogoKey.trim();
    }

    if (savedProfileKey != null && savedProfileKey.trim().isNotEmpty) {
      _profileS3Key = savedProfileKey.trim();
    }

    final savedName = prefs.getString('saved_business_name');

    if (savedName != null && savedName.isNotEmpty) {
      _businessName = savedName;
      nameController.text = savedName;
    }

    final savedEmail = prefs.getString('saved_email');

    if (savedEmail != null && savedEmail.isNotEmpty) {
      _email = savedEmail;
      emailController.text = savedEmail;
    }

    notifyListeners();
  }

  // ============================================================
  // SET GET ME DATA
  // ============================================================

  void setGetMeData(Language me) {
    // IMPORTANT:
    // CommonProvider-ын actual _me-ஐ update செய்கிறது.
    provider.setMe(me);

    _businessUid = me.data.uid;

    if (me.data.name != null) {
      _businessName = me.data.name!;
      nameController.text = me.data.name!;
    }

    if (me.data.email != null) {
      _email = me.data.email!;
      emailController.text = me.data.email!;
    }

    if (me.data.phone != null) {
      _mobileNumber = me.data.phone!;
      mobileController.text = me.data.phone!;
    }

    debugPrint("================================");

    debugPrint(
      "✅ ACCOUNT TYPE UPDATED = "
          "${provider.me?.data.accountType}",
    );

    debugPrint(
      "COMMON ACCOUNT TYPE = "
          "${provider.accountType}",
    );

    debugPrint(
      "IS PERSONAL = "
          "${provider.isPersonal}",
    );

    debugPrint("================================");

    notifyListeners();
  }

  // ============================================================
  // FORM METHODS
  // ============================================================

  void setMobileNumber(String value) {
    _mobileNumber = value.trim();

    mobileController.text = _mobileNumber;

    if (_mobileNumber.isEmpty) {
      _mobileError = "Contact number is required";
    } else if (_mobileNumber.length < 10) {
      _mobileError = "Enter a valid 10-digit contact number";
    } else {
      _mobileError = null;
    }

    notifyListeners();
  }

  void setBusinessName(String value) {
    _businessName = value;
    _nameError = null;

    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    _emailError = null;

    notifyListeners();
  }

  bool validateForm() {
    bool isValid = true;

    if (_selectedImage == null && _originalImage == null) {
      final accountType = provider.me?.data.accountType
          ?.toString()
          .trim()
          .toLowerCase();

      _imageError = accountType == "personal"
          ? "Please select or upload a profile photo"
          : "Please select or upload a logo";

      isValid = false;
    } else {
      _imageError = null;
    }

    if (_businessName.trim().isEmpty) {
      _nameError = "Business name is required";

      isValid = false;
    } else {
      _nameError = null;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (_email.trim().isEmpty) {
      _emailError = "Email address is required";

      isValid = false;
    } else if (!emailRegex.hasMatch(_email.trim())) {
      _emailError = "Enter a valid email address";

      isValid = false;
    } else {
      _emailError = null;
    }

    _mobileNumber = mobileController.text.trim();

    if (_mobileNumber.isEmpty) {
      _mobileError = "Contact number is required";

      isValid = false;
    } else if (_mobileNumber.length < 10) {
      _mobileError = "Enter a valid 10-digit contact number";

      isValid = false;
    } else {
      _mobileError = null;
    }

    notifyListeners();

    return isValid;
  }

  void setCurrentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  void setImageSelected(bool value) {
    _isImageSelected = value;
    notifyListeners();
  }

  set selectedImage(File? value) {
    _selectedImage = value;

    _resetLivePreview();

    _hasChanges = false;
    _isApplied = false;

    _processedImageBytes = null;
    _isProcessingBackground = false;

    notifyListeners();
  }

  void setSelectedTool(String tool) {
    _selectedTool = tool;

    _resetLivePreview();

    _hasChanges = false;

    notifyListeners();
  }

  void setAspect(String aspect) {
    _selectedAspect = aspect;

    _markChanged();

    notifyListeners();
  }

  void setLiveRotationAngle(double angle) {
    _liveRotationAngle = angle;

    _markChanged();

    notifyListeners();
  }

  void setLiveScaleValue(double value) {
    _liveScaleValue = value;

    _markChanged();

    notifyListeners();
  }

  void _resetLivePreview() {
    _liveRotationAngle = 0.0;
    _liveScaleValue = 1.0;
  }

  void clearImage() {
    _selectedImage = null;
    _originalImage = null;

    _resetLivePreview();

    _hasChanges = false;
    _isApplied = false;

    _processedImageBytes = null;
    _isProcessingBackground = false;

    notifyListeners();
  }

  void _markChanged() {
    _hasChanges = true;
    _isApplied = false;
  }

  Future<bool> requestPermissionIfNeeded() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();

      return status.isGranted;
    }

    final deviceInfo = DeviceInfoPlugin();

    final androidInfo = await deviceInfo.androidInfo;

    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final status = await Permission.photos.request();

      return status.isGranted;
    } else {
      final status = await Permission.storage.request();

      return status.isGranted;
    }
  }

  // ============================================================
  // IMAGE UPLOAD
  // ============================================================

  Future<bool> uploadEditedImage() async {
    if (_selectedImage == null) {
      debugPrint("❌ No image selected for upload");
      return false;
    }

    final imageFile = _selectedImage!;

    if (!await imageFile.exists()) {
      debugPrint("❌ Image file does not exist");
      return false;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? accountType = provider.me?.data.accountType
          ?.toString()
          .trim()
          .toLowerCase();

      debugPrint("======================================");
      debugPrint("🚀 EDITED IMAGE UPLOAD");
      debugPrint("ACCOUNT TYPE : $accountType");
      debugPrint("======================================");

      if (accountType == null || accountType.isEmpty) {
        _errorMessage = "Account type not found";
        _isUploading = false;
        notifyListeners();
        return false;
      }

      final String uploadSlot;

      if (accountType == "personal") {
        uploadSlot = "profile_photo";
      } else if (accountType == "business") {
        uploadSlot = "business_logo";
      } else {
        _errorMessage = "Invalid account type: $accountType";
        _isUploading = false;
        notifyListeners();
        return false;
      }

      debugPrint("UPLOAD SLOT : $uploadSlot");

      final filename = imageFile.path.split(Platform.pathSeparator).last;

      final uploadResult = await MediaUploadRepository.instance
          .uploadImageAndConfirm(
        imageFile: imageFile,
        filename: filename,
        width: 1080,
        height: 1080,
        slot: uploadSlot,
      );

      bool success = false;

      await uploadResult.when(
        success: (data) async {
          String? key;

          if (data is Map) {
            key = data['key']?.toString();

            if ((key == null || key!.isEmpty) &&
                data['keys'] is List &&
                (data['keys'] as List).isNotEmpty) {
              key = (data['keys'] as List).first?.toString();
            }

            if ((key == null || key!.isEmpty) &&
                data['results'] is List &&
                (data['results'] as List).isNotEmpty) {
              final first = (data['results'] as List).first;
              if (first is Map) {
                key = first['key']?.toString();
              }
            }

            if ((key == null || key!.isEmpty) && data['data'] is Map) {
              final nested = data['data'];

              key = nested['key']?.toString();

              if ((key == null || key!.isEmpty) &&
                  nested['keys'] is List &&
                  (nested['keys'] as List).isNotEmpty) {
                key = (nested['keys'] as List).first?.toString();
              }

              if ((key == null || key!.isEmpty) &&
                  nested['results'] is List &&
                  (nested['results'] as List).isNotEmpty) {
                final first = (nested['results'] as List).first;
                if (first is Map) {
                  key = first['key']?.toString();
                }
              }
            }
          }

          if (key == null || key!.trim().isEmpty) {
            debugPrint("❌ Upload succeeded but S3 key missing");
            debugPrint("UPLOAD RESPONSE: $data");
            _errorMessage = "Image uploaded but S3 key not found";
            success = false;
            return;
          }

          key = key!.trim();

          final prefs = await SharedPreferences.getInstance();

          if (accountType == "personal") {
            _profileS3Key = key;

            await prefs.remove('logo_s3_key');
            await prefs.setString('profile_s3_key', key);
            await prefs.setString('profile_s3_key', key);
            await prefs.setString('profile_photo_s3_key', key);

            debugPrint("👤 PERSONAL → profile_photo");
            debugPrint("📁 PROFILE S3 KEY → $key");
          } else {
            _logoS3Key = key;

            await prefs.remove('profile_s3_key');
            await prefs.remove('profile_photo_s3_key');
            await prefs.setString('logo_s3_key', key);

            debugPrint("🏢 BUSINESS → business_logo");
            debugPrint("📁 LOGO S3 KEY → $key");
          }

          _selectedImage = imageFile;
          _originalImage = imageFile;
          _savedImagePath = imageFile.path;

          await prefs.setString('saved_business_image_path', imageFile.path);

          success = true;

          debugPrint("======================================");
          debugPrint("✅ EDITED IMAGE UPLOAD SUCCESS");
          debugPrint("ACCOUNT TYPE : $accountType");
          debugPrint("UPLOAD SLOT  : $uploadSlot");
          debugPrint("S3 KEY       : $key");
          debugPrint("======================================");
        },
        failure: (error) {
          success = false;
          _errorMessage = error.message;
          debugPrint("❌ Image upload failed: ${error.message}");
        },
      );

      _isUploading = false;
      notifyListeners();

      return success;
    } catch (e, stackTrace) {
      _isUploading = false;
      _errorMessage = e.toString();

      debugPrint("❌ uploadEditedImage error: $e");
      debugPrintStack(stackTrace: stackTrace);

      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // SHOW UPLOAD SHEET
  // ============================================================

  Future<void> showUploadImageSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: this,
          child: const UploadImageAfterCropSheet(),
        );
      },
    );

    if (result == true) {
      await showBgRemoveScreen(context);
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> pickImage(
      BuildContext context, {
        ImageSource source = ImageSource.gallery,
      }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return;

      _selectedImage = File(image.path);

      _originalImage = File(image.path);

      _hasChanges = false;
      _isApplied = false;

      notifyListeners();

      final navigator = Navigator.of(context, rootNavigator: true);

      navigator.pop();

      await Future.delayed(const Duration(milliseconds: 300));

      if (!navigator.mounted) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: this,
            child: const EditPhotoScreen(),
          ),
        ),
      );
    } catch (e) {
      debugPrint("pickImage error: $e");
    }
  }

  // ============================================================
  // ACCOUNT TYPE LIST
  // ============================================================

  List<AccTypeModel> accountTypeList = [
    AccTypeModel(
      title: "For my Business",
      description:
      "Create branded designs tailored to your business and industry.",
    ),
    AccTypeModel(
      title: "Personal Use",
      description:
      "Create designs for festivals, birthdays, quotes, social posts, and more.",
    ),
  ];

  // ============================================================
  // OTHER HELPERS
  // ============================================================

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void selectCategory(String category) {
    selectedCategory = category;

    notifyListeners();
  }

  double? getAspectRatio(String aspect) {
    switch (aspect) {
      case "Square":
        return 1.0;

      case "3×2":
        return 3.0 / 2.0;

      case "4×3":
        return 4.0 / 3.0;

      case "16×9":
        return 16.0 / 9.0;

      case "Original":
        return selectedImage != null ? -1.0 : null;

      default:
        return null;
    }
  }

  // ============================================================
  // APPLY CROP
  // ============================================================

  Future<void> applyCrop() async {
    if (_selectedImage == null) {
      return;
    }

    final state = editorKey.currentState;

    if (state == null) {
      debugPrint("Editor state is null");

      return;
    }

    try {
      final cropRect = state.getCropRect();

      if (cropRect == null) {
        debugPrint("Crop rect is null");

        return;
      }

      final imageBytes = await _selectedImage!.readAsBytes();

      final codec = await ui.instantiateImageCodec(imageBytes);

      final frame = await codec.getNextFrame();

      final originalImage = frame.image;

      final recorder = ui.PictureRecorder();

      final canvas = Canvas(recorder);

      canvas.drawImageRect(
        originalImage,
        cropRect,
        Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
        Paint(),
      );

      final picture = recorder.endRecording();

      final croppedImage = await picture.toImage(
        cropRect.width.toInt(),
        cropRect.height.toInt(),
      );

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final dir = await getTemporaryDirectory();

        final file = File(
          "${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png",
        );

        await file.writeAsBytes(byteData.buffer.asUint8List());

        if (_selectedImage!.path.contains('temp')) {
          try {
            await _selectedImage!.delete();
          } catch (e) {
            debugPrint("Error deleting old image: $e");
          }
        }

        _selectedImage = file;

        _resetLivePreview();

        _isApplied = true;
        _hasChanges = false;

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Cropping failed: $e");
    }
  }

  // ============================================================
  // APPLY ROTATE
  // ============================================================

  Future<void> applyRotate() async {
    if (_selectedImage == null) {
      return;
    }

    if (_liveRotationAngle == 0.0) {
      _isApplied = true;
      _hasChanges = false;

      notifyListeners();

      return;
    }

    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      final codec = await ui.instantiateImageCodec(imageBytes);

      final frame = await codec.getNextFrame();

      final originalImage = frame.image;

      final width = originalImage.width;

      final height = originalImage.height;

      final angleInRadians = _liveRotationAngle * (math.pi / 180.0);

      final cosAngle = math.cos(angleInRadians).abs();

      final sinAngle = math.sin(angleInRadians).abs();

      final newWidth = (width * cosAngle + height * sinAngle).toInt();

      final newHeight = (width * sinAngle + height * cosAngle).toInt();

      final recorder = ui.PictureRecorder();

      final canvas = Canvas(recorder);

      canvas.translate(newWidth / 2.0, newHeight / 2.0);

      canvas.rotate(angleInRadians);

      canvas.translate(-width / 2.0, -height / 2.0);

      canvas.drawImage(originalImage, Offset.zero, Paint());

      final picture = recorder.endRecording();

      final rotatedImage = await picture.toImage(newWidth, newHeight);

      final byteData = await rotatedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final dir = await getTemporaryDirectory();

        final file = File(
          "${dir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.png",
        );

        await file.writeAsBytes(byteData.buffer.asUint8List());

        if (_selectedImage!.path.contains('temp')) {
          try {
            await _selectedImage!.delete();
          } catch (e) {
            debugPrint("Error deleting old image: $e");
          }
        }

        _selectedImage = file;

        _resetLivePreview();

        _isApplied = true;
        _hasChanges = false;

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Rotation failed: $e");
    }
  }

  // ============================================================
  // APPLY SCALE
  // ============================================================

  Future<void> applyScale() async {
    if (_selectedImage == null) {
      return;
    }

    if (_liveScaleValue == 1.0) {
      _isApplied = true;
      _hasChanges = false;

      notifyListeners();

      return;
    }

    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      final codec = await ui.instantiateImageCodec(imageBytes);

      final frame = await codec.getNextFrame();

      final originalImage = frame.image;

      final width = originalImage.width;

      final height = originalImage.height;

      final newWidth = (width * _liveScaleValue).toInt();

      final newHeight = (height * _liveScaleValue).toInt();

      final recorder = ui.PictureRecorder();

      final canvas = Canvas(recorder);

      canvas.drawImageRect(
        originalImage,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();

      final scaledImage = await picture.toImage(newWidth, newHeight);

      final byteData = await scaledImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final dir = await getTemporaryDirectory();

        final file = File(
          "${dir.path}/scaled_${DateTime.now().millisecondsSinceEpoch}.png",
        );

        await file.writeAsBytes(byteData.buffer.asUint8List());

        if (_selectedImage!.path.contains('temp')) {
          try {
            await _selectedImage!.delete();
          } catch (e) {
            debugPrint("Error deleting old image: $e");
          }
        }

        _selectedImage = file;

        _resetLivePreview();

        _isApplied = true;
        _hasChanges = false;

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Scaling failed: $e");
    }
  }

  void resetRotation() {
    _liveRotationAngle = 0.0;

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // BG REMOVE
  // ============================================================

  Future<void> bgRemoveSheet(BuildContext context) async {
    final businessProvider = this;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: businessProvider,
          child: BgRemoveSheet(
            onSuccess: () {
              //Navigator.of(modalContext).pop(true);
            },
          ),
        );
      },
    );
  }
  Future<void> showBgRemoveScreen(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: this,
          child: BgRemoveSheet(
            onSuccess: () {
            //  Navigator.of(modalContext).pop(true);
            },
          ),
        );
      },
    );
  }

  Future<void> showEditImageQuestion(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final shouldEdit = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 70,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Edit Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('Do you want to crop/edit this image?'),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('No'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Yes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (shouldEdit == true) {
      Navigator.pushNamed(context, "/EditPhotoScreen", arguments: this);
    } else if (shouldEdit == false) {
      await bgRemoveSheet(context);
    }
  }

  // ============================================================
  // BG REMOVE
  // ============================================================

  Future<bool> removeBackground() async {
    if (_selectedImage == null) {
      debugPrint("No image selected for background removal");

      return false;
    }

    _originalImage = _selectedImage;

    _isProcessingBackground = true;

    notifyListeners();

    try {
      final Uint8List? result = await platform.invokeMethod<Uint8List>(
        'removeBackground',
        {'imagePath': _selectedImage!.path},
      );

      if (result != null) {
        final dir = await getTemporaryDirectory();

        final fileName =
            'bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';

        final processedFile = File('${dir.path}/$fileName');

        await processedFile.writeAsBytes(result);

        if (_selectedImage!.path.contains('temp')) {
          try {
            await _selectedImage!.delete();
          } catch (e) {
            debugPrint("Error deleting old image: $e");
          }
        }

        _selectedImage = processedFile;

        _processedImageBytes = result;

        _resetLivePreview();

        _isApplied = true;
        _hasChanges = false;

        _isProcessingBackground = false;

        _isImageSelected = false;

        notifyListeners();

        return true;
      } else {
        _isProcessingBackground = false;

        notifyListeners();

        return false;
      }
    } on PlatformException catch (e) {
      debugPrint(
        "Failed to remove background: "
            "'${e.message}'",
      );

      _isProcessingBackground = false;

      notifyListeners();

      return false;
    } catch (e) {
      debugPrint("Background removal error: $e");

      _isProcessingBackground = false;

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // APPLY PROCESSED IMAGE
  // ============================================================

  Future<bool> applyProcessedImageToSelected() async {
    if (_processedImageBytes == null) {
      return false;
    }

    try {
      final dir = await getTemporaryDirectory();

      final fileName =
          'applied_bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';

      final processedFile = File('${dir.path}/$fileName');

      await processedFile.writeAsBytes(_processedImageBytes!);

      _selectedImage = processedFile;

      _resetLivePreview();

      _isApplied = true;
      _hasChanges = false;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("Failed to apply processed image: $e");

      return false;
    }
  }

  // ============================================================
  // SAVED IMAGE PATH
  // ============================================================

  void updateSavedImagePath(String path) {
    _savedImagePath = path;

    notifyListeners();
  }

  Future<bool> uploadBgRemovedImage() async {
    if (_selectedImage == null) {
      debugPrint("❌ No background removed image selected");
      return false;
    }

    final imageFile = _selectedImage!;

    if (!await imageFile.exists()) {
      debugPrint("❌ Image file does not exist");
      return false;
    }

    _isUploading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // ============================================================
      // ACCOUNT TYPE + SLOT
      // ============================================================

      final uploadSlot = _getUploadSlot();

      if (uploadSlot == null) {
        _isUploading = false;
        _errorMessage = "Invalid account type";

        notifyListeners();

        return false;
      }

      final accountType = provider.me?.data.accountType
          ?.toString()
          .toLowerCase()
          .trim();

      debugPrint("======================================");
      debugPrint("🚀 BG REMOVED IMAGE UPLOAD");
      debugPrint("ACCOUNT TYPE : $accountType");
      debugPrint("UPLOAD SLOT  : $uploadSlot");
      debugPrint("======================================");

      final filename = imageFile.path.split(Platform.pathSeparator).last;

      // ============================================================
      // UPLOAD
      // ============================================================

      final result = await MediaUploadRepository.instance.uploadImageAndConfirm(
        imageFile: imageFile,
        filename: filename,
        width: 1080,
        height: 1080,
        slot: uploadSlot,
      );

      bool success = false;

      await result.when(
        success: (data) async {
          debugPrint("======================================");
          debugPrint("✅ BG REMOVE UPLOAD SUCCESS");
          debugPrint("RESPONSE : $data");
          debugPrint("======================================");
          final responseData = data;

          String? s3Key;

          final directKey = responseData['key'];

          if (directKey != null &&
              directKey.toString().trim().isNotEmpty) {
            s3Key = directKey.toString().trim();
          }

          // 2. keys[]
          if (s3Key == null) {
            final keys = responseData['keys'];

            if (keys is List && keys.isNotEmpty) {
              final key = keys.first;

              if (key != null &&
                  key.toString().trim().isNotEmpty) {
                s3Key = key.toString().trim();
              }
            }
          }

          // 3. results[].key
          if (s3Key == null) {
            final results = responseData['results'];

            if (results is List && results.isNotEmpty) {
              final firstResult = results.first;

              if (firstResult is Map) {
                final key = firstResult['key'];

                if (key != null &&
                    key.toString().trim().isNotEmpty) {
                  s3Key = key.toString().trim();
                }
              }
            }
          }
          debugPrint("======================================");
          debugPrint("🔍 EXTRACTED S3 KEY");
          debugPrint("S3 KEY : $s3Key");
          debugPrint("======================================");

          if (s3Key == null || s3Key.isEmpty) {
            debugPrint(
              "❌ Upload success but S3 key not found",
            );

            debugPrint(
              "❌ Response was: $responseData",
            );

            success = false;
            return;
          }
          _logoS3Key = s3Key;
          success = true;

          debugPrint("======================================");
          debugPrint("✅ S3 KEY SAVED");
          debugPrint("$_logoS3Key");
          debugPrint("======================================");
        },

        failure: (error) {
          debugPrint("❌ Upload failed: ${error.message}");

          _errorMessage = error.message;

          success = false;
        },
      );
      _isUploading = false;

      notifyListeners();

      return success;
    } catch (e, stackTrace) {
      debugPrint("❌ uploadBgRemovedImage error: $e");

      debugPrintStack(stackTrace: stackTrace);

      _isUploading = false;

      _errorMessage = e.toString();

      notifyListeners();

      return false;
    }
  }

  String? _getUploadSlot() {
    final accountType = provider.me?.data.accountType
        ?.toString()
        .toLowerCase()
        .trim();

    debugPrint("======================================");
    debugPrint("ACCOUNT TYPE : $accountType");

    if (accountType == "personal") {
      debugPrint("UPLOAD SLOT  : profile");
      debugPrint("======================================");

      return "profile_photo";
    }

    if (accountType == "business") {
      debugPrint("UPLOAD SLOT  : logo");
      debugPrint("======================================");

      return "business_logo";
    }

    debugPrint("❌ Invalid account type: $accountType");
    debugPrint("======================================");

    return null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    mobileController.dispose();
    nameController.dispose();
    emailController.dispose();

    _cleanupTempFiles();

    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();

      final files = dir.listSync();

      for (var file in files) {
        if (file is File &&
            (file.path.contains('cropped_') ||
                file.path.contains('rotated_') ||
                file.path.contains('scaled_'))) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint("Error cleaning up temp files: $e");
    }
  }
}

class AccTypeModel {
  final String title;
  final String description;

  AccTypeModel({required this.title, required this.description});
}
