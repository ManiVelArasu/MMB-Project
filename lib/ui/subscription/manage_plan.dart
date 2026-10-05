import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:provider/provider.dart';

import '../../network/provider/plan_provider.dart';
import 'invoice_screen.dart';

class ManagePlanScreen extends StatelessWidget {
  const ManagePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanProvider()
        ..fetchMySubscription()
        ..fetchPaymentHistory(),
      child: const _ManagePlanView(),
    );
  }
}

class _ManagePlanView extends StatelessWidget {
  const _ManagePlanView();

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return "--";
    }

    try {
      final parsed = DateTime.parse(date);

      return "${parsed.day.toString().padLeft(2, '0')} "
          "${_monthName(parsed.month)} "
          "${parsed.year}";
    } catch (_) {
      return date;
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return months[month - 1];
  }

  // ============================================================
  // CURRENT PLAN FEATURES
  // ============================================================

  String _getFeaturesText(Map<String, dynamic>? data) {
    if (data == null) {
      return "";
    }

    final features = data["features"];

    if (features is! List || features.isEmpty) {
      return "";
    }

    final List<String> featureTexts = [];

    for (final item in features) {
      if (item is! Map) {
        continue;
      }

      final label = item["label"]?.toString() ?? "";
      final remaining = item["remaining"];
      final limit = item["limit"];
      final unlimited = item["unlimited"] == true;

      if (label.isEmpty) {
        continue;
      }

      String text = label;

      if (unlimited) {
        text = "$label - Unlimited";
      } else if (remaining != null) {
        text = "$label - $remaining remaining";
      } else if (limit != null) {
        text = "$label - $limit";
      }

      featureTexts.add(text);
    }

    return featureTexts.join("\n");
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    final data = provider.subscriptionData;

    final plan = data?["plan"];
    final billing = data?["billing"];
    final period = data?["period"];
    final subscription = data?["subscription"];

    final planName = plan is Map
        ? plan["name"]?.toString() ?? "Premium"
        : "Premium";

    final billingPrice = billing is Map
        ? billing["price"]?.toString() ?? "0"
        : "0";

    final billingCycle = billing is Map
        ? billing["cycle"]?.toString() ?? "monthly"
        : "monthly";

    final currency = billing is Map
        ? billing["currency"]?.toString() ?? "INR"
        : "INR";

    final renewalDate = period is Map ? period["end"]?.toString() : null;

    final subscriptionStatus = subscription is Map
        ? subscription["status"]?.toString() ?? "active"
        : "active";

    final autoRenew = subscription is Map
        ? subscription["auto_renew"] == true
        : false;

    final featuresText = _getFeaturesText(data);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),

      // ========================================================
      // APP BAR
      // ========================================================
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
            child: const Icon(Icons.arrow_back, color: Colors.red, size: 17),
          ),
        ),

        title: const AppText(
          "Manage Plan",
          style: TextStyle(
            color: Color(0xFF171A2B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: provider.isLoadingSubscription && data == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // CURRENT PLAN
                    // =================================================

                    const SizedBox(height: 2),

                    const AppText(
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
                        border: Border.all(color: const Color(0xFFE2E2E2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -----------------------------------------
                          // PLAN NAME + PRICE
                          // -----------------------------------------

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                planName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF171A2B),
                                ),
                              ),

                              AppText(
                                "$currency $billingPrice/$billingCycle",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF171A2B),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // -----------------------------------------
                          // RENEWAL
                          // -----------------------------------------
                          AppText(
                            "${billingCycle[0].toUpperCase()}${billingCycle.substring(1)} "
                            "Plan - Renewal on ${_formatDate(renewalDate)}",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // -----------------------------------------
                          // FEATURES
                          // -----------------------------------------
                          AppText(
                            featuresText.isEmpty
                                ? "No feature details available"
                                : featuresText,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF555555),
                              height: 1.45,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // -----------------------------------------
                          // STATUS
                          // -----------------------------------------
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1FAF3),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: AppText(
                                  subscriptionStatus.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF00A878),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              if (autoRenew)
                                const AppText(
                                  "Auto-renew ON",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF555555),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // PLAN BUTTONS
                    // =================================================
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
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const AppText(
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const AppText(
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

                    // =================================================
                    // PAYMENT HISTORY
                    // STATIC
                    // =================================================
                    Consumer<PlanProvider>(
                      builder: (context, provider, child) {
                        final items =
                            provider.paymentHistoryData?.data?.items ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              "PAYMENT HISTORY",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 8),

                            if (provider.isLoadingPaymentHistory)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (provider.paymentHistoryError != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: AppText(
                                  provider.paymentHistoryError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: AppText(
                                    "No payment history found",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final payment = items[index];

                                  final status =
                                      payment.status?.trim().toUpperCase() ??
                                      "UNKNOWN";

                                  return _paymentCard(
                                    status: _getPaymentStatusText(status),
                                    statusColor: _getPaymentStatusColor(status),
                                    statusBackground:
                                        _getPaymentStatusBackground(status),
                                    title:
                                        payment.description
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? payment.description!.trim()
                                        : "Payment",
                                    date: _formatPaymentDate(payment.date),
                                    amount: _formatPaymentAmount(
                                      payment.amount,
                                      payment.currency,
                                    ),
                                    invoice: "Invoice",
                                    receipt: "Receipt",
                                    onInvoiceTap: () async {
                                      debugPrint("Invoice clicked");

                                      final invoiceId = provider
                                          .paymentHistoryData
                                          ?.data
                                          ?.lastTransaction
                                          ?.uid;

                                      if (invoiceId == null ||
                                          invoiceId.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Invoice ID not found",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      debugPrint("Invoice UID: $invoiceId");

                                      final success = await provider.getInvoice(
                                        invoiceId,
                                      );

                                      if (!context.mounted) return;

                                      if (success &&
                                          provider.invoiceHtml != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => InvoiceScreen(
                                              html: provider.invoiceHtml!,
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              provider.invoiceError ??
                                                  "Unable to load invoice",
                                            ),
                                          ),
                                        );
                                      }
                                    },

                                    onReceiptTap: () async {
                                      debugPrint("Invoice clicked");

                                      final invoiceId = provider
                                          .paymentHistoryData
                                          ?.data
                                          ?.lastTransaction
                                          ?.uid;

                                      if (invoiceId == null ||
                                          invoiceId.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Invoice ID not found",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      debugPrint("Invoice UID: $invoiceId");

                                      final success = await provider.getReceipt(
                                        invoiceId,
                                      );

                                      if (!context.mounted) return;

                                      if (success &&
                                          provider.isReceiptHtml != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => InvoiceScreen(
                                              html: provider.isReceiptHtml!,
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              provider.invoiceError ??
                                                  "Unable to load invoice",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatPaymentAmount(String? amount, String? currency) {
    final value = amount?.trim();

    if (value == null || value.isEmpty) {
      return "—";
    }

    final currencyCode = currency?.trim().toUpperCase();

    if (currencyCode == null || currencyCode.isEmpty) {
      return value;
    }

    if (currencyCode == "INR") {
      return "₹$value";
    }

    return "$currencyCode $value";
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case "SUCCESS":
      case "SUCCESSFUL":
      case "COMPLETED":
      case "PAID":
        return "SUCCESSFUL";

      case "FAILED":
      case "FAILURE":
        return "FAILED";

      case "PENDING":
        return "PENDING";

      default:
        return status.isEmpty ? "UNKNOWN" : status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case "SUCCESS":
      case "SUCCESSFUL":
      case "COMPLETED":
      case "PAID":
        return const Color(0xFF00A878);

      case "FAILED":
      case "FAILURE":
        return const Color(0xFFFF3038);

      case "PENDING":
        return const Color(0xFFE6A900);

      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusBackground(String status) {
    switch (status) {
      case "SUCCESS":
      case "SUCCESSFUL":
      case "COMPLETED":
      case "PAID":
        return const Color(0xFFE1FAF3);

      case "FAILED":
      case "FAILURE":
        return const Color(0xFFFFE5E7);

      case "PENDING":
        return const Color(0xFFFFF1C7);

      default:
        return const Color(0xFFF2F2F2);
    }
  }

  String _formatPaymentDate(DateTime? date) {
    if (date == null) {
      return "Date not available";
    }

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "Charged on ${date.day} ${months[date.month - 1]} ${date.year}";
  }
  // =============================================================
  // PAYMENT CARD
  // =============================================================

  Widget _paymentCard({
    required String status,
    required Color statusColor,
    required Color statusBackground,
    required String title,
    required String date,
    required String amount,
    required String invoice,
    required String receipt,

    // 👇 callbacks
    VoidCallback? onInvoiceTap,
    VoidCallback? onReceiptTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(7),
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
                  borderRadius: BorderRadius.circular(5),
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppText(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF171A2B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              AppText(
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

          AppText(
            date,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 9),
          ),

          const SizedBox(height: 3),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: onInvoiceTap,
                child: AppText(
                  invoice,
                  style: const TextStyle(
                    color: Color(0xFF171A2B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              InkWell(
                onTap: onReceiptTap,
                child: AppText(
                  receipt,
                  style: const TextStyle(
                    color: Color(0xFF171A2B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// CHANGE PLAN BOTTOM SHEET
// =================================================================

class _ChangePlanBottomSheet extends StatelessWidget {
  const _ChangePlanBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Row(
              children: [
                const Expanded(
                  child: AppText(
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
                    child: const Icon(Icons.close, color: Colors.red, size: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const AppText(
              "SELECT THE PLAN",
              style: TextStyle(
                color: Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFFFD5D8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Elite",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      AppText(
                        "₹999/mo",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 7),

                  AppText(
                    "•  3,000 AI Credits + Business Listing",
                    style: TextStyle(fontSize: 9, color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFE2E2E2)),
              ),
              child: Column(
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Prorated difference",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),

                      AppText(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Charged today",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      AppText(
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
                child: const AppText(
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
                style: TextStyle(fontSize: 8, color: Colors.grey, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
