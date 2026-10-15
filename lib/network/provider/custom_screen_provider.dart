import 'package:flutter/material.dart';
import '../../Api Model/template_size_model.dart';
import '../../Repository/custom_theme_repository.dart';
import '../../model/custom_screen_model.dart';

class CustomScreenProvider extends ChangeNotifier {
  // 1. Create Your Own Canvas Ratios Data List
  final List<CanvasRatioModel> canvasRatios = [
    CanvasRatioModel(
      title: "POST",
      dimension: "1080X1080",
      imagePath: "assets/images/1080.png",
    ),
    CanvasRatioModel(
      title: "PORTRAIT",
      dimension: "1080X1440",
      imagePath: "assets/images/post_1440.png",
    ),
    CanvasRatioModel(
      title: "STORY/REEL",
      dimension: "1080X1920",
      imagePath: "assets/images/post_1920.png",
    ),
    CanvasRatioModel(
      title: "LANDSCAPE",
      dimension: "1080X566",
      imagePath: "assets/images/post_566.png",
    ),
  ];

  // 2. Generate with AI Tools Data List
  final List<AIToolModel> aiToolsList = [
    AIToolModel(
      title: "Logo Generator",
      subtitle: "Create professional logos in seconds",
      imagePath: 'assets/images/ai.png',
      routeName: "/LogoGeneratorScreen",
    ),
    AIToolModel(
      title: "Magic Media",
      subtitle: "Create product backgrounds with AI",
      imagePath: 'assets/images/ai_image.png',
      routeName: "/MagicMediaScreen",
    ),
    AIToolModel(
      title: "BG Remover",
      subtitle: "Remove backgrounds\ninstantly",
      imagePath: 'assets/images/bg_remover.png',
      routeName: "/AiRemoveBg",
    ),
    AIToolModel(
      title: "AI Image",
      subtitle: "Generate Images\nusing AI",
      imagePath: 'assets/images/magic_media.png',
      routeName: "/AiHubPage",
    ),
    AIToolModel(
      title: "Captions",
      subtitle: "Generate engaging captions",
      imagePath: 'assets/images/caption.png',
      routeName: "/CaptionsScreen",
    ),
    AIToolModel(
      title: "SM Calendar",
      subtitle: "Generate monthly content calendars",
      imagePath: 'assets/images/sm_calender.png',
      routeName: "/SocialCalendarFormScreen",
    ),
    AIToolModel(
      title: "Text to Audio",
      subtitle: "Convert text into natural AI voiceovers",
      imagePath: 'assets/images/text_to_audio.png',
      routeName: "/TextToAudioScreen",
    ),
    AIToolModel(
      title: "Translate",
      subtitle: "Translate to multiple\nlanguages",
      imagePath: 'assets/images/translate.png',
      routeName: "/AiHubScreen",
    ),
  ];

  int selectedCanvasIndex = 0;

  void selectCanvas(int index) {
    selectedCanvasIndex = index;
    notifyListeners();
  }

  final CustomThemeRepository _repository = CustomThemeRepository.instance;

  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  TemplateSizeModel? _plansData;
  TemplateSizeModel? get plansData => _plansData;

  String? _plansErrorMessage;
  String? get plansErrorMessage => _plansErrorMessage;
  Future<void> fetchPlans({bool forceRefresh = false}) async {
    if (_isLoadingPlans) return;
    if (_plansData != null && !forceRefresh) return;

    // Show the full-screen loader only for the first load.
    // During refresh, keep the existing data visible without loading UI.
    final bool hasExistingData = _plansData != null;
    if (!hasExistingData) {
      _isLoadingPlans = true;
      notifyListeners();
    }
    _plansErrorMessage = null;

    try {
      final result = await _repository.industry();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;
        _plansErrorMessage = null;
      } else {
        // Preserve the previous data if a background refresh fails.
        if (_plansData == null) {
          _plansErrorMessage = result.error?.message ?? 'Something went wrong';
        }
      }
    } catch (e) {
      // Do not replace an already-rendered screen with an error during refresh.
      if (_plansData == null) {
        _plansErrorMessage = e.toString();
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchPlans(forceRefresh: true);
  }
}
