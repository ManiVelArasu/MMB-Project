import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import 'common_provider.dart';

class BusinessProfileProvider extends ChangeNotifier {
  BusinessProfileProvider() {
    loadSavedBusinessName();
    loadKeyWords();
  }

  String _mobileNumber = "+91 9876543210";
  String get mobileNumber => _mobileNumber;

  List<KeyWordsData> _keyWords = [];

  List<KeyWordsData> get keyWords => _keyWords;

  bool _isKeyWordsLoading = false;
  bool get isKeyWordsLoading => _isKeyWordsLoading;

  String? _keyWordsError;
  String? get keyWordsError => _keyWordsError;
  final CommonProvider commonProvider = CommonProvider.instance;
  final BusinessProfileRepository businessProfileRepository =
      BusinessProfileRepository.instance;

  void updateMobileNumber(String newNumber) {
    _mobileNumber = newNumber;
    notifyListeners();
  }

  Future<bool> loadKeyWords({bool forceRefresh = false}) async {
    if (_keyWords.isNotEmpty && !forceRefresh) {
      return true;
    }

    _isKeyWordsLoading = true;
    _keyWordsError = null;
    notifyListeners();

    try {
      final result = await businessProfileRepository.industryKeyWords(
        commonProvider.business?.businessCategory?.parent?.slug ?? '',
      );

      final KeyWordsModel? data = result.data;

      if (data == null) {
        _keyWordsError = "Keywords data not found";
        return false;
      }
      _keyWords = data.data;

      debugPrint("================================");
      debugPrint("✅ KEYWORDS API SUCCESS");
      debugPrint("Total Keywords : ${_keyWords.length}");

      for (final keyword in _keyWords) {
        debugPrint("Keyword : ${keyword.name} | Slug : ${keyword.slug}");
      }

      debugPrint("================================");

      return true;
    } catch (e, stackTrace) {
      _keyWordsError = e.toString();

      debugPrint("❌ Keywords API failed: $e");
      debugPrint("$stackTrace");

      return false;
    } finally {
      _isKeyWordsLoading = false;
      notifyListeners();
    }
  }

  bool _isSolidBanner = true;
  bool get isSolidBanner => _isSolidBanner;

  void toggleBannerStyle(bool isSolid) {
    _isSolidBanner = isSolid;
    notifyListeners();
  }

  int _selectedFrameTab = 0;
  int get selectedFrameTab => _selectedFrameTab;

  String _businessName = "";

  String get businessName => _businessName;

  Future<void> loadSavedBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    _businessName = prefs.getString('saved_business_name') ?? "";
    notifyListeners();
  }

  void setBusinessName(String name) {
    _businessName = name;
    notifyListeners();
  }

  void updateFrameTab(int index) {
    _selectedFrameTab = index;
    notifyListeners();
  }

  final List<Map<String, String>> _staticFrames = [
    {"price": "Free", "type": "outline"},
    {"price": "Rs.0 (Rs.100 Unlocked)", "type": "solid"},
    {"price": "Free", "type": "outline"},
  ];

  List<Map<String, String>> get staticFrames => _staticFrames;

  final List<String> _keywords = [
    "Cakes",
    "Cookies",
    "Smoothie",
    "Brownies",
    "Cupcakes",
    "Muffins",
    "Birthday Special",
    "Sweets",
    "Today Special",
    "Wedding Special",
  ];

  List<String> get keywords => _keywords;
}
