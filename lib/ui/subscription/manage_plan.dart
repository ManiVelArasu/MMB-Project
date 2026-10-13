import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/subscription/razor_pay.dart';
import 'package:mmb_app/widgets/button_widget.dart';
import 'package:provider/provider.dart';
import '../../Api Model/plans_type.dart';
import '../../network/provider/plan_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import 'invoice_screen.dart';

class ManagePlanScreen extends StatelessWidget {
  final bool openCancelSheet;

  const ManagePlanScreen({super.key, this.openCancelSheet = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanProvider()
        ..fetchMySubscription()
        ..fetchPaymentHistory(),
      child: _ManagePlanView(openCancelSheet: openCancelSheet),
    );
  }
}

class _ManagePlanView extends StatefulWidget {
  final bool openCancelSheet;

  const _ManagePlanView({this.openCancelSheet = false});

  @override
  State<_ManagePlanView> createState() => _ManagePlanViewState();
}

class _ManagePlanViewState extends State<_ManagePlanView> {
  bool _cancelSheetOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_cancelSheetOpened) return;

    if (widget.openCancelSheet) {
      _cancelSheetOpened = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCancelRenewalBottomSheet();
      });
    }
  }

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
      final enabled = item["enabled"] == true;
      final limit = item["limit"];

      if (label.isEmpty) {
        continue;
      }

      if (enabled) {
        featureTexts.add(label);
      } else if (limit != null && limit is num && limit > 0) {
        featureTexts.add("$limit $label");
      }
    }

    return featureTexts.join(", ");
  }

  // ============================================================
  // CANCEL RENEWAL BOTTOM SHEET
  // ============================================================

  void _showCancelRenewalBottomSheet() {
    String selectedReason = "I found a better app";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            "What's making you cancel?",
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF171A2B),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(sheetContext);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE5E7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppText(
                      "Before you go, let us know why. It helps us improve\nMake My Brand for everyone.",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.appGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _reasonItem(
                      title: "I found a better app",
                      selected: selectedReason == "I found a better app",
                      onTap: () {
                        setSheetState(() {
                          selectedReason = "I found a better app";
                        });
                      },
                    ),
                    _reasonItem(
                      title: "Too expensive for what I use",
                      selected:
                          selectedReason == "Too expensive for what I use",
                      onTap: () {
                        setSheetState(() {
                          selectedReason = "Too expensive for what I use";
                        });
                      },
                    ),
                    _reasonItem(
                      title: "Missing a feature I need",
                      selected: selectedReason == "Missing a feature I need",
                      onTap: () {
                        setSheetState(() {
                          selectedReason = "Missing a feature I need";
                        });
                      },
                    ),
                    _reasonItem(
                      title: "I don't use it enough",
                      selected: selectedReason == "I don't use it enough",
                      onTap: () {
                        setSheetState(() {
                          selectedReason = "I don't use it enough";
                        });
                      },
                    ),
                    _reasonItem(
                      title: "Technical issues",
                      selected: selectedReason == "Technical issues",
                      onTap: () {
                        setSheetState(() {
                          selectedReason = "Technical issues";
                        });
                      },
                    ),
                    _reasonItem(
                      title: "Other",
                      selected: selectedReason == "Other",
                      onTap: () {
                        setSheetState(() {
                          selectedReason = "Other";
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 55,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "Add your valid inputs",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "BACK",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                debugPrint("Cancel reason: $selectedReason");
                                Navigator.pop(sheetContext);

                                Navigator.pushNamed(
                                  context,
                                  "/ConfirmCancellationScreen",
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "CONTINUE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reasonItem({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE5E7) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.red : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.red : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.red.shade900 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
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
      appBar: widget.openCancelSheet == false
          ? CustomAppBar(title: "Manage Plan", showRightIcon: false)
          : CustomAppBar(title: "Change Plan", showRightIcon: false),
      body: SafeArea(
        child: provider.isLoadingSubscription && data == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    AppText(
                      "CURRENT PLAN",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: AppFontSize.fontSize12,
                        fontWeight: FontWeight.w700,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                planName,
                                style: TextStyle(
                                  fontSize: AppFontSize.fontSize18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF171A2B),
                                ),
                              ),
                              AppText(
                                "₹$currency $billingPrice/$billingCycle"
                                    .replaceAll("nthly", "")
                                    .replaceAll("INR", ""),
                                style: TextStyle(
                                  fontSize: AppFontSize.fontSize18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF171A2B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            "${billingCycle[0].toUpperCase()}${billingCycle.substring(1)} "
                            "Plan - Renewal on ${_formatDate(renewalDate)}",
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize11,
                              color: Colors.red,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppText(
                            featuresText.isEmpty
                                ? "No feature details available"
                                : featuresText,
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              child: AppText(
                                "PLAN USAGE",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: AppFontSize.fontSize16,
                                  fontWeight: FontWeight.w700,
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
                                    return _ChangePlanBottomSheet(
                                      currentPlanName: planName,
                                    );
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
                              child: AppText(
                                "CHANGE PLAN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppFontSize.fontSize16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Consumer<PlanProvider>(
                      builder: (context, provider, child) {
                        final items =
                            provider.paymentHistoryData?.data?.items ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              "PAYMENT HISTORY",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: AppFontSize.fontSize12,
                                fontWeight: FontWeight.w700,
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
                                              html: provider.invoiceHtml ?? '',
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
                                              html:
                                                  provider.isReceiptHtml ?? '',
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
    if (value == null || value.isEmpty) return "—";
    final currencyCode = currency?.trim().toUpperCase();
    if (currencyCode == null || currencyCode.isEmpty) return value;
    if (currencyCode == "INR") return "₹$value";
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
    if (date == null) return "Date not available";
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

  Widget _paymentCard({
    required String status,
    required Color statusColor,
    required Color statusBackground,
    required String title,
    required String date,
    required String amount,
    required String invoice,
    required String receipt,
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
                child: AppText(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: AppFontSize.fontSize12,
                    fontWeight: FontWeight.w700,
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
                  style: TextStyle(
                    color: const Color(0xFF171A2B),
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppText(
                amount,
                style: TextStyle(
                  color: const Color(0xFF171A2B),
                  fontSize: AppFontSize.fontSize18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          AppText(
            date,
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: AppFontSize.fontSize12,
              fontWeight: FontWeight.w400,
            ),
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

// CHANGE PLAN BOTTOM SHEET (Dynamic API with current plan filter & payment flow)
// CHANGE PLAN BOTTOM SHEET (Dynamic API with current plan filter & payment flow)
// CHANGE PLAN BOTTOM SHEET (Filtered based on active plan)
class _ChangePlanBottomSheet extends StatefulWidget {
  final String currentPlanName;

  const _ChangePlanBottomSheet({required this.currentPlanName});

  @override
  State<_ChangePlanBottomSheet> createState() => _ChangePlanBottomSheetState();
}

class _ChangePlanBottomSheetState extends State<_ChangePlanBottomSheet> {
  Plan? selectedPlan;
  PlanBillingOption? selectedBilling;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlanProvider>();
      if (provider.plansData == null) {
        provider.fetchPlans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    final activePlan = widget.currentPlanName.trim().toLowerCase();

    // Filter out current active plan and lower plans if needed
    final plansList = (provider.plansData?.data ?? []).where((plan) {
      final pName = plan.name?.trim().toLowerCase() ?? "";
      if (activePlan.isNotEmpty && pName == activePlan) {
        return false; // Hide current active plan
      }
      return true;
    }).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
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
                  Expanded(
                    child: AppText(
                      "Change Plan",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF171A2B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
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
              AppText(
                "SELECT THE PLAN",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: AppFontSize.fontSize12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),

              provider.isLoadingPlans
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : plansList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        "No other upgrade plans available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plansList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final plan = plansList[index];
                        final billing = plan.planBillingOptions.isNotEmpty
                            ? plan.planBillingOptions.first
                            : null;
                        final isSelected = selectedPlan?.uid == plan.uid;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPlan = plan;
                              selectedBilling = billing;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red
                                    : const Color(0xFFFFD5D8),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppText(
                                      plan.name ?? "Plan",
                                      style: TextStyle(
                                        fontSize: AppFontSize.fontSize18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    AppText(
                                      "₹${billing?.discountedPrice ?? billing?.price ?? '0'}/${billing?.billingCycle ?? 'mo'}"
                                          .replaceAll("nthly", ""),
                                      style: TextStyle(
                                        fontSize: AppFontSize.fontSize18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (plan.description != null &&
                                    plan.description!.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  AppText(
                                    "• ${plan.description}",
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: AppFontSize.fontSize13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         AppText(
                          "Selected Plan",
                          style: TextStyle(  fontSize: AppFontSize.fontSize15,
                              fontWeight: FontWeight.w700, color: Colors.grey),
                        ),
                        AppText(
                          selectedPlan?.name ?? "None selected",
                          style:  TextStyle(
                            fontSize: AppFontSize.fontSize15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         AppText(
                          "Charged today",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppText(
                          "₹${selectedBilling?.discountedPrice ?? selectedBilling?.price ?? '0'}",
                          style:  TextStyle(
                            fontSize: AppFontSize.fontSize15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      provider.isCreatingSubscription ||
                          selectedBilling?.id == null
                      ? null
                      : () async {
                          final subscription = await provider
                              .createSubscription(
                                planBillingOptionId: int.parse(
                                  selectedBilling!.id!,
                                ),
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

                          Navigator.pop(context);

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
                  child: provider.isCreatingSubscription
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const AppText(
                          "PAY DIFFERENCE & UPGRADE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 9),
              const Center(
                child: Text(
                  "Downgrades take effect from your next billing cycle instead of\ncharging you today.",
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
      ),
    );
  }
}
