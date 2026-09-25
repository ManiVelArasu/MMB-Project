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

  // ============================================================
  // SPLASH FLOW
  // ============================================================

  Future<void> _checkUserStatusAndNavigate() async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      // --------------------------------------------------------
      // SPLASH DELAY
      // --------------------------------------------------------

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      // ========================================================
      // LOGIN CHECK
      // ========================================================

      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      debugPrint("======================================");
      debugPrint("🔐 SPLASH LOGIN STATUS: $isLoggedIn");
      debugPrint("======================================");

      // ========================================================
      // NOT LOGGED IN
      // ========================================================

      if (!isLoggedIn) {
        debugPrint(
          "🔐 USER NOT LOGGED IN"
          " → LoginScreen",
        );

        _goToLogin();
        return;
      }

      // ========================================================
      // TOKEN CHECK
      // ========================================================

      final String? accessToken =
          prefs.getString('access_token') ?? prefs.getString('auth_token');

      final String? refreshToken = prefs.getString('refresh_token');

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        debugPrint(
          "❌ SAVED TOKENS MISSING"
          " → LoginScreen",
        );

        await _clearSessionAndLogin();
        return;
      }

      // ========================================================
      // RESTORE TOKENS
      // ========================================================

      await ApiHandler.instance.setTokens(
        token: accessToken,
        refreshToken: refreshToken,
      );

      debugPrint("✅ SAVED TOKENS RESTORED");

      // ========================================================
      // GET ME
      // ========================================================

      debugPrint("📡 CALLING GET ME API...");

      final result = await GetMeRepository.instance.getMe();

      if (!mounted) return;

      // ========================================================
      // GET ME RESULT
      // ========================================================

      await result.when(
        success: (meApiData) async {
          await _handleGetMeSuccess(prefs, meApiData);
        },
        failure: (error) async {
          debugPrint(
            "❌ GET ME API FAILED: "
            "${error.message}",
          );

          debugPrint(
            "❌ GET ME FAILED"
            " → LoginScreen",
          );

          await _clearSessionAndLogin();
        },
      );
    } catch (e, stackTrace) {
      debugPrint("❌ SPLASH ERROR: $e");

      debugPrintStack(stackTrace: stackTrace);

      await _clearSessionAndLogin();
    } finally {
      _isChecking = false;
    }
  }

  // ============================================================
  // HANDLE GET ME SUCCESS
  // ============================================================

  Future<void> _handleGetMeSuccess(
    SharedPreferences prefs,
    dynamic meApiData,
  ) async {
    try {
      // ========================================================
      // GET ONBOARDING
      // ========================================================

      final onboarding = meApiData.data.onboarding;

      // ========================================================
      // ACCOUNT TYPE
      // ========================================================

      String? accountType = onboarding?.accountType
          ?.toString()
          .trim()
          .toLowerCase();

      // ========================================================
      // HAS BUSINESS
      // ========================================================

      final bool hasBusiness = onboarding?.hasBusiness ?? false;

      // ========================================================
      // COMPLETED
      // ========================================================

      final bool completed = onboarding?.completed ?? false;

      // ========================================================
      // CONTINUE
      // ========================================================

      final bool isContinue = prefs.getBool('continue') ?? false;

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint("======================================");
      debugPrint("✅ GET ME SUCCESS");
      debugPrint("ACCOUNT TYPE : $accountType");
      debugPrint("HAS BUSINESS : $hasBusiness");
      debugPrint("COMPLETED    : $completed");
      debugPrint("CONTINUE     : $isContinue");
      debugPrint("======================================");

      // ========================================================
      // SAVE COMPLETED
      // ========================================================

      await prefs.setBool('is_business_completed', completed);

      // ========================================================
      // SAVE ACCOUNT TYPE
      // ========================================================

      if (accountType != null && accountType.isNotEmpty) {
        await prefs.setString('account_type', accountType);

        debugPrint("✅ ACCOUNT TYPE SAVED: $accountType");
      } else {
        // Account type is not selected yet.
        //
        // DO NOT save empty account type.

        await prefs.remove('account_type');

        debugPrint("ℹ️ ACCOUNT TYPE NULL");
      }

      // ========================================================
      // IMPORTANT NAVIGATION FLOW
      // ========================================================

      // --------------------------------------------------------
      // 1. ACCOUNT TYPE NULL
      // --------------------------------------------------------
      //
      // First-time onboarding:
      //
      // Onboarding
      //    ↓
      // Login
      //    ↓
      // OTP
      //    ↓
      // Splash
      //    ↓
      // PlansAndPricingScreen
      //
      // continue value does NOT matter here.
      // --------------------------------------------------------

      if (accountType == null || accountType.isEmpty) {
        debugPrint(
          "🆕 ACCOUNT TYPE NULL"
          " → PlansAndPricingScreen",
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');

        return;
      }

      // --------------------------------------------------------
      // 2. ACCOUNT TYPE EXISTS
      //    CONTINUE = FALSE
      // --------------------------------------------------------
      //
      // Account type already selected,
      // but onboarding is not continued/completed.
      //
      // → BusinessDetailsScreen
      // --------------------------------------------------------

      if (!isContinue) {
        debugPrint(
          "➡️ ACCOUNT TYPE EXISTS"
          " + CONTINUE = FALSE"
          " → BusinessDetailsScreen",
        );

        if (!mounted) return;

        await _goToBusinessDetails(accountType: accountType);

        return;
      }

      // --------------------------------------------------------
      // 3. CHECK FULL ONBOARDING COMPLETION
      // --------------------------------------------------------

      final bool onboardingFullyCompleted =
          completed && (accountType == "business" ? hasBusiness : true);

      debugPrint("======================================");
      debugPrint(
        "ONBOARDING FULLY COMPLETED:"
        " $onboardingFullyCompleted",
      );
      debugPrint("======================================");

      // --------------------------------------------------------
      // 4. CONTINUE TRUE + ONBOARDING COMPLETE
      // --------------------------------------------------------
      //
      // Business:
      //
      // accountType = business
      // continue = true
      // completed = true
      // hasBusiness = true
      //
      // → CustomBottomNavScreen
      //
      // Personal:
      //
      // accountType = personal
      // continue = true
      // completed = true
      //
      // → CustomBottomNavScreen
      // --------------------------------------------------------

      if (isContinue && onboardingFullyCompleted) {
        debugPrint(
          "✅ CONTINUE = TRUE"
          " + ONBOARDING COMPLETE"
          " → CustomBottomNavScreen",
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');

        return;
      }

      debugPrint(
        "⚠️ CONTINUE = TRUE"
        " BUT ONBOARDING INCOMPLETE"
        " → BusinessDetailsScreen",
      );

      if (!mounted) return;

      await _goToBusinessDetails(accountType: accountType);
    } catch (e, stackTrace) {
      debugPrint("❌ GET ME SUCCESS HANDLING ERROR: $e");

      debugPrintStack(stackTrace: stackTrace);

      await _clearSessionAndLogin();
    }
  }

  Future<void> _goToBusinessDetails({required String accountType}) async {
    if (!mounted) return;

    if (accountType == "personal") {
      debugPrint(
        "👤 PERSONAL"
        " → BusinessDetailsScreen",
      );

      Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');

      return;
    }

    if (accountType == "business") {
      debugPrint(
        "🏢 BUSINESS"
        " → Loading business...",
      );

      try {
        final businessLoaded = await CommonProvider.instance.loadBusiness(
          forceRefresh: true,
        );

        debugPrint("🏢 BUSINESS LOADED: $businessLoaded");
      } catch (e, stackTrace) {
        debugPrint("❌ LOAD BUSINESS ERROR: $e");

        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted) return;

      final business = CommonProvider.instance.business;

      final String? businessUid = business?.uid;

      debugPrint("🏢 BUSINESS UID: $businessUid");

      if (businessUid != null && businessUid.isNotEmpty) {
        debugPrint(
          "🏢 → BusinessDetailsScreen"
          " with UID",
        );

        Navigator.pushReplacementNamed(
          context,
          '/BusinessDetailsScreen',
          arguments: businessUid,
        );

        return;
      }

      debugPrint(
        "⚠️ BUSINESS UID NOT FOUND"
        " → BusinessDetailsScreen",
      );

      Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');

      return;
    }

    debugPrint(
      "⚠️ UNKNOWN ACCOUNT TYPE:"
      " $accountType",
    );

    Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');
  }

  Future<void> _clearSessionAndLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('access_token');

      await prefs.remove('auth_token');

      await prefs.remove('refresh_token');

      await prefs.setBool('is_logged_in', false);

      await prefs.setBool('continue', false);

      await ApiHandler.instance.clearTokens();

      debugPrint("🧹 SESSION CLEARED");
    } catch (e) {
      debugPrint("❌ FAILED TO CLEAR SESSION: $e");
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/LoginScreen');
  }

  void _goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/LoginScreen');
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Center(
          child: Image.asset(
            'assets/images/splash.png',
            width: 120.w,
            height: 120.h,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
