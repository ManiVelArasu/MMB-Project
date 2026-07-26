import 'package:flutter/material.dart';

class BasicPlanScreen extends StatefulWidget {
  const BasicPlanScreen({super.key});

  @override
  State<BasicPlanScreen> createState() => _BasicPlanScreenState();
}

class _BasicPlanScreenState extends State<BasicPlanScreen> {
  bool isMonthlySelected = true;

  final List<Map<String, dynamic>> features = [
    {'title': '500 Business post templates', 'isAvailable': true},
    {'title': '200 Video templates', 'isAvailable': true},
    {'title': 'SM Themes', 'isAvailable': false},
    {'title': '2 Free AI logo Generations', 'isAvailable': true},
    {'title': '500 AI Bg remover Credits', 'isAvailable': true},
    {'title': '50 AI Image generation Credits', 'isAvailable': true},
    {'title': 'WhatsApp Stickers', 'isAvailable': true},
    {'title': 'Monthly SM Calendar', 'isAvailable': false},
    {'title': 'Schedule Posts', 'isAvailable': false},
    {'title': 'WhatsApp Stickers', 'isAvailable': true},
    {'title': 'List your Business in MMB', 'isAvailable': true},
  ];

  @override
  Widget build(BuildContext context) {
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),

                const SizedBox(height: 16),

                // Title
                const Center(
                  child: Text(
                    'Basic Plan',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pricing Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildPricingCard(
                        amount: '₹250',
                        period: '/month',
                        isSelected: isMonthlySelected,
                        onTap: () {
                          setState(() {
                            isMonthlySelected = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildPricingCard(
                        amount: '₹1999',
                        period: '/year',
                        isSelected: !isMonthlySelected,
                        onTap: () {
                          setState(() {
                            isMonthlySelected = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Plan Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Our Basic plan is perfect for Personal/small businesses posting 2–3 times a week.',
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

                // Feature List
                Column(
                  children: features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: feature['isAvailable']
                                  ? const Color(0xFF81C784)
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              feature['isAvailable']
                                  ? Icons.check
                                  : Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature['title'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: feature['isAvailable']
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

                // Pay Now Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle payment action
                    },
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

                // Footer Information
                Center(
                  child: Column(
                    children: [
                      Text(
                        isMonthlySelected
                            ? "You'll be charged Rs.250 per month. You can cancel anytime"
                            : "You'll be charged Rs.1999 per year. You can cancel anytime",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
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
                            child: TextStyleLink(text: 'Terms of use'),
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
                            child: TextStyleLink(text: 'Refund policy'),
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
