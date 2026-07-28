import 'package:flutter/material.dart';
import 'package:project_mmb/Repository/theme_repoaitory.dart';

import '../../Api Model/theme_screen_model.dart';
import '../../model/theme_screen_model.dart';

class ThemesScreenProvider extends ChangeNotifier {
  bool _isLoadingPlans = false;
  bool get isLoadingPlans => _isLoadingPlans;

  ThemeGroupResponse? _plansData;
  ThemeGroupResponse? get plansData => _plansData;

  String? _plansErrorMessage;
  String? get plansErrorMessage => _plansErrorMessage;

  final ThemeRepository _repository = ThemeRepository.instance;
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

  List<ThemeGroup> get groups {
    return _plansData?.data ?? [];
  }

  final List<ThemeCardModel> midnightRebelList = [
    ThemeCardModel(
      title: "MIDNIGHT R..",
      templateCount: "8 Templates",
      likesCount: "1.2k",
      imagePath: "assets/images/midnight_reel1.png",
      isPremium: true,
    ),
    ThemeCardModel(
      title: "MIDNIGHT R..",
      templateCount: "8 Templates",
      likesCount: "1.2k",
      imagePath: "assets/images/midnight_reel2.png",
      isPremium: true,
    ),
    ThemeCardModel(
      title: "MIDNIGHT R..",
      templateCount: "8 Templates",
      likesCount: "1.2k",
      imagePath: "assets/images/midnight_reel1.png",
      isPremium: true,
    ),
  ];

  final List<ThemeCardModel> lemonBuzzList = [
    ThemeCardModel(
      title: "MIDNIGHT R..",
      templateCount: "8 Templates",
      likesCount: "1.2k",
      imagePath: "assets/images/midnight_reel1.png",
      isPremium: true,
    ),
    ThemeCardModel(
      title: "MIDNIGHT R..",
      templateCount: "8 Templates",
      likesCount: "1.2k",
      imagePath: "assets/images/midnight_reel2.png",
      isPremium: true,
    ),
    ThemeCardModel(
      title: "MIDNIGHT R..",
      templateCount: "8 Templates",
      likesCount: "1.2k",
      imagePath: "assets/images/midnight_reel1.png",
      isPremium: true,
    ),
  ];
}
