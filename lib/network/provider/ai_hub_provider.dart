import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../Repository/ai_repository.dart';
import '../../Repository/image_upload_repository.dart';
import '../../core/api/api_endpoints.dart';

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

  /// Shown on the button: "UPLOADING IMAGE..." / "REMOVING BACKGROUND..."
  String bgStatus = '';

  /// Credits for one background removal (from GET ai/operations).
  int? bgCredits;

  Future<void> loadAiOperations() async {
    try {
      final result = await AiRepository.instance.operations();
      if (!result.isSuccess) return;
      debugPrint('AI operations: ${result.data}');

      final op = _findMap(
        result.data,
            (m) => m.values.any((v) => v == 'ai_bg_remover'),
      );
      final cost =
          op?['credits'] ?? op?['credit_cost'] ?? op?['credits_required'];
      bgCredits = int.tryParse('${cost ?? ''}');
      notifyListeners();
    } catch (e) {
      debugPrint('AI operations error: $e');
    }
  }

  /// upload (presign -> PUT -> confirm) -> ai_bg_remover -> poll job
  Future<bool> removeImageBackground() async {
    final image = selectedBgImage;
    if (image == null) {
      bgErrorMessage = 'Please select an image first.';
      notifyListeners();
      return false;
    }

    if (isRemovingBackground) return false;

    isRemovingBackground = true;
    removedBgImage = null;
    bgErrorMessage = null;
    bgStatus = 'UPLOADING IMAGE...';
    notifyListeners();

    try {
      if (await image.length() > 10 * 1024 * 1024) {
        throw const _BgError('Image must be smaller than 10MB.');
      }

      // 1. uploads/presign -> S3 PUT -> uploads/confirm
      final upload = await _uploadBgImage(image);

      // 2. the API wants the GUID of the upload: take it from the confirm
      //    response, otherwise from uploads?slot=media_library
      var uploadUid = _uploadUid(upload.data, upload.key);
      if (uploadUid.isEmpty) {
        final library = await AiRepository.instance.mediaLibrary();
        debugPrint('BG library: ${library.data}');
        uploadUid = _uploadUid(library.data, upload.key);
      }
      if (uploadUid.isEmpty) {
        throw const _BgError('Uploaded image id not found.');
      }
      if (_isStale(image)) return false;

      // 3. ai/operations/ai_bg_remover
      bgStatus = 'REMOVING BACKGROUND...';
      notifyListeners();

      final start = await AiRepository.instance.removeBackground(uploadUid);
      if (!start.isSuccess) {
        throw _BgError(start.error?.message ?? 'Unable to start AI job.');
      }
      debugPrint('BG remove start: ${start.data}');

      final jobId = _jobId(start.data);
      if (jobId.isEmpty) throw const _BgError('Job id not found.');

      // 4. jobs/{id} until finished
      final output = await _waitForJob(jobId, image);
      if (output == null) return false;

      // 5. download the transparent PNG
      final file = await _downloadResult(output);
      if (_isStale(image)) return false;

      removedBgImage = file;
      if (bgCredits != null) availableCredits -= bgCredits!;
      return true;
    } on _BgError catch (e) {
      if (!_isStale(image)) bgErrorMessage = e.message;
      return false;
    } catch (e, stackTrace) {
      debugPrint('Background removal error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!_isStale(image)) bgErrorMessage = 'Background removal failed.';
      return false;
    } finally {
      isRemovingBackground = false;
      bgStatus = '';
      notifyListeners();
    }
  }

  /// The user left the page or picked / cleared the image meanwhile.
  bool _isStale(File image) => _disposed || selectedBgImage != image;

  Future<({String key, dynamic data})> _uploadBgImage(File image) async {
    final decoded = await decodeImageFromList(await image.readAsBytes());
    final width = decoded.width;
    final height = decoded.height;
    decoded.dispose();

    final result = await MediaUploadRepository.instance.uploadImageAndConfirm(
      imageFile: image,
      filename: image.path.split(Platform.pathSeparator).last,
      width: width,
      height: height,
      slot: 'media_library',
    );

    String? key;
    String? error;
    dynamic body;

    await result.when(
      success: (data) async {
        debugPrint('BG upload: $data');
        body = data;
        key = _findMap(data, (m) => '${m['key'] ?? ''}'.isNotEmpty)?['key']
            ?.toString();
      },
      failure: (e) => error = e.message,
    );

    if (key == null) throw _BgError(error ?? 'Image upload failed.');
    return (key: key!, data: body);
  }

  static final RegExp _guid = RegExp(
    r'^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$',
  );

  /// GUID of the upload whose record contains [key] ('' if not found).
  String _uploadUid(dynamic body, String key) {
    String idOf(Map m) {
      for (final name in const ['upload_uid', 'uid', 'uuid', 'id']) {
        final value = '${m[name] ?? ''}';
        if (_guid.hasMatch(value)) return value;
      }
      return '';
    }

    final record = _findMap(
      body,
          (m) =>
      idOf(m).isNotEmpty &&
          m.values.any((v) => v is String && v.contains(key)),
    );
    if (record != null) return idOf(record);

    // response with an explicit upload_uid but without the key
    final direct = _findMap(
      body,
          (m) => _guid.hasMatch('${m['upload_uid'] ?? ''}'),
    );
    return '${direct?['upload_uid'] ?? ''}';
  }

  String _jobId(dynamic body) {
    final map =
        _findMap(body, (m) => m['job_uid'] != null || m['job_id'] != null) ??
            _findMap(body, (m) => m['uid'] != null || m['id'] != null);
    if (map == null) return '';
    return '${map['job_uid'] ?? map['job_id'] ?? map['uid'] ?? map['id']}';
  }

  /// Polls every 2 seconds (max 2 minutes). Returns the output url / key,
  /// or null when the request is no longer needed.
  Future<String?> _waitForJob(String jobId, File image) async {
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_isStale(image)) return null;

      final result = await AiRepository.instance.job(jobId);
      if (!result.isSuccess) {
        throw _BgError(result.error?.message ?? 'Unable to check the job.');
      }
      debugPrint('BG job: ${result.data}');

      final job = _findMap(result.data, (m) => m['status'] is String);
      final status = '${job?['status'] ?? ''}'.toLowerCase();

      if (const ['failed', 'error', 'cancelled'].contains(status)) {
        throw _BgError(
          '${job?['error_message'] ?? 'Background removal failed.'}',
        );
      }
      if (const [
        'completed',
        'complete',
        'succeeded',
        'success',
        'done',
      ].contains(status)) {
        final output = _outputOf(job!);
        if (output == null) throw const _BgError('Result image not found.');
        return output;
      }
    }
    throw const _BgError('Timed out. Please try again.');
  }

  /// Result image of a finished job: looks only at output / result fields,
  /// so the input image is never picked.
  String? _outputOf(Map job) {
    for (final name in const [
      'output_url',
      'result_url',
      'output_s3_key',
      'result_s3_key',
      'output',
      'outputs',
      'result',
      'results',
    ]) {
      final found = _firstImage(job[name]);
      if (found != null) return found;
    }
    return null;
  }

  String? _firstImage(dynamic value) {
    if (value is String) {
      final path = value.split('?').first.toLowerCase();
      final isImage = RegExp(r'\.(png|jpe?g|webp)$').hasMatch(path);
      return value.startsWith('http') || isImage ? value : null;
    }
    final children = value is Map
        ? value.values
        : (value is List ? value : const []);
    for (final child in children) {
      final found = _firstImage(child);
      if (found != null) return found;
    }
    return null;
  }

  /// First map (depth first) matching [test].
  Map? _findMap(dynamic value, bool Function(Map) test) {
    if (value is Map && test(value)) return value;
    final children = value is Map
        ? value.values
        : (value is List ? value : const []);
    for (final child in children) {
      final found = _findMap(child, test);
      if (found != null) return found;
    }
    return null;
  }

  Future<File> _downloadResult(String output) async {
    final url = output.startsWith('http')
        ? output
        : '${ApiEndpoints.cdnImageUrl}/$output';

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw _BgError('Unable to load result (${response.statusCode}).');
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      return file.writeAsBytes(bytes, flush: true);
    } finally {
      client.close();
    }
  }

  /// Saves the result to the gallery. Returns true on success.
  Future<bool> downloadRemovedBackground() async {
    final image = removedBgImage;
    if (image == null) {
      bgErrorMessage = 'No processed image available.';
      notifyListeners();
      return false;
    }

    try {
      await Gal.putImage(image.path);
      return true;
    } catch (e) {
      debugPrint('Save to gallery error: $e');
      bgErrorMessage = 'Unable to save the image.';
      notifyListeners();
      return false;
    }
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

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    promptController.dispose();
    promptImageController.dispose();
    textToVoiceController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}

class _BgError implements Exception {
  const _BgError(this.message);

  final String message;
}