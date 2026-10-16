import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import 'package:mmb_app/network/provider/plan_provider.dart';
import 'package:mmb_app/ui/subscription/razor_pay.dart';

import '../../Api Model/plans_type.dart';
import '../../component/custom_widget.dart';
import '../../utils/theme/app.colors.dart';

class ConfirmPlanScreen extends StatelessWidget {
  final Plan plan;
  final PlanBillingOption? billing;

  const ConfirmPlanScreen({
    super.key,
    required this.plan,
    required this.billing,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanProvider(),
      child: _ConfirmPlanContent(plan: plan, billing: billing),
    );
  }
}

class _ConfirmPlanContent extends StatelessWidget {
  final Plan plan;
  final PlanBillingOption? billing;

  const _ConfirmPlanContent({required this.plan, required this.billing});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    final double price =
        double.tryParse(
          billing?.discountedPrice?.toString() ??
              billing?.price?.toString() ??
              "0",
        ) ??
        0;

    final double gst = price * 0.18;
    final double total = price + gst;

    final String cycle = billing?.billingCycle?.toLowerCase() == "annual"
        ? "Annual"
        : "Monthly";

    String formatAmount(double amount) {
      return amount % 1 == 0
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: CustomAppBar(title: "Confirm Plan", showRightIcon: false),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE), // Soft pink background
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    // Crown Icon Container
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded, // Crown/Premium icon
                        color: Colors.amber,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Make My Brand Premium",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.appRed, // Red color title
                            ),
                          ),
                          SizedBox(height: 2.h),
                          AppText(
                            "Unlock unlimited professional designs",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      " Premium Features Included:",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.appWhite,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.statusYellowColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText(
                            "500 Video Templates",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppFontSize.fontSize15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.statusYellowColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText(
                            "AI Credits · Brand Series · Social Calendar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppFontSize.fontSize15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.statusYellowColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText(
                            "Watermark-free downloads & HD Export",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppFontSize.fontSize15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // PRICE DETAILS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "BILLING",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightedGrey,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Plan",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppText(
                          "${plan.name ?? "Plan"} $cycle",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Price",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppText(
                          "₹${formatAmount(price)}",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          "GST (18%)",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppText(
                          "₹${formatAmount(gst)}",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          "Total",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppText(
                          "₹${formatAmount(total)}",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // PAY BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: provider.isCreatingSubscription
                      ? null
                      : () async {
                          if (billing?.id == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Billing option not available"),
                              ),
                            );
                            return;
                          }

                          final subscription = await context
                              .read<PlanProvider>()
                              .createSubscription(
                                planBillingOptionId: int.parse(billing!.id!),
                              );

                          if (!context.mounted) return;

                          if (subscription == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.subscriptionError ??
                                      "Unable to start payment",
                                ),
                              ),
                            );
                            return;
                          }

                          debugPrint(
                            "💳 Razorpay URL: ${subscription.shortUrl}",
                          );

                          debugPrint(
                            "💳 Subscription ID: ${subscription.subscriptionId}",
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: provider,
                                child: RazorpaySubscriptionScreen(
                                  url: subscription.shortUrl,
                                  subscriptionId: subscription.subscriptionId,
                                ),
                              ),
                            ),
                          );
                        },

                  child: provider.isLoadingPlans
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : AppText(
                          "PROCEED TO PAY ₹${formatAmount(total)}",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              AppText(
                "By continuing, you agree to the Terms of Use & Refund Policy. "
                "Your subscription will renew automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppFontSize.fontSize11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
