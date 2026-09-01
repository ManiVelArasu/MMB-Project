import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../component/bottom_navigation.dart';
import '../../ui/industry/account_type_screen.dart';
import '../../ui/industry/business_category_choose_screen.dart';
import '../../ui/industry/business_details_screen.dart';
import '../../ui/industry/business_frame_screen.dart';
import '../../ui/industry/edit_photo_screen.dart';
import '../../ui/login/login_screen.dart';
import '../../ui/onboarding/onboarding_screen.dart';
import '../../ui/screens/business_profile_screen.dart';
import '../../ui/screens/download_screen.dart';
import '../../ui/screens/edit_profile_screen.dart';
import '../../ui/screens/profile_screen.dart';
import '../../ui/screens/smcalender_screen.dart';
import '../../ui/screens/theme_detail_screen.dart';
import '../../ui/splash/splash_screen.dart';
import '../../ui/subscription/subscription_screen.dart';
import '../../ui/verification/otp_screen.dart';

enum AppRoutes {
  splash('/SplashScreen'),
  login('/LoginScreen'),
  onboarding('/OnboardingScreen'),
  otp('/OtpScreen'),
  accountType('/AccountTypeScreen'),
  businessCategoryChoose('/BusinessCategoryChooseScreen'),
  businessDetails('/BusinessDetailsScreen'),
  editPhoto('/EditPhotoScreen'),
  businessFrame('/BusinessFrameScreen'),
  plansAndPricing('/PlansAndPricingScreen'),
  customBottomNav('/CustomBottomNavScreen'),
  basicPlan('/BasicPlan'),
  premiumPlan('/PremiumPlan'),
  elitePlan('/ElitePlan'),
  themeDetail('/ThemeDetailScreen'),
  profile('/ProfileScreen'),
  businessProfile('/BusinessProfileScreen'),
  myDownloads('/MyDownloadsScreen'),
  smCalendar('/SmCalendarScreen'),
  editProfile('/EditProfileScreen');

  final String path;
  const AppRoutes(this.path);
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('Navigating to >>>> ${settings.name}');

    switch (settings.name) {
      case '/SplashScreen':
        return _page(const SplashScreen(), settings: settings);

      case '/LoginScreen':
        return _page(const LoginScreen(), settings: settings);

      case '/OnboardingScreen':
        return _page(const OnboardingScreen(), settings: settings);

      case '/OtpScreen':
        return _page(const OtpScreen(), settings: settings);

      case '/AccountTypeScreen':
        return _page(const AccountTypeScreen(), settings: settings);

      case '/BusinessCategoryChooseScreen':
        return _page(const BusinessCategoryChooseView(), settings: settings);

      case '/BusinessDetailsScreen':
        return _page(const BusinessDetailsScreen(), settings: settings);

      case '/EditPhotoScreen':
        return _page(const EditPhotoScreen(), settings: settings);

      case '/BusinessFrameScreen':
        return _page(const BusinessFramesScreen(), settings: settings);

      case '/PlansAndPricingScreen':
        return _page(const PlansAndPricingScreen(), settings: settings);

     /* case '/CustomBottomNavScreen':
        return _page(const CustomBottomNavScreen(), settings: settings);*/



      case '/ThemeDetailScreen':
        return _page(const ThemeDetailScreen(), settings: settings);

      case '/ProfileScreen':
        return _page(const ProfileScreen(), settings: settings);

      case '/BusinessProfileScreen':
        return _page(const BusinessProfileScreen(), settings: settings);

      case '/MyDownloadsScreen':
        return _page(const MyDownloadsScreen(), settings: settings);

      case '/SmCalendarScreen':
        return _page(const SmCalendarScreen(), settings: settings);

      case '/EditProfileScreen':
        return _page(const EditProfileScreen(), settings: settings);

      default:
        return _page(
          const Scaffold(body: Center(child: Text('404 - Page Not Found'))),
          settings: settings,
        );
    }
  }

  // Helper method for MaterialPageRoute
  static MaterialPageRoute _page(Widget child, {RouteSettings? settings}) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}
