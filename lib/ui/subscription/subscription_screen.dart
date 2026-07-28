import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';
import '../../Api Model/plans_type.dart';
import '../../model/pricing_model.dart';
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
                      onTap: () =>
                          Navigator.pushNamed(context, "/AccountTypeScreen"),
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
                          // 1. Top Banner Video/Image
                          SizedBox(
                            height: 170.h,
                            width: double.infinity,
                            child: Image.asset(
                              "assets/images/pricelogo.png",
                              fit: BoxFit.cover,
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // 2. Trial Banner Image
                          SizedBox(
                            width: double.infinity,
                            child: Image.asset(
                              "assets/images/trial_logo.png",
                              fit: BoxFit.cover,
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // 3. Dynamic Plans List Builder matching screenshot design
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
                            'Cancel Anytime Refund Policy',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.sp,
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

    final priceText = billing == null ? "Free" : "₹${billing.price}";
    final periodText = billing == null ? "" : "/${billing.billingCycle}";

    Color cardBgColor;
    Color borderColor;
    Color buttonColor;

    if (index == 0) {

      cardBgColor = const Color(0xFFF9FFE6);
      borderColor = const Color(0xFFD4ED91);
      buttonColor = const Color(0xFF8BC34A);
    } else if (index == 1) {

      cardBgColor = const Color(0xFFFFECEE);
      borderColor = const Color(0xFFFFCDD2);
      buttonColor = const Color(0xFFF48FB1);
    } else {

      cardBgColor = const Color(0xFFF3E8FF);
      borderColor = const Color(0xFFD8B4FE);
      buttonColor = const Color(0xFFA78BFA);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Price Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      plan.name ?? "Plan",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AppText(
                          priceText,
                          style: TextStyle(
                            fontSize: 24.sp,
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

              // ACTIVATE NOW BUTTON
              ElevatedButton(
                onPressed: () {
                  // provider.selectPlan(plan.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                ),
                child: AppText(
                  "ACTIVATE NOW",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Description Text
          AppText(
            plan.description ?? "",
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
          ),

          SizedBox(height: 8.h),

          // PLAN DETAILS LINK
          InkWell(
            onTap: () {
              // Handle Plan Details click
            },
            child: AppText(
              "PLAN DETAILS",
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
