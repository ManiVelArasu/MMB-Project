import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/plan_provider.dart';

class MySubscriptionScreen extends StatelessWidget {
  final bool hideBackButton;

  const MySubscriptionScreen({super.key, this.hideBackButton = false});

  @override
  Widget build(BuildContext context) {
    final dynamic passedPlan = ModalRoute.of(context)?.settings.arguments;

    return ChangeNotifierProvider<PlanProvider>(
      create: (_) => PlanProvider()
        ..fetchMySubscription()
        ..fetchPlanUsage(),
      child: _MySubscriptionView(
        passedPlan: passedPlan,
        hideBackButton: hideBackButton,
      ),
    );
  }
}

class _MySubscriptionView extends StatelessWidget {
  const _MySubscriptionView({
    super.key,
    this.passedPlan,
    this.hideBackButton = false,
  });

  final dynamic passedPlan;
  final bool hideBackButton;

  // ==========================================================
  // DAYS REMAINING
  // ==========================================================

  int _daysRemaining(String? endDate) {
    if (endDate == null || endDate.isEmpty) {
      return 0;
    }

    try {
      final end = DateTime.parse(endDate).toLocal();

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final expiry = DateTime(end.year, end.month, end.day);

      final difference = expiry.difference(today).inDays;

      return difference < 0 ? 0 : difference;
    } catch (_) {
      return 0;
    }
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return "-";
    }

    try {
      final parsed = DateTime.parse(date).toLocal();

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sept",
        "Oct",
        "Nov",
        "Dec",
      ];

