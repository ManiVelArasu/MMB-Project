import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../component/home_appbar.dart';
import '../../component/language_bottom_sheet.dart';
import '../../network/provider/auth_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/profile_screen_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/button_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isPersonalUse = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccountType();
  }

  Future<void> _checkAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    final accountType = prefs.getString('selected_account_type') ?? "";
    setState(() {
      isPersonalUse = (accountType == "Personal Use");
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: const Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    final Size size = MediaQuery.of(context).size;

    return Consumer<ProfileScreenProvider>(
      builder: (context, provider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(70.h),
              child: HomeCustomAppBar(
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
                      // 🚀 Personal Use Banner & Cards
                      if (isPersonalUse) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A1C)
                                : const Color(0xFFFFECEE),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Start Your Business Journey",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Create your business profile to unlock industry-specific templates and AI tools.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
                                  "Set Up My Business →",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1B2A38)
                                      : const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.badge_outlined,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Personal Profile",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF231B38)
                                      : const Color(0xFFEDE7F6),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.download,
                                      color: Colors.deepPurpleAccent,
                                      size: 28,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "My Downloads",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                      ] else ...[
                        // Quick Actions for Business Account
                        Row(
                          children: provider.quickActions.map((item) {
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => item.onTap(context),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : item.backgroundColor,
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        item.iconPath,
                                        height: 32.h,
                                        width: 32.w,
                                        errorBuilder: (_, _, _) => Icon(
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
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
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
                        _buildSectionHeader("My Business Settings", isDark),
                        SizedBox(height: 10.h),
                        _buildSettingsTile(
                          title: "Preferred Languages",
                          subtitle: "English, தமிழ், हिंदी",
                          iconAsset: "assets/images/lang_icon.png",
                          isDark: isDark,
                          onTap: () async {
                            await provider.fetchLanguage();

                            if (!context.mounted) return;

                            _showLanguagesBottomSheet(
                              context,
                              provider,
                              isDark,
                            );
                          },
                        ),
                        _buildSettingsTile(
                          title: "Add Watermark",
                          iconAsset: "assets/images/watermark_icon.png",
                          isDark: isDark,
                          trailingWidget: Switch(
                            value: provider.isWatermarkEnabled,
                            onChanged: (val) => provider.toggleWatermark(val),
                            activeThumbColor: const Color(0xFFE53935),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],

                      _buildSectionHeader("Help & Support", isDark),
                      SizedBox(height: 10.h),
                      _buildSettingsTile(
                        title: "Help & Support",
                        iconAsset: "assets/images/help_icon.png",
                        isDark: isDark,
                        onTap: () {
                          Navigator.pushNamed(context, "/HelpSupportScreen");
                        },
                      ),
                      _buildSettingsTile(
                        title: "FAQs",
                        iconAsset: "assets/images/faq_icon.png",
                        isDark: isDark,
                        onTap: () {
                          Navigator.pushNamed(context, "/FaqScreen");
                        },
                      ),

                      SizedBox(height: 20.h),

                      _buildSectionHeader("App Settings", isDark),
                      SizedBox(height: 10.h),
                      _buildSettingsTile(
                        title: "Dark Mode",
                        iconAsset: "assets/images/dark_mode_icon.png",
                        isDark: isDark,
                        trailingWidget: Switch(
                          value: isDark,
                          activeThumbColor: const Color(0xFFE53935),
                          onChanged: (bool value) {
                            themeProvider.toggleTheme(value);
                          },
                        ),
                      ),
                      _buildSettingsTile(
                        title: "Notifications",
                        iconAsset: "assets/images/notification_icon.png",
                        isDark: isDark,
                        onTap: () {
                          Navigator.pushNamed(context, "/NotificationScreen");
                        },
                      ),

                      SizedBox(height: 20.h),

                      _buildSectionHeader("About App", isDark),
                      SizedBox(height: 10.h),
                      _buildSettingsTile(
                        title: "Feedback",
                        iconAsset: "assets/images/feedback_icon.png",
                        isDark: isDark,
                        onTap: () {
                          Navigator.pushNamed(context, "/FeedbackScreen");
                        },
                      ),
                      _buildSettingsTile(
                        title: "Privacy Policy",
                        iconAsset: "assets/images/privacy_icon.png",
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "Terms & Conditions",
                        iconAsset: "assets/images/terms_icon.png",
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "Refund Policy",
                        iconAsset: "assets/images/refund_icon.png",
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        title: "Follow Us",
                        iconAsset: "assets/images/follow_icon.png",
                        isDark: isDark,
                        onTap: () {},
                      ),
                      SizedBox(height: 10.h),
                      _buildSettingsTile(
                        title: "Delete my Account",
                        iconAsset: "assets/images/delete_icon.png",
                        isDark: isDark,
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

                      ButtonWidget(
                        isLoading: provider.isLogoutLoading,
                        buttonPress: () {
                          final parentContext = context;

                          showDialog(
                            context: parentContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text("Logout"),
                              content: const Text(
                                "Are you sure you want to logout?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(dialogContext);

                                    await provider.logoutApi(parentContext);
                                  },
                                  child: const Text(
                                    "Logout",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        title: "Logout",
                        textStyle: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        height: 54.h,
                      ),
                      Center(
                        child: Text(
                          "App Version 1.2",
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
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

  Future<void> logoutUser(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('is_business_completed');
    await prefs.remove('saved_business_name');
    await prefs.remove('saved_email');
    await prefs.remove('saved_mobile_number');
    await prefs.remove('saved_business_image_path');
    await prefs.remove('is_logged_in');
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/LoginScreen',
      (route) => false,
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required String iconAsset,
    required bool isDark,
    VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9FB),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        leading: Image.asset(
          iconAsset,
          height: 24.h,
          width: 24.w,
          errorBuilder: (_, _, _) => Icon(
            Icons.tune_rounded,
            size: 20.sp,
            color: const Color(0xFFE53935),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing:
            trailingWidget ??
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 20.sp,
            ),
        onTap: onTap,
      ),
    );
  }
}

void _showLanguagesBottomSheet(
  BuildContext context,
  ProfileScreenProvider provider,
  bool isDark,
) {
  final languages = provider.plansData?.data ?? [];

  final Set<String> selectedCodes = {"en", "ta", "hi"};

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.62,
            ),
            padding: EdgeInsets.only(
              top: 10.h,
              left: 18.w,
              right: 18.w,
              bottom: 24.h,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181818) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 82.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Languages",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3A2020)
                              : const Color(0xFFFFE8E8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 28.h),
                Row(
                  children: [
                    Text(
                      "Selected Languages",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Container(
                      width: 34.w,
                      height: 34.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        "${selectedCodes.length}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                Text(
                  "Your post, their language – connect better, reach wider!",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 18.h),

                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: languages.map((language) {
                    final isSelected = selectedCodes.contains(
                      language.isActive,
                    );

                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selectedCodes.remove(language.code);
                          } else {
                            selectedCodes.add(language.code);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 108.w,
                        height: 40.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFD1D5)
                              : (isDark
                                    ? const Color(0xFF181818)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFD1D5)
                                : const Color(0xFFFFBFC4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          language.name,

                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      );
    },
  );
}
