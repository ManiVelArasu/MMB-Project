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

    if (!mounted) return;
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );

    if (!isOnboarded) {
      print('d123');
      Navigator.pushReplacementNamed(context, '/OnboardingScreen');
    } else if (businessProvider.selectedImage != null) {
      print('ee123');
      Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');
    } else if (isLoggedIn && !hasSeenPlans) {
      print('2123');
      Navigator.pushReplacementNamed(context, '/PlansAndPricingScreen');
    } else if (isLoggedIn && hasSeenPlans) {
      print('bbb123');
      Navigator.pushReplacementNamed(context, '/CustomBottomNavScreen');
    } else {
      print('bbb1235555');
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
