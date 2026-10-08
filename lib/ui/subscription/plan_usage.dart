import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../Api Model/plan_usage.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/plan_provider.dart';

class PlanUsageScreen extends StatefulWidget {
  const PlanUsageScreen({super.key});

  @override
  State<PlanUsageScreen> createState() => _PlanUsageScreenState();
}

class _PlanUsageScreenState extends State<PlanUsageScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("================================");
    debugPrint("✅ AI CREDIT PAYMENT SUCCESS");
    debugPrint("Payment ID: ${response.paymentId}");
    debugPrint("Order ID: ${response.orderId}");
    debugPrint("Signature: ${response.signature}");
    debugPrint("================================");

    if (response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      debugPrint("❌ Razorpay response data missing");
      return;
    }

    final provider = context.read<PlanProvider>();

    final success = await provider.verifyAiPayment(
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
    );

    if (!mounted) return;

    if (success) {
      // Close bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Refresh usage
      await provider.fetchPlanUsage();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI Credits added successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.cancelPlanError ?? "Payment verification failed",
          ),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("================================");
    debugPrint("❌ AI CREDIT PAYMENT FAILED");
    debugPrint("Code: ${response.code}");
    debugPrint("Message: ${response.message}");
    debugPrint("================================");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanProvider()..fetchPlanUsage(),
      child: _PlanUsageView(razorpay: _razorpay),
    );
  }
}

class _PlanUsageView extends StatelessWidget {
  final Razorpay razorpay;

  const _PlanUsageView({required this.razorpay});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    final features = provider.planUsageData?.data?.features ?? [];

