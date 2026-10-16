import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/plans_type.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/plan_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

class PlansAndPricingScreen extends StatelessWidget {
  final bool showSkip;

  const PlansAndPricingScreen({super.key, this.showSkip = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = PlanProvider();
        provider.fetchPlans();
        provider.fetchMySubscription();
        return provider;
      },
      child: _PlansAndPricingBody(showSkip: showSkip),
    );
  }
}

class _PlansAndPricingBody extends StatelessWidget {
  final bool showSkip;

  const _PlansAndPricingBody({required this.showSkip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/plan_gradient.png",
              fit: BoxFit.cover,
            ),
          ),
          Container(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          "Plans & Pricing",
                          style: TextStyle(
                            color: AppColors.textBlack,
                            fontSize: AppFontSize.fontSize22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (showSkip)
                          InkWell(
                            onTap: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('has_seen_plans', true);
                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                "/CustomBottomNavScreen",
                              );
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

                  // ==========================================================
                  // BODY
                  // ==========================================================
                  Expanded(
                    child: Consumer<PlanProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoadingPlans ||
                            provider.isLoadingSubscription) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final plansList = provider.plansData?.data ?? [];

                        if (plansList.isEmpty) {
                          return Center(
                            child: AppText(
                              provider.plansErrorMessage ??
                                  "No plans available",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // FREE TRIAL CARD
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Image.asset(
                                      "assets/images/offers.png",
                                      width: double.infinity,
                                      height: 170.h,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(16.r),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppText(
                                          "UNLOCK",
                                          style: TextStyle(
                                            fontSize: AppFontSize.fontSize26,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.appRed,
                                            height: 1.15,
                                          ),
                                        ),
                                        AppText(
                                          "7 DAYS OF PREMIUM",
                                          style: TextStyle(
                                            fontSize: AppFontSize.fontSize26,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        AppText(
                                          "Get full access to MMB Premium features for 7 days.",
                                          style: TextStyle(
                                            fontSize: AppFontSize.fontSize13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 16.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                AppText(
                                                  "₹10",
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.fontSize26,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                    height: 1.0,
                                                  ),
                                                ),
                                                AppText(
                                                  "FOR 7 DAYS",
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.fontSize12,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 38.h,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Start free trial
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF4ED8F2,
                                                  ),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                  ),
                                                ),
                                                child: AppText(
                                                  "GET PREMIUM FOR ₹10",
                                                  style: TextStyle(
                                                    color: AppColors.deepBlue,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize:
                                                        AppFontSize.fontSize16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16.h),

                              // PRICE LOGO
                              Container(
                                height: 170.h,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                                width: double.infinity,
                                child: Image.asset(
                                  "assets/images/video_icon.png",
                                  fit: BoxFit.cover,
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // PLANS LIST
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: plansList.length,
                                itemBuilder: (context, index) {
                                  final plan = plansList[index];

                                  return _buildDynamicPricingCard(
                                    context: context,
                                    plan: plan,
                                    index: index,
                                    provider: provider,
                                  );
                                },
                              ),

                              SizedBox(height: 16.h),

                              // FOOTER
                              AppText(
                                '🔒 Secure Payment',
                                style: TextStyle(
                                  color: AppColors.appRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppFontSize.fontSize16,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                'Cancel anytime. Refund policy applies.',
                                style: TextStyle(
                                  color: AppColors.appBlack,
                                  fontSize: AppFontSize.fontSize14,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              AppText(
                                'Continue with Free Plan',
                                style: TextStyle(
                                  color: AppColors.normalButtonColor,
                                  fontSize: AppFontSize.fontSize16,
                                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildDynamicPricingCard({
    required BuildContext context,
    required Plan plan,
    required int index,
    required PlanProvider provider,
  }) {
    final buttonState = provider.getPlanButtonState(plan, index);
    final bool isActivePlan = buttonState.isCurrentActive;

    final billing = plan.planBillingOptions.isNotEmpty
        ? plan.planBillingOptions.first
        : null;

    final String actualPrice = billing?.price?.toString() ?? "0";
    final String? discountedPrice = billing?.discountedPrice?.toString();
    final String? description =plan.description;
    final bool hasDiscount =
        discountedPrice != null &&
        discountedPrice.isNotEmpty &&
        discountedPrice != "null" &&
        discountedPrice != "0" &&
        discountedPrice != actualPrice;

    String formatPrice(String value) {
      if (value.contains(".")) {
        return value.split(".").first;
      }
      return value;
    }

    final String actualPriceText = "₹${formatPrice(actualPrice)}";
    final String discountPriceText = hasDiscount
        ? "₹${formatPrice(discountedPrice)}"
        : actualPriceText;
    final String periodText = billing == null
        ? "/month"
        : "/${billing.billingCycle}";

    Color cardBgColor;
    Color borderColor;
    Color buttonColor;
    String staticDescription = "";
    String staticIncludes = "";

    if (index == 0) {
      cardBgColor = const Color(0xFFFCFFF6);
      borderColor = const Color(0xFFDCEFB8);
      buttonColor = const Color(0xFF92BF46);
      staticDescription = description??'';
      staticIncludes = "500 Templates  |   200 Videos  |   2 AI Logo Credits";
    } else if (index == 1) {
      cardBgColor = const Color(0xFFFFF7FC);
      borderColor = const Color(0xFFFFD6EE);
      buttonColor = const Color(0xFFFA83CE);
      staticDescription = description??'';
      staticIncludes = "2000 Templates  |   500 Videos  |   5 AI Logo Credits";
    } else if (index == 2) {
      cardBgColor = const Color(0xFFFAF8FF);
      borderColor = const Color(0xFFE5DEFF);
      buttonColor = const Color(0xFF9D89F0);
      staticDescription =description??'';
      staticIncludes =
          "2000 Templates  |   1000 Videos  |   10 AI Logo Credits";
    } else {
      cardBgColor = const Color(0xFFFAF8FF);
      borderColor = const Color(0xFFE5DEFF);
      buttonColor = const Color(0xFF9985ED);
      staticDescription = description??'';
      staticIncludes =
          "2000 Templates  |   1000 Videos  |   10 AI Logo Credits";
    }

    Color currentButtonColor;

    if (buttonState.text == "RENEW PLAN") {
      currentButtonColor = Colors.red.shade700;
    } else if (isActivePlan) {
      currentButtonColor = Colors.green;
    } else if (buttonState.text == "DOWNGRADE") {
      currentButtonColor = Colors.orange.shade700;
    } else if (buttonState.text == "UPGRADE") {
      currentButtonColor = plan.name=="Elite Plan"? Color(0xFF9D89F0):Color(0xFFFA83CE);
    } else {
      currentButtonColor = buttonColor;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActivePlan ? Colors.green : borderColor,
          width: isActivePlan ? 2 : 1.5,
        ),
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
                    // Plan Name
                    AppText(
                      plan.name ?? "Plan",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Price and Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AppText(
                              discountPriceText,
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize27,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            AppText(
                              periodText.replaceAll("ly", ""),
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize18,
                                fontWeight: FontWeight.w600,
                                color:  Colors.black,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (buttonState.text == "ACTIVE PLAN") {
                              Navigator.pushNamed(
                                context,
                                '/MySubscriptionScreen',
                                arguments: plan,
                              );
                              return;
                            }
                            if (buttonState.text == "RENEW PLAN") {
                              Navigator.pushNamed(
                                context,
                                '/PlanDetailScreen',
                                arguments: plan,
                              );
                              return;
                            }
                            Navigator.pushNamed(
                              context,
                              '/PlanDetailScreen',
                              arguments: plan,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentButtonColor,
                            disabledBackgroundColor: Colors.green,
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
                            buttonState.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: AppFontSize.fontSize15,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AppText(
            staticDescription,
            style: TextStyle(
              fontSize: AppFontSize .fontSize14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: 4.h),
          AppText(
            "Includes:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.fontSize15,
            ),
          ),
          SizedBox(height: 4.h),
          AppText(
            staticIncludes,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: AppFontSize.fontSize14,
            ),
          ),

          SizedBox(height: 8.h),
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
                    fontSize: AppFontSize.fontSize11,
                    fontWeight: FontWeight.w600,
                    color:
                        buttonColor, // Card-oda button color-e view features-kum varum
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 12.sp,
                  color: buttonColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
