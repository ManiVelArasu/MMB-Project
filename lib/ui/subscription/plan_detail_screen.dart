import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Api Model/plans_type.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  bool isMonthlySelected = true;

  @override
  Widget build(BuildContext context) {
    final billingOptions = widget.plan.planBillingOptions;

    PlanBillingOption? monthlyBilling;
    PlanBillingOption? annualBilling;

    for (var option in billingOptions) {
      if (option.billingCycle?.toLowerCase() == 'monthly') {
        monthlyBilling = option;
      } else if (option.billingCycle?.toLowerCase() == 'annual') {
        annualBilling = option;
      }
    }

    final String monthlyPrice = monthlyBilling?.discountedPrice?.isNotEmpty == true
        ? monthlyBilling!.discountedPrice!
        : (monthlyBilling?.price ?? "0");

    final String annualPrice = annualBilling?.discountedPrice?.isNotEmpty == true
        ? annualBilling!.discountedPrice!
        : (annualBilling?.price ?? "0");

    // Plan-ku ஏற்ற maathiri color styling
    final String planName = widget.plan.name?.toLowerCase() ?? "";
    Color themeColor;
    List<Color> bgGradient;

    if (planName.contains("basic")) {
      themeColor = const Color(0xFF96C63F);
      bgGradient = const [Color(0xFFE2F3CB), Color(0xFFF9FCF5)];
    } else if (planName.contains("elite")) {
      themeColor = const Color(0xFF9985ED);
      bgGradient = const [Color(0xFFE5DEFF), Color(0xFFFAF8FF)];
    } else {
      // Premium & others
      themeColor = const Color(0xFFF47BC5);
      bgGradient = const [Color(0xFFFFD6EE), Color(0xFFFFF7FC)];
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 12.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Back Button & Plan Title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38.w,
                        height: 38.h,
                        decoration: BoxDecoration(
                          color: AppColors.appWhite,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        widget.plan.name ?? "Plan Details",
                        style: TextStyle(
                          fontSize: 21.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Pricing Cards (Monthly / Annual)
                if (billingOptions.isNotEmpty)
                  Row(
                    children: [
                      if (monthlyBilling != null)
                        Expanded(
                          child: _buildPricingCard(
                            amount: '${monthlyBilling.discountedPrice?.isNotEmpty == true ? monthlyBilling.discountedPrice : monthlyBilling.price}',
                            originalPrice: monthlyBilling.discountedPrice?.isNotEmpty == true ? monthlyBilling.price : null,
                            period: '/m',
                            discountText: monthlyBilling.discountLabel,
                            isSelected: isMonthlySelected,
                            themeColor: themeColor,
                            onTap: () => setState(() => isMonthlySelected = true),
                          ),
                        ),
                      if (monthlyBilling != null && annualBilling != null)
                        SizedBox(width: 14.w),
                      if (annualBilling != null)
                        Expanded(
                          child: _buildPricingCard(
                            amount: '₹${annualBilling.discountedPrice?.isNotEmpty == true ? annualBilling.discountedPrice : annualBilling.price}',
                            period: '/y',
                            discountText: annualBilling.discountLabel,
                            isSelected: !isMonthlySelected,
                            themeColor: themeColor,
                            onTap: () => setState(() => isMonthlySelected = false),
                          ),
                        ),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      "Free Plan",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: themeColor,
                      ),
                    ),
                  ),
                SizedBox(height: 20.h),

                // Plan Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    widget.plan.description ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                Text(
                  "Features & Benefits",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10.h),

                // Features List
                Column(
                  children: widget.plan.features.map((feature) {
                    bool isAvailable = feature.enabled ?? false;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? themeColor
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isAvailable ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              feature.displayLabel ?? feature.label ?? "",
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 24.h),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedBilling = isMonthlySelected
                          ? monthlyBilling
                          : annualBilling;

                      Navigator.pushNamed(
                        context,
                        "/ConfirmPlanScreen",
                        arguments: {
                          "plan": widget.plan,
                          "billing": selectedBilling,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'START ${widget.plan.name?.toUpperCase() ?? "PLAN"}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Footer Information
                Center(
                  child: Column(
                    children: [
                      Text(
                        billingOptions.isEmpty
                            ? "This is a free plan. Enjoy your benefits!"
                            : isMonthlySelected
                            ? "You'll be charged ₹$monthlyPrice/month until cancelled."
                            : "You'll be charged ₹$annualPrice/year until cancelled.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: const TextStyleLink(text: 'Terms of Use'),
                          ),
                          Text(
                            ' | ',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const TextStyleLink(text: 'Refund Policy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required String amount,
    required String period,
    String? originalPrice,
    String? discountText,
    required bool isSelected,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isSelected ? themeColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price and Period Row
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (originalPrice != null && originalPrice != amount) ...[
                        AppText(
                          '₹$originalPrice',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 1.5,
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                      AppText(
                        amount,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      AppText(
                        period,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (discountText != null && discountText.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  AppText(
                    "$discountText with yearly billing",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.appBlack,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            top: -6,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }
}

class TextStyleLink extends StatelessWidget {
  final String text;
  const TextStyleLink({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF385A80),
      ),
    );
  }
}