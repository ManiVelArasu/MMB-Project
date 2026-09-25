import 'package:flutter/material.dart';
import 'package:mmb_app/component/custom_widget.dart';

class PlanUsageScreen extends StatelessWidget {
  const PlanUsageScreen({super.key});

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
            child: const Icon(Icons.arrow_back, color: Colors.red, size: 16),
          ),
        ),
        title: const AppText(
          "Plan Usage",
          style: TextStyle(
            color: Color(0xFF171A2B),
            fontSize: 16,
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
              const Center(
                child: AppText(
                  "EVERYTHING INCLUDED IN PREMIUM RESETS 12 SEPT 2026",
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              _usageProgressCard(
                title: "Static Templates",
                value: "214 / 1000",
                progress: 214 / 1000,
              ),

              const SizedBox(height: 8),

              _usageProgressCard(
                title: "Video Templates",
                value: "94 / 500",
                progress: 94 / 500,
              ),

              const SizedBox(height: 8),

              _usageProgressCard(
                title: "Brand Frames",
                value: "8 / 10",
                progress: 8 / 10,
              ),

              const SizedBox(height: 8),

              _usageProgressCard(
                title: "Brand Series",
                value: "2 / 5",
                progress: 2 / 5,
              ),

              const SizedBox(height: 9),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        AppText(
                          "AI Credits",
                          style: TextStyle(
                            color: Color(0xFF171A2B),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        AppText(
                          "Remaining 725",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 725 / 1000,
                        minHeight: 5,
                        backgroundColor: Color(0xFFEDEBE7),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        AppText(
                          "Used this cycle",
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 8,
                          ),
                        ),
                        AppText(
                          "275 / 1,000",
                          style: TextStyle(
                            color: Color(0xFF171A2B),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          AppText(
                            "Additional Credits Purchased",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 8,
                            ),
                          ),
                          AppText(
                            "+500",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        Expanded(
                          child: _creditFeature(
                            title: "Image Generation",
                            credits: "100 Credits",
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _creditFeature(
                            title: "Background Removal",
                            credits: "200 Credits",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Expanded(
                          child: _creditFeature(
                            title: "Logo Generation",
                            credits: "100 Credits",
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _creditFeature(
                            title: "Text to Audio",
                            credits: "100 Credits",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Expanded(
                          child: _creditFeature(
                            title: "AI SM Calendar",
                            credits: "400 Credits",
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: () {
                    // AI Credits Usage Calculation
                  },
                  child: const AppText(
                    "AI Credits Usage Calculation",
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 8,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    // IMPORTANT:
                    // This is the PlanUsageScreen context.
                    final BuildContext parentContext = context;

                    showModalBottomSheet(
                      context: parentContext,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (sheetContext) {
                        return _TopUpCreditsBottomSheet(
                          parentContext: parentContext,
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const AppText(
                    "TOP UP AI CREDITS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _usageProgressCard({
    required String title,
    required String value,
    required double progress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                title,
                style: const TextStyle(
                  color: Color(0xFF171A2B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppText(
                value,
                style: const TextStyle(
                  color: Color(0xFF171A2B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFEDEBE7),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _creditFeature({
    required String title,
    required String credits,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFFFD5D8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF171A2B),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          AppText(
            credits,
            style: const TextStyle(color: Color(0xFF333333), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _TopUpCreditsBottomSheet extends StatefulWidget {
  final BuildContext parentContext;

  const _TopUpCreditsBottomSheet({required this.parentContext});

  @override
  State<_TopUpCreditsBottomSheet> createState() =>
      _TopUpCreditsBottomSheetState();
}

class _TopUpCreditsBottomSheetState extends State<_TopUpCreditsBottomSheet> {
  int selectedIndex = 1;

  final List<Map<String, String>> plans = [
    {"price": "₹49", "credits": "100 Credits"},
    {"price": "₹79", "credits": "200 Credits"},
    {"price": "₹99", "credits": "150 Credits"},
    {"price": "₹249", "credits": "250 Credits"},
    {"price": "₹449", "credits": "500 Credits"},
    {"price": "₹899", "credits": "1000 Credits"},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
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

            const SizedBox(height: 10),

            Row(
              children: [
                const Expanded(
                  child: AppText(
                    "Top Up AI Credits",
                    style: TextStyle(
                      color: Color(0xFF171A2B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

            const SizedBox(height: 8),

            const Center(
              child: AppText(
                "Purchase additional credits valid for 360 days. Top up credits\n"
                "persist even if your subscription cancelled.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 8,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            const AppText(
              "SELECT THE PLAN",
              style: TextStyle(
                color: Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 7,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final plan = plans[index];
                final bool isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.red
                            : const Color(0xFFFFD5D8),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          plan["price"]!,
                          style: const TextStyle(
                            color: Color(0xFF171A2B),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AppText(
                          plan["credits"]!,
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 39,
              child: ElevatedButton(
                onPressed: () {
                  final selectedPlan = plans[selectedIndex];

                  debugPrint(
                    "Selected: "
                    "${selectedPlan["price"]} - "
                    "${selectedPlan["credits"]}",
                  );

                  Navigator.pop(context);

                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (!widget.parentContext.mounted) {
                      return;
                    }

                    showModalBottomSheet(
                      context: widget.parentContext,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (aiSheetContext) {
                        return const _AICreditsBottomSheet();
                      },
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const AppText(
                  "CONTINUE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AICreditsBottomSheet extends StatelessWidget {
  const _AICreditsBottomSheet();

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

            const SizedBox(height: 10),

            Row(
              children: [
                const Expanded(
                  child: AppText(
                    "AI Credits",
                    style: TextStyle(
                      color: Color(0xFF171A2B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E2E2)),
              ),
              child: const Column(
                children: [
                  _AICreditRow(
                    title: "Image Generation",
                    credits: "20 Credits",
                  ),

                  _AICreditRow(title: "Logo Generation", credits: "25 Credits"),

                  _AICreditRow(
                    title: "Background Removal",
                    credits: "5 Credits",
                  ),

                  _AICreditRow(
                    title: "Text to Audio (10 Seconds)",
                    credits: "15 Credits",
                  ),

                  _AICreditRow(title: "Auto Captions", credits: "5 Credits"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AICreditRow extends StatelessWidget {
  final String title;
  final String credits;

  const _AICreditRow({required this.title, required this.credits});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              title,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 9),
            ),
          ),

          AppText(
            credits,
            style: const TextStyle(
              color: Color(0xFF171A2B),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
