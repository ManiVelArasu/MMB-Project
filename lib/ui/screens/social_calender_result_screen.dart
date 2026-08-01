import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_mmb/component/appbar_widget.dart';
import 'package:provider/provider.dart';

import '../../network/provider/smcalender_form_provider.dart';

class SocialCalendarResultScreen extends StatefulWidget {
  final SocialCalendarProvider provider;
  const SocialCalendarResultScreen({super.key, required this.provider});

  @override
  State<SocialCalendarResultScreen> createState() =>
      _SocialCalendarResultScreenState();
}

class _SocialCalendarResultScreenState
    extends State<SocialCalendarResultScreen> {
  bool _isCalendarGridVisible = false;

  @override
  void initState() {
    widget.provider.resetTemplates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<SocialCalendarProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Scaffold(
              backgroundColor: Colors.white,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        // 🚀 Tappable Calendar Icon to toggle Grid View
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCalendarGridVisible = !_isCalendarGridVisible;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
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

                  if (_isCalendarGridVisible) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
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
                          // Dates Grid (31 Days mock matching your screenshot)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                            itemCount: 35, // 4 blank offsets + 31 days
                            itemBuilder: (context, index) {
                              if (index < 5) {
                                // Empty slots for month alignment
                                return const SizedBox.shrink();
                              }
                              int dayNum = index - 4;
                              bool isHighlighted =
                                  (dayNum == 1 ||
                                  dayNum ==
                                      8);

                              return Container(
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? Colors.grey.shade800
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
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
                                          : Colors.black87,
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
                              color: isSelected ? Colors.black : Colors.grey,
                              decoration: isSelected
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor: Colors.black,
                              decorationThickness: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(height: 1),

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
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons (Download / Save vs Generate Templates)
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEE),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black,
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
                      border: Border.all(color: Colors.grey.shade300),
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
            const Text(
              "VIEW ALL",
              style: TextStyle(
                color: Colors.black,
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

// Helper widget for day header labels in calendar grid
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
