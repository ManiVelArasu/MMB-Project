import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

    final String monthlyPrice = monthlyBilling?.price ?? "0";
    final String annualPrice = annualBilling?.price ?? "0";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2F3CB), Color(0xFFF9FCF5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      "assets/images/back.png",
                      height: 26,
                      width: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    widget.plan.name ?? "Plan",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (billingOptions.isNotEmpty)
                  Row(
                    children: [
                      if (monthlyBilling != null)
                        Expanded(
                          child: _buildPricingCard(
                            amount: '₹${monthlyBilling.price}',
                            period: '/month',
                            isSelected: isMonthlySelected,
                            onTap: () =>
                                setState(() => isMonthlySelected = true),
                          ),
                        ),
                      if (monthlyBilling != null && annualBilling != null)
                        const SizedBox(width: 14),
                      if (annualBilling != null)
                        Expanded(
                          child: _buildPricingCard(
                            amount: '₹${annualBilling.price}',
                            period: '/year',
                            isSelected: !isMonthlySelected,
                            onTap: () =>
                                setState(() => isMonthlySelected = false),
                          ),
                        ),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      "Free Plan",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // 🚀 Plan Description (API-ல் உள்ள description)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    widget.plan.description ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Features & Benefits",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                Column(
                  children: widget.plan.features.map((feature) {
                    bool isAvailable = feature.enabled ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? const Color(0xFF81C784)
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isAvailable ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature.displayLabel ?? feature.label ?? "",
                              style: TextStyle(
                                fontSize: 13.5,
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

                const SizedBox(height: 24),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/ConfirmPlanScreen");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'START ${widget.plan.name?.toUpperCase() ?? "PLAN"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                              fontSize: 12,
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
                const SizedBox(height: 16),
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF81C784)
                    : Colors.transparent,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
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
              decoration: const BoxDecoration(
                color: Color(0xFF81C784),
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
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF385A80),
      ),
    );
  }
}
