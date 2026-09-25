import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/network/provider/common_provider.dart';
import 'package:provider/provider.dart';
import '../../component/appbar_widget.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
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

        // Listen directly to CommonProvider because Edit Profile
        // refreshes GetMe/Business through this provider.
        // This guarantees the new profile image is rebuilt
        // immediately when the API returns.
        final commonProvider = context.watch<CommonProvider>();

        final accountType =
            commonProvider.me?.data.accountType ??
                businessProvider.provider.me?.data.accountType;

        // PERSONAL: only the personal design is shown.
        // BUSINESS: the existing business UI below is untouched.
        if (accountType == "personal") {
          return _buildPersonalProfileScreen(
            context,
            isDark,
            commonProvider,
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: provider.isKeyWordsLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
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
                              : const Color(
                            0xFFFFECEE,
                          ).withValues(alpha: 0.6),
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
                          width: 70.w,
                          height: 70.w,
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ImageViewerScreen(
                                        imagePath:
                                        '${ApiEndpoints.cdnImageUrl}/${provider.commonProvider.business?.logoS3Key ?? ''}',
                                      ),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  '${ApiEndpoints.cdnImageUrl}/${provider.commonProvider.business?.logoS3Key ?? ''}',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        AppText(
                          provider.businessName.isEmpty
                              ? "${provider.commonProvider.business?.name}"
                              : provider.businessName,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        AppText(
                          "${provider.commonProvider.business?.businessCategory?.parent?.slug}",
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
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              "/EditProfileScreen",
                            );

                            if (!context.mounted) return;

                            if (result == true) {
                              debugPrint(
                                "🔄 Edit Profile returned TRUE"
                                    " → refreshing profile API",
                              );

                              await context
                                  .read<BusinessProfileProvider>()
                                  .refreshProfileAfterEdit();
                            }
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
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    "Static Frames",
                                    style: TextStyle(
                                      color:
                                      provider.selectedFrameTab == 0
                                          ? (isDark
                                          ? Colors.white
                                          : Colors.black)
                                          : Colors.grey,
                                      fontSize: 14.sp,
                                      fontWeight:
                                      provider.selectedFrameTab == 0
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
                                      ? (isDark
                                      ? Colors.white
                                      : Colors.black)
                                      : Colors.grey.shade400,
                                  fontSize: 14.sp,
                                  fontWeight:
                                  provider.selectedFrameTab == 1
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E1E1E)
                                              : Colors.white,
                                          borderRadius:
                                          BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(10.r),
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Container(
                                                  color: isDark
                                                      ? const Color(
                                                    0xFF1E1E1E,
                                                  )
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
                                                        (
                                                        _,
                                                        __,
                                                        ___,
                                                        ) => Icon(
                                                      Icons
                                                          .auto_awesome,
                                                      size: 16.sp,
                                                      color:
                                                      const Color(
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
                                                child:
                                                provider.isSolidBanner
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
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  ),
                  SizedBox(height: 16.h),

                  const _BrandKitSection(),

                  SizedBox(height: 16.h),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              "My Keywords",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface,
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
                          children: (provider.keyWords).map<Widget>((
                              keywordItem,
                              ) {
                            final keyword =
                                keywordItem.name?.trim() ?? '';

                            if (keyword.isEmpty) {
                              return const SizedBox.shrink();
                            }

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
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface,
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

  // ===========================================================================
  // PERSONAL PROFILE DESIGN
  // ===========================================================================

  Widget _buildPersonalProfileScreen(
      BuildContext context,
      bool isDark,
      CommonProvider provider,
      ) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(showRightIcon: false,),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // HEADER + PERSONAL PROFILE
              // ----------------------------------------------------------------
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Column(
                  children: [
                    Container(
                      width: 70.w,
                      height: 70.w,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageViewerScreen(
                                    imagePath:
                                    '${ApiEndpoints.cdnImageUrl}/${provider.me?.data.profilePhotoS3Key ?? ''}',
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              '${ApiEndpoints.cdnImageUrl}/${provider.me?.data.profilePhotoS3Key ?? ''}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    AppText(
                      "${provider.me!.data.name!.isEmpty ? "${provider.me?.data.name}" : provider.me?.data.name}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    SizedBox(height: 8.h),

                    InkWell(
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          "/EditProfileScreen",
                        );

                        if (!context.mounted) return;

                        if (result == true) {
                          debugPrint(
                            "🔄 Edit Profile returned TRUE"
                                " → refreshing profile API",
                          );

                          await context
                              .read<BusinessProfileProvider>()
                              .refreshProfileAfterEdit();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            "EDIT PERSONAL DETAILS",
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
                  ],
                ),
              ),

              // ----------------------------------------------------------------
              // MY DOWNLOADS + MEDIA LIBRARY
              // ----------------------------------------------------------------
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: _personalActionCard(
                        title: "My Downloads",
                        icon: Icons.file_download_outlined,
                        iconColor: const Color(0xFF8067E8),
                        backgroundColor: const Color(0xFFF0EDFF),
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _personalActionCard(
                        title: "Media Library",
                        icon: Icons.folder_copy_outlined,
                        iconColor: const Color(0xFFE97955),
                        backgroundColor: const Color(0xFFFFEEDB),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.layers_rounded,
                              color: const Color(0xFFE53935),
                              size: 21.sp,
                            ),
                            SizedBox(width: 7.w),
                            Text(
                              "Your Frames",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 30.w,
                          width: 30.w,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3A2022)
                                : const Color(0xFFFFE1E4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: const Color(0xFFE53935),
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 11.h),

                    // Tabs exactly like the reference layout.
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Static Frames",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              height: 3.h,
                              width: 88.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 20.w),
                        Text(
                          "Animated Frames",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 11.h),

                    SizedBox(
                      height: 145.h,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _personalFrameCard(isDark: isDark, price: "Free"),
                          _personalFrameCard(
                            isDark: isDark,
                            price: "Rs.0 (Rs.100 Unlocked)",
                          ),
                          _personalFrameCard(isDark: isDark, price: "Free"),
                        ],
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
    );
  }

  Widget _personalActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 23.sp),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalFrameCard({required bool isDark, required String price}) {
    return Container(
      width: 100.w,
      margin: EdgeInsets.only(right: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7.r),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(5.w),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Icon(
                                Icons.auto_awesome,
                                size: 16.sp,
                                color: const Color(0xFF3478E5),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 17.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF3478E5),
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4.h,
                      left: 4.w,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 7.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandKitSection extends StatefulWidget {
  const _BrandKitSection();

  @override
  State<_BrandKitSection> createState() => _BrandKitSectionState();
}

class _BrandKitSectionState extends State<_BrandKitSection> {
  int selectedTab = 1;

  final List<_BrandPalette> palettes = [
    _BrandPalette(
      name: "My first palette",
      colors: [
        Color(0xFF2864D7),
        Color(0xFF1E3A8A),
        Color(0xFFE53E3E),
        Color(0xFFFF4B4B),
      ],
    ),
    _BrandPalette(
      name: "My first palette",
      colors: [
        Color(0xFF2563EB),
        Color(0xFF172554),
        Color(0xFFDC2626),
        Color(0xFFEF4444),
      ],
    ),
  ];

  final List<_BrandPalette> popularPalettes = [
    _BrandPalette(
      name: "Autumn Harvest",
      colors: [
        Color(0xFFFFB703),
        Color(0xFFFFD166),
        Color(0xFFF4E3C1),
        Color(0xFF6A994E),
      ],
    ),
    _BrandPalette(
      name: "Modern Pop",
      colors: [
        Color(0xFFFF4D6D),
        Color(0xFFFF758F),
        Color(0xFFEF233C),
        Color(0xFF4361EE),
        Color(0xFF3A0CA3),
      ],
    ),
    _BrandPalette(
      name: "Warm Haven",
      colors: [
        Color(0xFFD98C8C),
        Color(0xFFE7B7A3),
        Color(0xFFEFE3C8),
        Color(0xFF6A994E),
        Color(0xFF9AA6B2),
      ],
    ),
    _BrandPalette(
      name: "Urban Slate",
      colors: [
        Color(0xFF78909C),
        Color(0xFF90A4AE),
        Color(0xFF263238),
        Color(0xFF37474F),
        Color(0xFFECEFF1),
      ],
    ),
    _BrandPalette(
      name: "Cinnamon Blend",
      colors: [
        Color(0xFFB0BEC5),
        Color(0xFF8D6E63),
        Color(0xFF795548),
        Color(0xFF6D4C41),
        Color(0xFF4E342E),
      ],
    ),
    _BrandPalette(
      name: "Golden Meadow",
      colors: [
        Color(0xFF8BC34A),
        Color(0xFFAED581),
        Color(0xFFFFCA28),
        Color(0xFF26A69A),
        Color(0xFFF5E6C8),
      ],
    ),
    _BrandPalette(
      name: "Cozy Twilight",
      colors: [
        Color(0xFFB8A9D6),
        Color(0xFF8E9AAF),
        Color(0xFF253858),
        Color(0xFFE7B8B8),
        Color(0xFFD98F8F),
      ],
    ),
    _BrandPalette(
      name: "Blush Bloom",
      colors: [
        Color(0xFFFFCAD4),
        Color(0xFFFFB3C1),
        Color(0xFFFF8FAB),
        Color(0xFFE76F9A),
        Color(0xFFD45087),
      ],
    ),
    _BrandPalette(
      name: "Sandstone",
      colors: [
        Color(0xFFF4E9D8),
        Color(0xFFE6D5B8),
        Color(0xFFD5BDAF),
        Color(0xFFC5A880),
        Color(0xFF9C755F),
      ],
    ),
    _BrandPalette(
      name: "Lavender Meadow",
      colors: [
        Color(0xFF2B2D66),
        Color(0xFF5C5AA8),
        Color(0xFF8E8CC7),
        Color(0xFFB8D8D8),
        Color(0xFF9ED8C5),
        Color(0xFF252A34),
      ],
    ),
    _BrandPalette(
      name: "Spring Blossom",
      colors: [
        Color(0xFFE63946),
        Color(0xFFFFB703),
        Color(0xFF90BE6D),
        Color(0xFFA8DADC),
        Color(0xFFB8A9D6),
      ],
    ),
    _BrandPalette(
      name: "Sunset Coral",
      colors: [
        Color(0xFFE63946),
        Color(0xFFF94144),
        Color(0xFFF3722C),
        Color(0xFF43AA8B),
        Color(0xFF577590),
      ],
    ),
    _BrandPalette(
      name: "Floral Charm",
      colors: [
        Color(0xFFFFB5C5),
        Color(0xFFF6C6D8),
        Color(0xFFA8D5BA),
        Color(0xFF8FCB9B),
        Color(0xFFB7D7C5),
      ],
    ),
  ];

  final List<_BrandFont> fonts = [
    _BrandFont("Heading", "Inter", 85),
    _BrandFont("Subheading", "Poppins", 42),
    _BrandFont("Body text", "Inter", 24),
  ];

  // Keep this list in sync with the Google Fonts already configured in the app.
  // These names are also used by the existing editor font selector.
  final List<String> availableFonts = const [
    "Inter",
    "Janda Manatee Solid",
    "JekoVariable",
    "Anton",
    "Roboto",
    "Poppins",
    "Pacifico",
    "Playfair Display",
    "Montserrat",
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    color: const Color(0xFFE53935),
                    size: 21.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Brand Kit",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              _roundPlus(
                isDark: isDark,
                onTap: () => _showCustomColorDialog(context),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              _kitTab("Logo", 0, isDark),
              SizedBox(width: 16.w),
              _kitTab("Brand Colors", 1, isDark),
              SizedBox(width: 16.w),
              _kitTab("Fonts", 2, isDark),
            ],
          ),
          SizedBox(height: 14.h),

          if (selectedTab == 0)
            _buildLogoTab(context, isDark)
          else if (selectedTab == 1)
            _buildColorsTab(context, isDark)
          else
            _buildFontsTab(context, isDark),
        ],
      ),
    );
  }

  Widget _kitTab(String title, int index, bool isDark) {
    final selected = selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: selected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey.shade500,
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          SizedBox(height: 5.h),
          if (selected)
            Container(
              height: 2.5.h,
              width: title == "Brand Colors" ? 82.w : 35.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoTab(BuildContext context, bool isDark) {
    final provider = context.read<BusinessProfileProvider>();
    final logoKey = provider.commonProvider.business?.logoS3Key ?? "";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.black26 : Colors.grey.shade100,
            ),
            clipBehavior: Clip.antiAlias,
            child: logoKey.isEmpty
                ? Icon(Icons.image_outlined, color: Colors.grey, size: 30.sp)
                : Image.network(
              '${ApiEndpoints.cdnImageUrl}/$logoKey',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_outlined,
                color: Colors.grey,
                size: 30.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Business Logo",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Your primary brand logo",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 19.sp, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildColorsTab(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Colors",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            _smallPlus(
              isDark: isDark,
              onTap: () => _showCustomColorDialog(context),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Only selected/custom colors are shown here.
        // Every color is independent and can be selected separately.
        if (palettes.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171717) : Colors.white,
              borderRadius: BorderRadius.circular(9.r),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              "No brand colors added. Tap + to add a color.",
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            ),
          )
        else
          ...palettes.asMap().entries.map(
                (entry) =>
                _buildSingleColorCard(context, entry.key, entry.value, isDark),
          ),
      ],
    );
  }

  Widget _buildSingleColorCard(
      BuildContext context,
      int index,
      _BrandPalette palette,
      bool isDark,
      ) {
    final color = palette.colors.isEmpty ? Colors.grey : palette.colors.first;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171717) : Colors.white,
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: Colors.black.withValues(alpha: .08)),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  palette.name,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _hex(color),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (palette.isSelected)
            Icon(
              Icons.check_circle,
              size: 18.sp,
              color: const Color(0xFFE53935),
            ),
          SizedBox(width: 5.w),
          GestureDetector(
            onTap: () {
              setState(() {
                palettes.removeAt(index);
              });
            },
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18.sp,
              color: const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectSingleColor(BuildContext context, int index) async {
    if (index < 0 || index >= palettes.length) return;

    final palette = palettes[index];
    if (palette.colors.isEmpty) return;

    // Keep this color as the currently selected brand color.
    // The selected color is independent from every other color.
    setState(() {
      for (int i = 0; i < palettes.length; i++) {
        palettes[i] = _BrandPalette(
          name: palettes[i].name,
          colors: List<Color>.from(palettes[i].colors),
          isSelected: i == index,
        );
      }
    });
  }

  Widget _buildFontsTab(BuildContext context, bool isDark) {
    return Column(
      children: fonts.asMap().entries.map((entry) {
        final index = entry.key;
        final font = entry.value;

        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171717) : Colors.white,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${font.title}, ${font.family} - ${font.size}',
                      style: TextStyle(
                        fontFamily: font.family,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      font.family,
                      style: TextStyle(
                        fontFamily: font.family,
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () => _showFontEditDialog(context, index, isDark),
                child: Padding(
                  padding: EdgeInsets.all(6.r),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 17.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showFontEditDialog(
      BuildContext context,
      int index,
      bool isDark,
      ) async {
    final current = fonts[index];
    String selectedFont = current.family;
    double selectedSize = current.size.toDouble();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit ${current.title} Font',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Font Family',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      constraints: BoxConstraints(maxHeight: 260.h),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: availableFonts.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        itemBuilder: (_, fontIndex) {
                          final fontName = availableFonts[fontIndex];
                          final selected = selectedFont == fontName;

                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 34.w,
                              height: 34.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFECEE)
                                    : (isDark
                                    ? const Color(0xFF252525)
                                    : const Color(0xFFF5F5F5)),
                                borderRadius: BorderRadius.circular(7.r),
                              ),
                              child: Text(
                                'Aa',
                                style: TextStyle(
                                  fontFamily: fontName,
                                  fontSize: 14.sp,
                                  color: selected
                                      ? const Color(0xFFE53935)
                                      : (isDark
                                      ? Colors.white
                                      : Colors.black87),
                                ),
                              ),
                            ),
                            title: Text(
                              fontName,
                              style: TextStyle(
                                fontFamily: fontName,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFE53935),
                            )
                                : null,
                            onTap: () {
                              setDialogState(() => selectedFont = fontName);
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'Aa ${current.title}',
                      style: TextStyle(
                        fontFamily: selectedFont,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          'Size ${selectedSize.toInt()}',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        Expanded(
                          child: Slider(
                            min: 8,
                            max: 120,
                            value: selectedSize,
                            onChanged: (value) {
                              setDialogState(() => selectedSize = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      fonts[index] = _BrandFont(
                        current.title,
                        selectedFont,
                        selectedSize.round(),
                      );
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _roundPlus({required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30.h,
        width: 30.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_rounded,
          color: const Color(0xFFE53935),
          size: 21.sp,
        ),
      ),
    );
  }

  Widget _smallPlus({required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26.h,
        width: 26.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_rounded,
          color: const Color(0xFFE53935),
          size: 18.sp,
        ),
      ),
    );
  }

  Future<void> _showCustomColorDialog(BuildContext context) async {
    final controller = TextEditingController(text: "#E53935");
    Color selectedColor = const Color(0xFFE53935);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = context.read<CustomThemeProvider>().isDarkMode;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              titlePadding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 4.h),
              contentPadding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 16.h),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Choose Your Brand Colors",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Icon(
                      Icons.cancel,
                      color: const Color(0xFFFF9A9A),
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF202020)
                            : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Custom Colors",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  "Add your brand color using HEX codes or the color picker.",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "HEX Color",
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.tag),
                        hintText: "#E53935",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {
                            final color = _colorFromHex(controller.text);
                            if (color != null) {
                              setDialogState(() => selectedColor = color);
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                      ),
                      onSubmitted: (value) {
                        final color = _colorFromHex(value);
                        if (color != null) {
                          setDialogState(() => selectedColor = color);
                        }
                      },
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      "Popular Brand Color Palettes",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...popularPalettes.map(
                          (palette) => GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = palette.colors.first;
                            controller.text = _hex(selectedColor);
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 7.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF181818)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                palette.name,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                children: palette.colors
                                    .map(
                                      (color) => Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          selectedColor = color;
                                          controller.text = _hex(color);
                                        });
                                      },
                                      child: Container(
                                        height: 24.h,
                                        margin: EdgeInsets.only(right: 3.w),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                          BorderRadius.circular(3.r),
                                          border: Border.all(
                                            color:
                                            selectedColor.value ==
                                                color.value
                                                ? const Color(0xFFE53935)
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child:
                                        selectedColor.value ==
                                            color.value
                                            ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 15,
                                        )
                                            : null,
                                      ),
                                    ),
                                  ),
                                )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final color =
                        _colorFromHex(controller.text) ?? selectedColor;

                    setState(() {
                      palettes.insert(
                        0,
                        _BrandPalette(
                          name: "Brand Color ${palettes.length + 1}",
                          colors: [color],
                          isSelected: true,
                        ),
                      );
                      selectedTab = 1;
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Add Color"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value) return false;
    }
    return true;
  }

  Color? _colorFromHex(String value) {
    var hex = value.trim().replaceAll("#", "");

    if (hex.length == 6) {
      hex = "FF$hex";
    }

    if (hex.length != 8) return null;

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _hex(Color color) {
    return "#${color.value.toRadixString(16).substring(2).toUpperCase()}";
  }
}

class _BrandPalette {
  final String name;
  final List<Color> colors;
  final bool isSelected;

  const _BrandPalette({
    required this.name,
    required this.colors,
    this.isSelected = false,
  });
}

class _BrandFont {
  final String title;
  final String family;
  final int size;

  const _BrandFont(this.title, this.family, this.size);
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
              Icon(Icons.facebook, size: 5.sp, color: const Color(0xFF0066FF)),
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
          errorBuilder: (_, __, ___) =>
              Icon(Icons.badge_outlined, size: 24.sp, color: Colors.blueAccent),
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
