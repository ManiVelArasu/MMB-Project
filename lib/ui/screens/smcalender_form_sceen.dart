import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../network/provider/smcalender_form_provider.dart';

class SocialCalendarFormScreen extends StatelessWidget {
  const SocialCalendarFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SocialCalendarProvider(),
      child: Builder(
        builder: (context) {
          final provider = context.watch<SocialCalendarProvider>();

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
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    const Text(
                      "Generate Your Monthly Social Media Calendar",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Plan your content with ease using our AI-powered calendar. Get ready-to-use post ideas and matching content tailored for your brand. All in just a few taps!",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select Month
                    const Text(
                      "Select Month",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.selectedMonth,
                          isExpanded: true,
                          items: provider.months.map((month) {
                            return DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) provider.setMonth(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Posts per Week
                    const Text(
                      "Posts per Week",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          int count = index + 1;
                          bool isSelected = provider.postsPerWeek == count;
                          return GestureDetector(
                            onTap: () => provider.setPostsPerWeek(count),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "$count",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Social Media Platforms
                    const Text(
                      "Social Media Platforms",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.platformsList.map((platform) {
                        bool isSelected = provider.selectedPlatforms.contains(
                          platform,
                        );
                        return FilterChip(
                          selected: isSelected,
                          label: Text(platform),
                          selectedColor: Colors.grey.shade800,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onSelected: (_) => provider.togglePlatform(platform),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Select Your Tone
                    const Text(
                      "Select Your Tone",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.tonesList.map((tone) {
                        bool isSelected = provider.selectedTone == tone;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(tone),
                          selectedColor: Colors.grey.shade800,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onSelected: (_) => provider.setTone(tone),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),

                    // Generate Button -> Navigates to Screen 2 with Provider passed
                    SizedBox(
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
                          final parentProvider = context
                              .read<SocialCalendarProvider>();
                          Navigator.pushNamed(
                            context,
                            "/SocialCalendarResultScreen",
                            arguments: parentProvider,
                          );
                        },
                        child: const Text(
                          "GENERATE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
