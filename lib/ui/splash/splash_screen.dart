import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Repository/get_me_repository.dart';
import '../../core/api/api_handler.dart';
import '../../network/provider/getMe_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatusAndNavigate();
  }

  Future<void> _checkUserStatusAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();

    final bool isLoggedIn =
        prefs.getBool('is_logged_in') ?? false;

    final bool isOnboarded =
        prefs.getBool('isOnboarded') ?? false;
    if (!isOnboarded) {
      debugPrint("🆕 First launch → OnboardingScreen");

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/OnboardingScreen',
      );

      return;
    }
    if (!isLoggedIn) {
      debugPrint(
        "🔐 Onboarding completed → LoginScreen",
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/LoginScreen',
      );

      return;
    }
    final String? savedAccessToken =
        prefs.getString('access_token') ??
            prefs.getString('auth_token');

    final String? savedRefreshToken =
    prefs.getString('refresh_token');

    if (savedAccessToken == null ||
        savedAccessToken.isEmpty ||
        savedRefreshToken == null ||
        savedRefreshToken.isEmpty) {
      debugPrint("❌ Saved tokens missing → Login");

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/LoginScreen',
      );

      return;
    }

    await ApiHandler.instance.setTokens(
      token: savedAccessToken,
      refreshToken: savedRefreshToken,
    );

    debugPrint("✅ Saved tokens restored");

    debugPrint("📡 Calling GetMe API...");

    final result =
    await GetMeRepository.instance.getMe();

    if (!mounted) return;

    await result.when(
      success: (meApiData) async {
        final onboarding =
            meApiData.data.onboarding;

        final String? accountType =
            onboarding?.accountType;

        final bool hasBusiness =
            onboarding?.hasBusiness ?? false;

        final bool completed =
            onboarding?.completed ?? false;

        debugPrint(
          "======================================",
        );
        debugPrint("✅ GET ME SUCCESS");
        debugPrint("Account Type : $accountType");
        debugPrint("Has Business : $hasBusiness");
        debugPrint("Completed    : $completed");
        debugPrint(
          "======================================",
        );

        await prefs.setBool(
          'is_business_completed',
          completed,
        );

        if (accountType != null &&
            accountType.isNotEmpty) {
          await prefs.setString(
            'account_type',
            accountType,
          );
        }

        // ========================================================
        // 5. BUSINESS ACCOUNT → BUSINESS API
        // ========================================================
        if (accountType == "business" && hasBusiness) {
          debugPrint("🏢 BUSINESS ACCOUNT DETECTED");
          debugPrint("📡 Loading Business into CommonProvider...");

          final businessLoaded =
          await CommonProvider.instance.loadBusiness(
            forceRefresh: true,
          );

          if (businessLoaded) {
            final business = CommonProvider.instance.business;
            debugPrint("======================================");
            debugPrint("✅ BUSINESS API SUCCESS");
            debugPrint("Business UID : ${business?.uid}");
            debugPrint("Business Name : ${business?.name}");
            debugPrint("Logo S3 Key : ${business?.logoS3Key}");
            debugPrint("Industry : ${business?.businessCategory?.name}");
            debugPrint("Industry Slug : ${business?.businessCategory?.slug}");
            debugPrint("======================================");
          } else {
            debugPrint(
              "❌ BUSINESS API FAILED: ${CommonProvider.instance.businessError}",
            );
          }
        }

        if (!mounted) return;

        // ========================================================
        // 6. HOME
        // ========================================================

        if (completed) {
          debugPrint(
            "✅ Onboarding completed → Home",
          );

          Navigator.pushReplacementNamed(
            context,
            '/CustomBottomNavScreen',
          );

          return;
        }

        // ========================================================
        // 7. NEW / INCOMPLETE USER
        // ========================================================

        if (!completed &&
            !hasBusiness &&
            accountType == null) {
          debugPrint(
            "🆕 New/Incomplete User "
                "→ PlansAndPricingScreen",
          );

          Navigator.pushReplacementNamed(
            context,
            '/PlansAndPricingScreen',
          );

          return;
        }

        // ========================================================
        // 8. INCOMPLETE BUSINESS
        // ========================================================

        debugPrint(
          "⚠️ Incomplete onboarding "
              "→ BusinessDetailsScreen",
        );

        Navigator.pushReplacementNamed(
          context,
          '/BusinessDetailsScreen',
        );
      },

      // ==========================================================
      // GET ME FAILURE
      // ==========================================================

      failure: (error) {
        debugPrint(
          "❌ GetMe API failed: ${error.message}",
        );

        _tryRefreshingTokenOrLogin(
          prefs,
          savedRefreshToken,
        );
      },
    );
  }

  Future<void> _tryRefreshingTokenOrLogin(
      SharedPreferences prefs,
      String? refreshToken,
      ) async {
    if (refreshToken == null) {
      Navigator.pushReplacementNamed(context, '/LoginScreen');
      return;
    }

    try {
      await prefs.clear();
      await ApiHandler.instance.clearTokens();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/LoginScreen');
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/LoginScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Image.asset(
          'assets/images/splash.png',
          width: 200.w,
          height: 200.h,
        ),
      ),
    );
  }
}
