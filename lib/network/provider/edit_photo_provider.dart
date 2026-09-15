import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Api Model/me_api.dart';
import '../../Repository/update_profile.dart';
import '../../Repository/image_upload_repository.dart';
import '../../network/provider/getMe_provider.dart';

class EditPhotoProvider extends ChangeNotifier {
  // =========================================================
  // SEARCH
  // =========================================================

  final TextEditingController searchController = TextEditingController();

  // =========================================================
  // BASIC BUSINESS INFO
  // =========================================================

  final TextEditingController businessNameController = TextEditingController();

  final TextEditingController industryController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController contactController = TextEditingController();

  final TextEditingController whatsappController = TextEditingController();

  // =========================================================
  // MORE BUSINESS INFO
  // =========================================================

  final TextEditingController altContactController = TextEditingController();

  final TextEditingController websiteController = TextEditingController();

  final TextEditingController cityController = TextEditingController();

  final TextEditingController stateController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController latitudeController = TextEditingController();

  final TextEditingController longitudeController = TextEditingController();

  // =========================================================
  // SOCIAL
  // =========================================================

  final TextEditingController facebookController = TextEditingController();

  final TextEditingController instagramController = TextEditingController();

  final TextEditingController twitterController = TextEditingController();

  final TextEditingController youtubeController = TextEditingController();

  final TextEditingController linkedinController = TextEditingController();

  // =========================================================
  // BUSINESS UID
  // =========================================================

  String? _businessUid;

  String? get businessUid => _businessUid;

  // =========================================================
  // API FIELDS
  // =========================================================

  String logoS3Key = '';

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



  // =========================================================
  // GETME DATA
  // =========================================================

  void setGetMeData(Language me) {
    _businessUid = me.data.uid;

    businessNameController.text = me.data.name ?? '';
    emailController.text = me.data.email ?? '';
    contactController.text = me.data.phone ?? '';
    final profileKey = me.data.profilePhotoS3Key;
    if (profileKey != null && profileKey.isNotEmpty) {
      logoS3Key = profileKey;
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

      // Show selected image immediately
      _selectedImage = imageFile;

      _isUploadingImage = true;
      _imageUploadError = null;
      _uploadedImageKey = null;

      notifyListeners();

      final filename = imageFile.path.split(Platform.pathSeparator).last;

      debugPrint('📷 Uploading image: $filename');



      final uploadResult = await MediaUploadRepository.instance
          .uploadImageAndConfirm(
        imageFile: imageFile,
        filename: filename,
        width: 1080,
        height: 1080,
      );

      bool success = false;

      await uploadResult.when(
        success: (data) {
          final key = data['key']?.toString();

          if (key != null && key.isNotEmpty) {
            _uploadedImageKey = key;


            logoS3Key = key;

            success = true;

            debugPrint('✅ Image upload success');

            debugPrint('✅ Logo S3 Key: $key');
          } else {
            _imageUploadError = 'Image uploaded but S3 key not found';
          }
        },

        failure: (error) {
          _imageUploadError = error.message;

          debugPrint(
            '❌ Image upload failed: '
                '${error.message}',
          );
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
    logoS3Key = '';
    _imageUploadError = null;

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


  Future<bool> saveBusinessDetails({required String businessUid}) async {
    if (businessUid.trim().isEmpty) {
      saveError = 'Business UID not found';

      notifyListeners();

      return false;
    }


    if (_isUploadingImage) {
      saveError = 'Please wait for image upload to finish';

      notifyListeners();

      return false;
    }

    isSaving = true;

    saveError = null;

    notifyListeners();

    try {


      final latitudeText = latitudeController.text.trim();

      final double? latitude = latitudeText.isEmpty
          ? null
          : double.tryParse(latitudeText);


      final longitudeText = longitudeController.text.trim();

      final double? longitude = longitudeText.isEmpty
          ? null
          : double.tryParse(longitudeText);



      final updatedSocialLinks = buildSocialLinks();

      socialLinks = updatedSocialLinks;


      debugPrint('====================================');

      debugPrint('🚀 BUSINESS PATCH');

      debugPrint('UID: $businessUid');

      debugPrint('Logo S3 Key: $logoS3Key');

      debugPrint('====================================');



      await UpdateProfileRepository.instance.updateBusinessDetails(
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

      isSaving = false;

      notifyListeners();

      return true;
    } catch (e) {
      saveError = e.toString();

      debugPrint('❌ Update Business Error: $e');

      isSaving = false;

      notifyListeners();

      return false;
    }
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
