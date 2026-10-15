import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/plans_type.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/plan_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

class FreePlanScreen extends StatelessWidget {
  final bool showSkip;

  const FreePlanScreen({super.key, this.showSkip = false});

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
      appBar: CustomAppBar(title: "My Subscription", showRightIcon: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<PlanProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingPlans ||
                      provider.isLoadingSubscription) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final plans = provider.plansData?.data ?? [];

                  if (plans.isEmpty) {
                    return Center(
                      child: AppText(
                        provider.plansErrorMessage ?? 'No plans available',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFreeCard(),
                        SizedBox(height: 10.h),
                        _buildTrialCard(),
                        SizedBox(height: 10.h),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: plans.length,
                          itemBuilder: (context, index) {
                            return _buildPricingCard(
                              context: context,
                              plan: plans[index],
                              index: index,
                              provider: provider,
                            );
                          },
                        ),

                        SizedBox(height: 8.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeCard() {
    return Container(
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F8), Color(0xFFFFE5F2)],
        ),
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: const Color(0xFFFFD9E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                'Free',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E36),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: AppText(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AppText(
            "You're exploring Make My Brand on the Free plan. "
            'Upgrade anytime to unlock more templates, AI '
            'credits and watermark-free downloads.',
            style: TextStyle(
              fontSize: 10.sp,
              height: 1.35,
              color: const Color(0xFF554653),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard() {
    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB90D16), Color(0xFF480507)],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3038),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: AppText(
              'LIMITED OFFER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          AppText(
            'Start Your 7-Day Premium Trial',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          AppText(
            'Get full access to every Premium feature, '
            'templates, AI tools and watermark-free downloads.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 10.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AppText(
                '₹10',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 5.w),
              AppText(
                'one-time · 7 days',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 32.h,
            child: ElevatedButton(
              onPressed: () {
                // Keep your existing trial/payment function here.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF252D),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.r),
                ),
              ),
              child: AppText(
                'START FREE TRIAL →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required BuildContext context,
    required Plan plan,
    required int index,
    required PlanProvider provider,
  }) {
    final buttonState = provider.getPlanButtonState(plan, index);
    final isActivePlan = buttonState.isCurrentActive;

    final billing = plan.planBillingOptions.isNotEmpty
        ? plan.planBillingOptions.first
        : null;

    final actualPrice = billing?.price?.toString() ?? '0';
    final discountedPrice = billing?.discountedPrice?.toString();

    final hasDiscount =
        discountedPrice != null &&
        discountedPrice.isNotEmpty &&
        discountedPrice != 'null' &&
        discountedPrice != '0' &&
        discountedPrice != actualPrice;

    String formatPrice(String value) {
      return value.contains('.') ? value.split('.').first : value;
    }

    final priceText = hasDiscount
        ? '₹${formatPrice(discountedPrice)}'
        : '₹${formatPrice(actualPrice)}';

    final billingCycle = billing?.billingCycle ?? 'month';
    final periodText = '/${billingCycle.replaceAll('ly', '')}';

    final descriptions = plan.description ?? '';

    final List<Color> cardColors = [
      const Color(0xFFFCFFF6),
      const Color(0xFFFFF7FC),
      const Color(0xFFFAF8FF),
    ];

    final List<Color> borderColors = [
      const Color(0xFFDCEFB8),
      const Color(0xFFFFD6EE),
      const Color(0xFFE5DEFF),
    ];

    final List<Color> buttonColors = [
      const Color(0xFF92BF46),
      const Color(0xFFFA83CE),
      const Color(0xFF9D89F0),
    ];

    final List<String> includes = [
      '500 Templates  |  200 Videos  |  2 AI Logo Credits',
      '2000 Templates  |  500 Videos  |  5 AI Logo Credits',
      '2000 Templates  |  1000 Videos  |  10 AI Logo Credits',
    ];

    final colorIndex = index.clamp(0, 2);
    final cardColor = cardColors[colorIndex];
    final borderColor = borderColors[colorIndex];
    final buttonColor = buttonColors[colorIndex];

    Color currentButtonColor = buttonColor;

    if (buttonState.text == 'RENEW PLAN') {
      currentButtonColor = Colors.red.shade700;
    } else if (isActivePlan) {
      currentButtonColor = Colors.green;
    } else if (buttonState.text == 'DOWNGRADE') {
      currentButtonColor = Colors.orange.shade700;
    } else if (buttonState.text == 'UPGRADE') {
      currentButtonColor = buttonColor;
    }

    final isPopular = index == 1;

    final card = Container(
      margin: EdgeInsets.only(top: isPopular ? 8.h : 0, bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color: isActivePlan ? Colors.green : borderColor,
          width: isActivePlan ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppText(
                  plan.name ?? 'Plan',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              AppText(
                priceText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 3.w),
              AppText(
                periodText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          AppText(
            descriptions,
            style: TextStyle(
              fontSize: 10.sp,
              height: 1.3,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 5.h),
          AppText(
            'Includes:',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          AppText(
            includes[colorIndex],
            style: TextStyle(
              fontSize: 9.sp,
              height: 1.3,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 7.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
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
                      Flexible(
                        child: AppText(
                          'VIEW FEATURES',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: buttonColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.arrow_forward,
                        size: 11.sp,
                        color: buttonColor,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30.h,
                child: ElevatedButton(
                  onPressed: () {
                    if (buttonState.text == 'ACTIVE PLAN') {
                      Navigator.pushNamed(
                        context,
                        '/MySubscriptionScreen',
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
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 11.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  child: AppText(
                    buttonState.text == 'ACTIVE PLAN'
                        ? 'ACTIVE'
                        : buttonState.text == 'START PLAN'
                        ? 'START ${plan.name ?? 'PLAN'}'
                        : buttonState.text,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isPopular) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: 0,
          left: 10.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E36),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AppText(
              'MOST POPULAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
