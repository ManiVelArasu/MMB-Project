import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Repository/get_me_repository.dart';
import '../../core/api/api_handler.dart';

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
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final bool isOnboarded = prefs.getBool('isOnboarded') ?? false;

    if (!isOnboarded) {
      debugPrint("🆕 First launch → OnboardingScreen");

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/OnboardingScreen');

      return;
    }
    if (!isLoggedIn) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/LoginScreen');
      return;
    }
    final String? savedAccessToken = prefs.getString('access_token');
    final String? savedRefreshToken = prefs.getString('refresh_token');

    if (savedAccessToken != null && savedRefreshToken != null) {
      await ApiHandler.instance.setTokens(
        token: savedAccessToken,
        refreshToken: savedRefreshToken,
      );
    }

    final result = await GetMeRepository.instance.getMe();

    if (!mounted) return;

    result.when(
      success: (meApiData) async {
        final onboarding = meApiData.data.onboarding;

        final String? accountType = onboarding?.accountType;

        final bool hasBusiness = onboarding?.hasBusiness ?? false;

        final bool completed = onboarding?.completed ?? false;
        await prefs.setBool('is_business_completed', completed);

        if (accountType != null && accountType.isNotEmpty) {
          await prefs.setString('account_type', accountType);
        }

        if (!mounted) return;

        if (!completed && !hasBusiness && accountType == null) {
          debugPrint("🆕 New/Incomplete User → PlanDetailScreen");

          Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');

          return;
        }
        if (completed || (accountType == "business" && hasBusiness)) {
          debugPrint("✅ Onboarding completed → Home");

          Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');

          return;
        }
        debugPrint("⚠️ Incomplete onboarding → BusinessDetailsScreen");

        Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');
      },
      failure: (error) {
        _tryRefreshingTokenOrLogin(prefs, savedRefreshToken);
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
