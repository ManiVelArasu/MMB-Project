import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Repository/get_me_repository.dart';
import '../../core/api/api_handler.dart';
import '../../network/provider/common_provider.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Repository/get_me_repository.dart';
import '../../core/api/api_handler.dart';
import '../../network/provider/common_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserStatusAndNavigate();
    });
  }

  // ==============================================================
  // SPLASH FLOW
  // ==============================================================

  Future<void> _checkUserStatusAndNavigate() async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      await Future.delayed(
        const Duration(seconds: 2),
      );

      final prefs =
      await SharedPreferences.getInstance();

      // ==========================================================
      // LOGIN CHECK
      // ==========================================================

      final bool isLoggedIn =
          prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        debugPrint(
          "🔐 User not logged in → LoginScreen",
        );

        _goToLogin();

        return;
      }

      // ==========================================================
      // TOKEN CHECK
      // ==========================================================

      final String? accessToken =
          prefs.getString('access_token') ??
              prefs.getString('auth_token');

      final String? refreshToken =
      prefs.getString('refresh_token');

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        debugPrint(
          "❌ Saved tokens missing → Login",
        );

        _goToLogin();

        return;
      }

      // ==========================================================
      // RESTORE TOKENS
      // ==========================================================

      await ApiHandler.instance.setTokens(
        token: accessToken,
        refreshToken: refreshToken,
      );

      debugPrint(
        "✅ Saved tokens restored",
      );

      // ==========================================================
      // GET ME
      // ==========================================================

      debugPrint(
        "📡 Calling GetMe API...",
      );

      final result =
      await GetMeRepository.instance.getMe();

      if (!mounted) return;

      await result.when(
        // ========================================================
        // SUCCESS
        // ========================================================

        success: (meApiData) async {
          await _handleGetMeSuccess(
            prefs,
            meApiData,
          );
        },

        // ========================================================
        // FAILURE
        // ========================================================

        failure: (error) async {
          debugPrint(
            "❌ GetMe API failed: ${error.message}",
          );

          // ------------------------------------------------------
          // IMPORTANT
          //
          // TokenRefreshInterceptor should already have tried
          // refreshing the token when API returned 401.
          //
          // If we still reach here, refresh also failed.
          // ------------------------------------------------------

          debugPrint(
            "❌ GetMe failed even after token refresh → Login",
          );

          await _clearSessionAndLogin();
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        "❌ Splash error: $e",
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      await _clearSessionAndLogin();
    } finally {
      _isChecking = false;
    }
  }

  // ==============================================================
  // HANDLE GET ME SUCCESS
  // ==============================================================

  Future<void> _handleGetMeSuccess(
      SharedPreferences prefs,
      dynamic meApiData,
      ) async {
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

    debugPrint(
      "✅ GET ME SUCCESS",
    );

    debugPrint(
      "Account Type : $accountType",
    );

    debugPrint(
      "Has Business : $hasBusiness",
    );

    debugPrint(
      "Completed    : $completed",
    );

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

    if (completed) {
      debugPrint(
        "======================================",
      );

      debugPrint(
        "✅ SERVER → completed = TRUE",
      );

      debugPrint(
        "🚫 OnboardingScreen will NOT open",
      );

      debugPrint(
        "🏠 Going directly to Home",
      );

      debugPrint(
        "======================================",
      );

      // --------------------------------------------------------
      // Load Business
      // --------------------------------------------------------

      if (accountType == "business" &&
          hasBusiness) {
        debugPrint(
          "🏢 BUSINESS ACCOUNT DETECTED",
        );

        debugPrint(
          "📡 Loading Business API...",
        );

        final businessLoaded =
        await CommonProvider.instance.loadBusiness(
          forceRefresh: true,
        );

        if (businessLoaded) {
          final business =
              CommonProvider.instance.business;

          debugPrint(
            "======================================",
          );

          debugPrint(
            "✅ BUSINESS API SUCCESS",
          );

          debugPrint(
            "Business UID : ${business?.uid}",
          );

          debugPrint(
            "Business Name : ${business?.name}",
          );

          debugPrint(
            "Logo S3 Key : ${business?.logoS3Key}",
          );

          debugPrint(
            "Industry : ${business?.businessCategory?.name}",
          );

          debugPrint(
            "Industry Slug : ${business?.businessCategory?.slug}",
          );

          debugPrint(
            "======================================",
          );
        } else {
          debugPrint(
            "❌ BUSINESS API FAILED: "
                "${CommonProvider.instance.businessError}",
          );
        }
      }

      // --------------------------------------------------------
      // HOME
      // --------------------------------------------------------

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/CustomBottomNavScreen',
      );

      return;
    }

    // ==========================================================
    // COMPLETED = FALSE
    // ==========================================================

    debugPrint(
      "⚠️ SERVER → completed = FALSE",
    );

    // ==========================================================
    // NEW USER
    // ==========================================================

    if (!hasBusiness &&
        (accountType == null ||
            accountType.isEmpty)) {
      debugPrint(
        "🆕 New user → PlansAndPricingScreen",
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/PlansAndPricingScreen',
      );

      return;
    }

    // ==========================================================
    // INCOMPLETE BUSINESS
    // ==========================================================

    debugPrint(
      "⚠️ Incomplete business → BusinessDetailsScreen",
    );

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/BusinessDetailsScreen',
    );
  }

  // ==============================================================
  // CLEAR SESSION
  // ==============================================================

  Future<void> _clearSessionAndLogin() async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      await prefs.remove('access_token');
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');

      await prefs.setBool(
        'is_logged_in',
        false,
      );

      await ApiHandler.instance.clearTokens();
    } catch (e) {
      debugPrint(
        "❌ Failed to clear session: $e",
      );
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/LoginScreen',
    );
  }

  // ==============================================================
  // LOGIN
  // ==============================================================

  void _goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/LoginScreen',
    );
  }

  // ==============================================================
  // UI
  // ==============================================================

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
