import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Confirm Plan",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top Banner Card
      
              const SizedBox(height: 16),
      
              // Features Card (Black)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "• AI Credits · Brand Series · Social Calendar",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "• Watermark-free downloads & HD Export",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
      
              // Proceed Button
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
                  onPressed: () {
                    Navigator.pushNamed(context, "/SubscriptionActivatedScreen");
                  },
                  child: Text(
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
                "By continuing, you agree to the Terms of Use & Refund Policy. Your subscription will renew automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
