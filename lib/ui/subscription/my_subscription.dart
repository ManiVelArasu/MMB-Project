import 'package:flutter/material.dart';

import 'change_plan_screen.dart';

class MySubscriptionScreen extends StatelessWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF9),
      body: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            Container(
              height: 72,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE5E7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFFFF2027),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Text(
                    "My Subscription",
                    style: TextStyle(
                      color: Color(0xFF171A2B),
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // BODY
            // ====================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const SizedBox(height: 0),

                    // ==================================================
                    // PREMIUM CARD
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB4DB), Color(0xFFF6D9F0)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFA5D3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ------------------------------------------
                          // PLAN NAME + ACTIVE
                          // ------------------------------------------

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Premium",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF2027),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "ACTIVE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ------------------------------------------
                          // RENEW TEXT
                          // ------------------------------------------
                          const Text(
                            "Your plan will automatically renew next month.",
                            style: TextStyle(
                              color: Color(0xFF59545D),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ------------------------------------------
                          // FEATURES
                          // ------------------------------------------
                          const Text(
                            "2000 Static, 500 Video Templates, 1000 AI\n"
                            "Credits, 5 Brand Series",
                            style: TextStyle(
                              color: Color(0xFF59545D),
                              fontSize: 12,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ==================================================
                    // DAYS CIRCLE
                    // ==================================================
                    SizedBox(
                      width: 145,
                      height: 145,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          SizedBox(
                            width: 145,
                            height: 145,
                            child: CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 10,
                              backgroundColor: const Color(0xFFEDEBE7),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFEDEBE7),
                              ),
                            ),
                          ),

                          // Red progress
                          SizedBox(
                            width: 145,
                            height: 145,
                            child: CircularProgressIndicator(
                              value: 0.75,
                              strokeWidth: 10,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF2027),
                              ),
                            ),
                          ),

                          // Center content
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "17",
                                    style: TextStyle(
                                      color: Color(0xFF171A2B),
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 7),
                                    child: Text(
                                      "Days",
                                      style: TextStyle(
                                        color: Color(0xFF171A2B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 1),

                              Text(
                                "TILL RENEWAL",
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ==================================================
                    // SUBSCRIPTION DETAILS
                    // ==================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE4E0DB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _detailRow(title: "Renews on", value: "12 Sept 2026"),

                          const SizedBox(height: 16),

                          _detailRow(
                            title: "Auto Renewal",
                            value: "ON",
                            valueColor: const Color(0xFFFF2027),
                          ),

                          const SizedBox(height: 16),

                          _detailRow(
                            title: "Payment Method",
                            value: "Razorpay • UPI",
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // SPACE
                    // ==================================================
                    const SizedBox(height: 132),

                    // ==================================================
                    // MANAGE PLAN
                    // ==================================================
                    _buildActionButton(
                      title: "MANAGE PLAN",
                      backgroundColor: const Color(0xFFFF2027),
                      borderColor: const Color(0xFFFF2027),
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.pushNamed(context, "/ManagePlanScreen");
                      },
                    ),

                    const SizedBox(height: 10),

                    // ==================================================
                    // CANCEL RENEWAL
                    // ==================================================
                    _buildActionButton(
                      title: "CANCEL RENEWAL",
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFF171A2B),
                      textColor: const Color(0xFF171A2B),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/ChangePlanScreen",
                          arguments: {"openCancelSheet": true},
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // DETAIL ROW
  // ==============================================================

  Widget _detailRow({
    required String title,
    required String value,
    Color valueColor = const Color(0xFF171A2B),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // ACTION BUTTON
  // ==============================================================

  Widget _buildActionButton({
    required String title,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
