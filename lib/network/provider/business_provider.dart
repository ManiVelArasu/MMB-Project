// FIXED BUSINESS PROVIDER - Correct Logic Version
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_mmb/ui/industry/widgets/bg_remove_sheet.dart';

class BusinessProvider extends ChangeNotifier {
  BusinessProvider() {
    requestPermissionIfNeeded();
  }

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
  static const platform = MethodChannel('com.mobile.mmb.project_mmb/background_removal');
bool _isImageSelected =false;
  Uint8List? _processedImageBytes;
  bool _isProcessingBackground = false;


  // LIVE PREVIEW variables
  double _liveRotationAngle = 0.0;
  double _liveScaleValue = 1.0;

  ///get method
  int get currentIndex => _currentIndex;
  File? get selectedImage => _selectedImage;
  File? get originalImage =>_originalImage;
  String get businessName => _businessName;
  String get email => _email;
  String get mobileNumber => _mobileNumber;
  String get selectedTool => _selectedTool;
  String get selectedAspect => _selectedAspect;
  double get rotationAngle => _liveRotationAngle;
  double get scaleValue => _liveScaleValue;
  bool get isApplied => _isApplied;
  bool get hasChanges => _hasChanges;
  Uint8List? get processedImageBytes => _processedImageBytes; // NEW: Getter for processed image
  bool get isProcessingBackground => _isProcessingBackground; // NEW: Getter for processing state
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

// UPDATED SETTERS WITH AUTO ERROR CLEARING
  void setBusinessName(String value) {
    _businessName = value;
    _nameError = null; // Error reset on typing
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    _emailError = null; // Error reset on typing
    notifyListeners();
  }

  void setMobileNumber(String value) {
    _mobileNumber = value;
    _mobileError = null; // Error reset on typing
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

    // 4. Contact Number Validation
    if (_mobileNumber.trim().isEmpty) {
      _mobileError = "Contact number is required";
      isValid = false;
    } else if (_mobileNumber.trim().length < 10) {
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
    _processedImageBytes = null; // NEW: Clear processed image when new image selected
    _isProcessingBackground = false;
    notifyListeners();
  }

  void setSelectedTool(String tool) {
    _selectedTool = tool;
    _resetLivePreview(); // Reset preview when switching tools
    _hasChanges = false; // Reset changes when switching tools
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
    _processedImageBytes = null; // NEW: Clear processed image
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
    final sdkInt = androidInfo.version.sdkInt ?? 0;
    if (sdkInt >= 33) {
      final status = await Permission.photos.request();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> pickImage(
      BuildContext context, {
        ImageSource source = ImageSource.gallery,
      }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90, // Optional: Good quality photo capture
      );

      if (image != null) {
        selectedImage = File(image.path);
        notifyListeners();

        if (context.mounted) {
          Navigator.pop(context);

          await Future.delayed(const Duration(milliseconds: 200));

          if (context.mounted) {
            Navigator.pushNamed(context, "/EditPhotoScreen");
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }
  List<AccTypeModel> accountTypeList = [
    AccTypeModel(
      title: "For my Business",
      description: "Find business category that matches your Products/Services",
    ),
    AccTypeModel(
      title: "Personal Use",
      description:
      "Find Special Occasions, Daily Quotes, Funny Posts to build your social media face",
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

  final List<String> businessCategories = [
    "Real Estate",
    "Electrical",
    "Mobile Store",
    "Tour and Travels",
    "Automobile",
    "Construction",
    "Clothing & Fashion",
    "Hospitality",
    "Food & Beverage",
    "IT Services",
    "Hardware Store",
    "Furniture",
    "Medical & Pharmacy",
    "Education",
    "Beauty & Wellness",
    "Grocery Store",
    "Home Appliances",
    "Jewellery",
    "Photography",
    "Logistics",
    "Sports & Fitness",
    "Pet Store",
  ];

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

      // Move to center, rotate, then draw
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

        // Clean up old image if it's in temp directory
        if (_selectedImage!.path.contains('temp')) {
          try {
            await _selectedImage!.delete();
          } catch (e) {
            debugPrint("Error deleting old image: $e");
          }
        }

        _selectedImage = file;
        _resetLivePreview(); // Reset to 0° after applying
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

        // Clean up old image if it's in temp directory
        if (_selectedImage!.path.contains('temp')) {
          try {
            await _selectedImage!.delete();
          } catch (e) {
            debugPrint("Error deleting old image: $e");
          }
        }

        _selectedImage = file;
        _resetLivePreview(); // IMPORTANT: Reset scale to 1.0 after applying
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

  void bgRemoveSheet(BuildContext context) {
    if (_selectedImage == null) {
      debugPrint("No image selected for background removal");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: BgRemoveSheet(),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up any temp files when provider is disposed
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
        // Convert bytes back to File and update _selectedImage
        final dir = await getTemporaryDirectory();
        final fileName = 'bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';
        final processedFile = File('${dir.path}/$fileName');
        await processedFile.writeAsBytes(result);

        // Clean up old image if it's in temp directory
        if (_selectedImage!.path.contains('temp')) {
          try {
            await _selectedImage!.delete();
          } catch (e) {
            debugPrint("Error deleting old image: $e");
          }
        }

        // Update _selectedImage with processed image (as requested)
        _selectedImage = processedFile;
        _processedImageBytes = result;
        _resetLivePreview();
        _isApplied = true;
        _hasChanges = false;
        _isProcessingBackground = false;
        notifyListeners();

        debugPrint("Background removed successfully and _selectedImage updated");
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

  // NEW: Method to apply processed image bytes directly to _selectedImage (alternative)
  Future<bool> applyProcessedImageToSelected() async {
    if (_processedImageBytes == null) return false;

    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'applied_bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';
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



}

class AccTypeModel {
  final String title;
  final String description;

  AccTypeModel({required this.title, required this.description});
}