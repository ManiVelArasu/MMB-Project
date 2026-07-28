import 'package:flutter/material.dart';
import 'package:project_mmb/ui/industry/account_type_screen.dart';
import 'package:project_mmb/ui/industry/business_category_choose_screen.dart';
import 'package:project_mmb/ui/industry/business_details_screen.dart';
import 'package:project_mmb/ui/industry/edit_photo_screen.dart';
import 'package:project_mmb/ui/login/login_screen.dart';
import 'package:project_mmb/ui/onboarding/onboarding_screen.dart';
import 'package:project_mmb/ui/splash/splash_screen.dart';
import 'package:project_mmb/ui/verification/otp_screen.dart';
import 'package:provider/provider.dart';

import '../component/bottom_navigation.dart';
import '../network/provider/auth_provider.dart';
import '../network/provider/business_provider.dart';
import '../ui/industry/business_frame_screen.dart';
import '../ui/screens/business_profile_screen.dart';
import '../ui/screens/download_screen.dart';
import '../ui/screens/edit_profile_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/smcalender_screen.dart';
import '../ui/screens/theme_detail_screen.dart';
import '../ui/subscription/basic_plan.dart';
import '../ui/subscription/elit_plan.dart';
import '../ui/subscription/premium_plan.dart';
import '../ui/subscription/subscription_screen.dart';

class RouteGenerator {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case "/LoginScreen":
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      case "/SplashScreen":
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      case "/OnboardingScreen":
        return MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        );
      case "/OtpScreen":
        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const OtpScreen(),
          ),
        );
      case "/AccountTypeScreen":
        return MaterialPageRoute(
          builder: (context) => const AccountTypeScreen(),
        );
      case "/BusinessCategoryChooseScreen":
        return MaterialPageRoute(
          builder: (context) => const BusinessCategoryChooseScreen(),
        );
      case "/BusinessDetailsScreen":
        return MaterialPageRoute(
          builder: (context) => const BusinessDetailsScreen(),
        );
      case "/EditPhotoScreen":
        final businessProvider = settings.arguments as BusinessProvider;
        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: businessProvider, // 👈 Passing the exact same instance
            child: const EditPhotoScreen(),
          ),
        );
      case "/BusinessFrameScreen":
        return MaterialPageRoute(
          builder: (context) => const BusinessFramesScreen(),
        );
      case "/PlansAndPricingScreen":
        return MaterialPageRoute(
          builder: (context) => const PlansAndPricingScreen(),
        );
      case "/CustomBottomNavScreen":
        return MaterialPageRoute(
          builder: (context) => const CustomBottomNavScreen(),
        );
      case "/BasicPlan":
        return MaterialPageRoute(builder: (context) => const BasicPlanScreen());
      case "/PremiumPlan":
        return MaterialPageRoute(
          builder: (context) => const PremiumPlanScreen(),
        );
      case "/ElitePlan":
        return MaterialPageRoute(builder: (context) => const ElitePlanScreen());
      case "/ThemeDetailScreen":
        return MaterialPageRoute(
          builder: (context) => const ThemeDetailScreen(),
        );
      case "/ProfileScreen":
        return MaterialPageRoute(builder: (context) => const ProfileScreen());
      case "/BusinessProfileScreen":
        return MaterialPageRoute(
          builder: (context) => const BusinessProfileScreen(),
        );
      case "/MyDownloadsScreen":
        return MaterialPageRoute(
          builder: (context) => const MyDownloadsScreen(),
        );
      case "/SmCalendarScreen":
        return MaterialPageRoute(
          builder: (context) => const SmCalendarScreen(),
        );
      case "/EditProfileScreen":
        return MaterialPageRoute(
          builder: (context) => const EditProfileScreen(),
        );
    }
    return null;
  }
}
