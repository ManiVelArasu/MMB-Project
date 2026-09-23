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

    if (!mounted) return;

    setState(() {
      isPersonalUse = accountType == "Personal Use";
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
              child: HomeCustomAppBar(notificationCount: "2"),
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
                      // =====================================================
                      // PERSONAL ACCOUNT
                      // =====================================================

                      if (isPersonalUse) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                title: 'Personal Profile',
                                icon: Icons.person_outline_rounded,
                                iconColor: const Color(0xFF1976D2),
                                background: isDark
                                    ? const Color(0xFF18232D)
                                    : const Color(0xFFEAF5FF),
                                onTap: () {},
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildActionCard(
                                title: 'My Downloads',
                                icon: Icons.download_rounded,
                                iconColor: const Color(0xFF7C4DFF),
                                background: isDark
                                    ? const Color(0xFF241D32)
                                    : const Color(0xFFF0EAFE),
                                onTap: () {},
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        // =================================================
                        // MY ZONE
                        // =================================================
                        _buildSectionCard(
                          title: 'My Zone',
                          isDark: isDark,
                          children: [
                            _buildSettingsTile(
                              title: 'Dashboard',
                              icon: Icons.dashboard_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'My Brand',
                              icon: Icons.business_center_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'My Pins',
                              icon: Icons.push_pin_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'Brand Series',
                              icon: Icons.collections_bookmark_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'My Files',
                              icon: Icons.folder_open_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'AI Hub',
                              icon: Icons.auto_awesome_outlined,
                              isDark: isDark,
                              onTap: () {},
                              isLast: true,
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),
                      ]
                      // =====================================================
                      // BUSINESS ACCOUNT
                      // =====================================================
                      else ...[
                        Row(
                          children: provider.quickActions.map((item) {
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => item.onTap(context),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                                  height: 76.h,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1D1D1D)
                                        : item.backgroundColor,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(alpha: .05),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        item.iconPath,
                                        height: 25.h,
                                        width: 25.w,
                                        errorBuilder: (_, __, ___) {
                                          return Icon(
                                            Icons.dashboard_customize_rounded,
                                            size: 24.sp,
                                            color: const Color(0xFFE53935),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 5.h),
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 10),
                        _buildSectionCard(
                          title: 'My Zone',
                          isDark: isDark,
                          children: [
                            _buildSettingsTile(
                              title: 'Dashboard',
                              icon: Icons.dashboard_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'My Brand',
                              icon: Icons.business_center_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'My Pins',
                              icon: Icons.push_pin_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'Brand Series',
                              icon: Icons.collections_bookmark_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'My Files',
                              icon: Icons.folder_open_outlined,
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'AI Hub',
                              icon: Icons.auto_awesome_outlined,
                              isDark: isDark,
                              onTap: () {},
                              isLast: true,
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        _buildSectionCard(
                          title: "My Business Settings",
                          isDark: isDark,
                          children: [
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
                                onChanged: (value) {
                                  provider.toggleWatermark(value);
                                },
                              ),
                              isLast: true,
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),
                      ],

                      _buildSectionCard(
                        title: "Help & Support",
                        isDark: isDark,
                        children: [
                          _buildSettingsTile(
                            title: "Help & Support",
                            iconAsset: "assets/images/help_icon.png",
                            isDark: isDark,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                "/HelpSupportScreen",
                              );
                            },
                          ),
                          _buildSettingsTile(
                            title: "FAQs",
                            iconAsset: "assets/images/faq_icon.png",
                            isDark: isDark,
                            onTap: () {
                              Navigator.pushNamed(context, "/FaqScreen");
                            },
                            isLast: true,
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // =====================================================
                      // APP SETTINGS
                      // =====================================================
                      SizedBox(height: 20.h),

                      _buildSectionCard(
                        title: "App Settings",
                        isDark: isDark,
                        children: [
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
                              Navigator.pushNamed(
                                context,
                                "/NotificationScreen",
                              );
                            },
                            isLast: true,
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // =====================================================
                      // ABOUT APP
                      // =====================================================
                      SizedBox(height: 20.h),

                      _buildSectionCard(
                        title: "About App",
                        isDark: isDark,
                        children: [
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
                          _buildSettingsTile(
                            title: "Delete my Account",
                            iconAsset: "assets/images/delete_icon.png",
                            isDark: isDark,
                            onTap: provider.isDeactivateLoading
                                ? null
                                : () {
                                    provider.showDeactivateDialog(context);
                                  },
                            trailingWidget: provider.isDeactivateLoading
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : Icon(
                                    Icons.chevron_right_rounded,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    size: 20.sp,
                                  ),
                            isLast: true,
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // =====================================================
                      // OFFER BANNER
                      // =====================================================
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
                              "Select, Customize, and Publish.\n"
                              "All in One Place!",
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

                      // =====================================================
                      // LOGOUT
                      // =====================================================
                      ButtonWidget(
                        isLoading: provider.isLogoutLoading,
                        buttonPress: () {
                          final parentContext = context;

                          showDialog(
                            context: parentContext,
                            builder: (dialogContext) {
                              return AlertDialog(
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
                              );
                            },
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

                      SizedBox(height: 12.h),

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

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color background,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 76.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: .05),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 26.sp),
            SizedBox(height: 5.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS TILE
  // ============================================================

  Widget _buildSettingsTile({
    required String title,
    required bool isDark,
    IconData? icon,
    String? iconAsset,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailingWidget,
    Color? iconColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 27.w,
                  height: 27.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2020)
                        : const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: iconAsset != null
                      ? Image.asset(
                          iconAsset,
                          width: 16.w,
                          height: 16.w,
                          errorBuilder: (_, __, ___) {
                            return Icon(
                              icon ?? Icons.tune_rounded,
                              size: 16.sp,
                              color: iconColor ?? const Color(0xFFE53935),
                            );
                          },
                        )
                      : Icon(
                          icon ?? Icons.tune_rounded,
                          size: 16.sp,
                          color: iconColor ?? const Color(0xFFE53935),
                        ),
                ),

                SizedBox(width: 9.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (subtitle != null) ...[
                        SizedBox(height: 1.h),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black45,
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                trailingWidget ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white38 : Colors.black45,
                      size: 17.sp,
                    ),
              ],
            ),
          ),
        ),

        if (!isLast)
          Divider(
            height: 1,
            thickness: .5,
            indent: 46.w,
            endIndent: 10.w,
            color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8E8E8),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .025),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 9.h, 12.w, 4.h),
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

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
}

// ================================================================
// LOGOUT USER
// ================================================================

Future<void> logoutUser(BuildContext context, AuthProvider authProvider) async {
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

  Navigator.pushNamedAndRemoveUntil(context, '/LoginScreen', (route) => false);
}

// ================================================================
// LANGUAGE BOTTOM SHEET
// ================================================================

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
                // Drag handle
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

                // Header
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

                // Selected languages
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
                  "Your post, their language – "
                  "connect better, reach wider!",
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
                    final String code = language.code ?? "";

                    final bool isSelected = selectedCodes.contains(code);

                    final bool isActive = language.isActive == 1;

                    return GestureDetector(
                      onTap: () {
                        if (!isActive) return;

                        setModalState(() {
                          if (isSelected) {
                            selectedCodes.remove(code);
                          } else {
                            selectedCodes.add(code);
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
                                ? Colors.red
                                : const Color(0xFFFFBFC4),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          language.name ?? "",
                          style: TextStyle(
                            color: isSelected
                                ? Colors.red
                                : (isDark ? Colors.white : Colors.black),
                            fontSize: 15.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
