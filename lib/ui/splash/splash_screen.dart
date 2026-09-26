import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Repository/get_me_repository.dart';
import '../../core/api/api_handler.dart';
import '../../core/api/api_interceptor.dart';
import '../../core/api/enums/refreh_result.dart';
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
  // CHECK USER STATUS
  // ============================================================

  Future<void> _checkUserStatusAndNavigate() async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      // ========================================================
      // SPLASH DELAY
      // ========================================================

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // ========================================================
      // SHARED PREFERENCES
      // ========================================================

      final prefs = await SharedPreferences.getInstance();

      // ========================================================
      // LOGIN / ONBOARD STATUS
      // ========================================================

      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      final bool isOnboard = prefs.getBool('is_onboard') ?? false;

      // ========================================================
      // ONBOARDING CHECK
      // ========================================================

      if (!isOnboard) {
        debugPrint(
          "🚀 USER NOT ONBOARDED "
          "→ OnboardingScreen",
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/OnboardingScreen');

        return;
      }

      // ========================================================
      // LOGIN CHECK
      // ========================================================

      debugPrint("======================================");
      debugPrint("🔐 SPLASH LOGIN STATUS: $isLoggedIn");
      debugPrint("======================================");

      if (!isLoggedIn) {
        debugPrint(
          "🔐 USER NOT LOGGED IN "
          "→ LoginScreen",
        );

        _goToLogin();

        return;
      }

      // ========================================================
      // ACCESS TOKEN
      // ========================================================

      String? accessToken =
          prefs.getString('access_token') ?? prefs.getString('auth_token');

      // ========================================================
      // REFRESH TOKEN
      // ========================================================

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
      // TOKEN VALIDATION
      // ========================================================

      if (accessToken == null ||
          accessToken!.trim().isEmpty ||
          refreshToken == null ||
          refreshToken!.trim().isEmpty) {
        debugPrint(
          "❌ SAVED TOKENS MISSING "
          "→ LoginScreen",
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
      // REFRESH ACCESS TOKEN
      // ========================================================

      debugPrint("🔍 CHECKING ACCESS TOKEN...");

      final tokenInterceptor = TokenRefreshInterceptor(ApiHandler.instance.dio);

      final RefreshResult refreshResult = await tokenInterceptor
          .refreshAccessTokenOnAppStart();

      // ========================================================
      // REFRESH SUCCESS
      // ========================================================

      if (refreshResult == RefreshResult.success) {
        debugPrint("======================================");

        debugPrint("✅ ACCESS TOKEN REFRESH SUCCESS");

        debugPrint("======================================");
      }
      // ========================================================
      // NETWORK ERROR
      // ========================================================
      else if (refreshResult == RefreshResult.networkError) {
        debugPrint("======================================");

        debugPrint("🌐 REFRESH API NETWORK ERROR");

        debugPrint("⚠️ KEEPING EXISTING SESSION");

        debugPrint("======================================");

        // Don't logout.
        // Don't clear tokens.
      }
      // ========================================================
      // INVALID REFRESH TOKEN
      // ========================================================
      else if (refreshResult == RefreshResult.invalidRefreshToken) {
        debugPrint("======================================");

        debugPrint("❌ REFRESH TOKEN INVALID / EXPIRED");

        debugPrint("🔐 SESSION EXPIRED → LoginScreen");

        debugPrint("======================================");

        await _clearSessionAndLogin();

        return;
      }
      // ========================================================
      // OTHER REFRESH FAILURE
      // ========================================================
      else {
        debugPrint("⚠️ TOKEN REFRESH FAILED");

        // Keep existing session.
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
      // VERIFY LATEST TOKENS
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
        token: accessToken,
        refreshToken: refreshToken,
      );

      debugPrint("✅ LATEST TOKENS RESTORED");

      // ========================================================
      // GET ME API
      // ========================================================

      debugPrint("📡 CALLING GET ME API...");

      final result = await GetMeRepository.instance.getMe();

      if (!mounted) return;

      // ========================================================
      // GET ME RESULT
      // ========================================================

      await result.when(
        // ======================================================
        // SUCCESS
        // ======================================================

        success: (meApiData) async {
          debugPrint("✅ GET ME API SUCCESS");

          await _handleGetMeSuccess(latestPrefs, meApiData);
        },

        // ======================================================
        // FAILURE
        // ======================================================
        failure: (error) async {
          debugPrint(
            "❌ GET ME API FAILED: "
            "${error.message}",
          );

          // ====================================================
          // ERROR MESSAGE
          // ====================================================

          final String message = error.message.toString().toLowerCase();

          // ====================================================
          // NETWORK ERROR
          // ====================================================

          final bool isNetworkError =
              message.contains('no internet') ||
              message.contains('network') ||
              message.contains('connection') ||
              message.contains('failed host lookup') ||
              message.contains('socketexception') ||
              message.contains('timeout') ||
              message.contains('timed out');

          if (isNetworkError) {
            debugPrint("======================================");

            debugPrint("🌐 GET ME NETWORK ERROR");

            debugPrint("⚠️ KEEPING SESSION");

            debugPrint("❌ NOT CLEARING TOKENS");

            debugPrint("======================================");

            return;
          }

          // ====================================================
          // AUTHENTICATION ERROR
          // ====================================================

          final int? statusCode = error.statusCode;

          if (statusCode == 401 || statusCode == 403) {
            debugPrint("======================================");

            debugPrint("🔐 GET ME AUTHENTICATION FAILED");

            debugPrint("🔐 STATUS: $statusCode");

            debugPrint("➡️ CLEARING SESSION");

            debugPrint("======================================");

            await _clearSessionAndLogin();

            return;
          }

          // ====================================================
          // OTHER SERVER ERROR
          // ====================================================

          debugPrint("======================================");

          debugPrint("⚠️ GET ME SERVER/UNKNOWN ERROR");

          debugPrint("⚠️ KEEPING SESSION");

          debugPrint("======================================");
        },
      );
    } catch (e, stackTrace) {
      debugPrint("❌ SPLASH ERROR: $e");

      debugPrintStack(stackTrace: stackTrace);

      // Don't automatically clear session.
      debugPrint(
        "⚠️ Unexpected splash error "
        "→ KEEP SESSION",
      );
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
      final onboarding = meApiData.data.onboarding;

      final String? accountType = onboarding?.accountType
          ?.toString()
          .trim()
          .toLowerCase();

      final bool hasBusiness = onboarding?.hasBusiness ?? false;

      final bool completed = onboarding?.completed ?? false;

      // ========================================================
      // CONTINUE
      // ========================================================

      final bool isContinue = prefs.getBool('continue') ?? false;

      debugPrint("======================================");
      debugPrint("🚦 SPLASH NAVIGATION");
      debugPrint("accountType : $accountType");
      debugPrint("hasBusiness : $hasBusiness");
      debugPrint("completed   : $completed");
      debugPrint("continue    : $isContinue");
      debugPrint("======================================");

      // ========================================================
      // SAVE API STATUS
      // ========================================================

      await prefs.setBool('is_business_completed', completed);

      if (accountType != null && accountType.isNotEmpty) {
        await prefs.setString('account_type', accountType);
      }

      // ========================================================
      // NO ACCOUNT TYPE
      // ========================================================

      if (accountType == null || accountType.isEmpty) {
        debugPrint(
          "🆕 ACCOUNT TYPE NULL"
          " → PlansAndPricingScreen",
        );

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/PlansAndPricingScreen",
          (route) => false,
        );

        return;
      }

      // ========================================================
      // ONBOARDING COMPLETE
      // ========================================================

      final bool onboardingCompleted =
          completed && (accountType == "business" ? hasBusiness : true);

      debugPrint(
        "onboardingCompleted: "
        "$onboardingCompleted",
      );

      // ========================================================
      // COMPLETE + CONTINUE TRUE
      //
      // User actually pressed Continue previously.
      // ========================================================

      if (onboardingCompleted && isContinue) {
        debugPrint(
          "✅ COMPLETE + CONTINUE TRUE"
          " → CustomBottomNavScreen",
        );

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/CustomBottomNavScreen",
          (route) => false,
        );

        return;
      }

      // ========================================================
      // COMPLETE + CONTINUE FALSE
      //
      // User has data but closed app before pressing Continue.
      //
      // IMPORTANT:
      // Don't send to Home.
      // Resume BusinessDetails.
      // ========================================================

      if (onboardingCompleted && !isContinue) {
        debugPrint(
          "⚠️ COMPLETE DATA"
          " + CONTINUE FALSE"
          " → BusinessDetailsScreen",
        );

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/BusinessDetailsScreen",
          (route) => false,
        );

        return;
      }

      // ========================================================
      // INCOMPLETE
      // ========================================================

      debugPrint(
        "⚠️ ONBOARDING INCOMPLETE"
        " → BusinessDetailsScreen",
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        "/BusinessDetailsScreen",
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint("❌ SPLASH GET ME HANDLING ERROR: $e");

      debugPrintStack(stackTrace: stackTrace);
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
      debugPrint(
        "👤 PERSONAL "
        "→ BusinessDetailsScreen",
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/BusinessDetailsScreen',
        (route) => false,
      );

      return;
    }

    // ==========================================================
    // BUSINESS
    // ==========================================================

    if (accountType == "business") {
      debugPrint(
        "🏢 BUSINESS "
        "→ Loading business...",
      );

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

      debugPrint(
        "🏢 BUSINESS UID: "
        "$businessUid",
      );

      // ========================================================
      // BUSINESS UID FOUND
      // ========================================================

      if (businessUid != null && businessUid.isNotEmpty) {
        debugPrint(
          "🏢 → BusinessDetailsScreen "
          "with UID",
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/BusinessDetailsScreen',
          (route) => false,
          arguments: businessUid,
        );

        return;
      }

      // ========================================================
      // BUSINESS UID NOT FOUND
      // ========================================================

      debugPrint(
        "⚠️ BUSINESS UID NOT FOUND "
        "→ BusinessDetailsScreen",
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/BusinessDetailsScreen',
        (route) => false,
      );

      return;
    }

    // ==========================================================
    // UNKNOWN ACCOUNT TYPE
    // ==========================================================

    debugPrint(
      "⚠️ UNKNOWN ACCOUNT TYPE: "
      "$accountType",
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/PlansAndPricingScreen',
      (route) => false,
    );
  }

  // ============================================================
  // CLEAR SESSION + LOGIN
  // ============================================================

  Future<void> _clearSessionAndLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ========================================================
      // CLEAR TOKENS
      // ========================================================

      await prefs.remove('access_token');

      await prefs.remove('auth_token');

      await prefs.remove('refresh_token');

      // ========================================================
      // LOGIN STATUS
      // ========================================================

      await prefs.setBool('is_logged_in', false);

      // ========================================================
      // CONTINUE
      //
      // Session is genuinely invalid here.
      // ========================================================

      await prefs.setBool('continue', false);

      // ========================================================
      // CLEAR API TOKENS
      // ========================================================

      await ApiHandler.instance.clearTokens();

      debugPrint("🧹 SESSION CLEARED");
    } catch (e) {
      debugPrint("❌ FAILED TO CLEAR SESSION: $e");
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/LoginScreen',
      (route) => false,
    );
  }

  // ============================================================
  // GO LOGIN
  // ============================================================

  void _goToLogin() {
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/LoginScreen',
      (route) => false,
    );
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
