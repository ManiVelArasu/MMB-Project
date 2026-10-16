import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:mmb_app/widgets/button_widget.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../Api Model/plans_type.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/plan_provider.dart';

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
                        _buildTrialCard(context),
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
                  fontSize: AppFontSize.fontSize22,
                  fontWeight: FontWeight.w700,
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
                    fontSize: AppFontSize.fontSize11,
                    fontWeight: FontWeight.w700,
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
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: AppColors.lightedGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context) {
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
                fontSize: AppFontSize.fontSize11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          AppText(
            'Start Your 7-Day Premium Trial',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.fontSize18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          AppText(
            'Get full access to every Premium feature, '
            'templates, AI tools and watermark-free downloads.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
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
                  fontSize: AppFontSize.fontSize32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5.w),
              AppText(
                'one-time · 7 days',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.fontSize18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          SizedBox(
            height: 32.h,
            width: 164,
            child: ButtonWidget(
              buttonPress: () {
                showReviewOrderDialog(context);
              },
              title: 'Start Free Trial →',
              buttonColor: AppColors.appRed,
              textStyle: TextStyle(
                color: AppColors.appWhite,
                fontSize: AppFontSize.fontSize14,
                fontWeight: FontWeight.w600,
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
                    fontSize: AppFontSize.fontSize18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              AppText(
                priceText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: AppFontSize.fontSize18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 3.w),
              AppText(
                periodText.replaceAll("nth", ""),
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
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: 5.h),
          AppText(
            'Includes:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.fontSize15,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 3.h),
          AppText(
            includes[colorIndex],
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: AppFontSize.fontSize14,
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
                            fontSize: AppFontSize.fontSize11,
                            fontWeight: FontWeight.w600,
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
                fontSize: AppFontSize.fontSize10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewOrderDialog extends StatefulWidget {
  const ReviewOrderDialog({super.key});

  @override
  State<ReviewOrderDialog> createState() => _ReviewOrderDialogState();
}

class _ReviewOrderDialogState extends State<ReviewOrderDialog> {
  late Razorpay razorpay;

  @override
  void initState() {
    super.initState();

    razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

    debugPrint("✅ Razorpay callbacks registered");
  }

  Future<void> handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("🎉 HANDLE PAYMENT SUCCESS CALLED");
    debugPrint("Payment ID: ${response.paymentId}");
    debugPrint("Order ID: ${response.orderId}");
    debugPrint("Signature: ${response.signature}");

    if (response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      debugPrint("❌ Razorpay response data missing");
      return;
    }

    final provider = context.read<PlanProvider>();

    try {
      final success = await provider.verifyAiPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      debugPrint("Payment verification result: $success");

      if (!mounted) return;

      if (success) {
        debugPrint("✅ Payment verified. Navigating...");
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          "/SubscriptionActivatedScreen",
          (route) => false,
        );

        // Refresh usage separately
        try {
          await provider.fetchPlanUsage();
        } catch (e) {
          debugPrint("⚠️ Plan usage refresh failed: $e");
        }
      } else {
        debugPrint("❌ Payment verification failed");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.cancelPlanError ?? "Payment verification failed",
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Payment success handler error: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment failed: ${response.message}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Payment failed')),
    );
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('Wallet: ${response.walletName}');
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'Review Your Order',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              AppText(
                'Please review your order details before proceeding to secure payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 20.h),

              // Selected plan
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6E8),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Column(
                  children: [
                    AppText(
                      'All-Access Pass',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    AppText(
                      '7 Days Premium Access',
                      style: TextStyle(fontSize: 10.sp, color: Colors.black),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              _sectionTitle('PAYMENT SUMMARY'),
              _summaryRow('Subtotal', '₹10.00'),
              _summaryRow('GST (18%)', '₹1.80'),
              _summaryRow('Total Payable', '₹11.80', isBold: true),

              SizedBox(height: 14.h),

              /*_sectionTitle('BILLING DETAILS'),
              _summaryRow('Business Name', 'testing'),
              _summaryRow('Mobile', '+919789575284'),

              SizedBox(height: 14.h),*/
              SizedBox(
                width: double.infinity,
                height: 38.h,
                child: ElevatedButton(
                  onPressed: () async {
                    debugPrint("🟡 Subscription access API started");

                    final planProvider = context.read<PlanProvider>();

                    final bool success = await planProvider
                        .sSubscriptionAccess();

                    debugPrint("🟡 Subscription access result: $success");

                    if (!context.mounted) return;

                    if (!success) {
                      debugPrint("❌ Subscription access API failed");
                      return;
                    }

                    final data = planProvider.subscriptionAccessData;

                    if (data == null || data['order_id'] == null) {
                      debugPrint("❌ Order ID missing");
                      return;
                    }

                    final options = {
                      'key': 'rzp_test_TWag5Xvk4KWWgY',
                      'order_id': data['order_id'],
                      'amount': ((data['amount'] as num) * 100).round(),
                      'currency': data['currency'] ?? 'INR',
                      'name': 'Make My Brand',
                      'description': '${data['pass_days']} Days Premium Access',
                      'prefill': {'contact': '', 'email': ''},
                      'notes': {
                        'payment_uid': data['payment_uid'],
                        'user_subscription_uid': data['user_subscription_uid'],
                      },
                    };

                    try {
                      debugPrint("🟡 Opening Razorpay...");
                      razorpay.open(options);
                    } catch (e, stackTrace) {
                      debugPrint("❌ Razorpay open error: $e");
                      debugPrintStack(stackTrace: stackTrace);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2029),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: AppText(
                    'PROCEED TO SECURE PAYMENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              AppText(
                "🔒 You'll be redirected to Razorpay to complete your payment securely.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 5.h),
        child: AppText(
          title,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isBold = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E3E3), width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              title,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.black87,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Flexible(
            child: AppText(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.black,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showReviewOrderDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const ReviewOrderDialog(),
  );
}
