import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

class AiHubProvider extends ChangeNotifier {
  // ---------------- CONTENT GENERATOR ----------------

  final TextEditingController promptController = TextEditingController();

  final List<String> suggestions = const [
    'Instagram post for Diwali jewellery sale with 20% off',
    'Product description for a handmade leather wallet',
    'Catchy tagline for my new gym opening',
  ];

  String tone = 'Tone';
  String language = 'Language';
  String generatedContent = '';
  bool isGenerating = false;
  int selectedBottomIndex = 0;

  int get creditsAvailable => availableCredits;
  int get creditsUsed => creditsPerImage;

  bool get hasGeneratedContent => generatedContent.isNotEmpty;

  void setTone(String value) {
    tone = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void setPrompt(String value) {
    promptController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    notifyListeners();
  }

  void selectSuggestion(String value) {
    setPrompt(value);
  }

  Future<void> generateContent() async {
    if (promptController.text.trim().isEmpty || isGenerating) {
      return;
    }

    isGenerating = true;
    notifyListeners();

    try {
      // TODO: Connect your content-generation API.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final prompt = promptController.text.trim().toLowerCase();

      if (prompt.contains('diwali') || prompt.contains('jewellery')) {
        generatedContent =
        '"Make this Diwali shine brighter with our '
            'exclusive jewellery collection. Enjoy 20% off '
            'selected designs — for a limited time only. ✨"';
      } else {
        generatedContent =
        'Bring your idea to life! '
            '${promptController.text.trim()} '
            '— crafted with care to help your brand stand out.';
      }
    } catch (e) {
      errorMessage = 'Content generation failed.';
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  void updateGeneratedContent(String value) {
    generatedContent = value;
    notifyListeners();
  }

  Future<void> regenerateContent() async {
    await generateContent();
  }

  // ---------------- IMAGE GENERATOR ----------------

  final TextEditingController promptImageController = TextEditingController(
    text:
    'A premium coffee shop interior with warm lighting, '
        'modern furniture and a cup of cappuccino on the table',
  );

  String selectedStyle = 'Realistic';
  String selectedRatio = '1:1';
  String selectedImageLanguage = 'English';
  String selectedCategory = 'Promotional';

  bool isGeneratingImage = false;
  String? generatedImageUrl;
  String? errorMessage;

  int availableCredits = 20;
  final int creditsPerImage = 6;

  final List<String> styles = const [
    'Realistic',
    'Anime',
    '3D Render',
    'Minimalist',
    'Cinematic',
  ];

  final List<String> ratios = const ['1:1', '16:9', '9:16', '4:3'];

  final List<String> languages = const ['English', 'Tamil', 'Hindi'];

  final List<String> categories = const [
    'Promotional',
    'Social Media',
    'Business',
    'Product',
  ];

  bool get hasGeneratedImage =>
      generatedImageUrl != null && generatedImageUrl!.isNotEmpty;

  void updateImagePrompt(String value) {
    promptImageController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    notifyListeners();
  }

  void updateStyle(String? value) {
    if (value == null) return;
    selectedStyle = value;
    notifyListeners();
  }

  void updateRatio(String? value) {
    if (value == null) return;
    selectedRatio = value;
    notifyListeners();
  }

  void updateImageLanguage(String? value) {
    if (value == null) return;
    selectedImageLanguage = value;
    notifyListeners();
  }

  void updateCategory(String? value) {
    if (value == null) return;
    selectedCategory = value;
    notifyListeners();
  }

  void useImageSuggestion(String suggestion) {
    updateImagePrompt(suggestion);
  }

  Future<bool> generateImage() async {
    if (promptImageController.text.trim().isEmpty) {
      errorMessage = 'Please enter an image prompt.';
      notifyListeners();
      return false;
    }

    if (isGeneratingImage) return false;

    if (availableCredits < creditsPerImage) {
      errorMessage = 'Not enough AI credits.';
      notifyListeners();
      return false;
    }

    isGeneratingImage = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace this demo with your actual image API.
      // Send promptImageController.text, selectedStyle,
      // selectedRatio, selectedImageLanguage and selectedCategory.
      await Future<void>.delayed(const Duration(seconds: 2));

      // Demo image only; this is NOT AI-generated.
      generatedImageUrl =
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24'
          '?auto=format&fit=crop&w=1000&q=85';

      availableCredits -= creditsPerImage;
      return true;
    } catch (e) {
      errorMessage = 'Image generation failed. Please try again.';
      return false;
    } finally {
      isGeneratingImage = false;
      notifyListeners();
    }
  }

  Future<bool> regenerateImage() async {
    return generateImage();
  }


  // ---------------- REMOVE BACKGROUND ----------------

  File? selectedBgImage;
  File? removedBgImage;
  bool isRemovingBackground = false;
  String? bgErrorMessage;

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickBackgroundImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      bgErrorMessage = null;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile == null) return;

      selectedBgImage = File(pickedFile.path);
      removedBgImage = null;

      notifyListeners();
    } catch (e) {
      bgErrorMessage = 'Unable to select image.';
      notifyListeners();
    }
  }

  void clearBackgroundImage() {
    selectedBgImage = null;
    removedBgImage = null;
    bgErrorMessage = null;
    notifyListeners();
  }

  Future<bool> removeImageBackground() async {
    if (selectedBgImage == null) {
      bgErrorMessage = 'Please select an image first.';
      notifyListeners();
      return false;
    }

    if (isRemovingBackground) return false;

    isRemovingBackground = true;
    bgErrorMessage = null;
    notifyListeners();

    try {
      // TODO: Connect a real background-removal API here.
      //
      // Send selectedBgImage to your API as multipart/form-data.
      // Save the returned transparent PNG to removedBgImage.
      //
      // Do not assign selectedBgImage to removedBgImage:
      // that would display the original image, not a removed background.

      bgErrorMessage =
      'Connect a background-removal API to process this image.';

      return false;
    } catch (e) {
      bgErrorMessage = 'Background removal failed.';
      return false;
    } finally {
      isRemovingBackground = false;
      notifyListeners();
    }
  }

  Future<void> downloadRemovedBackground() async {
    if (removedBgImage == null) {
      bgErrorMessage = 'No processed image available.';
      notifyListeners();
      return;
    }

    // The processed PNG is already a local file.
    // Copy/export it to a user-accessible gallery or downloads folder
    // using the appropriate platform-specific implementation.
  }


  void clearImageResult() {
    generatedImageUrl = null;
    errorMessage = null;
    notifyListeners();
  }


  // ---------------- TEXT TO VOICE ----------------

  final TextEditingController textToVoiceController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  String voiceLanguage = 'English';
  String voiceGender = 'Male';
  String voiceStyle = 'Energetic';
  bool isConvertingVoice = false;
  bool isSpeakingVoice = false;
  String? voiceErrorMessage;
  bool hasVoiceResult = false;

  final List<String> voiceLanguages = const ['English', 'Tamil', 'Hindi'];
  final List<String> voiceGenders = const ['Male', 'Female'];
  final List<String> voiceStyles = const [
    'Energetic', 'Calm', 'Friendly', 'Professional'
  ];

  void setVoiceLanguage(String? value) {
    if (value == null) return;
    voiceLanguage = value;
    notifyListeners();
  }


  void setVoiceGender(String? value) {
    if (value == null) return;
    voiceGender = value;
    notifyListeners();
  }

  void setVoiceStyle(String? value) {
    if (value == null) return;
    voiceStyle = value;
    notifyListeners();
  }

  void setVoiceText(String value) {
    voiceErrorMessage = null;
    hasVoiceResult = false;
    notifyListeners();
  }

  Future<bool> generateVoice() async {
    final text = textToVoiceController.text.trim();
    if (text.isEmpty) {
      voiceErrorMessage = 'Please enter text to convert to voice.';
      notifyListeners();
      return false;
    }
    if (isConvertingVoice) return false;

    isConvertingVoice = true;
    voiceErrorMessage = null;
    notifyListeners();

    try {
      await _flutterTts.stop();
      final locale = switch (voiceLanguage) {
        'Tamil' => 'ta-IN',
        'Hindi' => 'hi-IN',
        _ => 'en-US',
      };
      await _flutterTts.setLanguage(locale);
      await _flutterTts.setSpeechRate(switch (voiceStyle) {
        'Calm' => 0.38,
        'Professional' => 0.45,
        'Friendly' => 0.48,
        _ => 0.55,
      });
      await _flutterTts.setPitch(voiceGender == 'Female' ? 1.25 : 0.85);
      _flutterTts.setStartHandler(() {
        isSpeakingVoice = true;
        notifyListeners();
      });
      _flutterTts.setCompletionHandler(() {
        isSpeakingVoice = false;
        notifyListeners();
      });
      _flutterTts.setCancelHandler(() {
        isSpeakingVoice = false;
        notifyListeners();
      });
      _flutterTts.setErrorHandler((message) {
        isSpeakingVoice = false;
        voiceErrorMessage = 'Voice playback failed: $message';
        notifyListeners();
      });

      hasVoiceResult = true;
      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      voiceErrorMessage = 'Unable to convert text to voice: $e';
      hasVoiceResult = false;
      return false;
    } finally {
      isConvertingVoice = false;
      notifyListeners();
    }
  }

  Future<void> playVoice() async {
    final text = textToVoiceController.text.trim();
    if (text.isEmpty) return;
    if (isSpeakingVoice) {
      await _flutterTts.stop();
      isSpeakingVoice = false;
      notifyListeners();
    } else {
      await generateVoice();
    }
  }

  Future<void> stopVoice() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
  Future<void> regenerateVoice() async {
    await generateVoice();
  }

  Future<void> downloadVoice() async {
    voiceErrorMessage =
    'To download an audio file, connect a TTS API that returns an audio file URL.';
    notifyListeners();
  }


  // ---------------- BOTTOM NAVIGATION ----------------

  void selectBottomItem(int index) {
    selectedBottomIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    promptController.dispose();
    promptImageController.dispose();
    textToVoiceController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
