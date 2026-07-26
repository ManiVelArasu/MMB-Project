import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';
import '../../model/pricing_model.dart';
import '../../utils/theme/app.fonts.dart';

class PlansAndPricingScreen extends StatelessWidget {
  const PlansAndPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PricingProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
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
                      child: Text(
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 170.h,
                        width: double.infinity,
                        child: Image.asset("assets/images/pricelogo.png"),
                      ),

                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: Image.asset("assets/images/trial_logo.png"),
                      ),
                      SizedBox(height: 16.h),

                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, "/BasicPlan");
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.asset("assets/images/basic_plan.png"),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      InkWell(
                        onTap: (){
                          Navigator.pushNamed(context, "/PremiumPlan");
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.asset("assets/images/premium_plan.png"),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      InkWell(
                        onTap: (){
                          Navigator.pushNamed(context, "/ElitePlan");
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.asset("assets/images/elite_plan.png"),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      AppText(
                        'Secure Payment',
                        style: TextStyle(color: AppColors.normalButtonColor),
                      ),
                      AppText('CancelAnyTime Refund Policy'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard(
    PricingPlanModel plan,
    PricingProvider provider,
    BuildContext context,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: plan.cardBgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: plan.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        plan.price,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        plan.period,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // ACTIVATE NOW BUTTON
              ElevatedButton(
                onPressed: () {
                  provider.selectPlan(plan.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.buttonColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                ),
                child: Text(
                  "ACTIVATE NOW",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            plan.description,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: () {},
            child: Text(
              "PLAN DETAILS",
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: plan.detailsTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
