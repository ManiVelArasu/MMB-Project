import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';

import 'package:provider/provider.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/smcalender_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../utils/theme/app.colors.dart';

class SmCalendarScreen extends StatelessWidget {
  const SmCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SmCalendarProvider(),
      child: const SmCalendarView(),
    );
  }
}

class SmCalendarView extends StatelessWidget {
  const SmCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<SmCalendarProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: "My Monthly SM Calendars",
            showRightIcon: false,
          ),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 150.h,
                child: Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: Image.asset(
                        "assets/images/sm_mask.png",
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),

                    // Text over the image
                    Positioned(
                      left: 16.w,
                      right: 16.w,
                      bottom: 12.h,
                      child: AppText(
                        "Plan your content with AI and get ready-to-use posts tailored to your business.",
                        style: TextStyle(
                          color: AppColors.appGrey,
                          fontSize: AppFontSize.fontSize14,
                          height: 1.4,
                          fontWeight: FontWeight.w400,

                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              "My AI Social Media Calendar",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // CALENDARS LIST
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.calendars.length,
                              itemBuilder: (context, index) {
                                final item = provider.calendars[index];

                                final isMonthly = item.title.toLowerCase().contains('month');
                                final monthName = item.title
                                    .replaceAll('month Calendar', '')
                                    .replaceAll('month calendar', '')
                                    .trim();

                                return Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.only(bottom: 14.h),
                                  padding: EdgeInsets.all(16.r),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : (index == 0
                                        ? const Color(0xFFFFE5E5)
                                        : const Color(0xFFF7F7F7)),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Monthly / Weekly badge
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: AppText(
                                          isMonthly ? 'MONTHLY' : 'WEEKLY',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 5.h),

                                      // Month name
                                      AppText(
                                        monthName,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      SizedBox(height: 2.h),

                                      // Platforms
                                      AppText(
                                        item.platformAndPosts.toLowerCase().contains('facebook')
                                            ? 'Instagram + Facebook'
                                            : 'Instagram',
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black87,
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),

                                      SizedBox(height: 12.h),

                                      // Stats row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                AppText(
                                                  'Total posts',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.black87,
                                                    fontSize: 11.sp,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                AppText(
                                                  '12 Posts',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : Colors.black,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                AppText(
                                                  'Posting cadence',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.black87,
                                                    fontSize: 11.sp,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                AppText(
                                                  '3 / week',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : Colors.black,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                AppText(
                                                  'Used credits',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.black87,
                                                    fontSize: 11.sp,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                AppText(
                                                  isMonthly ? '24' : '8',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : Colors.black,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: SizedBox(
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
                              Navigator.pushNamed(
                                context,
                                "/SocialCalendarFormScreen",
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
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
