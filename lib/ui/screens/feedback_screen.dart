import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_widget.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/feedback_provider.dart';
import '../../widgets/emoji_rating.dart';
import '../../widgets/feedback_textfield.dart';

import '../../network/provider/custom_theme_provider.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedbackProvider(),
      child: Consumer2<FeedbackProvider, CustomThemeProvider>(
        builder: (context, provider, themeProvider, child) {
          final isDark = themeProvider.isDarkMode;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: const CustomAppBar(
              showTitle: true,
              title: "Feedback",
              showRightIcon: false,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20.h),

                  AppText(
                    "Our support Team will available Monday to Saturday,10 AM-7 PM to assist you with any queries",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  const EmojiRating(),

                  SizedBox(height: 30.h),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      "Do you have any thoughts you'd like to share:",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  const FeedbackTextField(),

                  SizedBox(height: 40.h),

                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.submitFeedback();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Feedback submitted successfully"),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: AppText(
                        "Submit",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
}
