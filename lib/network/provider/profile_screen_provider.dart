import 'package:flutter/material.dart';
import 'package:mmb_app/network/provider/common_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/language_model.dart';
import '../../Repository/auth_repository.dart';
import '../../Repository/profile_repository.dart';
import '../../core/api/api_handler.dart';
import '../../model/profile_screen_model.dart';
import '../../ui/screens/profile_screen.dart';
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
  bool _isDeactivateLoading = false;

  bool get isDeactivateLoading => _isDeactivateLoading;
  final CommonProvider provider = CommonProvider.instance;

  Future<bool> deactivateAccount() async {
    _isDeactivateLoading = true;
    notifyListeners();

    try {
      final result = await _repository.accountDeactivate();

      if (result.isSuccess) {
        debugPrint("✅ Account deactivate API success");

        _isDeactivateLoading = false;
        notifyListeners();

        return true;
      }

      debugPrint(
        "❌ Account deactivate failed: "
        "${result.error?.message}",
      );

      _isDeactivateLoading = false;
      notifyListeners();

      return false;
    } catch (e) {
      debugPrint("❌ Account deactivate error: $e");

      _isDeactivateLoading = false;
      notifyListeners();

      return false;
    }
  }

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
      iconPath: "assets/images/personalcard.png",
      backgroundColor: const Color(0xFFE0F7FA),
      onTap: (context) {
        Navigator.pushNamed(context, '/BusinessProfileScreen');
      },
    ),
    QuickActionModel(
      title: "My\nDownloads",
      iconPath: "assets/images/document-download.png",
      backgroundColor: const Color(0xFFEDE7F6),
      onTap: (context) {
        Navigator.pushNamed(context, "/MyDownloadsScreen");
      },
    ),
    QuickActionModel(
      title: "Festival\n Post",
      iconPath: "assets/images/festival_calender.png",
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

  Future<void> showDeactivateDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Account?",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            "Are you sure you want to delete your account?\n\n"
            "Your account will be permanently deleted within 24 hours.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                clearUserSession(context);
                Navigator.pop(dialogContext, false);
              },
              child: const Text("NO", style: TextStyle(color: Colors.grey)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _isDeactivateLoading
                  ? null
                  : () {
                      Navigator.pop(dialogContext, true);
                    },
              child: const Text("YES", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await deactivateAccount();

    if (!context.mounted) return;

    if (success) {
      // Clear local data
      await ApiHandler.instance.clearTokens();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account deletion requested. Your account will be deleted within 24 hours.",
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));

      if (!context.mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/LoginScreen", (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to delete account. Please try again."),
        ),
      );
    }
  }
}
