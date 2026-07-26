import 'package:flutter/material.dart';

class BusinessProfileProvider extends ChangeNotifier {
  String _mobileNumber = "+91 9876543210";
  String get mobileNumber => _mobileNumber;

  void updateMobileNumber(String newNumber) {
    _mobileNumber = newNumber;
    notifyListeners();
  }

  bool _isSolidBanner = true;
  bool get isSolidBanner => _isSolidBanner;

  void toggleBannerStyle(bool isSolid) {
    _isSolidBanner = isSolid;
    notifyListeners();
  }

  int _selectedFrameTab = 0;
  int get selectedFrameTab => _selectedFrameTab;

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
