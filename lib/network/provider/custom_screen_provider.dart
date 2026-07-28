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
      subtitle: "Turn your text into\nstunning logos",
      imagePath: 'assets/images/logo_generator.png',

    ),
    AIToolModel(
      title: "Magic Media",
      subtitle: "Elevate your products\nwith unique bgs",
      imagePath: 'assets/images/magic_media.png',
    ),
    AIToolModel(
      title: "BG Remover",
      subtitle: "Remove backgrounds\ninstantly",
      imagePath: 'assets/images/logo_generator.png',
    ),
    AIToolModel(
      title: "AI Image",
      subtitle: "Generate Images\nusing AI",
      imagePath: 'assets/images/magic_media.png',
    ),
    AIToolModel(
      title: "Captions",
      subtitle: "Image-driven\ncaptions!",
      imagePath: 'assets/images/captions.png',
    ),
    AIToolModel(
      title: "SM Calendar",
      subtitle: "Create custom,\nmonthly SM calendars",
      imagePath: 'assets/images/sm.png',
    ),
    AIToolModel(
      title: "Text to Audio",
      subtitle: "Instant High Quality\nHuman Like Voiceover",
      imagePath: 'assets/images/text_audio.png',
    ),
    AIToolModel(
      title: "Translate",
      subtitle: "Translate to multiple\nlanguages",
      imagePath: 'assets/images/translate.png',
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
  Future<void> fetchPlans() async {
    _isLoadingPlans = true;
    _plansErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.industry();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;
      } else {
        _plansErrorMessage = result.error?.message ?? "Something went wrong";
      }
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }
}