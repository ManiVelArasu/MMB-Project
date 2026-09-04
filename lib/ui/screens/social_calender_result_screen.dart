import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_widget.dart';
import '../../network/provider/smcalender_form_provider.dart';

import '../../network/provider/custom_theme_provider.dart';

class SocialCalendarResultScreen extends StatefulWidget {
  final SocialCalendarProvider provider;
  const SocialCalendarResultScreen({super.key, required this.provider});

  @override
  State<SocialCalendarResultScreen> createState() =>
      _SocialCalendarResultScreenState();
}

class _SocialCalendarResultScreenState
    extends State<SocialCalendarResultScreen> {
  @override
  void initState() {
    widget.provider.resetTemplates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer2<SocialCalendarProvider, CustomThemeProvider>(
        builder: (context, provider, themeProvider, child) {
          final isDark = themeProvider.isDarkMode;

          return SafeArea(
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: const CustomAppBar(
                title: "SM Calendar",
                showRightIcon: false,
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your SM Calendar for the month",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            provider.isCalendarGridVisible =
                                !provider.isCalendarGridVisible;
                            provider.notifyListeners();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A1A1C)
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              "assets/images/calendar.png",
                              width: 22,
                              height: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (provider.isCalendarGridVisible) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Days Header (SUN - SAT)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _DayHeaderLabel("SUN"),
                              _DayHeaderLabel("MON"),
                              _DayHeaderLabel("TUE"),
                              _DayHeaderLabel("WED"),
                              _DayHeaderLabel("THU"),
                              _DayHeaderLabel("FRI"),
                              _DayHeaderLabel("SAT"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Dates Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                            itemCount: 35,
                            itemBuilder: (context, index) {
                              if (index < 5) {
                                return const SizedBox.shrink();
                              }
                              int dayNum = index - 4;
                              bool isHighlighted = (dayNum == 1 || dayNum == 8);

                              return Container(
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? (isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade800)
                                      : (isDark
                                            ? const Color(0xFF2C2C2C)
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "$dayNum",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlighted
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        int weekNum = index + 1;
                        bool isSelected = provider.selectedWeekTab == weekNum;
                        return GestureDetector(
                          onTap: () => provider.setWeekTab(weekNum),
                          child: Text(
                            "Week $weekNum",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.grey,
                              decoration: isSelected
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor: isDark
                                  ? Colors.white
                                  : Colors.black,
                              decorationThickness: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),

                  // Generated Posts List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildPostCard(
                          postNumber: "Post 5",
                          date: "Friday 1 ${provider.selectedMonth}",
                          topic: "Behind the Scenes",
                          title: "Inside BeFit",
                          tagline: "Not just reps. It's the culture.",
                          supportText:
                              "Ever wondered what goes on beyond the workout floor?\nMeet the trainers, the early risers, the playlist makers, and the hustle behind your favorite gym. We don't just build bodies, we build energy.",
                          cta: "👉 Book a trial session today.",
                          isGenerated: provider.isTemplatesGenerated,
                          isDark: isDark,
                        ),
                        _buildPostCard(
                          postNumber: "Post 6",
                          date: "Friday 8 ${provider.selectedMonth}",
                          topic: "Behind the Scenes",
                          title: "Inside BeFit",
                          tagline: "Not just reps. It's the culture.",
                          supportText:
                              "Ever wondered what goes on beyond the workout floor?\nMeet the trainers, the early risers, the playlist makers, and the hustle behind your favorite gym. We don't just build bodies, we build energy.",
                          cta: "👉 Book a trial session today.",
                          isGenerated: provider.isTemplatesGenerated,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: provider.isTemplatesGenerated
                        ? Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.red,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Calendar Downloaded Successfully!",
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "DOWNLOAD",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Calendar Saved Successfully!",
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "SAVE",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                provider.generateTemplates();
                              },
                              child: const Text(
                                "GENERATE TEMPLATES",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard({
    required String postNumber,
    required String date,
    required String topic,
    required String title,
    required String tagline,
    required String supportText,
    required String cta,
    required bool isGenerated,
    required bool isDark,
  }) {
    final List<String> templateImages = [
      'https://picsum.photos/300/300?1',
      'https://picsum.photos/300/300?2',
      'https://picsum.photos/300/300?3',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.shade100,
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                postNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A1A1C)
                      : const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Topic: $topic",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.black,
                fontSize: 12,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: "Title:\n",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "$title\n"),
                const TextSpan(
                  text: "Tagline:\n",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "$tagline\n"),
                const TextSpan(
                  text: "Support Text:\n",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "$supportText\n"),
                const TextSpan(
                  text: "CTA:\n",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: cta),
              ],
            ),
          ),

          if (isGenerated) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: templateImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(templateImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "VIEW ALL",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayHeaderLabel extends StatelessWidget {
  final String label;
  const _DayHeaderLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }
}
