import 'package:flutter/material.dart';
import 'package:mmb_app/ui/screens/template_list_screen.dart';
import 'package:provider/provider.dart';
import '../Api Model/plans_type.dart';
import '../Api Model/theme_screen_model.dart';
import '../component/bottom_navigation.dart';
import '../network/provider/auth_provider.dart';
import '../network/provider/business_provider.dart';
import '../network/provider/smcalender_form_provider.dart';
import '../ui/industry/account_type_screen.dart';
import '../ui/industry/business_category_choose_screen.dart';
import '../ui/industry/business_category_choose_view.dart';
import '../ui/industry/business_details_screen.dart';
import '../ui/industry/business_frame_screen.dart';
import '../ui/industry/edit_photo_screen.dart';
import '../ui/login/login_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/screens/business_profile_screen.dart';
import '../ui/screens/download_screen.dart';
import '../ui/screens/edit_profile_screen.dart';
import '../ui/screens/faq_screen.dart';
import '../ui/screens/notification_screen.dart';
import '../ui/screens/help_support_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/smcalender_form_sceen.dart';
import '../ui/screens/smcalender_screen.dart';
import '../ui/screens/social_calender_result_screen.dart';
import '../ui/screens/special_days_screen.dart';
import '../ui/screens/template_detail_screen.dart';
import '../ui/screens/template_edit.dart';
import '../ui/screens/theme_detail_screen.dart';
import '../ui/screens/theme_single_item_view_screen.dart';

import '../ui/splash/splash_screen.dart';
import '../ui/subscription/change_plan_screen.dart';
import '../ui/subscription/confirm_cancel.dart';
import '../ui/subscription/confirm_plan.dart';

import '../ui/subscription/manage_plan.dart';
import '../ui/subscription/my_subscription.dart';
import '../ui/subscription/plan_detail_screen.dart';

