import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/core/api/api_endpoints.dart';
import 'package:project_mmb/network/provider/home_screen_provider.dart';

import 'package:project_mmb/ui/screens/video_widget/video_widget.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:project_mmb/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../component/custom_searchbar.dart';
import '../../component/home_appbar.dart';
import '../../network/provider/custom_theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return ChangeNotifierProvider(
      create: (_) => HomeScreenProvider(),
      builder: (context, provider) => Consumer<HomeScreenProvider>(
        builder: (context, homeScreenProvider, child) {
          if (homeScreenProvider.templateCategories.isEmpty) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: const Center(
                child: CircularProgressIndicator(color: Color(0xFFE53935)),
              ),
            );
          }
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: const HomeCustomAppBar(
              businessCategory: "Cake and Sweets",
              notificationCount: "2",
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomSearchBar(
                        hintText: "Find your Industry",
                        prefixAsset: "assets/images/search.png",
                        suffixAsset: "assets/images/search.png",
                        borderColor: AppColors.searchBorderColor,
                        onChanged: (query) {},
                      ),

                      SizedBox(height: 20.h),

                      _buildSectionHeader(
                        title: "My Space",
                        iconAsset: "assets/images/myspace.png",
                        hasViewAll: true,
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      _buildMySpaceList(homeScreenProvider, isDark),

                      SizedBox(height: 20.h),

                      Row(
                        children: [
                          Image.asset(
                            "assets/images/special_days.png",
                            height: 32.h,
                            width: 32.w,
                          ),
                          SizedBox(width: 8.w),
                          AppText(
                            "Special Days",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.darkBlack,
                              fontSize: AppFontSize.fontSize18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Image.asset(
                            "assets/images/calendar.png",
                            height: 32.h,
                            width: 32.w,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _buildSpecialDaysList(homeScreenProvider, isDark),

                      SizedBox(height: 20.h),

                      // MY ZONE SECTION
                      _buildSectionHeader(
                        title: "My Zone",
                        iconAsset: "assets/images/my_zone.png",
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      _buildMyZoneSlider(homeScreenProvider, isDark),

                      SizedBox(height: 24.h),

                      _buildMyFrameHeader(isDark),

                      SizedBox(height: 16.h),
                      _buildLeadBannerSlider(homeScreenProvider, isDark),

                      SizedBox(height: 20.h),

                      _buildSectionHeader(
                        title: "My Brand Posts",
                        iconAsset: "assets/images/my_brand_posts.png",
                        hasViewAll: true,
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),

                      SizedBox(
                        height: 45.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: homeScreenProvider.videoCategories.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            bool isSelected =
                                homeScreenProvider.selectedVideoCategoryIndex ==
                                index;
                            return GestureDetector(
                              onTap: () => homeScreenProvider
                                  .updateVideoCategoryIndex(index),
                              child: Container(
                                margin: EdgeInsets.only(right: 10.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 22.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF555555)
                                      : (isDark
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(30.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : (isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade400),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    homeScreenProvider.videoCategories[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.grey.shade800),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 16.h),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            homeScreenProvider.brandVideoPostsList.isNotEmpty
                            ? homeScreenProvider.brandVideoPostsList.length
                            : 4,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                "/TemplateDetailScreen",
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.grey.shade100,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.r),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.asset(
                                        "assets/images/thumbnail1.png",
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: isDark
                                              ? const Color(0xFF2C2C2C)
                                              : Colors.grey.shade200,
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 40.sp,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10.h,
                                      left: 10.w,
                                      child: Container(
                                        padding: EdgeInsets.all(6.r),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          "assets/images/crown.png",
                                          width: 14.w,
                                          height: 14.h,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10.h,
                                      right: 10.w,
                                      child: Container(
                                        padding: EdgeInsets.all(6.r),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.more_horiz,
                                          color: Colors.white,
                                          size: 16.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12.h),

                      // MY BRAND VIDEO POSTS
                      _buildSectionHeader(
                        title: "My Brand Video Posts",
                        iconAsset: "assets/images/my_brand_posts.png",
                        hasViewAll: true,
                        isDark: isDark,
                      ),

                      SizedBox(height: 12.h),

                      SizedBox(
                        height: 38.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: homeScreenProvider.videoCategories.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            bool isSelected =
                                homeScreenProvider.selectedVideoCategoryIndex ==
                                index;
                            return GestureDetector(
                              onTap: () => homeScreenProvider
                                  .updateVideoCategoryIndex(index),
                              child: Container(
                                margin: EdgeInsets.only(right: 10.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF555555)
                                      : (isDark
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : (isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade400),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    homeScreenProvider.videoCategories[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.grey.shade800),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 16.h),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            homeScreenProvider.brandVideoPostsList.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final videoData =
                              homeScreenProvider.brandVideoPostsList[index];
                          return BrandVideoCard(
                            thumbnailUrl: videoData["thumbnail"]!,
                            videoUrl: videoData["videoUrl"]!,
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: homeScreenProvider.templateCategories.length,
                        itemBuilder: (context, index) {
                          final category = homeScreenProvider.templateCategories[index];
                          final categoryName = category.name ?? "";
                          final categoryIcon = "${ApiEndpoints.cdnImageUrl}/${category.iconS3Key ?? ''}";
                          final slug = category.slug ?? ""; // Slug-ah vachu list-ah map panrom

                          // Slug-ku etha mathiri data list-ah select panrom
                          List<dynamic> currentList = [];
                          if (index == 0) {
                            // First category-ku ungaloda special method / list
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16.h),
                                _buildSectionHeader(
                                  title: categoryName,
                                  iconAsset: categoryIcon,
                                  hasViewAll: true,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 12.h),
                                _buildMyCelebrateList(homeScreenProvider, isDark),
                              ],
                            );
                          } else if (index == 1) {
                            // Second category-ku ungaloda grid method
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16.h),
                                _buildSectionHeader(
                                  title: categoryName,
                                  iconAsset: categoryIcon,
                                  hasViewAll: true,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 12.h),
                                _buildYoutubePostsGrid(isDark),
                              ],
                            );
                          } else {
                            if (slug == "whatsapp-status" || index == 2) {
                              currentList = homeScreenProvider.whatsappStatusList;
                            } else if (slug == "devotional" || index == 3) {
                              currentList = homeScreenProvider.devotionalList;
                            } else {
                              currentList = homeScreenProvider.corporateNeedsList;
                            }

                            if (currentList.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 24.h),
                                _buildSectionHeader(
                                  title: categoryName,
                                  iconAsset: categoryIcon,
                                  hasViewAll: true,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(
                                  height: 165.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: currentList.length,
                                    itemBuilder: (context, itemIndex) {
                                      final item = currentList[itemIndex];
                                      final imageUrl = item is String ? item : (item["image"] ?? '');

                                      return Container(
                                        width: 110.w,
                                        margin: EdgeInsets.only(right: 12.w),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16.r),
                                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                          border: Border.all(
                                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16.r),
                                          child: Image.asset(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                                              child: Icon(Icons.image, size: 30.sp, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String iconAsset,
    bool hasViewAll = false,
    required bool isDark,
  }) {
    return Row(
      children: [
        Image.network(
          iconAsset,
          height: 32.h,
          width: 32.w,
          errorBuilder: (_, _, _) => Container(
            height: 32.h,
            width: 32.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flash_on,
              color: const Color(0xFFE53935),
              size: 18.sp,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        AppText(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkBlack,
            fontSize: AppFontSize.fontSize18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (hasViewAll)
          Text(
            "VIEW ALL",
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildMySpaceList(HomeScreenProvider homeScreenProvider, bool isDark) {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeScreenProvider.mySpaceList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = homeScreenProvider.mySpaceList[index];
          return Container(
            width: 100.w,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradientColors.isNotEmpty
                    ? item.gradientColors
                    : (isDark
                          ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                          : [Colors.white, Colors.grey.shade200]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  item.icon,
                  height: 36.h,
                  width: 36.w,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 6.h),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialDaysList(
    HomeScreenProvider homeScreenProvider,
    bool isDark,
  ) {
    return SizedBox(
      height: 160.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeScreenProvider.mySpecialDaysList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = homeScreenProvider.mySpecialDaysList[index];
          return Container(
            width: 150.w,
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      onTap: () async {},
                      child: Image.asset(item["icon"]!, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    bottom: 10.h,
                    left: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEB04B),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        item["dayCount"] ?? "${index + 5}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
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

  Widget _buildMyZoneSlider(
    HomeScreenProvider homeScreenProvider,
    bool isDark,
  ) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        String? savedImagePath;
        if (snapshot.hasData) {
          savedImagePath = snapshot.data!.getString(
            'saved_business_image_path',
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 360.h,
              child: PageView.builder(
                controller: homeScreenProvider.zonePageController,
                itemCount: homeScreenProvider.myZoneBanners.length,
                onPageChanged: (index) =>
                    homeScreenProvider.updateZoneIndex(index),
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 25.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: savedImagePath != null && savedImagePath.isNotEmpty
                          ? Image.file(
                              File(savedImagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Image.asset(
                              homeScreenProvider.myZoneBanners[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, _, _) => Container(
                                color: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 50.sp,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                homeScreenProvider.myZoneBanners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  height: 6.h,
                  width: homeScreenProvider.currentZoneIndex == index
                      ? 22.w
                      : 6.w,
                  decoration: BoxDecoration(
                    color: homeScreenProvider.currentZoneIndex == index
                        ? const Color(0xFFE53935)
                        : (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyFrameHeader(bool isDark) {
    return Row(
      children: [
        Text(
          "MY FRAME - 1",
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkBlack,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 6.w),
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.more_vert_rounded,
            color: const Color(0xFFE53935),
            size: 16.sp,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.edit_outlined,
            color: const Color(0xFFE53935),
            size: 18.sp,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.file_download_outlined,
            color: const Color(0xFFE53935),
            size: 18.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildLeadBannerSlider(
    HomeScreenProvider homeScreenProvider,
    bool isDark,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 140.h,
          child: PageView.builder(
            controller: homeScreenProvider.leadPageController,
            itemCount: homeScreenProvider.leadBanners.length,
            onPageChanged: (index) =>
                homeScreenProvider.updateLeadBannerIndex(index),
            itemBuilder: (context, index) {
              final banner = homeScreenProvider.leadBanners[index];
              return Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E2C)
                      : const Color(0xFFF3EFEF),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner["title"]!,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9FA8DA)
                            : const Color(0xFF7C4DFF),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      banner["subTitle"]!,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9172FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        banner["btnText"]!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            homeScreenProvider.leadBanners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              height: 6.h,
              width: homeScreenProvider.currentLeadBannerIndex == index
                  ? 22.w
                  : 6.w,
              decoration: BoxDecoration(
                color: homeScreenProvider.currentLeadBannerIndex == index
                    ? (isDark ? Colors.blueAccent : const Color(0xFF2C3860))
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYoutubePostsGrid(bool isDark) {
    return SizedBox(
      height: 180.h,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 8,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.h,
          mainAxisSpacing: 12.w,
          childAspectRatio: 0.70,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(
                "assets/images/thumbnail1.png",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey.shade200,
                  child: Icon(
                    Icons.smart_display_rounded,
                    size: 40.sp,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyCelebrateList(
    HomeScreenProvider homeScreenProvider,
    bool isDark,
  ) {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeScreenProvider.myCelebrateList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = homeScreenProvider.myCelebrateList[index];
          return Container(
            width: 100.w,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradientColors.isNotEmpty
                    ? item.gradientColors
                    : (isDark
                          ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                          : [Colors.white, Colors.grey.shade200]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  item.icon,
                  height: 36.h,
                  width: 36.w,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 6.h),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
