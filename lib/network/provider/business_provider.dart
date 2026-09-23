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
import '../../ui/industry/widgets/remove_sheet.dart';

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

  // LIVE PREVIEW variables
  double _liveRotationAngle = 0.0;
  double _liveScaleValue = 1.0;

  ///get method
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

  // GETTERS FOR ERRORS
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
  final CommonProvider provider = CommonProvider.instance;
  void setBusinessUid(String uid) {
    _businessUid = uid;
    notifyListeners();
  }

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
    await prefs.remove('saved_business_image_path');

    notifyListeners();
  }

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

  Future<void> loadSavedBusinessImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('saved_business_image_path');

    if (imagePath != null && imagePath.isNotEmpty) {
      _savedImagePath = imagePath;
      _originalImage = File(imagePath);
      notifyListeners();
    }
  }

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
      final filename = imageFile.path.split(Platform.pathSeparator).last;

      final uploadResult = await MediaUploadRepository.instance
          .uploadImageAndConfirm(
            imageFile: imageFile,
            filename: filename,
            width: 1080,
            height: 1080,
          );

      bool success = false;

      await uploadResult.when(
        success: (data) async {
          success = true;

          // Store the REMOTE path/key returned by the upload API.
          // Fall back to the local file path only when the API does not return
          // a usable remote value.
          String? apiPath;
          String? apiKey;

          final dynamic rootPath =
              data['path'] ?? data['filePath'] ?? data['url'];
          final dynamic rootKey =
              data['key'] ?? data['s3Key'] ?? data['logoS3Key'];

          apiPath = rootPath?.toString();
          apiKey = rootKey?.toString();

          // Support APIs that wrap the result inside `data`.
          final nested = data['data'];
          if (nested is Map) {
            apiPath ??= (nested['path'] ?? nested['filePath'] ?? nested['url'])
                ?.toString();
            apiKey ??= (nested['key'] ?? nested['s3Key'] ?? nested['logoS3Key'])
                ?.toString();
          }

          _savedImagePath = (apiPath != null && apiPath.isNotEmpty)
              ? apiPath
              : imageFile.path;

          if (apiKey != null && apiKey.isNotEmpty) {
            _logoS3Key = apiKey;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_business_image_path', _savedImagePath!);

          debugPrint("✅ Image uploaded: $_savedImagePath");
          debugPrint("✅ Logo key: $_logoS3Key");
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
      notifyListeners();
      debugPrint("❌ uploadCurrentImage error: $e");
      return false;
    }
  }

  /// Final Business Details save. No image upload is performed here.
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

  /// Called after the crop screen saves the cropped image.
  /// Uploads the cropped image and then opens the BG-remove question.
  Future<bool> onCropSaved(BuildContext context) async {
    final uploaded = await uploadCurrentImage();
    if (!uploaded || !context.mounted) return false;

    await bgRemoveSheet(context);
    return true;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String _savedCategorySlug = "";
  String get savedCategorySlug => _savedCategorySlug;

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

      debugPrint("Industry: $_savedCategorySlug");
      debugPrint("Sub Industry: $subIndustry");
      debugPrint("Saved Mobile Number: $mobileNumber");

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

      _isUploading = false;
      notifyListeners();

      return await result.when(
        success: (data) async {
          final uid = data['uid']?.toString();

          if (uid == null || uid.isEmpty) {
            _errorMessage = "Business UID not found";
            _isUploading = false;
            notifyListeners();
            return null;
          }
          final prefs = await SharedPreferences.getInstance();
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

      debugPrint("======================================");
      debugPrint("🚀 UPDATE BUSINESS");
      debugPrint("Business UID : $businessUid");
      debugPrint("Name         : $name");
      debugPrint("Email        : $email");
      debugPrint("Phone        : $phone");
      debugPrint("Logo S3 Key  : $logoS3Key");
      debugPrint("======================================");

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

          debugPrint("✅ SAVED LOGO KEY: $logoS3Key");

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

  Future<bool> updatePersonalDetails(BuildContext context) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final phone = mobileController.text.trim();

      final logoS3Key = _logoS3Key?.trim() ?? '';

      debugPrint("======================================");
      debugPrint("🚀 UPDATE BUSINESS");
      debugPrint("Business UID : $businessUid");
      debugPrint("Name         : $name");
      debugPrint("Email        : $email");
      debugPrint("Phone        : $phone");
      debugPrint("Logo S3 Key  : $logoS3Key");
      debugPrint("======================================");

      final result = await GetMeRepository.instance.updateBusinessDetail(
        name,
        email,
        phone,
        logoS3Key,
      );

      return await result.when(
        success: (data) async {
          _isUploading = false;

          final prefs = await SharedPreferences.getInstance();

          if (logoS3Key.isNotEmpty) {
            await prefs.setString('logo_s3_key', logoS3Key);
          }
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

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedNumber = prefs.getString('saved_mobile_number');
    if (savedNumber != null && savedNumber.isNotEmpty) {
      _mobileNumber = savedNumber;
      mobileController.text = savedNumber;
    }

    // 2. பிசினஸ் இமேஜ் பாத்
    _savedImagePath = prefs.getString('saved_business_image_path');

    final savedLogoKey = prefs.getString('logo_s3_key');
    if (savedLogoKey != null && savedLogoKey.trim().isNotEmpty) {
      _logoS3Key = savedLogoKey.trim();
    }

    // 3. பிசினஸ் பெயர்
    final savedName = prefs.getString('saved_business_name');
    if (savedName != null && savedName.isNotEmpty) {
      _businessName = savedName;
      nameController.text = savedName;
    }

    // 4. இமெயில்
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _email = savedEmail;
      emailController.text = savedEmail;
    }

    notifyListeners();
  }

  void setGetMeData(Language me) {
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

    notifyListeners();
  }

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

  // FORM VALIDATION FUNCTION
  bool validateForm() {
    bool isValid = true;

    // 1. Logo Image Validation
    if (_selectedImage == null && _originalImage == null) {
      _imageError = "Please select or upload a logo";
      isValid = false;
    } else {
      _imageError = null;
    }

    // 2. Business Name Validation
    if (_businessName.trim().isEmpty) {
      _nameError = "Business name is required";
      isValid = false;
    } else {
      _nameError = null;
    }

    // 3. Email Validation
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

  /// set method
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

  // LIVE PREVIEW setters
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
    if (!Platform.isAndroid && !Platform.isIOS) return true;
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

  Future<bool> uploadEditedImage() async {
    if (_selectedImage == null) {
      debugPrint("No image selected for upload");
      return false;
    }

    final imageFile = _selectedImage!;

    if (!await imageFile.exists()) {
      debugPrint("Image file does not exist");
      return false;
    }

    _isUploading = true;
    notifyListeners();

    try {
      final filename = imageFile.path.split('/').last;

      final uploadResult = await MediaUploadRepository.instance
          .uploadImageAndConfirm(
            imageFile: imageFile,
            filename: filename,
            width: 1080,
            height: 1080,
          );

      bool success = false;

      await uploadResult.when(
        success: (data) async {
          String? key;

          // Direct key
          if (data is Map) {
            key = data['key']?.toString();

            // Confirm response:
            // { keys: [...] }
            if ((key == null || key!.isEmpty) &&
                data['keys'] is List &&
                (data['keys'] as List).isNotEmpty) {
              key = (data['keys'] as List).first?.toString();
            }

            // Confirm response:
            // { results: [{ key: "...", status: "confirmed" }] }
            if ((key == null || key!.isEmpty) &&
                data['results'] is List &&
                (data['results'] as List).isNotEmpty) {
              final first = (data['results'] as List).first;

              if (first is Map) {
                key = first['key']?.toString();
              }
            }

            // Nested data support
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

            success = false;
            _errorMessage = "Image uploaded but S3 key not found";
            return;
          }

          key = key!.trim();

          // ⭐ VERY IMPORTANT
          _logoS3Key = key;

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('logo_s3_key', key);

          debugPrint("======================================");
          debugPrint("✅ IMAGE UPLOAD SUCCESS");
          debugPrint("✅ NEW LOGO KEY:");
          debugPrint(key);
          debugPrint("======================================");

          success = true;

          _selectedImage = imageFile;
          _originalImage = imageFile;

          final localPath = imageFile.path;

          _savedImagePath = localPath;

          await prefs.setString('saved_business_image_path', localPath);

          notifyListeners();
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
      notifyListeners();

      debugPrint("uploadEditedImage error: $e");

      return false;
    }
  }

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

  Future<bool> uploadBgRemovedImage() async {
    final file = _selectedImage;

    if (file == null || !await file.exists()) {
      _errorMessage = "BG removed image is not available";
      debugPrint("❌ BG removed file doesn't exist");
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final filename = file.path.split(Platform.pathSeparator).last;

      final result = await MediaUploadRepository.instance.uploadImageAndConfirm(
        imageFile: file,
        filename: filename,
        width: 1080,
        height: 1080,
      );

      bool success = false;

      await result.when(
        success: (data) async {
          success = true;

          String? apiPath;
          String? apiKey;

          apiPath = (data['path'] ?? data['filePath'] ?? data['url'])
              ?.toString();
          apiKey = (data['key'] ?? data['s3Key'] ?? data['logoS3Key'])
              ?.toString();
          final nested = data['data'];
          if (nested is Map) {
            apiPath ??= (nested['path'] ?? nested['filePath'] ?? nested['url'])
                ?.toString();
            apiKey ??= (nested['key'] ?? nested['s3Key'] ?? nested['logoS3Key'])
                ?.toString();
          }

          // IMPORTANT: this is the API path, not the local temp path.
          if (apiPath != null && apiPath.isNotEmpty) {
            _savedImagePath = apiPath;
          } else {
            // Keep the local path only as a fallback for preview.
            _savedImagePath = file.path;
            debugPrint(
              "⚠️ Upload succeeded but API path was not found in response: $data",
            );
          }

          if (apiKey != null && apiKey.isNotEmpty) {
            _logoS3Key = apiKey;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_business_image_path', _savedImagePath!);

          debugPrint("✅ BG removed image uploaded. API PATH: $_savedImagePath");
          debugPrint("✅ API KEY: $_logoS3Key");

          notifyListeners();
        },
        failure: (error) {
          success = false;
          _errorMessage = error.message;
          debugPrint("❌ BG removed image upload failed: ${error.message}");
        },
      );

      _isUploading = false;
      notifyListeners();
      return success;
    } catch (e, stackTrace) {
      _isUploading = false;
      _errorMessage = e.toString();
      notifyListeners();

      debugPrint("❌ uploadBgRemovedImage error: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> showRemoveBackgroundQuestion(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: this,
          child: const RemoveBackgroundQuestionSheet(),
        );
      },
    );
    if (result == true && context.mounted) {
      await bgRemoveSheet(context);
    }
  }

  Future<void> showBgRemoveScreen(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: this,
          child: const BgRemoveSheet(),
        );
      },
    );
  }

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

      // Close ChooseImageSheet
      navigator.pop();

      await Future.delayed(const Duration(milliseconds: 300));

      if (!navigator.mounted) return;

      // Go to Crop/Edit screen
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

  Future<void> showEditImageQuestion(BuildContext context) async {
    if (!context.mounted) return;

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

    if (!context.mounted) return;

    if (shouldEdit == true) {
      Navigator.pushNamed(context, "/EditPhotoScreen", arguments: this);
    } else if (shouldEdit == false) {
      // Image was already uploaded in STEP 1. Do not upload again.
      await bgRemoveSheet(context);
    }
  }

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

  /// APPLY CROP - Uses editor crop rect on CURRENT image
  Future<void> applyCrop() async {
    if (_selectedImage == null) return;
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

        // Clean up old image if it's in temp directory
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

  /// APPLY ROTATE - Rotates by the LIVE angle (not just 90°)
  Future<void> applyRotate() async {
    if (_selectedImage == null) return;
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

      // Convert angle to radians
      final angleInRadians = _liveRotationAngle * (math.pi / 180.0);

      // Calculate new dimensions after rotation
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

  /// APPLY SCALE - Uses live scale value on CURRENT image
  Future<void> applyScale() async {
    if (_selectedImage == null) return;
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

  Future<void> bgRemoveSheet(BuildContext context) async {
    final businessProvider = this;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: businessProvider,
          child: const BgRemoveSheet(),
        );
      },
    );
  }

  @override
  void dispose() {
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

        debugPrint(
          "Background removed successfully and _selectedImage updated",
        );
        return true;
      } else {
        _isProcessingBackground = false;
        notifyListeners();
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to remove background: '${e.message}'");
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

  Future<bool> applyProcessedImageToSelected() async {
    if (_processedImageBytes == null) return false;

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

  void updateSavedImagePath(String path) {
    _savedImagePath = path;
    notifyListeners();
  }
}

class AccTypeModel {
  final String title;
  final String description;

  AccTypeModel({required this.title, required this.description});
}
