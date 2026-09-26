import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../component/home_appbar.dart';
import '../../component/language_bottom_sheet.dart';
import '../../network/provider/auth_provider.dart';
import '../../network/provider/common_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/home_screen_provider.dart';
import '../../network/provider/profile_screen_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/button_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String accountType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccountType();
  }

  Future<void> _checkAccountType() async {
    final prefs = await SharedPreferences.getInstance();

    String type =
        CommonProvider.instance.accountType?.trim().toLowerCase() ?? '';
    if (type.isEmpty) {
      await CommonProvider.instance.loadMe(forceRefresh: true);

      type = CommonProvider.instance.accountType?.trim().toLowerCase() ?? '';
    }

    // Final fallback
    if (type.isEmpty) {
      type = (prefs.getString('account_type') ?? '').trim().toLowerCase();
    }

    debugPrint('================================');
    debugPrint('PROFILE ACCOUNT TYPE = [$type]');
    debugPrint('================================');

    if (!mounted) return;

    setState(() {
      accountType = type;
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
              child: HomeCustomAppBar(),
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
                      if (accountType == 'personal') ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            border: Border.all(
                              color: const Color(0xFFFFDADA),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // =====================================================
                              // TITLE + GIFT IMAGE
                              // =====================================================

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AppText(
                                    'Great News!',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),

                                  SizedBox(
                                    width: 48.w,
                                    height: 48.w,
                                    child: Image.asset(
                                      'assets/images/gift.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4.h),

                              // =====================================================
                              // 20 + FREE AI CREDITS
                              // =====================================================
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AppText(
                                    '20',
                                    style: TextStyle(
                                      fontSize: 52.sp,
                                      height: 0.9,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF5222D),
                                    ),
                                  ),

                                  SizedBox(width: 12.w),

                                  Expanded(
                                    child: AppText(
                                      'Free AI Credits\nhave been added to your account',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        height: 1.18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4.h),

                              // =====================================================
                              // DESCRIPTION
                              // =====================================================
                              AppText(
                                'Use your credits to explore AI tools and create\namazing content for yourself.',
                                style: TextStyle(
                                  fontSize: AppFontSize.fontSize13,
                                  height: 1.25,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF555555),
                                ),
                              ),

                              SizedBox(height: 7.h),

                              Row(
                                children: [
                                  SizedBox(
                                    height: 42.h,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF5222D,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                      ),
                                      child: AppText(
                                        'EXPLORE AI TOOLS',
                                        style: TextStyle(
                                          fontSize: AppFontSize.fontSize13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 10.w),

                                  TextButton(
                                    onPressed: () {
                                      // Credit usage
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: AppText(
                                      'CREDIT USAGE',
                                      style: TextStyle(
                                        fontSize: AppFontSize.fontSize13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF5222D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 6.h),

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF700000),
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'Set Up Your Business',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21.sp,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              SizedBox(height: 5.h),

                              AppText(
                                accountType == 'personal'
                                    ? 'Add your profile details, interests, and other information once, it makes your personal experience easier.'
                                    : 'Add your business name, category, contact details, and other information once, it makes creating content for your business easier.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              SizedBox(height: 10.h),

                              SizedBox(
                                height: 42.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (accountType == 'personal') {
                                      Navigator.pushNamed(
                                        context,
                                        "/PersonalProfileScreen",
                                      );
                                    } else {
                                      Navigator.pushNamed(
                                        context,
                                        "/BusinessDetailsScreen",
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF5222D),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: AppText(
                                    accountType == 'personal'
                                        ? 'COMPLETE MY PROFILE →'
                                        : 'SET UP MY BUSINESS →',
                                    style: TextStyle(
                                      fontSize: AppFontSize.fontSize13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10.h),
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
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/BusinessProfileScreen",
                                  );
                                },
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

                        _buildSectionCard(
                          title: 'My Zone',
                          isDark: isDark,
                          children: [
                            _buildSettingsTile(
                              title: 'My Plan',
                              iconAsset: "assets/images/my_plan.png",
                              isDark: isDark,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  "/PlansAndPricingScreen",
                                );
                              },
                            ),

                            _buildSettingsTile(
                              title: 'Near Me',
                              iconAsset: "assets/images/shop.png",
                              isDark: isDark,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  "/PlansAndPricingScreen",
                                );
                              },
                            ),
                            _buildSettingsTile(
                              title: 'AI Hub',
                              iconAsset: "assets/images/ai_tool.png",
                              isDark: isDark,
                              onTap: () {},
                              isLast: true,
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),
                      ] else ...[
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
                                      AppText(
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
                              title: 'My Plan',
                              iconAsset: "assets/images/my_plan.png",
                              isDark: isDark,
                              onTap: () {
                                Navigator.pushNamed(context, "/PlansAndPricingScreen");
                              },
                            ),
                            _buildSettingsTile(
                              title: 'Brand Series',
                              iconAsset: "assets/images/direct.png",
                              isDark: isDark,
                              onTap: () {},
                            ),

                            _buildSettingsTile(
                              title: 'Near Me',
                              iconAsset: "assets/images/shop.png",
                              isDark: isDark,
                              onTap: () {},
                            ),
                            _buildSettingsTile(
                              title: 'AI Hub',
                              iconAsset: "assets/images/ai_tool.png",
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
                              iconAsset: "assets/images/message_favorite.png",
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
                              iconAsset: "assets/images/pet.png",
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
                            iconAsset: "assets/images/help.png",
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
                            iconAsset: "assets/images/faq.png",
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
                            iconAsset: "assets/images/moon.png",
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
                            iconAsset: "assets/images/notification.png",
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
                            iconAsset: "assets/images/feedback.png",
                            isDark: isDark,
                            onTap: () {
                              Navigator.pushNamed(context, "/FeedbackScreen");
                            },
                          ),
                          _buildSettingsTile(
                            title: "Privacy Policy",
                            iconAsset: "assets/images/document_text.png",
                            isDark: isDark,
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            title: "Terms & Conditions",
                            iconAsset: "assets/images/document_text.png",
                            isDark: isDark,
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            title: "Refund Policy",
                            iconAsset: "assets/images/bill.png",
                            isDark: isDark,
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            title: "Follow Us",
                            iconAsset: "assets/images/people.png",
                            isDark: isDark,
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            title: "Delete my Account",
                            iconAsset: "assets/images/user_remove.png",
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
                            AppText(
                              "Build Your Brand with Brand Series",
                              style: TextStyle(
                                color: const Color(0xFF303F9F),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            AppText(
                              "Create consistent social media designs \nfor your business, all in one place.",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8C74F5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: const AppText(
                                "Explore Now",
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
                                title: const AppText("Logout"),
                                content: const AppText(
                                  "Are you sure you want to logout?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    child: const AppText("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);

                                      await provider.logoutApi(parentContext);
                                    },
                                    child: const AppText(
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
                        child: AppText(
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
            AppText(
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
                      AppText(
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
                        AppText(
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
            child: AppText(
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
  await prefs.remove('logo_s3_key');
  await prefs.remove('profile_s3_key');
  await prefs.remove('profile_photo_s3_key');
  clearUserSession(context);

  if (!context.mounted) return;

  Navigator.pushNamedAndRemoveUntil(context, '/LoginScreen', (route) => false);
}

Future<void> clearUserSession(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // =========================================================
  // AUTH
  // =========================================================

  await prefs.remove('is_logged_in');
  await prefs.remove('auth_token');
  await prefs.remove('refresh_token');

  // =========================================================
  // USER
  // =========================================================

  await prefs.remove('user_id');
  await prefs.remove('uid');
  await prefs.remove('mobile_number');
  await prefs.remove('phone_number');

  // =========================================================
  // ACCOUNT
  // =========================================================

  await prefs.remove('account_type');
  await prefs.remove('role');

  // =========================================================
  // BUSINESS / PROFILE
  // =========================================================

  await prefs.remove('is_business_completed');
  await prefs.remove('saved_business_name');
  await prefs.remove('saved_email');
  await prefs.remove('saved_mobile_number');
  await prefs.remove('saved_business_image_path');

  await prefs.remove('business_name');

  await prefs.remove('logo_s3_key');
  await prefs.remove('profile_s3_key');
  await prefs.remove('profile_photo_s3_key');

  // =========================================================
  // ACCOUNT SELECTION / CONTINUE
  // =========================================================

  await prefs.remove('continue');
  await prefs.remove('continue_status');
  await prefs.remove('selected_account');
  await prefs.remove('selected_account_type');

  // =========================================================
  // PROVIDER CLEAR
  // =========================================================

  CommonProvider.instance.clearAll();

  try {
    context.read<HomeScreenProvider>().clearUserData();
  } catch (e) {
    debugPrint('HomeScreenProvider clear error: $e');
  }

  try {
    context.read<CommonProvider>().clearAll();
  } catch (e) {
    debugPrint('AuthProvider clear error: $e');
  }

  debugPrint("========================================");
  debugPrint("✅ COMPLETE USER SESSION CLEARED");
  debugPrint("========================================");
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
                      child: AppText(
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
                    AppText(
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
                      child: AppText(
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

                AppText(
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
                        child: AppText(
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