    final period = provider.planUsageData?.data?.period;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.red),
        ),

        title: const AppText(
          "Plan Usage",
          style: TextStyle(
            color: Color(0xFF171A2B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: provider.isLoadingPlanUsage && provider.planUsageData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : provider.planUsageError != null && provider.planUsageData == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AppText(
                  provider.planUsageError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            )
          : features.isEmpty
          ? const Center(child: AppText("No usage data found"))
          : RefreshIndicator(
              color: Colors.red,
              onRefresh: () async {
                await provider.fetchPlanUsage();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                children: [
                  if (period?.end != null) _buildResetText(period!.end!),

                  ..._buildFeatureCards(features),

                  const SizedBox(height: 12),

                  _buildCalculationText(),

                  const SizedBox(height: 28),

                  _buildTopUpButton(context),

                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // RESET TEXT
  // ------------------------------------------------------------

  Widget _buildResetText(DateTime endDate) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
      child: AppText(
        "EVERYTHING INCLUDED IN PREMIUM RESETS "
        "${_formatDate(endDate).toUpperCase()}",
        style: const TextStyle(
          fontSize: 8,
          color: Color(0xFF555555),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FEATURE CARDS
  // ------------------------------------------------------------

  List<Widget> _buildFeatureCards(List<Feature> features) {
    final List<Widget> widgets = [];

    for (final feature in features) {
      final label = (feature.label ?? feature.key ?? "").trim();

      if (_isAiCredits(feature)) {
        widgets.add(_buildAiCreditsCard(feature));

        widgets.add(const SizedBox(height: 8));

        continue;
      }

      widgets.add(_buildNormalFeatureCard(feature));

      widgets.add(const SizedBox(height: 8));
    }

    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }

    return widgets;
  }

  // ------------------------------------------------------------
  // NORMAL FEATURE CARD
  // ------------------------------------------------------------

  Widget _buildNormalFeatureCard(Feature feature) {
    final bool unlimited = feature.unlimited == true;

    final String? limitString = feature.effectiveLimit ?? feature.limit;

    final bool hasLimit =
        !unlimited && limitString != null && limitString.trim().isNotEmpty;

    final double used = _toDouble(feature.used);
    final double limit = _toDouble(limitString);

    final double progress = hasLimit ? _calculateProgress(used, limit) : 0;

    final String title = feature.label ?? feature.key ?? "Feature";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE6E1DC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A2B),
                  ),
                ),
              ),

              // Unlimited
              if (unlimited)
                const AppText(
                  "Unlimited",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A2B),
                  ),
                )
              // Limit available
              else if (hasLimit)
                AppText(
                  "${_formatNumber(used)} / "
                  "${_formatNumber(limit)}",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A2B),
                  ),
                ),
            ],
          ),

          // Progress line ONLY when limit exists
          if (hasLimit) ...[
            const SizedBox(height: 6),

            _buildProgressLine(progress),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // AI CREDITS CARD
  // ------------------------------------------------------------

  Widget _buildAiCreditsCard(Feature feature) {
    final double used = _toDouble(feature.used);

    final double limit = _toDouble(feature.effectiveLimit ?? feature.limit);

    final double remaining = _toDouble(feature.remaining);

    final double topupGranted = _toDouble(feature.topupGranted);

    final double progress = _calculateProgress(used, limit);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE + REMAINING
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppText(
                  feature.label ?? "AI Credits",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A2B),
                  ),
                ),
              ),

              AppText(
                "Remaining ${_formatNumber(remaining)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // PROGRESS
          _buildProgressLine(progress),

          const SizedBox(height: 8),

          // USED THIS CYCLE
          Row(
            children: [
              const AppText(
                "Used this cycle",
                style: TextStyle(fontSize: 9, color: Color(0xFF666666)),
              ),

              const Spacer(),

              AppText(
                "${_formatNumber(used)} / "
                "${_formatNumber(limit)}",
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),

          // TOP UP
          if (topupGranted > 0) ...[
            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AppText(
                "Additional Credits Purchased "
                "+${_formatNumber(topupGranted)}",
                style: const TextStyle(fontSize: 8, color: Color(0xFF555555)),
              ),
            ),
          ],

          // BREAKDOWN
          if (feature.breakdown != null && feature.breakdown!.isNotEmpty) ...[
            const SizedBox(height: 8),

            _buildBreakdown(feature.breakdown!),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // AI BREAKDOWN
  // ------------------------------------------------------------

  Widget _buildBreakdown(List<dynamic> breakdown) {
    final List<Widget> children = [];

    for (final item in breakdown) {
      if (item is! Map) {
        continue;
      }

      final String label =
          item["label"]?.toString() ??
          item["name"]?.toString() ??
          item["title"]?.toString() ??
          "";

      final String credits =
          item["credits"]?.toString() ??
          item["amount"]?.toString() ??
          item["limit"]?.toString() ??
          item["value"]?.toString() ??
          "";

      if (label.isEmpty) {
        continue;
      }

      children.add(_buildBreakdownItem(label: label, credits: credits));
    }

    return Wrap(spacing: 5, runSpacing: 5, children: children);
  }

  Widget _buildBreakdownItem({required String label, required String credits}) {
    return Container(
      width: 102,
      constraints: const BoxConstraints(minHeight: 47),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD7DA)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171A2B),
            ),
          ),

          const SizedBox(height: 3),

          AppText(
            credits.isEmpty ? "Credits" : "$credits Credits",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PROGRESS LINE
  // ------------------------------------------------------------

  Widget _buildProgressLine(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFEAE7E3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CALCULATION
  // ------------------------------------------------------------

  Widget _buildCalculationText() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // TODO:
          // Navigate to AI Credits Usage Calculation
        },
        child: const AppText(
          "AI Credits Usage Calculation",
          style: TextStyle(
            fontSize: 9,
            color: Color(0xFF555555),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP UP BUTTON
  // ------------------------------------------------------------

  Widget _buildTopUpButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () async {
          final provider = context.read<PlanProvider>();

          final success = await provider.fetchAiTopUp();

          if (!context.mounted) return;

          if (success) {
            _showAiTopUpBottomSheet(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.aiTopUpError ?? "Unable to load AI credits",
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF51F29),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          "TOP UP AI CREDITS",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showAiTopUpBottomSheet(BuildContext context) {
    final provider = context.read<PlanProvider>();
    final topUp = provider.aiTopUpData;

    if (topUp == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 25),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HANDLE
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

                const SizedBox(height: 18),

                // TITLE
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Top Up AI Credits",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF171A2B),
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close, size: 21),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // =================================================
                // AI CREDIT CARD
                // =================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD7DA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BADGE
                      if (topUp.badge != null &&
                          topUp.badge!.toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2027),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            topUp.badge!.toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // NAME
                      Text(
                        topUp.name ?? "AI Credits",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF171A2B),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // DESCRIPTION
                      if (topUp.description != null &&
                          topUp.description!.isNotEmpty)
                        Text(
                          topUp.description!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // CREDITS
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFFF2027),
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            "${topUp.quantity ?? 0} AI Credits",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // =================================================
                      // ORIGINAL PRICE
                      // =================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Original Price",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF777777),
                            ),
                          ),

                          Text(
                            "₹${topUp.strikePrice ?? "0"}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      // =================================================
                      // ACTUAL PRICE
                      // =================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Actual Price",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF171A2B),
                            ),
                          ),

                          Text(
                            "₹${topUp.price ?? "0"}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF2027),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // GST
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "GST",
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF777777),
                            ),
                          ),
                          Text(
                            "₹${topUp.gstAmount ?? "0"}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Divider(),

                      const SizedBox(height: 8),

                      // TOTAL
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Price",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            "₹${topUp.totalPrice ?? "0"}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF2027),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // BUY BUTTON
                // =================================================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final paymentData = await provider.quotaAiPack(
                        topUp.uid ?? '',
                      );
                      final options = {
                        'key': 'rzp_test_TWag5Xvk4KWWgY', // ✅ Razorpay KEY ID
                        'amount': 5900, // ₹59
                        'currency': 'INR',
                        'order_id':
                            paymentData?.orderId, // order_TlOWS90GVJ99Kf
                        'name': 'MMB',
                        'description': 'AI Credits',
                      };

                      debugPrint("========== RAZORPAY OPTIONS ==========");
                      debugPrint("KEY: ${options['key']}");
                      debugPrint("AMOUNT: ${options['amount']}");
                      debugPrint("CURRENCY: ${options['currency']}");
                      debugPrint("ORDER ID: ${options['order_id']}");
                      debugPrint("======================================");

                      razorpay.open(options);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2027),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      "BUY NOW",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ------------------------------------------------------------
  // AI CREDIT CHECK
  // ------------------------------------------------------------

  bool _isAiCredits(Feature feature) {
    final label = feature.label?.trim().toLowerCase() ?? "";

    final key = feature.key?.trim().toLowerCase() ?? "";

    return label.contains("ai credit") ||
        key.contains("ai_credit") ||
        key.contains("ai-credits");
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  double _toDouble(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 0;
    }

    return double.tryParse(value.replaceAll(",", "")) ?? 0;
  }

  double _calculateProgress(double used, double limit) {
    if (limit <= 0) {
      return 0;
    }

    return (used / limit).clamp(0.0, 1.0);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
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

    return "${date.day.toString().padLeft(2, '0')} "
        "${months[date.month - 1]} "
        "${date.year}";
  }
}
