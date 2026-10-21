import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_widget.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/smcalender_form_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

class SocialCalendarFormScreen extends StatelessWidget {
  const SocialCalendarFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SocialCalendarProvider(),
      child: const _SocialCalendarFormBody(),
    );
  }
}

class _SocialCalendarFormBody extends StatefulWidget {
  const _SocialCalendarFormBody();

  @override
  State<_SocialCalendarFormBody> createState() =>
      _SocialCalendarFormBodyState();
}

class _SocialCalendarFormBodyState extends State<_SocialCalendarFormBody> {
  String selectedMode = 'WEEKLY';

  final List<String> goalsList = [
    'Brand Awareness',
    'Product Promotion',
    'Leads',
    'Sales',
    'Engagement',
    'Education',
  ];

  final Set<String> selectedGoals = {'Brand Awareness', 'Education'};

  void toggleGoal(String goal) {
    setState(() {
      if (selectedGoals.contains(goal)) {
        selectedGoals.remove(goal);
      } else if (selectedGoals.length < 3) {
        selectedGoals.add(goal);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select up to 3 content goals'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialCalendarProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "AI Social Media Calendar",
        showRightIcon: false,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 245.h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/sm_mask.png',
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter,
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Plan your content with AI and get ready-to-use '
                              'posts tailored to your business.',
                          style: TextStyle(
                            color: AppColors.appGrey,
                            fontSize: 12.sp,
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        Center(
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _modeButton(
                                  'MONTHLY',
                                  selectedMode == 'MONTHLY',
                                ),
                                _modeButton(
                                  'WEEKLY',
                                  selectedMode == 'WEEKLY',
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        if (selectedMode == 'MONTHLY')
                          Container(
                            height: 40.h,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: provider.months.contains(
                                  provider.selectedMonth,
                                )
                                    ? provider.selectedMonth
                                    : null,
                                hint: const Text('Select month'),
                                isExpanded: true,
                                items: provider.months.map((month) {
                                  return DropdownMenuItem<String>(
                                    value: month,
                                    child: Text(month),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) provider.setMonth(value);
                                },
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Aug 17 – Aug 23, 2026',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.calendar_month,
                                  color: Colors.red,
                                  size: 16.sp,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 200.h),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),
                        _sectionLabel('Posts per Week', showInfo: true),
                        SizedBox(height: 8.h),
                        Row(
                          children: List.generate(7, (index) {
                            final count = index + 1;
                            final selected = provider.postsPerWeek == count;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == 6 ? 0 : 6.w,
                                ),
                                child: InkWell(
                                  onTap: () => provider.setPostsPerWeek(count),
                                  child: Container(
                                    height: 34.h,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF555555)
                                          : Colors.white,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(5.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: 14.h),

                        // Social Media Platforms
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel(
                                'Social Media Platforms',
                                showInfo: true,
                              ),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 4.w,
                                runSpacing: 4.h,
                                children: provider.platformsList.map((
                                  platform,
                                ) {
                                  final selected = provider.selectedPlatforms
                                      .contains(platform);

                                  return _choiceChip(
                                    label: platform,
                                    selected: selected,
                                    onTap: () =>
                                        provider.togglePlatform(platform),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Content Goals
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel(
                                'Content Goals',
                                subtitle: '(Select upto 3)',
                                showInfo: true,
                              ),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 4.w,
                                runSpacing: 4.h,
                                children: goalsList.map((goal) {
                                  return _choiceChip(
                                    label: goal,
                                    selected: selectedGoals.contains(goal),
                                    onTap: () => toggleGoal(goal),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Tone selection
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel(
                                'Select Your Tone',
                                subtitle: '(Select upto 2)',
                                showInfo: true,
                              ),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 4.w,
                                runSpacing: 4.h,
                                children: provider.tonesList.map((tone) {
                                  return _choiceChip(
                                    label: tone,
                                    selected: provider.selectedTone == tone,
                                    onTap: () => provider.setTone(tone),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),

                // Fixed Generate button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SizedBox(
                    height: 44.h,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF51F27),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                      ),
                      onPressed: () {
                        if (provider.selectedPlatforms.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one platform',
                              ),
                            ),
                          );
                          return;
                        }

                        if (selectedGoals.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one content goal',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pushNamed(
                          context,
                          '/SocialCalendarResultScreen',
                          arguments: provider,
                        );
                      },
                      child: Text(
                        'GENERATE',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String title, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedMode = title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF51F27) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(
    String title, {
    String subtitle = '',
    bool showInfo = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Color(0xFF555555)),
          ),
        ],
        if (showInfo) ...[
          const SizedBox(width: 4),
          const Icon(Icons.info, color: Color(0xFFFFB6A8), size: 11),
        ],
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: child,
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF555555) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, color: Colors.white, size: 10),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
