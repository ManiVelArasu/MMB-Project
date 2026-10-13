import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../network/provider/plan_provider.dart';
import 'my_subscription.dart';

class SubscriptionActivatedScreen extends StatefulWidget {
  const SubscriptionActivatedScreen({super.key});

  @override
  State<SubscriptionActivatedScreen> createState() =>
      _SubscriptionActivatedScreenState();
}

class _SubscriptionActivatedScreenState
    extends State<SubscriptionActivatedScreen> {
  late final PlanProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = PlanProvider();

    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final isActive = await _provider.fetchMySubscription();

    if (!mounted) return;

    debugPrint("📦 Subscription active: $isActive");
    debugPrint("📦 Subscription data: ${_provider.subscriptionData}");

    setState(() {});
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<PlanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingSubscription) {
            return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/PlansAndPricingScreen",
                  (route) => true,
                );
              },
              child: const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final data = provider.subscriptionData;

          final plan = data?["plan"] as Map<String, dynamic>?;

          final features = data?["features"] as List<dynamic>? ?? [];

          final planName = plan?["name"]?.toString() ?? "Premium Plan";

          return Scaffold(
            backgroundColor: Colors.white,

            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                "Subscription Activated",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                   Image.asset("assets/images/celebration.png",width: 64,height: 64,),

                    const SizedBox(height: 12),

                     AppText(
                      "SUBSCRIPTION ACTIVATED!",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize21,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 4),

                    AppText(
                      "$planName is now active on your account.",
                      textAlign: TextAlign.center,
                      style:  TextStyle(fontSize: AppFontSize.fontSize15,
                          fontWeight: FontWeight.w400, color: Colors.grey),
                    ),


                    const SizedBox(height: 20),

                    // ------------------------------------------
                    // ACCESS LIST
                    // ------------------------------------------
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "YOU NOW HAVE ACCESS TO",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          features.isEmpty
                              ? const AppText(
                            "No features available",
                            style: TextStyle(color: Colors.grey),
                          )
                              : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: features.length,
                            separatorBuilder: (_, __) => SizedBox(height: 10.h),
                            itemBuilder: (context, index) {
                              final feature = features[index];

                              if (feature is! Map<String, dynamic>) {
                                return const SizedBox();
                              }

                              // Correct label extraction from map
                              final label = feature["label"]?.toString() ?? "";
                              final enabled = feature["enabled"];

                              return Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.amber,
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: AppText(
                                      label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppFontSize.fontSize15,
                                        color: enabled == true ? Colors.black87 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------
                    // START EXPLORING
                    // ------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final planProvider = context.read<PlanProvider>();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: planProvider,
                                child: const MySubscriptionScreen(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "START EXPLORING",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, "/CustomBottomNavScreen");
                        },
                        child: const AppText(
                          "GO TO MY SUBSCRIPTION",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: AppText(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: AppText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

}