      return "${parsed.day} "
          "${months[parsed.month - 1]} "
          "${parsed.year}";
    } catch (_) {
      return date;
    }
  }

  // ==========================================================
  // FEATURE TEXT
  // ==========================================================

  String _buildFeaturesText(List<dynamic> features) {
    final List<String> result = [];

    for (final item in features) {
      if (item is! Map) {
        continue;
      }

      final label = item["label"]?.toString() ?? "";

      final dataType = item["data_type"]?.toString();

      if (label.isEmpty) {
        continue;
      }

      if (dataType == "boolean") {
        if (item["enabled"] == true) {
          result.add(label);
        }

        continue;
      }

      final limit = item["limit"];

      if (limit != null) {
        result.add("$limit ${_shortFeatureName(label)}");
      } else {
        result.add(label);
      }
    }

    return result.join(", ");
  }

  // ==========================================================
  // SHORT FEATURE NAME
  // ==========================================================

  String _shortFeatureName(String value) {
    if (value.toLowerCase().contains("business post")) {
      return "Static Templates";
    }

    if (value.toLowerCase().contains("video")) {
      return "Video Templates";
    }

    if (value.toLowerCase().contains("ai")) {
      return "AI Credits";
    }

    return value;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF9),

      body: SafeArea(
        child: Consumer<PlanProvider>(
          builder: (context, provider, child) {
            // ==================================================
            // API DATA
            // ==================================================

            final apiData = provider.subscriptionData;

            // Fallback if API not loaded yet
            final fallbackData = (passedPlan is Map<String, dynamic>)
                ? {"plan": passedPlan}
                : null;

            final data = apiData ?? fallbackData;

            // ==================================================
            // LOADING
            // ==================================================

            if (provider.isLoadingSubscription && data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (data == null) {
              return Center(
                child: Text(
                  provider.subscriptionError ?? "Unable to load subscription",
                ),
              );
            }

            // ==================================================
            // RESPONSE PARSING
            // ==================================================

            final subscription =
                data["subscription"] as Map<String, dynamic>? ?? {};

            final plan =
                data["plan"] as Map<String, dynamic>? ??
                (passedPlan is Map<String, dynamic> ? passedPlan : {});

            final billing = data["billing"] as Map<String, dynamic>? ?? {};

            final period = data["period"] as Map<String, dynamic>? ?? {};

            final features = data["features"] as List<dynamic>? ?? [];

            // ==================================================
            // BASIC DATA
            // ==================================================

            final planName = plan["name"]?.toString() ?? "Premium Plan";

            final status = subscription["status"]?.toString() ?? "Active";

            final autoRenew = subscription["auto_renew"] == true;

            final paymentGateway =
                subscription["payment_gateway"]?.toString() ?? "";

            final paymentMethod =
                subscription["payment_method"]?.toString() ?? "";

            final paymentMethodDetail =
                subscription["payment_method_detail"]?.toString() ?? "";

            final renewsOn =
                subscription["renews_on"]?.toString() ??
                period["end"]?.toString();

            final endDate =
                subscription["ends_at"]?.toString() ??
                period["end"]?.toString();

            final daysRemaining = _daysRemaining(endDate);

            final featuresText = _buildFeaturesText(features);

            // ==================================================
            // CANCELLATION STATE
            // ==================================================

            final renewalCancelledAt = subscription["renewal_cancelled_at"];

            final bool isSubscriptionCancelled =
                renewalCancelledAt != null &&
                renewalCancelledAt.toString().trim().isNotEmpty &&
                renewalCancelledAt.toString().toLowerCase() != "null";

            // ==================================================
            // PROGRESS
            // ==================================================

            final startsAt = subscription["starts_at"]?.toString();

            double progress = 0.0;

            try {
              if (startsAt != null && endDate != null) {
                final start = DateTime.parse(startsAt).toLocal();

                final end = DateTime.parse(endDate).toLocal();

                final now = DateTime.now();

                final total = end.difference(start).inSeconds;

                final elapsed = now.difference(start).inSeconds;

                if (total > 0) {
                  progress = (1 - (elapsed / total)).clamp(0.0, 1.0);
                }
              }
            } catch (_) {
              progress = 0.0;
            }

            // ==================================================
            // SCREEN
            // ==================================================

            return Column(
              children: [
                _buildHeader(context, hideBackButton: hideBackButton),

                Expanded(
                  child: isSubscriptionCancelled
                      ? _buildCancelledSubscriptionView(
                          context: context,
                          planName: planName,
                          endDate: endDate,
                          features: features,
                          passedPlan: passedPlan,
                        )
                      : _buildActiveSubscriptionView(
                          context: context,
                          provider: provider,
                          planName: planName,
                          status: status,
                          autoRenew: autoRenew,
                          paymentGateway: paymentGateway,
                          paymentMethod: paymentMethod,
                          paymentMethodDetail: paymentMethodDetail,
                          renewsOn: renewsOn,
                          endDate: endDate,
                          daysRemaining: daysRemaining,
                          featuresText: featuresText,
                          progress: progress,
                          billing: billing,
                          subscription: subscription,
                          passedPlan: passedPlan,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader(BuildContext context, {required bool hideBackButton}) {
    return Container(
      height: 72,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!hideBackButton) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
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
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Text(
              "My Subscription",
              style: TextStyle(
                color: Color(0xFF171A2B),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Tooltip(
            message: "Go to Home",
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/CustomBottomNavScreen",
                  (route) => false,
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFFFF2027),
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CANCELLED SUBSCRIPTION SCREEN
  // ==========================================================

  Widget _buildCancelledSubscriptionView({
    required BuildContext context,
    required String planName,
    required String? endDate,
    required List<dynamic> features,
    required dynamic passedPlan,
  }) {
    final formattedEndDate = _formatDate(endDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // CANCELLED CARD
          // ====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD71920), Color(0xFF4D0508)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2027),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "SUBSCRIPTION CANCELLED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // END DATE
                Text(
                  "$planName access ends "
                  "$formattedEndDate",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "You won't be charged again. "
                  "$planName features stay active "
                  "until your current cycle ends, "
                  "then your account moves to "
                  "the Free plan.",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ====================================================
          // WHAT'S INCLUDED
          // ====================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD6D9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "What's included",
                  style: TextStyle(
                    color: Color(0xFF171A2B),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 14),

                _buildCancelledFeatureList(features),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (passedPlan != null) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    "/PlanDetailScreen",
                    arguments: passedPlan,
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text(
                  "VIEW PLAN DETAILS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF2027),
                  side: const BorderSide(color: Color(0xFFFF2027)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ====================================================
          // REACTIVATE
          // ====================================================
          SizedBox(
            width: 240,
            height: 53,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  "/PlanDetailScreen",
                  arguments: {"reactivate": true, "planName": planName},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2027),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "REACTIVATE SUBSCRIPTION",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledFeatureList(List<dynamic> features) {
    final List<String> featureList = [];

    for (final item in features) {
      if (item is! Map) {
        continue;
      }

      final label = item["label"]?.toString() ?? "";

      final dataType = item["data_type"]?.toString();

      if (label.isEmpty) {
        continue;
      }

      // Boolean feature
      if (dataType == "boolean") {
        if (item["enabled"] == true) {
          featureList.add(label);
        }

        continue;
      }

      // Count feature
      final limit = item["limit"];

      if (limit != null) {
        featureList.add("$limit $label");
      } else {
        featureList.add(label);
      }
    }

    if (featureList.isEmpty) {
      return const Text(
        "No features available",
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < featureList.length; i++)
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  featureList[i],
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              if (i != featureList.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFFFD6D9)),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildActiveSubscriptionView({
    required BuildContext context,
    required PlanProvider provider,
    required String planName,
    required String status,
    required bool autoRenew,
    required String paymentGateway,
    required String paymentMethod,
    required String paymentMethodDetail,
    required String? renewsOn,
    required String? endDate,
    required int daysRemaining,
    required String featuresText,
    required double progress,
    required Map<String, dynamic> billing,
    required Map<String, dynamic> subscription,
    required dynamic passedPlan,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

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
              border: Border.all(color: const Color(0xFFFFA5D3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      planName,
                      style: const TextStyle(
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
                        color: status.toLowerCase() == "active"
                            ? const Color(0xFFFF2027)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  autoRenew
                      ? "Your plan will automatically renew next month."
                      : "Automatic renewal is turned off.",
                  style: const TextStyle(
                    color: Color(0xFF59545D),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  featuresText.isEmpty ? "No features available" : featuresText,
                  style: const TextStyle(
                    color: Color(0xFF59545D),
                    fontSize: 12,
                    height: 1.5,
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

                SizedBox(
                  width: 145,
                  height: 145,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF2027),
                    ),
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$daysRemaining",
                          style: const TextStyle(
                            color: Color(0xFF171A2B),
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(width: 3),

                        const Padding(
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

                    const SizedBox(height: 1),

                    const Text(
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E0DB)),
            ),
            child: Column(
              children: [
                _detailRow(title: "Renews on", value: _formatDate(renewsOn)),

                const SizedBox(height: 16),

                _detailRow(
                  title: "Auto Renewal",
                  value: autoRenew ? "ON" : "OFF",
                  valueColor: autoRenew ? const Color(0xFFFF2027) : Colors.grey,
                ),

                const SizedBox(height: 16),

                _detailRow(
                  title: "Payment Method",
                  value: paymentGateway.isEmpty
                      ? paymentMethod
                      : "${_capitalize(paymentGateway)} • "
                            "${paymentMethod.toUpperCase()}",
                ),

                if (paymentMethodDetail.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _detailRow(
                    title: "Payment Detail",
                    value: paymentMethodDetail,
                  ),
                ],

                const SizedBox(height: 16),

                _detailRow(
                  title: "Plan Price",
                  value:
                      "${billing["currency"] ?? "INR"} "
                      "${billing["price"] ?? "-"}",
                ),

                const SizedBox(height: 16),

                _detailRow(
                  title: "Amount Paid",
                  value:
                      "${billing["currency"] ?? "INR"} "
                      "${subscription["amount_paid"] ?? "-"}",
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ==================================================
          // VIEW PLAN DETAILS
          // ==================================================
          if (passedPlan != null)
            _buildActionButton(
              title: "VIEW PLAN DETAILS",
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFFF2027),
              textColor: const Color(0xFFFF2027),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/PlanDetailScreen",
                  arguments: passedPlan,
                );
              },
            ),

          if (passedPlan != null) const SizedBox(height: 10),

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
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

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

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

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

  // ==========================================================
  // CAPITALIZE
  // ==========================================================

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}
