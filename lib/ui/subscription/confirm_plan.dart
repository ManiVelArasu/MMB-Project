import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mmb_app/network/provider/plan_provider.dart';
import 'package:mmb_app/ui/subscription/razor_pay.dart';

import '../../Api Model/plans_type.dart';


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
      child: _ConfirmPlanContent(
        plan: plan,
        billing: billing,
      ),
    );
  }
}

class _ConfirmPlanContent extends StatelessWidget {
  final Plan plan;
  final PlanBillingOption? billing;

  const _ConfirmPlanContent({
    required this.plan,
    required this.billing,
  });

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

    final String cycle =
    billing?.billingCycle?.toLowerCase() == "annual"
        ? "Annual"
        : "Monthly";

    String formatAmount(double amount) {
      return amount % 1 == 0
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.red,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Confirm Plan",
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
              const SizedBox(height: 16),
        
              // FEATURES
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Premium Features Included:",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "• 500 Video Templates",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "• AI Credits · Brand Series · Social Calendar",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "• Watermark-free downloads & HD Export",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
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
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Plan",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "${plan.name ?? "Plan"} $cycle",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
        
                    const Divider(height: 20),
        
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Price",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "₹${formatAmount(price)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
        
                    const Divider(height: 20),
        
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "GST (18%)",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "₹${formatAmount(gst)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
        
                    const Divider(height: 20),
        
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "₹${formatAmount(total)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
                      : Text(
                    "PROCEED TO PAY ₹${formatAmount(total)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
        
              const SizedBox(height: 8),
        
              const Text(
                "By continuing, you agree to the Terms of Use & Refund Policy. "
                    "Your subscription will renew automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

