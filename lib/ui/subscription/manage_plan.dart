import 'package:flutter/material.dart';

class ManagePlanScreen extends StatelessWidget {
  const ManagePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.red,
              size: 17,
            ),
          ),
        ),
        title: const Text(
          "Manage Plan",
          style: TextStyle(
            color: Color(0xFF171A2B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // CURRENT PLAN
              // =========================================================
        
              const SizedBox(height: 2),
        
              const Text(
                "CURRENT PLAN",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
        
              const SizedBox(height: 7),
        
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(13, 14, 13, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E2E2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Premium",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF171A2B),
                          ),
                        ),
                        Text(
                          "₹499/mo",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF171A2B),
                          ),
                        ),
                      ],
                    ),
        
                    const SizedBox(height: 2),
        
                    const Text(
                      "Monthly Plan - Renewal on 12 Sep, 2026",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
        
                    const SizedBox(height: 6),
        
                    const Text(
                      "2000 Static, 500 Video Templates, 1000 AI Credits,\n"
                          "5 Brand Series",
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF555555),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
        
              const SizedBox(height: 16),
        
              // =========================================================
              // PLAN BUTTONS
              // =========================================================
        
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            "/PlanUsageScreen",
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.red,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "PLAN USAGE",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
        
                  const SizedBox(width: 9),

                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) {
                              return const _ChangePlanBottomSheet();
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "CHANGE PLAN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        
              const SizedBox(height: 18),
        
              // =========================================================
              // PAYMENT HISTORY
              // =========================================================
        
              const Text(
                "PAYMENT HISTORY",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
        
              const SizedBox(height: 8),
        
              _paymentCard(
                status: "SUCCESSFUL",
                statusColor: const Color(0xFF00A878),
                statusBackground: const Color(0xFFE1FAF3),
                title: "500 AI Credits - AI TopUp",
                date: "Charged on 22 Aug 2026",
                amount: "₹249",
              ),
        
              const SizedBox(height: 8),
        
              _paymentCard(
                status: "SUCCESSFUL",
                statusColor: const Color(0xFF00A878),
                statusBackground: const Color(0xFFE1FAF3),
                title: "Premium - Monthly Plan",
                date: "Charged on 12 Aug 2026",
                amount: "₹499",
              ),
        
              const SizedBox(height: 8),
        
              _paymentCard(
                status: "FAILED",
                statusColor: const Color(0xFFFF3038),
                statusBackground: const Color(0xFFFFE5E7),
                title: "Premium - Monthly Plan",
                date: "Charged on 12 Aug 2026",
                amount: "₹499",
              ),
        
              const SizedBox(height: 8),
        
              _paymentCard(
                status: "PENDING",
                statusColor: const Color(0xFFE6A900),
                statusBackground: const Color(0xFFFFF1C7),
                title: "Basic - Monthly Plan",
                date: "Charged on 12 May 2026",
                amount: "₹199",
              ),
        
              const SizedBox(height: 8),
        
              _paymentCard(
                status: "SUCCESSFUL",
                statusColor: const Color(0xFF00A878),
                statusBackground: const Color(0xFFE1FAF3),
                title: "Basic - Trial Account",
                date: "Charged on 12 May 2026",
                amount: "₹0",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // PAYMENT CARD
  // ===============================================================

  Widget _paymentCard({
    required String status,
    required Color statusColor,
    required Color statusBackground,
    required String title,
    required String date,
    required String amount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        12,
        13,
        11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E2E2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Arrow
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius:
                  BorderRadius.circular(7),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius:
                  BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.north_east,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Title + Amount
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF171A2B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFF171A2B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            date,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePlanBottomSheet extends StatelessWidget {
  const _ChangePlanBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          10,
          12,
          10,
          18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Handle
            Center(
              child: Container(
                width: 55,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Change Plan",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF171A2B),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE5E7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Text(
              "SELECT THE PLAN",
              style: TextStyle(
                color: Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            // Elite plan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                12,
                11,
                12,
                11,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFFFFD5D8),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Elite",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "₹999/mo",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    "•  3,000 AI Credits + Business Listing",
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Price details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                12,
                11,
                12,
                11,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              child: Column(
                children: const [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Prorated difference",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "₹500",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 9),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Charged today",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "₹500",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 39,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  // Upgrade API / Payment
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  "PAY DIFFERENCE & UPGRADE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 9),

            const Center(
              child: Text(
                "Downgrades take effect from your next billing cycle instead of\n"
                    "charging you today.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}