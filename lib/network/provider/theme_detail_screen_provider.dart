import 'package:flutter/cupertino.dart';

import '../../model/theme_screen_model.dart';

import 'package:flutter/material.dart';

class ThemeDetailProvider extends ChangeNotifier {
  bool isFavorite = false;

  final String themeTitle = "Lemon Buzz-003";
  final String description1 =
      "Bold, bright, and versatile—this theme offers multiple layouts with a consistent yellow-blue combo. Perfect for brands that want to stand out while keeping it professional.";
  final String description2 =
      "Perfect for brands that want to strike a balance between creativity and credibility.";

  final List<String> tags = [
    "Education & Coaching",
    "Startups & Tech",
    "Marketing & Creative Agencies",
    "Fitness & Wellness",
    "Financial Services",
    "Retail & Product brands",
    "Real Estate",
    "Events & Promotions",
    "Freelancers & Consultants",
    "Logistics & Delivery Services",
  ];

  final List<String> templatesList = [
    "assets/images/midnight_reel1.png",
    "assets/images/midnight_reel2.png",
    "assets/images/midnight_reel2.png",
    "assets/images/midnight_reel2.png",
  ];
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
  void toggleFavorite() {
    isFavorite = !isFavorite;
    notifyListeners();
  }
}