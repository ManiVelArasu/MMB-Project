import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/language_model.dart';
import '../../Repository/auth_repository.dart';
import '../../Repository/profile_repository.dart';
import '../../core/api/api_handler.dart';
import '../../model/profile_screen_model.dart';
import 'business_provider.dart';

class ProfileScreenProvider extends ChangeNotifier {
  bool isDarkMode = false;
  bool isWatermarkEnabled = false;
  bool _isLogoutLoading = false;
  bool get isLogoutLoading => _isLogoutLoading;
  LanguageModel? _plansData;
  LanguageModel? get plansData => _plansData;

  String? _plansErrorMessage;
  String? get plansErrorMessage => _plansErrorMessage;
  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  final ProfileRepository _repository = ProfileRepository.instance;
  void toggleWatermark(bool value) {
    isWatermarkEnabled = value;
    notifyListeners();
  }

  final List<QuickActionModel> quickActions = [
    QuickActionModel(
      title: "Business\nProfile",
      iconPath: "assets/images/business_profile.png",
      backgroundColor: const Color(0xFFE0F7FA),
      onTap: (context) {
        Navigator.pushNamed(context, '/BusinessProfileScreen');
      },
    ),
    QuickActionModel(
      title: "My\nDownloads",
      iconPath: "assets/images/my_downloads.png",
      backgroundColor: const Color(0xFFEDE7F6),
      onTap: (context) {
        Navigator.pushNamed(context, "/MyDownloadsScreen");
      },
    ),
    QuickActionModel(
      title: "SM\nCalendar",
      iconPath: "assets/images/sm_calendar.png",
      backgroundColor: const Color(0xFFFFECB3),
      onTap: (context) {
        Navigator.pushNamed(context, "/SmCalendarScreen");
      },
    ),
  ];
  Future<void> logoutApi(BuildContext context) async {
    _isLogoutLoading = true;
    notifyListeners();

    try {
      await AuthRepository.instance.logout();

      if (context.mounted) {
        final businessProvider = Provider.of<BusinessProvider>(
          context,
          listen: false,
        );

        await businessProvider.clearBusinessDataForNewLogin();
      }
      await ApiHandler.instance.clearTokens();

      _isLogoutLoading = false;
      notifyListeners();

      if (!context.mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/LoginScreen", (route) => false);
    } catch (e) {
      _isLogoutLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logout failed. Please try again.")),
        );
      }
    }
  }

  Future<void> fetchLanguage() async {
    notifyListeners();

    try {
      final result = await _repository.getLanguage();

      if (result.isSuccess && result.data != null) {
        _plansData = result.data;
      } else {
        _plansErrorMessage = result.error?.message ?? "Something went wrong";
      }
    } finally {
      notifyListeners();
    }
  }
}
