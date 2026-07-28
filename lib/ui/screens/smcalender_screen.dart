import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/smcalender_provider.dart';

class SmCalendarScreen extends StatelessWidget {
  const SmCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 FIX: Wrap with ChangeNotifierProvider so SmCalendarProvider is locally available for this route
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
    return Consumer<SmCalendarProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
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
                    decoration: BoxDecoration(
                      color: AppColors.litePink,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.r),
                        bottomRight: Radius.circular(30.r),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: 12.w,
                                  top: 4.h,
                                  bottom: 4.h,
                                ),
                                child: Image.asset(
                                  "assets/images/back.png",
                                  width: 26.w,
                                  height: 26.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            AppText(
                              "My Monthly SM Calendars",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        AppText(
                          "Plan your content with ease using our AI-powered calendar. Get ready-to-use post ideas and matching content tailored for your brand. All in just a few taps!",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.5.sp,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                          "My SM Calendars",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
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

                            return Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 14.h),
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    item.title,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  SizedBox(height: 4.h),

                                  AppText(
                                    item.frequency,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  SizedBox(height: 10.h),
                                  AppText(
                                    item.platformAndPosts,
                                    style: TextStyle(
                                      color: AppColors.appBlack,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
