import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/provider/business_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingAndNavigate();
  }

  Future<void> _checkOnboardingAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final bool isOnboarded = prefs.getBool('isOnboarded') ?? false;
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final bool hasSeenPlans = prefs.getBool('has_seen_plans') ?? false;
    final bool isBusinessCompleted =
        prefs.getBool('is_business_completed') ?? false;
    final bool isPersonalUse = prefs.getBool('is_personal_use') ?? false;

    if (!mounted) return;
    print("fsdfsdfsdfsdf${isBusinessCompleted}");

    if (!isOnboarded) {
      Navigator.pushReplacementNamed(context, '/OnboardingScreen');
    } else if (isLoggedIn && !hasSeenPlans) {
      Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');
    } else if (isLoggedIn && hasSeenPlans && !isBusinessCompleted && !isPersonalUse) {
      // பிசினஸும் முடிக்கவில்லை, பர்சனல் யூசரும் இல்லை எனில் பிசினஸ் டீடெய்ல்ஸ் போகும்
      Navigator.pushReplacementNamed(context, '/BusinessDetailsScreen');
    } else if (isLoggedIn && hasSeenPlans && (isBusinessCompleted || isPersonalUse)) {
      // 🚀 பிசினஸ் கம்ப்ீட் ஆகியிருந்தாலோ அல்லது பர்சனல் யூசாக இருந்தாலோ நேராக ஹோம் ஸ்கிரீனுக்குச் செல்லும்
      Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');
    } else {
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
