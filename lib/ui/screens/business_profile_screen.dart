import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:provider/provider.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/businessprofile_provider.dart';

import '../../network/provider/custom_theme_provider.dart';
import '../industry/widgets/image_viewer.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusinessProfileProvider(),
      child: const BusinessProfileView(),
    );
  }
}

class BusinessProfileView extends StatelessWidget {
  const BusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<BusinessProfileProvider>(
      builder: (context, provider, child) {
        final businessProvider = context.watch<BusinessProvider>();
        String? savedImagePath = businessProvider.savedImagePath;

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
                      horizontal: size.width * 0.04,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark
                              ? const Color(0xFF2A1A1C)
                              : const Color(0xFFFFECEE).withValues(alpha: 0.6),
                          isDark ? const Color(0xFF121212) : Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Back Arrow
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 38.h,
                              width: 38.w,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A1A1C)
                                    : const Color(0xFFFFECEE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: const Color(0xFFE53935),
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // Profile Logo
                        Container(
                          height: 48.h,
                          width: 48.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: ClipOval(
                            child:
                                savedImagePath != null &&
                                    savedImagePath.isNotEmpty &&
                                    File(savedImagePath).existsSync()
                                ? InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ImageViewerScreen(
                                                imagePath: savedImagePath,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Image.file(
                                      File(savedImagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                                "assets/images/BName.png",
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: const Color(
                                                        0xFFE91E63,
                                                      ),
                                                      child: const Icon(
                                                        Icons.business,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                              ),
                                    ),
                                  )
                                : Image.asset(
                                    "assets/images/BName.png",
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: const Color(0xFFE91E63),
                                              child: const Icon(
                                                Icons.business,
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        AppText(
                          provider.businessName.isEmpty
                              ? "Business Name"
                              : provider.businessName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          "Pastry Kitchen",
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, "/EditProfileScreen");
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                "EDIT BUSINESS DETAILS",
                                style: TextStyle(
                                  color: const Color(0xFFE53935),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.edit_note_rounded,
                                color: const Color(0xFFE53935),
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),

                        Row(
                          children: [
                            _buildActionCard(
                              title: "ABOUT",
                              iconAsset: "assets/images/about.png",
                              bgColor: isDark
                                  ? const Color(0xFF332211)
                                  : const Color(0xFFFFDBB9),
                              isDark: isDark,
                            ),
                            SizedBox(width: 10.w),
                            _buildActionCard(
                              title: "MY PRODUCTS",
                              iconAsset: "assets/images/product.png",
                              bgColor: isDark
                                  ? const Color(0xFF113338)
                                  : const Color(0xFF72E8F5),
                              isDark: isDark,
                            ),
                            SizedBox(width: 10.w),
                            _buildActionCard(
                              title: "UPLOADS",
                              iconAsset: "assets/images/uploads.png",
                              bgColor: isDark
                                  ? const Color(0xFF1D3315)
                                  : const Color(0xFF9AE278),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  SizedBox(height: 16.h),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Plus Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  "assets/images/frames_icon.png",
                                  height: 24.h,
                                  width: 24.w,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.layers_rounded,
                                    color: const Color(0xFFE53935),
                                    size: 22.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                AppText(
                                  "My Frames",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 32.h,
                              width: 32.w,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A1A1C)
                                    : const Color(0xFFFFECEE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: const Color(0xFFE53935),
                                size: 22.sp,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12.h),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => provider.updateFrameTab(0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    "Static Frames",
                                    style: TextStyle(
                                      color: provider.selectedFrameTab == 0
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black)
                                          : Colors.grey,
                                      fontSize: 14.sp,
                                      fontWeight: provider.selectedFrameTab == 0
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (provider.selectedFrameTab == 0)
                                    Container(
                                      margin: EdgeInsets.only(top: 4.h),
                                      height: 3.h,
                                      width: 85.w,
                                      color: const Color(0xFFE53935),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20.w),
                            GestureDetector(
                              onTap: () => provider.updateFrameTab(1),
                              child: AppText(
                                "Animated Frames",
                                style: TextStyle(
                                  color: provider.selectedFrameTab == 1
                                      ? (isDark ? Colors.white : Colors.black)
                                      : Colors.grey.shade400,
                                  fontSize: 14.sp,
                                  fontWeight: provider.selectedFrameTab == 1
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Frames Horizontal ListView
                        SizedBox(
                          height: 145.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: provider.staticFrames.length,
                            itemBuilder: (context, index) {
                              final frame = provider.staticFrames[index];

                              return Container(
                                width: 110.w,
                                margin: EdgeInsets.only(right: 12.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E1E1E)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Container(
                                                  color: isDark
                                                      ? const Color(0xFF1E1E1E)
                                                      : Colors.white,
                                                ),
                                              ),
                                              Positioned(
                                                top: 8.h,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: Image.asset(
                                                    "assets/images/abslogo.png",
                                                    height: 18.h,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                          Icons.auto_awesome,
                                                          size: 16.sp,
                                                          color: const Color(
                                                            0xFFE53935,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 4.h,
                                                left: 4.w,
                                                right: 4.w,
                                                child: provider.isSolidBanner
                                                    ? _buildSolidBanner(
                                                        provider,
                                                      )
                                                    : _buildOutlineBanner(
                                                        provider,
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    AppText(
                                      frame["price"] ??
                                          (index == 0
                                              ? "Free"
                                              : "Rs.0 (Rs.100 Unlocked)"),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  SizedBox(height: 16.h),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "My Keywords",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            AppText(
                              "MANAGE",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12.h),

                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: provider.keywords.map((keyword) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                              ),
                              child: AppText(
                                keyword,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  SizedBox(height: 16.h),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Online Presence",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        Row(
                          children: [
                            Expanded(
                              child: _buildPresenceTile(
                                title: "Business Profile",
                                iconAsset: "assets/images/b_profile.png",
                                bgColor: isDark
                                    ? const Color(0xFF2A1A1C)
                                    : const Color(0xFFFFECEE),
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildPresenceTile(
                                title: "Business Card",
                                iconAsset: "assets/images/b_card.png",
                                bgColor: isDark
                                    ? const Color(0xFF1B2A38)
                                    : const Color(0xFFE3F2FD),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutlineBanner(BusinessProfileProvider businessProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF0066FF), width: 1.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: const Color(0xFF0066FF), size: 6.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: AppText(
              businessProvider.mobileNumber.isEmpty
                  ? "+91 9876543210"
                  : businessProvider.mobileNumber,
              style: TextStyle(
                color: const Color(0xFF0066FF),
                fontSize: 5.5.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF0066FF), width: 0.8),
            ),
            child: Row(
              children: [
                Icon(Icons.message, size: 5.sp, color: const Color(0xFF0066FF)),
                SizedBox(width: 1.w),
                Icon(
                  Icons.facebook,
                  size: 5.sp,
                  color: const Color(0xFF0066FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidBanner(BusinessProfileProvider businessProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0066FF),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: Colors.white, size: 6.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: AppText(
              businessProvider.mobileNumber.isEmpty
                  ? "+91 9876543210"
                  : businessProvider.mobileNumber,
              style: TextStyle(
                color: Colors.white,
                fontSize: 5.5.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(Icons.message, size: 5.sp, color: Colors.white),
                SizedBox(width: 1.w),
                Icon(Icons.facebook, size: 5.sp, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String iconAsset,
    required Color bgColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        height: 100.h,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              height: 36.h,
              width: 36.w,
              errorBuilder: (_, __, ___) => Icon(
                Icons.folder_outlined,
                size: 32.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: 8.h),
            AppText(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceTile({
    required String title,
    required String iconAsset,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            height: 28.h,
            width: 28.w,
            errorBuilder: (_, __, ___) => Icon(
              Icons.badge_outlined,
              size: 24.sp,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: AppText(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
