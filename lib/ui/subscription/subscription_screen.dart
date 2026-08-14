import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/ui/subscription/plan_detail_screen.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Api Model/plans_type.dart';
import '../../network/provider/plan_provider.dart';
import '../../utils/theme/app.fonts.dart';

class PlansAndPricingScreen extends StatelessWidget {
  const PlansAndPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanProvider()..fetchPlans(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      "Plans & Pricing",
                      style: TextStyle(
                        color: AppColors.textBlack,
                        fontSize: AppFontSize.fontSize17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_seen_plans', true);

                        if (!context.mounted) return;
                        Navigator.pushNamed(context, "/AccountTypeScreen");
                      },
                      child: AppText(
                        "SKIP",
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Consumer<PlanProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingPlans) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final plansList = provider.plansData?.data ?? [];

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 170.h,
                            width: double.infinity,
                            child: Image.asset(
                              "assets/images/pricelogo.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Stack(
                            children: [
                              // 1. பின்னணியில் உள்ள இமேஜ் (Background Image)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Image.asset(
                                  "assets/images/offer.png",
                                  width: double.infinity,
                                  height: 150
                                      .h, // உங்களது இமேஜ் உயரத்திற்கேற்ப மாற்றிக் கொள்ளலாம்
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // 2. இமேஜின் மீது தெரிய வேண்டிய டெக்ஸ்ட்கள் மற்றும் பட்டன்
                              Padding(
                                padding: EdgeInsets.all(16.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      "START YOUR\n7-DAY FREE TRIAL",
                                      style: TextStyle(
                                        fontSize: AppFontSize.fontSize21,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                        height: 1.15,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    AppText(
                                      "Get full access to all Premium features.",
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        AppText(
                                          "Just Pay ",
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        AppText(
                                          "₹10",
                                          style: TextStyle(
                                            fontSize: AppFontSize.fontSize21,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),

                                    // Start Free Trial பட்டன்
                                    SizedBox(
                                      height: 34.h,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Action here
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF38BDF8,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                          ),
                                        ),
                                        child: AppText(
                                          "START FREE TRIAL",
                                          style: TextStyle(
                                            color: AppColors.deepBlue,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Dynamic Plans List Builder
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: plansList.length,
                            itemBuilder: (context, index) {
                              final plan = plansList[index];
                              return _buildDynamicPricingCard(
                                plan,
                                index,
                                provider,
                                context,
                              );
                            },
                          ),

                          SizedBox(height: 16.h),

                          AppText(
                            'Secure Payment',
                            style: TextStyle(
                              color: AppColors.normalButtonColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                            ),
                          ),

                          SizedBox(height: 4.h),
                          AppText(
                            'Cancel anytime. Refund policy applies.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          AppText(
                            'Continue with Free Plan',
                            style: TextStyle(
                              color: AppColors.normalButtonColor,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicPricingCard(
    Plan plan,
    int index,
    PlanProvider provider,
    BuildContext context,
  ) {
    final billing = plan.planBillingOptions.isNotEmpty
        ? plan.planBillingOptions.first
        : null;

    String rawPrice = '${billing != null ? billing.price : "0"}';
    if (rawPrice.contains('.')) {
      rawPrice = rawPrice.split('.').first;
    }

    final priceText = "₹$rawPrice";
    final periodText = billing == null ? "/month" : "/${billing.billingCycle}";

    Color cardBgColor;
    Color borderColor;
    Color buttonColor;
    String buttonText;

    String staticDescription = "";
    String staticIncludes = "";

    if (index == 0) {
      cardBgColor = const Color(0xFFFCFFF6);
      borderColor = const Color(0xFFBBE5ED);
      buttonColor = const Color(0xFF43CBD9);
      buttonText = "CONTINUE WITH\nFREE PLAN";
      staticDescription = "Perfect for exploring MMB before upgrading";
      staticIncludes =
          "10 Business Templates | 2 Video Templates | 10 AI Credits | Watermarked Downloads";
    } else if (index == 1) {
      cardBgColor = const Color(0xFFFCFFF6);
      borderColor = const Color(0xFFD4ED91);
      buttonColor = const Color(0xFF8BC34A);
      buttonText = "START BASIC";
      staticDescription = "Perfect for individuals & small businesses.";
      staticIncludes = "500 Templates | 200 Videos | 2 AI Logo Credits";
    } else if (index == 2) {
      cardBgColor = const Color(0xFFFFECEE);
      borderColor = const Color(0xFFFFCDD2);
      buttonColor = const Color(0xFFFF6FB5);
      buttonText = "START PREMIUM";
      staticDescription = "Perfect for growing businesses.";
      staticIncludes = "2000 Templates | 500 Videos | 5 AI Logo Credits";
    } else {
      cardBgColor = const Color(0xFFF3E8FF);
      borderColor = const Color(0xFFD8B4FE);
      buttonColor = const Color(0xFFA78BFA);
      buttonText = "START ELITE";
      staticDescription = "Perfect for individuals & small businesses.";
      staticIncludes = "2000 Templates | 1000 Videos | 10 AI Logo Credits";
    }

    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      plan.name ?? "Plan",
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AppText(
                          priceText, //
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        AppText(
                          periodText,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlanDetailScreen(plan: plan),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                ),
                child: AppText(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: index == 0 ? 10.sp : 11.sp,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // 🚀 Static Description Text
          AppText(
            staticDescription,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: 4.h),

          // 🚀 Static Includes Text
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 11.5.sp, color: Colors.black),
              children: [
                const TextSpan(
                  text: "Includes:\n",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: staticIncludes,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // 🚀 VIEW FEATURES பகுதி (Free பிளானைத் தவிர மற்றவைகளுக்கு மட்டும்)
          if (index > 0)
            InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/PlanDetailScreen',
                  arguments: plan,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    "VIEW FEATURES",
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12.sp,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
