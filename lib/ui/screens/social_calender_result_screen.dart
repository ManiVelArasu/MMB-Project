import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/smcalender_form_provider.dart';

class SocialCalendarResultScreen extends StatefulWidget {
  final SocialCalendarProvider provider;
  const SocialCalendarResultScreen({super.key, required this.provider});

  @override
  State<SocialCalendarResultScreen> createState() => _SocialCalendarResultScreenState();
}

class _SocialCalendarResultScreenState extends State<SocialCalendarResultScreen> {
  int selectedWeekTab = 1;

  @override
  Widget build(BuildContext context) {
    // 🚀 Wrap Screen 2 with ChangeNotifierProvider.value so it accesses the exact same provider data
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<SocialCalendarProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  "My Monthly SM Calendar",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "SM Calendar for ${provider.selectedMonth}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),

                  // Weeks Tab Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        int weekNum = index + 1;
                        bool isSelected = selectedWeekTab == weekNum;
                        return GestureDetector(
                          onTap: () => setState(() => selectedWeekTab = weekNum),
                          child: Text(
                            "Week $weekNum",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? Colors.black : Colors.grey,
                              decoration: isSelected ? TextDecoration.underline : TextDecoration.none,
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
                          supportText: "Ever wondered what goes on beyond the workout floor?\nMeet the trainers, the early risers, the playlist makers, and the hustle behind your favorite gym. We don't just build bodies, we build energy.",
                          cta: "👉 Book a trial session today.",
                        ),
                        _buildPostCard(
                          postNumber: "Post 6",
                          date: "Friday 8 ${provider.selectedMonth}",
                          topic: "Behind the Scenes",
                          title: "Inside BeFit",
                          tagline: "Not just reps. It's the culture.",
                          supportText: "Ever wondered what goes on beyond the workout floor?\nMeet the trainers, the early risers, the playlist makers, and the hustle behind your favorite gym. We don't just build bodies, we build energy.",
                          cta: "👉 Book a trial session today.",
                        ),
                      ],
                    ),
                  ),

                  // Bottom Generate Templates Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Templates Generated Successfully!")),
                          );
                        },
                        child: const Text(
                          "GENERATE TEMPLATES",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
  }) {
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
              Text(postNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  date,
                  style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Topic: $topic",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.4),
              children: [
                const TextSpan(text: "Title:\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "$title\n"),
                const TextSpan(text: "Tagline:\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "$tagline\n"),
                const TextSpan(text: "Support Text:\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "$supportText\n"),
                const TextSpan(text: "CTA:\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: cta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}