import '../ui/subscription/plan_usage.dart';
import '../ui/subscription/subscription_activate_screen.dart';
import '../ui/subscription/subscription_screen.dart';
import '../ui/screens/feedback_screen.dart';
import '../ui/subscription/usage_screen.dart';
import '../ui/verification/otp_screen.dart';

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
        return MaterialPageRoute(builder: (context) => const OtpScreen());
      case "/AccountTypeScreen":
        return MaterialPageRoute(
          builder: (context) => const AccountTypeScreen(),
        );
      case "/BusinessCategoryChooseScreen":
        return MaterialPageRoute(
          builder: (context) => const BusinessCategoryChooseScreen(),
        );

      case "/BusinessDetailsScreen":
        final String variantId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (context) => BusinessDetailsScreen(businessUid: variantId),
        );
      case "/EditPhotoScreen":
        final businessProvider = settings.arguments as BusinessProvider;
        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: businessProvider,
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

      case '/ThemeDetailScreen':
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) =>
              ThemeDetailScreen(themeItem: args is ThemeItem ? args : null),
        );
      case "/NotificationScreen":
        return MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        );
      case "/HelpSupportScreen":
        return MaterialPageRoute(
          builder: (context) => const HelpSupportScreen(),
        );
      /* case "/FeedbackScreen":
        return MaterialPageRoute(
          builder: (context) => const FeedbackScreen(),
        );*/
      case "/ProfileScreen":
        return MaterialPageRoute(builder: (context) => const ProfileScreen());
      case "/BusinessProfileScreen":
        return MaterialPageRoute(
          builder: (context) => const BusinessProfileScreen(),
        );
      case "/MyDownloadsScreen":
        return MaterialPageRoute(
          builder: (context) => const MyDownloadScreen(),
        );
      case "/SmCalendarScreen":
        return MaterialPageRoute(
          builder: (context) => const SmCalendarScreen(),
        );
      case "/EditProfileScreen":
        return MaterialPageRoute(
          builder: (context) => const EditProfileScreen(),
        );
      case "/TemplateDetailScreen":
        final arguments = settings.arguments;

        String? category;

        if (arguments is Map<String, dynamic>) {
          category = arguments["category"]?.toString();
        }

        debugPrint("📂 TemplateDetailScreen category: $category");

        return MaterialPageRoute(
          settings: settings,
          builder: (context) =>
              TemplateDetailScreen(categorySlug: category ?? ""),
        );

      /* case "/EditorScreen":
        return MaterialPageRoute(
          builder: (context) => const EditorScreen(),
        ); */
      case "/TemplateEditScreen":
        final args = settings.arguments;

        String? resizeSize;
        String? templateUid;
        String? projectUid;
        String? projectName;

        double? canvasWidth;
        double? canvasHeight;

        if (args is String) {
          // Old route support
          resizeSize = args;
        } else if (args is Map) {
          resizeSize = args["resizeSize"] ?? args["resize_size"];

          templateUid =
              args["templateUid"] ?? args["template_uid"] ?? args["uid"];

          projectUid = args["projectUid"] ?? args["project_uid"];

          projectName =
              args["projectName"] ?? args["project_name"] ?? args["name"];

          final widthValue =
              args["canvasWidth"] ?? args["canvas_width"] ?? args["width"];

          final heightValue =
              args["canvasHeight"] ?? args["canvas_height"] ?? args["height"];

          canvasWidth = double.tryParse(widthValue?.toString() ?? "");

          canvasHeight = double.tryParse(heightValue?.toString() ?? "");
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            return TemplateEditScreen(
              resizeSize: resizeSize ?? "Post Square (1:1)",

              templateUid: templateUid,

              canvasWidth: canvasWidth,

              canvasHeight: canvasHeight,
            );
          },
        );
      case "/SocialCalendarFormScreen":
        return MaterialPageRoute(
          builder: (context) => const SocialCalendarFormScreen(),
        );

      case "/SocialCalendarResultScreen":
        final provider = settings.arguments as SocialCalendarProvider;
        return MaterialPageRoute(
          builder: (context) => SocialCalendarResultScreen(provider: provider),
        );

      case "/BusinessCategoryChooseView":
        return MaterialPageRoute(
          builder: (context) => const BusinessCategoryChooseView(),
        );
      case "/FeedbackScreen":
        return MaterialPageRoute(builder: (context) => const FeedbackScreen());
      case "/ThemeSingleitemViewScreen":
        final String variantId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (context) => ThemeSingleitemViewScreen(variantId: variantId),
        );
      case "/FaqScreen":
        return MaterialPageRoute(builder: (context) => const FaqScreen());
      case "/Help&SupportScreen":
        return MaterialPageRoute(builder: (context) => const FaqScreen());
      case "/PlanDetailScreen":
        final plan = settings.arguments as Plan;
        return MaterialPageRoute(
          builder: (context) => PlanDetailScreen(plan: plan),
        );
      case "/ConfirmPlanScreen":
        final args = settings.arguments;

        if (args is! Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text("Plan details not found")),
            ),
          );
        }

        final plan = args["plan"];

        if (plan is! Plan) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text("Invalid plan details")),
            ),
          );
        }

        final billing = args["billing"];

        return MaterialPageRoute(
          builder: (_) => ConfirmPlanScreen(
            plan: plan,
            billing: billing is PlanBillingOption ? billing : null,
          ),
        );
      case "/SubscriptionActivatedScreen":
        return MaterialPageRoute(
          builder: (context) => SubscriptionActivatedScreen(),
        );
      case "/MySubscriptionScreen":
        return MaterialPageRoute(builder: (context) => MySubscriptionScreen());
      case "/ChangePlanScreen":
        final args = settings.arguments;

        final bool openCancelSheet =
            args is Map && args["openCancelSheet"] == true;

        return MaterialPageRoute(
          builder: (context) =>
              ChangePlanScreen(openCancelSheet: openCancelSheet),
        );
      case "/UsageScreen":
        return MaterialPageRoute(builder: (context) => UsageScreen());
      case "/SpecialDaysScreen":
        final selectedDate = settings.arguments as String?;

        return MaterialPageRoute(builder: (context) => SpecialDaysScreen());

      case "/ConfirmCancellationScreen":
        return MaterialPageRoute(
          builder: (context) => const ConfirmCancellationScreen(),
        );
      case "/ManagePlanScreen":
        return MaterialPageRoute(
          builder: (context) => const ManagePlanScreen(),
        );
      case "/PlanUsageScreen":
        return MaterialPageRoute(builder: (context) => const PlanUsageScreen());
      case "/TemplateListScreen":
        final arguments = settings.arguments;

        String? type;

        if (arguments is Map<String, dynamic>) {
          type = arguments["type"]?.toString();
        }

        debugPrint("🎉 TemplateListScreen route type: $type");

        return MaterialPageRoute(
          settings: settings,
          builder: (context) => TemplateListScreen(type: type),
        );
    }
    return null;
  }
}
