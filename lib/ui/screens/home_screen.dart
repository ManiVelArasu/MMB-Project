import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/core/api/api_endpoints.dart';
import 'package:project_mmb/network/provider/home_screen_provider.dart';
import 'package:project_mmb/Api Model/Template_model.dart';
import 'package:project_mmb/ui/screens/template_edit.dart';
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

    const bool isBusinessUser = true;

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
                      _buildMySpaceList(homeScreenProvider, isDark, (item) {
                        Navigator.pushNamed(context, "/TemplateEditScreen");
                      }),

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
                          Text(
                            "VIEW ALL",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // 🚀 2. Special Days-க்கு கீழே வர வேண்டிய டேட் ஸ்க்ரோலர் பாக்ஸ் (இருவருக்கும் பொதுவானது)
                      Container(
                        height: 50.h,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            // Month
                            Container(
                              width: 74.w,
                              height: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: AppText(
                                "AUG",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(width: 4.w),

                            // Dates
                            Expanded(
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildDateBox(
                                    context,
                                    homeScreenProvider,
                                    "2",
                                  ),
                                  _buildDateBox(
                                    context,
                                    homeScreenProvider,
                                    "7",
                                  ),
                                  _buildDateBox(
                                    context,
                                    homeScreenProvider,
                                    "15",
                                  ),
                                  _buildDateBox(
                                    context,
                                    homeScreenProvider,
                                    "17",
                                  ),
                                  _buildDateBox(
                                    context,
                                    homeScreenProvider,
                                    "26",
                                  ),
                                  _buildDateBox(
                                    context,
                                    homeScreenProvider,
                                    "29",
                                  ),
                                  _buildDateBox(
                                    context,
                                    homeScreenProvider,
                                    "30",
                                  ),

                                  SizedBox(width: 2.w),

                                  SizedBox(
                                    width: 34.w,
                                    child: Center(
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16.sp,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      _buildSpecialDaysList(homeScreenProvider, isDark),

                      SizedBox(height: 20.h),

                      _buildSectionHeader(
                        title: "My Zone",
                        iconAsset: "assets/images/my_zone.png",
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),

                      _buildMyZoneSlider(
                        homeScreenProvider,
                        isDark,
                        isBusinessUser: isBusinessUser,
                      ),

                      SizedBox(height: 24.h),

                      _buildMyFrameHeader(isDark),

                      SizedBox(height: 16.h),

                      _buildLeadBannerSlider(
                        homeScreenProvider,
                        isDark,
                        isBusinessUser: isBusinessUser,
                      ),

                      SizedBox(height: 20.h),

                      // 🚀 My Brand Posts (பிசினஸ் யூசர்களுக்கு மட்டும்)
                      if (isBusinessUser) ...[
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
                            itemCount:
                            homeScreenProvider.videoCategories.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              bool isSelected =
                                  homeScreenProvider
                                      .selectedVideoCategoryIndex ==
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
                                    child: AppText(
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
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
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
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                      ],

                      // 🚀 My Brand Video Posts (பிசினஸ் யூசர்களுக்கு மட்டும்)
                      if (isBusinessUser) ...[
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
                            itemCount:
                            homeScreenProvider.videoCategories.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              bool isSelected =
                                  homeScreenProvider
                                      .selectedVideoCategoryIndex ==
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
                                    child: AppText(
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
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                            childAspectRatio: 1.0,
                          ),
                          itemBuilder: (context, index) {
                            final videoData =
                            homeScreenProvider.brandVideoPostsList[index];
                            return BrandVideoCard(
                              thumbnailUrl: videoData["thumbnail"] ?? '',
                              videoUrl: videoData["videoUrl"] ?? '',
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                      ],

                      // பொதுவான டெம்ப்ளேட் வகைகள்
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: homeScreenProvider.templateCategories.length,
                        itemBuilder: (context, index) {
                          final category =
                          homeScreenProvider.templateCategories[index];
                          final categoryName = category.name?.trim() ?? '';
                          final slug = category.slug?.trim() ?? '';

                          if (slug.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final categoryIcon =
                          (category.iconS3Key?.trim().isNotEmpty ?? false)
                              ? '${ApiEndpoints.cdnImageUrl}/${category.iconS3Key}'
                              : '';

                          final templates = homeScreenProvider
                              .templatesForCategory(slug);
                          final isLoading = homeScreenProvider
                              .isTemplateLoading(slug);

                          return Padding(
                            padding: EdgeInsets.only(top: 24.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  title: categoryName,
                                  iconAsset: categoryIcon,
                                  hasViewAll: true,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 12.h),
                                if (isLoading)
                                  SizedBox(
                                    height: 165.h,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFE53935),
                                      ),
                                    ),
                                  )
                                else if (templates.isEmpty)
                                  SizedBox(
                                    height: 110.h,
                                    child: Center(
                                      child: AppText(
                                        'No templates available',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 165.h,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: templates.length,
                                      itemBuilder: (context, templateIndex) {
                                        return _buildApiTemplateCard(
                                          context,
                                          templates[templateIndex],
                                          isDark,
                                        );
                                      },
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateBox(
      BuildContext context,
      HomeScreenProvider provider,
      String date,
      ) {
    final isSelected = provider.selectedDates == date;

    return GestureDetector(
      onTap: () {
        provider.setSelectedDate(date);
      },
      child: Container(
        width: 44.w,
        height: 42.h,
        margin: EdgeInsets.only(right: 5.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935) : const Color(0xFFFFF8F8),
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: AppText(
          date,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildApiTemplateCard(
      BuildContext context,
      TemplateModel template,
      bool isDark,
      ) {
    final key = template.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final templateUid =
            (template as dynamic).uid?.toString().trim() ?? '';

        if (templateUid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template UID not available'),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditScreen(
              templateUid: templateUid,
              resizeSize: 'Post Square (1:1)',
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: imageUrl.isEmpty
              ? _templateImagePlaceholder(isDark)
              : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorWidget: (context, url, error) {
              return _templateImagePlaceholder(isDark);
            },
          ),
        ),
      ),
    );
  }

  Widget _templateImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 36.sp,
        color: Colors.grey.shade400,
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

  Widget _buildMySpaceList(
      HomeScreenProvider homeScreenProvider,
      bool isDark,
      void Function(dynamic item) onTap,
      ) {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeScreenProvider.mySpaceList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = homeScreenProvider.mySpaceList[index];

          return InkWell(
            onTap: () => onTap(item),
            child: Container(
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
                  AppText(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
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
                      child: Image.asset(item["icon"] ?? "", fit: BoxFit.cover),
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
      bool isDark, {
        required bool isBusinessUser,
      }) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        String? savedImagePath;
        if (snapshot.hasData) {
          savedImagePath = snapshot.data?.getString(
            'saved_business_image_path',
          );
        }

        return SizedBox(
          height: 360.h,
          child: PageView.builder(
            controller: homeScreenProvider.zonePageController,
            itemCount: homeScreenProvider.myZoneBanners.length,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      savedImagePath != null && savedImagePath.isNotEmpty
                          ? Image.file(File(savedImagePath), fit: BoxFit.cover)
                          : Image.asset(
                        homeScreenProvider.myZoneBanners[index],
                        fit: BoxFit.cover,
                      ),
                      if (isBusinessUser)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 12.h,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFF246BFE),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '+91 98765 43210',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Sarah Gym & Fitness',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
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
      ],
    );
  }

  Widget _buildLeadBannerSlider(
      HomeScreenProvider homeScreenProvider,
      bool isDark, {
        required bool isBusinessUser,
      }) {
    if (!isBusinessUser) {
      return SizedBox(
        height: 140.h,
        child: PageView.builder(
          controller: homeScreenProvider.leadPageController,
          itemCount: homeScreenProvider.leadBanners.length,
          itemBuilder: (context, index) {
            return Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    "Grow Your Business",
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AppText(
                    "List your business on MMB and get discovered by potential customers.",
                    style: TextStyle(
                      color: AppColors.appBlack,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // 🚀 Button Action இங்கே எழுதவும்
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          AppColors.gold, // மிகவும் எளிய மற்றும் சரியான வழி
                          foregroundColor:
                          Colors.white, // உரையின் நிறம் (Text color)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12.r,
                            ), // விளிம்புகளை வளைக்க
                          ),
                        ),
                        child: AppText(
                          "GO PREMIUM",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 140.h,
      child: PageView.builder(
        controller: homeScreenProvider.leadPageController,
        itemCount: homeScreenProvider.leadBanners.length,
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  "Grow Your Business",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                AppText(
                  "List your business on MMB and get discovered by potential customers.",
                  style: TextStyle(
                    color: AppColors.appBlack,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // 🚀 Button Action இங்கே எழுதவும்
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        AppColors.gold, // மிகவும் எளிய மற்றும் சரியான வழி
                        foregroundColor:
                        Colors.white, // உரையின் நிறம் (Text color)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12.r,
                          ), // விளிம்புகளை வளைக்க
                        ),
                      ),
                      child: AppText(
                        "GO PREMIUM",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
