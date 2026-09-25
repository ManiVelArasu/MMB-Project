import 'package:flutter/material.dart';

class PaymentDetailsScreen extends StatelessWidget {
  const PaymentDetailsScreen({super.key});

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
            width: 27,
            height: 27,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.red,
              size: 16,
            ),
          ),
        ),
        title: const Text(
          "Payment Details",
          style: TextStyle(
            color: Color(0xFF171A2B),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(9, 0, 9, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================================================
            // PAYMENT DETAILS CARD
            // =========================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              child: Column(
                children: [

                  // Transaction status
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "TRANSACTION STATUS",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Google Pay (UPI)",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1FAF3),
                          borderRadius:
                          BorderRadius.circular(7),
                        ),
                        child: const Text(
                          "SUCCESSFUL",
                          style: TextStyle(
                            color: Color(0xFF00A878),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEAEAEA),
                  ),

                  const SizedBox(height: 8),

                  _detailRow(
                    "Plan Purchased",
                    "Premium - Monthly",
                  ),

                  _detailRow(
                    "Transaction ID",
                    "TXN908124992",
                  ),

                  _detailRow(
                    "Date & Time",
                    "12 Aug 2026, 10:24 AM",
                  ),

                  _detailRow(
                    "Base Amount",
                    "₹422.88",
                  ),

                  _detailRow(
                    "GST (18%)",
                    "₹76.12",
                  ),

                  const SizedBox(height: 5),

                  const Divider(
                    height: 1,
                    color: Color(0xFFEAEAEA),
                  ),

                  const SizedBox(height: 11),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Total Paid",
                        style: TextStyle(
                          color: Color(0xFF171A2B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "₹499.00",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =========================================================
            // INVOICE / RECEIPT BUTTONS
            // =========================================================

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 39,
                    child: OutlinedButton(
                      onPressed: () {
                        // Invoice action
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.red,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        "INVOICE",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: SizedBox(
                    height: 39,
                    child: ElevatedButton(
                      onPressed: () {
                        // Receipt action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        "RECEIPT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // =========================================================
            // BILLING DETAILS
            // =========================================================

            const Text(
              "BILLING DETAILS",
              style: TextStyle(
                color: Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                11,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E2E2),
                ),
              ),
              child: Column(
                children: const [
                  _BillingRow(
                    title: "Billed To",
                    value: "Sarah Joshua",
                  ),
                  SizedBox(height: 8),
                  _BillingRow(
                    title: "Email/Mobile",
                    value: "sarah@mail.com",
                  ),
                  SizedBox(height: 8),
                  _BillingRow(
                    title: "GSTIN",
                    value: "07AAAAA1111A1ZI",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _detailRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 9,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF171A2B),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingRow extends StatelessWidget {
  final String title;
  final String value;

  const _BillingRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 9,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF171A2B),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}