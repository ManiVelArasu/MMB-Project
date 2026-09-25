import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Repository/get_me_repository.dart';
import '../../core/api/api_handler.dart';
import '../../core/api/api_interceptor.dart';
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



  Future<void> _checkUserStatusAndNavigate() async {
    if (_isChecking) return;

    _isChecking = true;

    try {


      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();



      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      debugPrint("======================================");
      debugPrint("🔐 SPLASH LOGIN STATUS: $isLoggedIn");
      debugPrint("======================================");



      if (!isLoggedIn) {
        debugPrint("🔐 USER NOT LOGGED IN → LoginScreen");

        _goToLogin();
        return;
      }



      String? accessToken =
          prefs.getString('access_token') ?? prefs.getString('auth_token');

      String? refreshToken = prefs.getString('refresh_token');

      debugPrint(
        "🔑 ACCESS TOKEN EXISTS: "
        "${accessToken != null && accessToken!.isNotEmpty}",
      );

      debugPrint(
        "🔄 REFRESH TOKEN EXISTS: "
        "${refreshToken != null && refreshToken!.isNotEmpty}",
      );

      // ========================================================
      // TOKEN MISSING
      // ========================================================

      if (accessToken == null ||
          accessToken.trim().isEmpty ||
          refreshToken == null ||
          refreshToken.trim().isEmpty) {
        debugPrint("❌ SAVED TOKENS MISSING → LoginScreen");

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
      // REFRESH TOKEN ON APP START
      // ========================================================
      //
      // IMPORTANT:
      //
      // App close/background → App open
      //
      // If access token is expired,
      // refresh token API will generate
      // a new access token.
      //
      // If refresh token is invalid,
      // only then LoginScreen.
      //
      // ========================================================

      debugPrint("🔍 CHECKING ACCESS TOKEN...");

      final tokenInterceptor = TokenRefreshInterceptor(ApiHandler.instance.dio);

      final bool refreshSuccess = await tokenInterceptor
          .refreshAccessTokenOnAppStart();

      if (!refreshSuccess) {
        debugPrint("⚠️ TOKEN REFRESH FAILED");

        // ------------------------------------------------------
        // IMPORTANT:
        //
        // If refresh token is invalid/expired,
        // only then clear session.
        // ------------------------------------------------------

        final latestPrefs = await SharedPreferences.getInstance();

        final latestRefreshToken = latestPrefs.getString('refresh_token');

        if (latestRefreshToken == null || latestRefreshToken.trim().isEmpty) {
          debugPrint("❌ REFRESH TOKEN NOT AVAILABLE → LOGIN");

          await _clearSessionAndLogin();
          return;
        }

        debugPrint("⚠️ REFRESH FAILED BUT REFRESH TOKEN EXISTS");

        // GetMe will be allowed to determine
        // the actual session state.
      } else {
        debugPrint("======================================");
        debugPrint("✅ ACCESS TOKEN REFRESH SUCCESS");
        debugPrint("======================================");
      }

      // ========================================================
      // GET LATEST TOKENS
      // ========================================================

      final latestPrefs = await SharedPreferences.getInstance();

      accessToken =
          latestPrefs.getString('access_token') ??
          latestPrefs.getString('auth_token');

      refreshToken = latestPrefs.getString('refresh_token');

      // ========================================================
      // VERIFY TOKENS AFTER REFRESH
      // ========================================================

      if (accessToken == null ||
          accessToken!.trim().isEmpty ||
          refreshToken == null ||
          refreshToken!.trim().isEmpty) {
        debugPrint("❌ TOKENS NOT AVAILABLE AFTER REFRESH");

        await _clearSessionAndLogin();
        return;
      }

      // ========================================================
      // RESTORE LATEST TOKENS
      // ========================================================

      await ApiHandler.instance.setTokens(
        token: accessToken!,
        refreshToken: refreshToken!,
      );

      debugPrint("✅ LATEST TOKENS RESTORED");

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
          await _handleGetMeSuccess(latestPrefs, meApiData);
        },
        failure: (error) async {
          debugPrint(
            "❌ GET ME API FAILED: "
            "${error.message}",
          );

          debugPrint("❌ GET ME FAILED → Checking session");

          // ----------------------------------------------------
          // DO NOT IMMEDIATELY LOGOUT.
          //
          // The interceptor should already have tried
          // refresh + retry for 401.
          //
          // If it still fails, then session is invalid.
          // ----------------------------------------------------

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
          "🆕 ACCOUNT TYPE NULL "
          "→ PlansAndPricingScreen",
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
          "➡️ ACCOUNT TYPE EXISTS "
          "+ CONTINUE = FALSE "
          "→ BusinessDetailsScreen",
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
          "✅ CONTINUE = TRUE "
          "+ ONBOARDING COMPLETE "
          "→ CustomBottomNavScreen",
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');

        return;
      }

      // --------------------------------------------------------
      // CONTINUE TRUE BUT INCOMPLETE
      // --------------------------------------------------------

      debugPrint(
        "⚠️ CONTINUE = TRUE "
        "BUT ONBOARDING INCOMPLETE "
        "→ BusinessDetailsScreen",
      );

      if (!mounted) return;

      await _goToBusinessDetails(accountType: accountType);
    } catch (e, stackTrace) {
      debugPrint("❌ GET ME SUCCESS HANDLING ERROR: $e");

      debugPrintStack(stackTrace: stackTrace);

      await _clearSessionAndLogin();
    }
  }

  // ============================================================
  // BUSINESS DETAILS
  // ============================================================

  Future<void> _goToBusinessDetails({required String accountType}) async {
    if (!mounted) return;

    // ==========================================================
    // PERSONAL
    // ==========================================================

    if (accountType == "personal") {
      debugPrint("👤 PERSONAL → BusinessDetailsScreen");

      Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');

      return;
    }

    // ==========================================================
    // BUSINESS
    // ==========================================================

    if (accountType == "business") {
      debugPrint("🏢 BUSINESS → Loading business...");

      try {
        final businessLoaded = await CommonProvider.instance.loadBusiness(
          forceRefresh: true,
        );

        debugPrint(
          "🏢 BUSINESS LOADED: "
          "$businessLoaded",
        );
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
          "🏢 → BusinessDetailsScreen "
          "with UID",
        );

        Navigator.pushReplacementNamed(
          context,
          '/BusinessDetailsScreen',
          arguments: businessUid,
        );

        return;
      }

      debugPrint(
        "⚠️ BUSINESS UID NOT FOUND "
        "→ BusinessDetailsScreen",
      );

      Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');

      return;
    }

    // ==========================================================
    // UNKNOWN ACCOUNT TYPE
    // ==========================================================

    debugPrint(
      "⚠️ UNKNOWN ACCOUNT TYPE: "
      "$accountType",
    );

    Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');
  }

  // ============================================================
  // CLEAR SESSION + LOGIN
  // ============================================================

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

  // ============================================================
  // GO LOGIN
  // ============================================================

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
