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

      debugPrint("🔐 LOGIN STATUS: $isLoggedIn");

      // --------------------------------------------------------
      // NOT LOGGED IN
      // --------------------------------------------------------

      if (!isLoggedIn) {
        debugPrint("🔐 User not logged in → LoginScreen");

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
        debugPrint("❌ Saved tokens missing → Login");

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

      debugPrint("✅ Saved tokens restored");

      // ========================================================
      // GET ME
      // ========================================================

      debugPrint("📡 Calling GetMe API...");

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
            "❌ GetMe API failed: "
            "${error.message}",
          );

          debugPrint("❌ GetMe failed → Login");

          await _clearSessionAndLogin();
        },
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Splash error: $e");

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
      final onboarding = meApiData.data.onboarding;

      final String? accountType = onboarding?.accountType
          ?.toString()
          .toLowerCase();

      final bool hasBusiness = onboarding?.hasBusiness ?? false;

      final bool completed = onboarding?.completed ?? false;

      final bool isContinue = prefs.getBool('continue') ?? false;

      debugPrint("======================================");

      debugPrint("✅ GET ME SUCCESS");

      debugPrint("Account Type : $accountType");

      debugPrint("Has Business : $hasBusiness");

      debugPrint("Completed    : $completed");

      debugPrint("Continue     : $isContinue");

      debugPrint("======================================");

      await prefs.setBool('is_business_completed', completed);

      if (accountType != null && accountType.isNotEmpty) {
        await prefs.setString('account_type', accountType);
      }

      if (isContinue) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');

        return;
      }

      if (accountType == "personal") {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/EditPhotoScreen');

        return;
      }

      if (accountType == "business") {
        final businessLoaded = await CommonProvider.instance.loadBusiness(
          forceRefresh: true,
        );

        if (!mounted) return;

        final business = CommonProvider.instance.business;

        final String? businessUid = business?.uid;

        if (businessUid != null && businessUid.isNotEmpty) {
          Navigator.pushReplacementNamed(
            context,
            '/BusinessDetailsScreen',
            arguments: businessUid,
          );

          return;
        }

        Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');

        return;
      }

      if (accountType == null || accountType.isEmpty) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');

        return;
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);

      await _clearSessionAndLogin();
    }
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

      debugPrint("🧹 Session cleared");
    } catch (e) {
      debugPrint("❌ Failed to clear session: $e");
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/LoginScreen');
  }

  void _goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/LoginScreen');
  }

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
