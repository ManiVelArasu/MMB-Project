import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Api Model/plan_usage.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/plan_provider.dart';

class PlanUsageScreen extends StatelessWidget {
  const PlanUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanProvider()..fetchPlanUsage(),
      child: const _PlanUsageView(),
    );
  }
}

class _PlanUsageView extends StatelessWidget {
  const _PlanUsageView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    final features =
        provider.planUsageData?.data?.features ?? [];

    final period =
        provider.planUsageData?.data?.period;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.red,
          ),
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

      body: provider.isLoadingPlanUsage &&
          provider.planUsageData == null
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      )
          : provider.planUsageError != null &&
          provider.planUsageData == null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AppText(
            provider.planUsageError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
            ),
          ),
        ),
      )
          : features.isEmpty
          ? const Center(
        child: AppText(
          "No usage data found",
        ),
      )
          : RefreshIndicator(
        color: Colors.red,
        onRefresh: () async {
          await provider.fetchPlanUsage();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            8,
            8,
            8,
            20,
          ),
          children: [
            if (period?.end != null)
              _buildResetText(
                period!.end!,
              ),

            ..._buildFeatureCards(
              features,
            ),

            const SizedBox(height: 12),

            _buildCalculationText(),

            const SizedBox(height: 28),

            _buildTopUpButton(
              context,
            ),

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
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 10,
      ),
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

  List<Widget> _buildFeatureCards(
      List<Feature> features,
      ) {
    final List<Widget> widgets = [];

    for (final feature in features) {
      final label =
      (feature.label ?? feature.key ?? "")
          .trim();

      if (_isAiCredits(feature)) {
        widgets.add(
          _buildAiCreditsCard(feature),
        );

        widgets.add(
          const SizedBox(height: 8),
        );

        continue;
      }

      widgets.add(
        _buildNormalFeatureCard(feature),
      );

      widgets.add(
        const SizedBox(height: 8),
      );
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

    final String? limitString =
        feature.effectiveLimit ?? feature.limit;

    final bool hasLimit =
        !unlimited &&
            limitString != null &&
            limitString.trim().isNotEmpty;

    final double used = _toDouble(feature.used);
    final double limit = _toDouble(limitString);

    final double progress = hasLimit
        ? _calculateProgress(used, limit)
        : 0;

    final String title =
        feature.label ??
            feature.key ??
            "Feature";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE6E1DC),
        ),
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

  Widget _buildAiCreditsCard(
      Feature feature,
      ) {
    final double used =
    _toDouble(feature.used);

    final double limit =
    _toDouble(
      feature.effectiveLimit ??
          feature.limit,
    );

    final double remaining =
    _toDouble(feature.remaining);

    final double topupGranted =
    _toDouble(feature.topupGranted);

    final double progress =
    _calculateProgress(
      used,
      limit,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE6E1DC),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // TITLE + REMAINING
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppText(
                  feature.label ??
                      "AI Credits",
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
          _buildProgressLine(
            progress,
          ),

          const SizedBox(height: 8),

          // USED THIS CYCLE
          Row(
            children: [
              const AppText(
                "Used this cycle",
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF666666),
                ),
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
              padding:
              const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E7),
                borderRadius:
                BorderRadius.circular(4),
              ),
              child: AppText(
                "Additional Credits Purchased "
                    "+${_formatNumber(topupGranted)}",
                style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          ],

          // BREAKDOWN
          if (feature.breakdown != null &&
              feature.breakdown!.isNotEmpty) ...[
            const SizedBox(height: 8),

            _buildBreakdown(
              feature.breakdown!,
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // AI BREAKDOWN
  // ------------------------------------------------------------

  Widget _buildBreakdown(
      List<dynamic> breakdown,
      ) {
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

      children.add(
        _buildBreakdownItem(
          label: label,
          credits: credits,
        ),
      );
    }

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: children,
    );
  }

  Widget _buildBreakdownItem({
    required String label,
    required String credits,
  }) {
    return Container(
      width: 102,
      constraints: const BoxConstraints(
        minHeight: 47,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFD7DA),
        ),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          AppText(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171A2B),
            ),
          ),

          const SizedBox(height: 3),

          AppText(
            credits.isEmpty
                ? "Credits"
                : "$credits Credits",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PROGRESS LINE
  // ------------------------------------------------------------

  Widget _buildProgressLine(
      double progress,
      ) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(10),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor:
          const Color(0xFFEAE7E3),
          valueColor:
          const AlwaysStoppedAnimation<Color>(
            Colors.red,
          ),
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
            decoration:
            TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP UP BUTTON
  // ------------------------------------------------------------

  Widget _buildTopUpButton(
      BuildContext context,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          // TODO:
          // Navigate to Top Up AI Credits
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
          const Color(0xFFF51F29),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(8),
          ),
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

  // ------------------------------------------------------------
  // AI CREDIT CHECK
  // ------------------------------------------------------------

  bool _isAiCredits(
      Feature feature,
      ) {
    final label =
        feature.label
            ?.trim()
            .toLowerCase() ??
            "";

    final key =
        feature.key
            ?.trim()
            .toLowerCase() ??
            "";

    return label.contains("ai credit") ||
        key.contains("ai_credit") ||
        key.contains("ai-credits");
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  double _toDouble(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 0;
    }

    return double.tryParse(
      value.replaceAll(",", ""),
    ) ??
        0;
  }

  double _calculateProgress(
      double used,
      double limit,
      ) {
    if (limit <= 0) {
      return 0;
    }

    return (used / limit)
        .clamp(0.0, 1.0);
  }

  String _formatNumber(
      double value,
      ) {
    if (value ==
        value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatDate(
      DateTime date,
      ) {
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