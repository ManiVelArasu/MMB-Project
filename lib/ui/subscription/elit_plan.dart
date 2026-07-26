import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class ElitePlanScreen extends StatefulWidget {
  const ElitePlanScreen({super.key});

  @override
  State<ElitePlanScreen> createState() => _ElitePlanScreenState();
}

class _ElitePlanScreenState extends State<ElitePlanScreen> {
  bool isMonthlySelected = true;

  final List<Map<String, dynamic>> features = [
    {'title': '2000 Business post templates', 'isAvailable': true},
    {'title': '1000 Video templates', 'isAvailable': true},
    {'title': 'SM Themes', 'isAvailable': true},
    {'title': '10 Free AI logo Generations', 'isAvailable': true},
    {'title': '3000 AI Bg remover Credits', 'isAvailable': true},
    {'title': '500 AI Image generation Credits', 'isAvailable': true},
    {'title': 'WhatsApp Stickers', 'isAvailable': true},
    {'title': 'Monthly SM Calendar', 'isAvailable': true},
    {'title': 'Schedule Posts', 'isAvailable': true},
    {'title': 'WhatsApp Stickers', 'isAvailable': true},
    {'title': 'List your Business in MMB', 'isAvailable': true},
  ];

  static const Color accentPurple = Color(0xFF9E86FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEBE6FF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Center(
                  child: Text(
                    'Elite Plan',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pricing Row
                Row(
                  children: [
                    Expanded(
                      child: _buildPricingCard(
                        amount: '₹999',
                        period: '/month',
                        isSelected: isMonthlySelected,
                        onTap: () => setState(() => isMonthlySelected = true),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildPricingCard(
                        amount: '₹9999',
                        period: '/year',
                        isSelected: !isMonthlySelected,
                        onTap: () => setState(() => isMonthlySelected = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Plan Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Our Elite plan is perfect for all businesses posting more than 6 times a week.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Features
                Column(
                  children: features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: accentPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'PAY NOW',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        isMonthlySelected
                            ? "You'll be charged Rs.999 per month. You can cancel anytime"
                            : "You'll be charged Rs.9999 per year. You can cancel anytime",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Terms of use', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF385A80))),
                          Text(' | ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Refund policy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF385A80))),
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
                color: isSelected ? accentPurple : Colors.transparent,
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
                color: accentPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}
