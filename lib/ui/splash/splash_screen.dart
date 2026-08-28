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
    await Future.delayed(const Duration(seconds: 2)); // ஸ்பிளாஷ் டிலே

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

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
      debugPrint("✅ Restored Saved Token Successfully");
    }

    final result = await GetMeRepository.instance.getMe();

    if (!mounted) return;

    result.when(
      success: (meApiData) async {
        final onboarding = meApiData.data.onboarding;
        final String accountType = onboarding?.accountType ?? "business";
        final bool hasBusiness = onboarding?.hasBusiness ?? false;
        final bool completed = onboarding?.completed ?? false;

        await prefs.setBool('is_business_completed', completed);
        await prefs.setString('account_type', accountType);

        if (!mounted) return;
        if (completed || (accountType == "business" && hasBusiness)) {
          Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');
        } else {
          Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');
        }
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
      // உங்கள் AuthRepository-ல் உள்ள Refresh Token API-ஐ இங்கே கால் செய்ய வேண்டும்
      // உதாரணத்திற்கு:
      // final newTokenResult = await AuthRepository.instance.refreshToken(refreshToken);

      // புதிய டோக்கன் வெற்றிகரமாக கிடைத்தால் அதை செட் செய்துவிட்டு மீண்டும் ஹோம் ஸ்கிரீனுக்கு செல்லலாம்.
      // இல்லையெனில் மட்டும் கீழ்க்கண்டவாறு லாகின் ஸ்கிரீனுக்கு அனுப்பலாம்:

      await prefs.clear();
      await ApiHandler.instance.clearTokens();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/LoginScreen');
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/LoginScreen');
    }
  }

  void _fallbackNavigation(SharedPreferences prefs) {
    final bool isBusinessCompleted =
        prefs.getBool('is_business_completed') ?? false;
    final bool isPersonalUse = prefs.getBool('is_personal_use') ?? false;

    if (!mounted) return;

    if (isBusinessCompleted || isPersonalUse) {
      Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');
    } else {
      Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');
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
