import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    if (!mounted) return;

    if (!isOnboarded) {

      Navigator.pushReplacementNamed(context, '/OnboardingScreen');
    } else if (isLoggedIn) {

      Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');
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
