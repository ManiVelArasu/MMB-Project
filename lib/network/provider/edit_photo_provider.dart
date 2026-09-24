import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/me_api.dart';
import '../../Api Model/business_model.dart';
import '../../Repository/get_me_repository.dart';
import '../../Repository/update_profile.dart';
import '../../Repository/image_upload_repository.dart';
import '../../network/provider/common_provider.dart';

class EditPhotoProvider extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  final TextEditingController businessNameController = TextEditingController();

  final TextEditingController industryController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController contactController = TextEditingController();

  final TextEditingController whatsappController = TextEditingController();

  final TextEditingController altContactController = TextEditingController();

  final TextEditingController websiteController = TextEditingController();

  final TextEditingController cityController = TextEditingController();

  final TextEditingController stateController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController latitudeController = TextEditingController();

  final TextEditingController longitudeController = TextEditingController();

  final TextEditingController facebookController = TextEditingController();

  final TextEditingController instagramController = TextEditingController();

  final TextEditingController twitterController = TextEditingController();

  final TextEditingController youtubeController = TextEditingController();

  final TextEditingController linkedinController = TextEditingController();

  String? _businessUid;

  String? get businessUid => _businessUid;

  // =========================================================
  // API FIELDS
  // =========================================================

  String logoS3Key = '';

  // Personal account profile photo S3 key.
  String profilePhotoS3Key = '';

  String coverS3Key = '';

  int watermarkEnabled = 0;

  String? headingFontId;

  String? bodyFontId;

  List<Map<String, dynamic>> brandColors = [];

  Map<String, dynamic> socialLinks = {};

  Map<String, dynamic> operatingHours = {};

  // =========================================================
  // UI STATE
  // =========================================================

  bool isMoreInfoExpanded = true;

  bool isSocialExpanded = true;

  // =========================================================
  // BUSINESS SAVE STATE
  // =========================================================

  bool isSaving = false;

  String? saveError;

  // =========================================================
  // IMAGE STATE
  // =========================================================

  File? _selectedImage;

  File? get selectedImage => _selectedImage;

  bool _isUploadingImage = false;

  bool get isUploadingImage => _isUploadingImage;

  String? _imageUploadError;

  String? get imageUploadError => _imageUploadError;

  String? _uploadedImageKey;

  String? get uploadedImageKey => _uploadedImageKey;

  final CommonProvider provider = CommonProvider.instance;

  GetMeRepository getMeRepository = GetMeRepository.instance;

  void setGetMeData(Language me) {
    _businessUid = me.data.uid;

    businessNameController.text = me.data.name ?? '';
    emailController.text = me.data.email ?? '';
    contactController.text = me.data.phone ?? '';

    final accountType = me.data.accountType;
    final profileKey = me.data.profilePhotoS3Key;

    if (accountType == 'personal') {
      if (profileKey != null && profileKey.isNotEmpty) {
        profilePhotoS3Key = profileKey;
      }
    } else {
      if (profileKey != null && profileKey.isNotEmpty) {
        logoS3Key = profileKey;
      }
    }

    notifyListeners();
  }

  void setUid(String? uid) {
    _businessUid = uid;
    notifyListeners();
  }

  Future<bool> pickAndUploadImage() async {
    if (_isUploadingImage) {
      return false;
    }

    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return false;
      }

      final File imageFile = File(pickedFile.path);

      if (!imageFile.existsSync()) {
        _imageUploadError = 'Selected image not found';
        notifyListeners();
        return false;
      }

      _selectedImage = imageFile;
      _isUploadingImage = true;
      _imageUploadError = null;
      _uploadedImageKey = null;

      notifyListeners();

      final filename = imageFile.path.split(Platform.pathSeparator).last;

      final accountType = provider.me?.data.accountType;

      debugPrint('📷 Uploading image: $filename');
      debugPrint('👤 Account type: $accountType');

      // The upload slot MUST match the account type.
      // Business -> business_logo
      // Personal -> profile_photo
      final String uploadSlot;

      if (accountType == 'personal') {
        uploadSlot = 'profile_photo';
      } else if (accountType == 'business') {
        uploadSlot = 'business_logo';
      } else {
        _isUploadingImage = false;
        _imageUploadError = 'Account type not found';
        notifyListeners();
        return false;
      }

      debugPrint('📌 Upload slot: $uploadSlot');

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

          key = data['key']?.toString();

          if ((key == null || key.isEmpty) &&
              data['keys'] is List &&
              (data['keys'] as List).isNotEmpty) {
            key = (data['keys'] as List).first?.toString();
          }

          if ((key == null || key.isEmpty) &&
              data['results'] is List &&
              (data['results'] as List).isNotEmpty) {
            final result = (data['results'] as List).first;
            if (result is Map) {
              key = result['key']?.toString();
            }
          }

          if (key == null || key.trim().isEmpty) {
            _imageUploadError = 'Image uploaded but S3 key not found';

            debugPrint('❌ Upload response did not contain S3 key: $data');
            return;
          }

          key = key.trim();
          _uploadedImageKey = key;

          final prefs = await SharedPreferences.getInstance();

          if (accountType == 'personal') {
            // PERSONAL → profile_photo_s3_key
            profilePhotoS3Key = key;

            // Remove stale business key so it cannot be reused.
            await prefs.remove('logo_s3_key');
            await prefs.setString('profile_photo_s3_key', key);

            debugPrint('👤 PERSONAL → profile_photo_s3_key: $key');
          } else if (accountType == 'business') {
            // BUSINESS → logo_s3_key
            logoS3Key = key;

            // Remove stale personal key so it cannot be reused.
            await prefs.remove('profile_photo_s3_key');
            await prefs.setString('logo_s3_key', key);

            debugPrint('🏢 BUSINESS → logo_s3_key: $key');
          } else {
            _imageUploadError = 'Account type not found';

            debugPrint(
              '❌ Cannot assign S3 key. '
              'Account type: $accountType',
            );
            return;
          }

          success = true;

          debugPrint('================================');
          debugPrint('✅ IMAGE UPLOAD SUCCESS');
          debugPrint('✅ Account type: $accountType');
          debugPrint('✅ S3 Key: $key');
          debugPrint('================================');
        },
        failure: (error) {
          _imageUploadError = error.message;

          debugPrint('❌ Image upload failed: ${error.message}');
        },
      );

      _isUploadingImage = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isUploadingImage = false;
      _imageUploadError = e.toString();

      debugPrint('❌ Image upload exception: $e');

      notifyListeners();
      return false;
    }
  }

  void removeSelectedImage() {
    _selectedImage = null;
    _imageUploadError = null;

    final accountType = provider.me?.data.accountType;

    if (accountType == 'personal') {
      profilePhotoS3Key = '';
    } else {
      logoS3Key = '';
    }

    notifyListeners();
  }

  /// Fill the edit form from the Business API response.
  /// This is the single source for business name, industry,
  /// description, logo, contact, address and social data.
  Future<void> setBusinessApiData(BusinessApiModel business) async {
    print(business.whatsapp);
    _businessUid = business.uid;

    businessNameController.text = business.name ?? '';
    industryController.text = business.businessCategory?.slug ?? '';
    descriptionController.text = business.description ?? '';
    emailController.text = business.email ?? '';
    contactController.text = business.phone ?? '';
    whatsappController.text = business.whatsapp ?? '';
    websiteController.text = business.website ?? '';
    cityController.text = business.city ?? '';
    stateController.text = business.state ?? '';
    addressController.text = business.address ?? '';
    latitudeController.text = business.latitude ?? '';
    longitudeController.text = business.longitude ?? '';

    logoS3Key = business.logoS3Key ?? '';
    coverS3Key = business.coverS3Key ?? '';
    watermarkEnabled = int.tryParse(business.watermarkEnabled ?? '0') ?? 0;
    headingFontId = business.headingFontId;
    bodyFontId = business.bodyFontId;

    if (business.socialLinks != null && business.socialLinks!.isNotEmpty) {
      try {
        final decoded = jsonDecode(business.socialLinks!);
        socialLinks = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
      } catch (_) {
        socialLinks = {};
      }
    } else {
      socialLinks = {};
    }

    final social = socialLinks;
    facebookController.text = social['facebook']?.toString() ?? '';
    instagramController.text = social['instagram']?.toString() ?? '';
    twitterController.text = social['twitter']?.toString() ?? '';
    youtubeController.text = social['youtube']?.toString() ?? '';
    linkedinController.text = social['linkedin']?.toString() ?? '';

    // Keep the business UID available to the existing save method.
    final prefs = await SharedPreferences.getInstance();
    if (_businessUid != null && _businessUid!.isNotEmpty) {
      await prefs.setString('business_uid', _businessUid!);
    }
    if (logoS3Key.isNotEmpty) {
      await prefs.setString('logo_s3_key', logoS3Key);
    }

    debugPrint('======================================');
    debugPrint('📝 EDIT PROFILE FILLED FROM BUSINESS API');
    debugPrint('Name     : ${business.name}');
    debugPrint('Industry : ${business.businessCategory?.parent?.name}');
    debugPrint('Email    : ${business.email}');
    debugPrint('Phone    : ${business.phone}');
    debugPrint('WhatsApp : ${business.whatsapp}');
    debugPrint('Logo     : ${business.logoS3Key}');
    debugPrint('======================================');

    notifyListeners();
  }

  void setBusinessData({
    required String? uid,
    String? name,
    String? industry,
    String? description,
    String? email,
    String? phone,
    String? whatsapp,
    String? website,
    String? city,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    String? logoS3Key,
    String? coverS3Key,
    int? watermarkEnabled,
    String? headingFontId,
    String? bodyFontId,
    List<Map<String, dynamic>>? brandColors,
    Map<String, dynamic>? socialLinks,
    Map<String, dynamic>? operatingHours,
  }) {
    _businessUid = uid;

    businessNameController.text = name ?? '';

    industryController.text = industry ?? '';

    descriptionController.text = description ?? '';

    emailController.text = email ?? '';

    contactController.text = phone ?? '';

    whatsappController.text = whatsapp ?? '';

    websiteController.text = website ?? '';

    cityController.text = city ?? '';

    stateController.text = state ?? '';

    addressController.text = address ?? '';

    latitudeController.text = latitude?.toString() ?? '';

    longitudeController.text = longitude?.toString() ?? '';

    this.logoS3Key = logoS3Key ?? '';

    this.coverS3Key = coverS3Key ?? '';

    this.watermarkEnabled = watermarkEnabled ?? 0;

    this.headingFontId = headingFontId;

    this.bodyFontId = bodyFontId;

    this.brandColors = brandColors ?? [];

    this.socialLinks = socialLinks ?? {};

    this.operatingHours = operatingHours ?? {};

    final social = this.socialLinks;

    facebookController.text = social['facebook']?.toString() ?? '';

    instagramController.text = social['instagram']?.toString() ?? '';

    twitterController.text = social['twitter']?.toString() ?? '';

    youtubeController.text = social['youtube']?.toString() ?? '';

    linkedinController.text = social['linkedin']?.toString() ?? '';

    notifyListeners();
  }

  Map<String, dynamic> buildSocialLinks() {
    return {
      "facebook": facebookController.text.trim(),

      "instagram": instagramController.text.trim(),

      "twitter": twitterController.text.trim(),

      "youtube": youtubeController.text.trim(),

      "linkedin": linkedinController.text.trim(),
    };
  }

  Future<bool> saveBusinessDetails() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUid = prefs.getString('business_uid');
    final businessUid = savedUid?.trim();

    if (businessUid == null || businessUid.isEmpty) {
      saveError = 'Business UID not found';
      notifyListeners();
      return false;
    }

    if (_isUploadingImage) {
      saveError = 'Please wait for image upload to finish';
      notifyListeners();
      return false;
    }

    // BUSINESS ONLY: use logo_s3_key.
    final savedLogoS3Key = prefs.getString('logo_s3_key')?.trim();

    if (savedLogoS3Key != null && savedLogoS3Key.isNotEmpty) {
      logoS3Key = savedLogoS3Key;
      _uploadedImageKey = savedLogoS3Key;
    }

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final latitudeText = latitudeController.text.trim();
      final longitudeText = longitudeController.text.trim();

      final double? latitude = latitudeText.isEmpty
          ? null
          : double.tryParse(latitudeText);

      final double? longitude = longitudeText.isEmpty
          ? null
          : double.tryParse(longitudeText);

      final updatedSocialLinks = buildSocialLinks();

      socialLinks = updatedSocialLinks;

      debugPrint('====================================');
      debugPrint('🚀 BUSINESS PATCH');
      debugPrint('UID: $businessUid');
      debugPrint('logo_s3_key: $logoS3Key');
      debugPrint('====================================');

      final result = await UpdateProfileRepository.instance.updateBusiness(
        businessUid: businessUid,
        name: businessNameController.text.trim(),
        industry: industryController.text.trim(),
        description: descriptionController.text.trim(),
        logoS3Key: logoS3Key,
        coverS3Key: coverS3Key,
        brandColors: brandColors,
        watermarkEnabled: watermarkEnabled,
        headingFontId: headingFontId,
        bodyFontId: bodyFontId,
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        address: addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        phone: contactController.text.trim(),
        whatsapp: whatsappController.text.trim(),
        email: emailController.text.trim(),
        website: websiteController.text.trim(),
        socialLinks: updatedSocialLinks,
        operatingHours: operatingHours,
      );

      bool success = false;

      await result.when(
        success: (data) async {
          success = true;

          debugPrint('✅ BUSINESS PATCH SUCCESS: $data');

          await CommonProvider.instance.loadBusiness(forceRefresh: true);

          // Business API success also marks the flow complete.
          await prefs.setBool('continue', true);
        },
        failure: (error) {
          saveError = error.message;

          debugPrint(
            '❌ BUSINESS PATCH FAILED: '
            '${error.message}',
          );
        },
      );

      isSaving = false;
      notifyListeners();

      return success;
    } catch (e) {
      isSaving = false;
      saveError = e.toString();

      debugPrint('❌ Update Business Error: $e');

      notifyListeners();
      return false;
    }
  }

  Future<bool> savePersonalDetails() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isUploadingImage) {
      saveError = 'Please wait for image upload to finish';
      notifyListeners();
      return false;
    }

    // PERSONAL ONLY: use profile_photo_s3_key.
    final savedProfilePhotoKey = prefs
        .getString('profile_photo_s3_key')
        ?.trim();

    if (savedProfilePhotoKey != null && savedProfilePhotoKey.isNotEmpty) {
      profilePhotoS3Key = savedProfilePhotoKey;
      _uploadedImageKey = savedProfilePhotoKey;
    }

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final latitudeText = latitudeController.text.trim();
      final longitudeText = longitudeController.text.trim();

      final double? latitude = latitudeText.isEmpty
          ? null
          : double.tryParse(latitudeText);

      final double? longitude = longitudeText.isEmpty
          ? null
          : double.tryParse(longitudeText);

      debugPrint('====================================');
      debugPrint('🚀 PERSONAL PATCH');
      debugPrint('profile_photo_s3_key: $profilePhotoS3Key');
      debugPrint('====================================');

      // Do NOT send business-only fields here.
      // The API validation already showed these are not
      // allowed for the personal /user endpoint:
      // brand_colors
      // watermark_enabled
      // phone
      // social_links
      // operating_hours

      final result = await UpdateProfileRepository.instance.updatePersonal(
        name: businessNameController.text.trim(),
        industry: industryController.text.trim(),
        profile_photo_s3_key: profilePhotoS3Key.trim().isEmpty
            ? null
            : profilePhotoS3Key.trim(),
        coverS3Key: coverS3Key.trim().isEmpty ? null : coverS3Key.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        address: addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        whatsapp: whatsappController.text.trim(),
        email: emailController.text.trim(),
        website: websiteController.text.trim(),
      );

      bool success = false;

      await result.when(
        success: (data) async {
          success = true;

          debugPrint('====================================');
          debugPrint('✅ PERSONAL PATCH SUCCESS');
          debugPrint('Response: $data');
          debugPrint('====================================');

          // The screen refreshes CommonProvider.me after success.
          // Do not call the Business API for a personal account.

          // Save ONLY after personal API success.
          await prefs.setBool('continue', true);

          debugPrint('✅ continue = true saved');
        },
        failure: (error) {
          success = false;
          saveError = error.message;

          debugPrint(
            '❌ PERSONAL PATCH FAILED: '
            '${error.message}',
          );
        },
      );

      isSaving = false;
      notifyListeners();

      return success;
    } catch (e) {
      isSaving = false;
      saveError = e.toString();

      debugPrint('❌ Personal Update Error: $e');

      notifyListeners();

      return false;
    }
  }

  Future<void> handleProfileImageUpload(String uploadedS3Key) async {
    final key = uploadedS3Key.trim();

    if (key.isEmpty) {
      debugPrint('❌ Uploaded S3 key is empty');
      return;
    }

    final accountType = provider.me?.data.accountType;

    final prefs = await SharedPreferences.getInstance();

    if (accountType == 'business') {
      logoS3Key = key;
      _uploadedImageKey = key;

      await prefs.remove('profile_photo_s3_key');
      await prefs.setString('logo_s3_key', key);

      debugPrint('🏢 BUSINESS → logo_s3_key = $key');
    } else if (accountType == 'personal') {
      profilePhotoS3Key = key;
      _uploadedImageKey = key;

      await prefs.remove('logo_s3_key');
      await prefs.setString('profile_photo_s3_key', key);

      debugPrint('👤 PERSONAL → profile_photo_s3_key = $key');
    } else {
      debugPrint('❌ Unknown account type: $accountType');
      return;
    }

    notifyListeners();
  }

  void setBrandColors(List<Map<String, dynamic>> colors) {
    brandColors = colors;

    notifyListeners();
  }

  void setOperatingHours(Map<String, dynamic> hours) {
    operatingHours = hours;

    notifyListeners();
  }

  void setLogoS3Key(String value) {
    logoS3Key = value;

    _uploadedImageKey = value;

    notifyListeners();
  }

  void setCoverS3Key(String value) {
    coverS3Key = value;

    notifyListeners();
  }

  void setWatermarkEnabled(bool enabled) {
    watermarkEnabled = enabled ? 1 : 0;

    notifyListeners();
  }

  void setHeadingFontId(String? value) {
    headingFontId = value;

    notifyListeners();
  }

  void setBodyFontId(String? value) {
    bodyFontId = value;

    notifyListeners();
  }

  void toggleMoreInfo() {
    isMoreInfoExpanded = !isMoreInfoExpanded;

    notifyListeners();
  }

  void toggleSocial() {
    isSocialExpanded = !isSocialExpanded;

    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();

    businessNameController.dispose();
    industryController.dispose();
    descriptionController.dispose();

    emailController.dispose();
    contactController.dispose();
    whatsappController.dispose();

    altContactController.dispose();
    websiteController.dispose();

    cityController.dispose();
    stateController.dispose();
    addressController.dispose();

    latitudeController.dispose();
    longitudeController.dispose();

    facebookController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    youtubeController.dispose();
    linkedinController.dispose();

    super.dispose();
  }
}
