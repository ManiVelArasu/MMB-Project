import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../component/home_appbar.dart';
import '../../component/language_bottom_sheet.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/you_screen_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Consumer<ProfileScreenProvider>(
      builder: (context, provider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Dark status bar icons
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(70.h),
              child: HomeCustomAppBar(
                businessName: "Business Name",
                businessCategory: "Cake and Sweets",
                notificationCount: "2",
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: 12.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: provider.quickActions.map((item) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => item.onTap(context),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4.w),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  color: item.backgroundColor,
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      item.iconPath,
                                      height: 32.h,
                                      width: 32.w,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.badge_outlined,
                                        size: 28.sp,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      item.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 24.h),

                      _buildSectionHeader("My Business Settings"),
                      SizedBox(height: 10.h),
                      _buildSettingsTile(
                        title: "Preferred Languages",
                        subtitle: "English, தமிழ், हिंदी",
                        iconAsset: "assets/images/lang_icon.png",
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const LanguagesBottomSheet(),
                          );
                        },
                      ),
                      _buildSettingsTile(
                        title: "Add Watermark",
                        iconAsset: "assets/images/watermark_icon.png",
                        trailingWidget: Switch(
                          value: provider.isWatermarkEnabled,
                          onChanged: (val) => provider.toggleWatermark(val),
                          activeThumbColor: const Color(0xFFE53935),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      _buildSectionHeader("Help & Support"),
                      SizedBox(height: 10.h),
                      _buildSettingsTile(
                        title: "Help & Support",
                        iconAsset: "assets/images/help_icon.png",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "FAQs",
                        iconAsset: "assets/images/faq_icon.png",
                        onTap: () {},
                      ),

                      SizedBox(height: 20.h),

                      _buildSectionHeader("App Settings"),
                      SizedBox(height: 10.h),
                      Consumer<CustomThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _buildSettingsTile(
                            title: "Dark Mode",
                            iconAsset: "assets/images/dark_mode_icon.png",
                            trailingWidget: Switch(
                              value: themeProvider.isDarkMode,
                              activeThumbColor: const Color(0xFFE53935),
                              onChanged: (bool value) {
                                themeProvider.toggleTheme(value);
                              },
                            ),
                          );
                        },
                      ),
                      _buildSettingsTile(
                        title: "Notifications",
                        iconAsset: "assets/images/notification_icon.png",
                        onTap: () {},
                      ),

                      SizedBox(height: 20.h),

                      _buildSectionHeader("About App"),
                      SizedBox(height: 10.h),
                      _buildSettingsTile(
                        title: "Feedback",
                        iconAsset: "assets/images/feedback_icon.png",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "Privacy Policy",
                        iconAsset: "assets/images/privacy_icon.png",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "Terms & Conditions",
                        iconAsset: "assets/images/terms_icon.png",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "Refund Policy",
                        iconAsset: "assets/images/refund_icon.png",
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "Follow Us",
                        iconAsset: "assets/images/follow_icon.png",
                        onTap: () {},
                      ),

                      SizedBox(height: 10.h),

                      _buildSettingsTile(
                        title: "Delete my Account",
                        iconAsset: "assets/images/delete_icon.png",
                        onTap: () {},
                      ),

                      SizedBox(height: 24.h),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          image: const DecorationImage(
                            image: AssetImage("assets/images/offer bg.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Level Up your SM with\nour Themes",
                              style: TextStyle(
                                color: const Color(0xFF303F9F),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Select, Customize, and Publish.\nAll in One Place!",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C4DFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: const Text(
                                "ACTIVATE NOW",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required String iconAsset,
    VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      color: const Color(0xFFF9F9FB),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        leading: Image.asset(
          iconAsset,
          height: 24.h,
          width: 24.w,
          errorBuilder: (_, __, ___) => Icon(
            Icons.tune_rounded,
            size: 20.sp,
            color: const Color(0xFFE53935),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing:
            trailingWidget ??
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black87,
              size: 20.sp,
            ),
        onTap: onTap,
      ),
    );
  }
}
