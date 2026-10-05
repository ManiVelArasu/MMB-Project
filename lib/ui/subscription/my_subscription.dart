import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/plan_provider.dart';


class MySubscriptionScreen extends StatelessWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlanProvider>(
      create: (_) => PlanProvider()
        ..fetchMySubscription()
        ..fetchPlanUsage(),
      child: const _MySubscriptionView(),
    );
  }
}

class _MySubscriptionView extends StatelessWidget {
  const _MySubscriptionView({super.key});

  int _daysRemaining(String? endDate) {
    if (endDate == null || endDate.isEmpty) {
      return 0;
    }

    try {
      final end = DateTime.parse(endDate).toLocal();

      final now = DateTime.now();

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final expiry = DateTime(
        end.year,
        end.month,
        end.day,
      );

      final difference = expiry.difference(today).inDays;

      return difference < 0 ? 0 : difference;
    } catch (_) {
      return 0;
    }
  }

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

      return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
    } catch (_) {
      return date;
    }
  }

  String _buildFeaturesText(List<dynamic> features) {
    final List<String> result = [];

    for (final item in features) {
      if (item is! Map<String, dynamic>) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF9),

      body: SafeArea(
        child: Consumer<PlanProvider>(
          builder: (context, provider, child) {

            if (provider.isLoadingSubscription &&
                provider.subscriptionData == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final data = provider.subscriptionData;

            if (data == null) {
              return Center(
                child: Text(
                  provider.subscriptionError ??
                      "Unable to load subscription",
                ),
              );
            }

            final subscription =
                data["subscription"] as Map<String, dynamic>? ?? {};

            final plan =
                data["plan"] as Map<String, dynamic>? ?? {};

            final billing =
                data["billing"] as Map<String, dynamic>? ?? {};

            final period =
                data["period"] as Map<String, dynamic>? ?? {};

            final features =
                data["features"] as List<dynamic>? ?? [];

            // ------------------------------------------
            // API DATA
            // ------------------------------------------

            final planName =
                plan["name"]?.toString() ?? "Premium Plan";

            final status =
                subscription["status"]?.toString() ?? "";

            final autoRenew =
                subscription["auto_renew"] == true;

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

            final daysRemaining =
            _daysRemaining(endDate);

            final featuresText =
            _buildFeaturesText(features);

            // ------------------------------------------
            // PROGRESS
            // ------------------------------------------

            final startsAt =
            subscription["starts_at"]?.toString();

            double progress = 0.0;

            try {
              if (startsAt != null &&
                  endDate != null) {
                final start =
                DateTime.parse(startsAt).toLocal();

                final end =
                DateTime.parse(endDate).toLocal();

                final now = DateTime.now();

                final total =
                    end.difference(start).inSeconds;

                final elapsed =
                    now.difference(start).inSeconds;

                if (total > 0) {
                  progress =
                      (1 - (elapsed / total))
                          .clamp(0.0, 1.0);
                }
              }
            } catch (_) {
              progress = 0.0;
            }

            // ====================================================
            // ORIGINAL DESIGN
            // ====================================================

            return Column(
              children: [

                // ====================================================
                // HEADER
                // ====================================================

                Container(
                  height: 72,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFEAEAEA),
                        width: 1,
                      ),
                    ),
                  ),

                  child: Row(
                    children: [

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
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      20,
                    ),

                    child: Column(
                      children: [

                        const SizedBox(height: 0),

                        // ==================================================
                        // PREMIUM CARD
                        // ==================================================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            18,
                          ),

                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFB4DB),
                                Color(0xFFF6D9F0),
                              ],
                            ),

                            borderRadius:
                            BorderRadius.circular(16),

                            border: Border.all(
                              color: const Color(0xFFFFA5D3),
                              width: 1,
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              // PLAN NAME + ACTIVE

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,

                                crossAxisAlignment:
                                CrossAxisAlignment.center,

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
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 6,
                                    ),

                                    decoration: BoxDecoration(
                                      color:
                                      status.toLowerCase() ==
                                          "active"
                                          ? const Color(0xFFFF2027)
                                          : Colors.grey,

                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),

                                    child: Text(
                                      status
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight:
                                        FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // RENEW TEXT

                              Text(
                                autoRenew
                                    ? "Your plan will automatically renew next month."
                                    : "Automatic renewal is turned off.",
                                style: const TextStyle(
                                  color: Color(0xFF59545D),
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight:
                                  FontWeight.w400,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // FEATURES

                              Text(
                                featuresText.isEmpty
                                    ? "No features available"
                                    : featuresText,
                                style: const TextStyle(
                                  color: Color(0xFF59545D),
                                  fontSize: 12,
                                  height: 1.5,
                                  fontWeight:
                                  FontWeight.w400,
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

                                child:
                                CircularProgressIndicator(
                                  value: 1,
                                  strokeWidth: 10,
                                  backgroundColor:
                                  const Color(0xFFEDEBE7),

                                  valueColor:
                                  const AlwaysStoppedAnimation<
                                      Color>(
                                    Color(0xFFEDEBE7),
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: 145,
                                height: 145,

                                child:
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 10,
                                  backgroundColor:
                                  Colors.transparent,

                                  valueColor:
                                  const AlwaysStoppedAnimation<
                                      Color>(
                                    Color(0xFFFF2027),
                                  ),
                                ),
                              ),

                              Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,

                                children: [

                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,

                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,

                                    children: [

                                      Text(
                                        "$daysRemaining",
                                        style:
                                        const TextStyle(
                                          color:
                                          Color(0xFF171A2B),
                                          fontSize: 36,
                                          fontWeight:
                                          FontWeight.w800,
                                        ),
                                      ),

                                      const SizedBox(width: 3),

                                      const Padding(
                                        padding:
                                        EdgeInsets.only(
                                          bottom: 7,
                                        ),

                                        child: Text(
                                          "Days",
                                          style:
                                          TextStyle(
                                            color:
                                            Color(0xFF171A2B),
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 1),

                                  const Text(
                                    "TILL RENEWAL",
                                    style: TextStyle(
                                      color:
                                      Color(0xFF666666),
                                      fontSize: 9,
                                      fontWeight:
                                      FontWeight.w600,
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

                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius:
                            BorderRadius.circular(16),

                            border: Border.all(
                              color:
                              const Color(0xFFE4E0DB),
                              width: 1,
                            ),
                          ),

                          child: Column(
                            children: [

                              _detailRow(
                                title: "Renews on",
                                value:
                                _formatDate(renewsOn),
                              ),

                              const SizedBox(height: 16),

                              _detailRow(
                                title: "Auto Renewal",
                                value:
                                autoRenew
                                    ? "ON"
                                    : "OFF",
                                valueColor:
                                autoRenew
                                    ? const Color(
                                    0xFFFF2027)
                                    : Colors.grey,
                              ),

                              const SizedBox(height: 16),

                              _detailRow(
                                title: "Payment Method",
                                value:
                                paymentGateway.isEmpty
                                    ? paymentMethod
                                    : "${_capitalize(paymentGateway)} • ${paymentMethod.toUpperCase()}",
                              ),

                              if (paymentMethodDetail
                                  .isNotEmpty) ...[

                                const SizedBox(height: 16),

                                _detailRow(
                                  title: "Payment Detail",
                                  value:
                                  paymentMethodDetail,
                                ),
                              ],

                              const SizedBox(height: 16),

                              _detailRow(
                                title: "Plan Price",
                                value:
                                "${billing["currency"] ?? "INR"} ${billing["price"] ?? "-"}",
                              ),

                              const SizedBox(height: 16),

                              _detailRow(
                                title: "Amount Paid",
                                value:
                                "${billing["currency"] ?? "INR"} ${subscription["amount_paid"] ?? "-"}",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 132),

                        // ==================================================
                        // MANAGE PLAN
                        // ==================================================

                        _buildActionButton(
                          title: "MANAGE PLAN",
                          backgroundColor:
                          const Color(0xFFFF2027),
                          borderColor:
                          const Color(0xFFFF2027),
                          textColor: Colors.white,

                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              "/ManagePlanScreen",
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // CANCEL RENEWAL
                        // ==================================================

                        _buildActionButton(
                          title: "CANCEL RENEWAL",
                          backgroundColor:
                          Colors.white,
                          borderColor:
                          const Color(0xFF171A2B),
                          textColor:
                          const Color(0xFF171A2B),

                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              "/ChangePlanScreen",
                              arguments: {
                                "openCancelSheet": true,
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==============================================================
  // CAPITALIZE
  // ==============================================================

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  // ==============================================================
  // DETAIL ROW
  // ==============================================================

  Widget _detailRow({
    required String title,
    required String value,
    Color valueColor =
    const Color(0xFF171A2B),
  }) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,

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

          side: BorderSide(
            color: borderColor,
            width: 1.5,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
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
