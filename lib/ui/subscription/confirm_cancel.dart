import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/plan_provider.dart';

class ConfirmCancellationScreen extends StatefulWidget {
  const ConfirmCancellationScreen({super.key});

  @override
  State<ConfirmCancellationScreen> createState() =>
      _ConfirmCancellationScreenState();
}

class _ConfirmCancellationScreenState extends State<ConfirmCancellationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<PlanProvider>().fetchMySubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanProvider>(
      builder: (context, provider, child) {
        final data = provider.subscriptionData;

        final plan = data?["plan"];

        final String planName = plan is Map
            ? plan["name"]?.toString() ?? "Premium"
            : "Premium";

        final String expiryDate =
            data?["current_period_end"]?.toString() ??
            data?["end_date"]?.toString() ??
            data?["expires_at"]?.toString() ??
            "your current billing period";

        final List<String> features = _getFeatures(data);

        return Scaffold(
          backgroundColor: Colors.white,

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 15,
                  color: Colors.red,
                ),
              ),
            ),
            title: const Text(
              "Confirm Cancellation",
              style: TextStyle(
                color: Color(0xFF171A2B),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          body: provider.isLoadingSubscription
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // ICON
                        Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE5E7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Sure you want to cancel $planName?",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Your $planName access continues until $expiryDate.\n"
                          "After that, your plan won't renew and you'll move\n"
                          "to the Free plan.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // COST INFO
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5E7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "💡 Cost was the reason? Switching to Basic keeps\n"
                            "templates & AI tools from just ₹199/mo — no need to\n"
                            "lose everything.",
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // LOSE ACCESS
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "YOU'LL LOSE ACCESS TO",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 8),

                              if (features.isEmpty)
                                const Text(
                                  "❌ Premium plan features",
                                  style: TextStyle(fontSize: 10),
                                )
                              else
                                ...features.map(
                                  (feature) => Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: Text(
                                      "❌  $feature",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // KEEP PLAN
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "KEEP MY PLAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // CONFIRM CANCEL
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: provider.isCancellingPlan
                                ? null
                                : () => _confirmCancellation(provider),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: provider.isCancellingPlan
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Text(
                                    "CONFIRM CANCELLATION",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _confirmCancellation(
      PlanProvider provider,
      ) async {
    final success = await provider.cancelSubscription();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Your subscription has been cancelled successfully.",
          ),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        "/MySubscriptionScreen",
            (route) => false,
        arguments: {
          "hideBackButton": true,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.cancelPlanError ??
                "Unable to cancel subscription.",
          ),
        ),
      );
    }
  }

  List<String> _getFeatures(Map<String, dynamic>? data) {
    if (data == null) return [];

    final plan = data["plan"];

    if (plan is! Map) return [];

    final dynamic rawFeatures =
        plan["features"] ?? plan["plan_features"] ?? plan["included_features"];

    if (rawFeatures is! List) return [];

    return rawFeatures
        .map((item) {
          if (item is String) {
            return item;
          }

          if (item is Map) {
            return item["name"]?.toString() ??
                item["label"]?.toString() ??
                item["title"]?.toString();
          }

          return null;
        })
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList();
  }
}
