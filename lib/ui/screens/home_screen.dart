import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/network/provider/home_screen_provider.dart';

import 'package:project_mmb/ui/screens/video_widget/video_widget.dart';
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:project_mmb/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';
import 'package:project_mmb/network/provider/business_provider.dart';

import '../../component/custom_searchbar.dart';
import '../../component/home_appbar.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Consumer2<HomeScreenProvider, BusinessProvider>(
      builder: (context, homeProvider, businessProvider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Dark status bar icons
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: HomeCustomAppBar(
              businessName: businessProvider.businessName.isEmpty
                  ? "Business Name"
                  : businessProvider.businessName,
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

                      // 2. MY SPACE SECTION
                      _buildSectionHeader(
                        title: "My Space",
                        iconAsset: "assets/images/myspace.png",
                        hasViewAll: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildMySpaceList(homeProvider),

                      SizedBox(height: 20.h),

                      // 3. SPECIAL DAYS SECTION
                      Row(
                        children: [
                          Image.asset("assets/images/special_days.png", height: 32.h, width: 32.w),
                          SizedBox(width: 8.w),
                          AppText(
                            "Special Days",
                            style: TextStyle(
                              color: AppColors.darkBlack,
                              fontSize: AppFontSize.fontSize18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Image.asset("assets/images/calendar.png", height: 32.h, width: 32.w),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _buildSpecialDaysList(homeProvider),

                      SizedBox(height: 20.h),

                      // 4. MY ZONE SECTION (SLIDER)
                      _buildSectionHeader(
                        title: "My Zone",
                        iconAsset: "assets/images/my_zone.png",
                      ),
                      SizedBox(height: 12.h),
                      _buildMyZoneSlider(homeProvider),

                      SizedBox(height: 24.h),

                      _buildMyFrameHeader(),

                      SizedBox(height: 16.h),
                      _buildLeadBannerSlider(homeProvider),

                      SizedBox(height: 20.h),

                      _buildSectionHeader(
                        title: "My Brand Posts",
                        iconAsset: "assets/images/my_brand_posts.png",
                        hasViewAll: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildCategoryChips(homeProvider),

                      SizedBox(height: 16.h),
                      _buildBrandPostsGrid(),
                      SizedBox(height: 12.h),
                      // ------------------------------------------------------------
                      _buildSectionHeader(
                        title: "My Brand Video Posts",
                        iconAsset: "assets/images/my_brand_posts.png",
                        hasViewAll: true,
                      ),

                      SizedBox(height: 12.h),

                      SizedBox(
                        height: 38.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: homeProvider.videoCategories.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            bool isSelected = homeProvider.selectedVideoCategoryIndex == index;
                            return GestureDetector(
                              onTap: () => homeProvider.updateVideoCategoryIndex(index),
                              child: Container(
                                margin: EdgeInsets.only(right: 10.w),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF555555) : Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.grey.shade400,
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    homeProvider.videoCategories[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade800,
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
                        itemCount: homeProvider.brandVideoPostsList.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 1.0, // Square Grid
                        ),
                        itemBuilder: (context, index) {
                          final videoData = homeProvider.brandVideoPostsList[index];
                          return BrandVideoCard(
                            thumbnailUrl: videoData["thumbnail"]!,
                            videoUrl: videoData["videoUrl"]!,
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildSectionHeader(
                        title: "Celebrate Moment",
                        iconAsset: "assets/images/special_days.png",
                        hasViewAll: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildMyCelebrateList(homeProvider),
                      SizedBox(height: 16.h),
                      _buildSectionHeader(
                        title: "Youtube Thumbnail",
                        iconAsset: "assets/images/special_days.png",
                        hasViewAll: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildYoutubePostsGrid(),
                      SizedBox(height: 12.h),
                      _buildSectionHeader(
                        title: "WhatsApp Status",
                        iconAsset: "assets/images/whatsapp_status.png",
                        hasViewAll: true,
                      ),
                      SizedBox(height: 12.h),

                      SizedBox(
                        height: 200.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: homeProvider.whatsappStatusList.length,
                          itemBuilder: (context, index) {
                            final item = homeProvider.whatsappStatusList[index];
                            return Container(
                              width: 115.w,
                              margin: EdgeInsets.only(right: 12.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: Colors.grey.shade200,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Stack(
                                  children: [
                                    // Image Banner
                                    Positioned.fill(
                                      child: Image.asset(
                                        item["image"],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade300,
                                          child: Icon(Icons.image, size: 30.sp, color: Colors.grey),
                                        ),
                                      ),
                                    ),

                                    if (item["isVideo"] == true)
                                      Positioned(
                                        bottom: 10.h,
                                        left: 10.w,
                                        child: Container(
                                          padding: EdgeInsets.all(4.r),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 18.sp,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 24.h),

                      _buildSectionHeader(
                        title: "Devotional",
                        iconAsset: "assets/images/devotional.png",
                        hasViewAll: true,
                      ),
                      SizedBox(height: 12.h),

                      SizedBox(
                        height: 165.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: homeProvider.devotionalList.length,
                          itemBuilder: (context, index) {
                            final item = homeProvider.devotionalList[index];
                            return Container(
                              width: 110.w,
                              margin: EdgeInsets.only(right: 12.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Top Image
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                                      child: Image.asset(
                                        item["image"]??'',
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: Icon(Icons.auto_awesome, size: 30.sp, color: Colors.orange),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom White Title Container
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(15.r)),
                                    ),
                                    child: Text(
                                      item["title"]??"",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 24.h),

                      _buildSectionHeader(
                        title: "Corporate Needs",
                        iconAsset: "assets/images/corporate_icon.png",
                        hasViewAll: true,
                      ),
                      SizedBox(height: 12.h),

                      SizedBox(
                        height: 100.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: homeProvider.corporateNeedsList.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 105.w,
                              margin: EdgeInsets.only(right: 12.w),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14.r),
                                child: Image.asset(
                                  homeProvider.corporateNeedsList[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.business_center, size: 30.sp, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
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

  Widget _buildSectionHeader({
    required String title,
    required String iconAsset,
    bool hasViewAll = false,
  }) {
    return Row(
      children: [
        Image.asset(
          iconAsset,
          height: 32.h,
          width: 32.w,
          errorBuilder: (_, __, ___) => Container(
            height: 32.h,
            width: 32.w,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECEE),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flash_on, color: const Color(0xFFE53935), size: 18.sp),
          ),
        ),
        SizedBox(width: 8.w),
        AppText(
          title,
          style: TextStyle(
            color: AppColors.darkBlack,
            fontSize: AppFontSize.fontSize18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (hasViewAll)
          Text(
            "VIEW ALL",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  // My Space List
  Widget _buildMySpaceList(HomeScreenProvider homeProvider) {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeProvider.mySpaceList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = homeProvider.mySpaceList[index];
          return Container(
            width: 100.w,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradientColors.isNotEmpty
                    ? item.gradientColors
                    : [Colors.white, Colors.grey.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(item.icon, height: 36.h, width: 36.w, fit: BoxFit.contain),
                SizedBox(height: 6.h),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.w900, height: 1.1),
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Special Days List
  Widget _buildSpecialDaysList(HomeScreenProvider homeProvider) {
    return SizedBox(
      height: 160.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeProvider.mySpecialDaysList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = homeProvider.mySpecialDaysList[index];
          return Container(
            width: 150.w,
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(item["icon"]!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 10.h,
                    left: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEB04B),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        item["dayCount"] ?? "${index + 5}",
                        style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900),
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

  // My Zone Slider
  Widget _buildMyZoneSlider(HomeScreenProvider homeProvider) {
    return Column(
      children: [
        SizedBox(
          height: 360.h,
          child: PageView.builder(
            controller: homeProvider.zonePageController,
            itemCount: homeProvider.myZoneBanners.length,
            onPageChanged: (index) => homeProvider.updateZoneIndex(index),
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 25.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.asset(
                    homeProvider.myZoneBanners[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
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
            homeProvider.myZoneBanners.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              height: 6.h,
              width: homeProvider.currentZoneIndex == index ? 22.w : 6.w,
              decoration: BoxDecoration(
                color: homeProvider.currentZoneIndex == index
                    ? const Color(0xFFE53935)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // My Frame Header
  Widget _buildMyFrameHeader() {
    return Row(
      children: [
        Text(
          "MY FRAME - 1",
          style: TextStyle(color: AppColors.darkBlack, fontSize: 18.sp, fontWeight: FontWeight.w800),
        ),
        SizedBox(width: 6.w),
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: const BoxDecoration(color: Color(0xFFFFECEE), shape: BoxShape.circle),
          child: Icon(Icons.more_vert_rounded, color: const Color(0xFFE53935), size: 16.sp),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: const BoxDecoration(color: Color(0xFFFFECEE), shape: BoxShape.circle),
          child: Icon(Icons.edit_outlined, color: const Color(0xFFE53935), size: 18.sp),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: const BoxDecoration(color: Color(0xFFFFECEE), shape: BoxShape.circle),
          child: Icon(Icons.file_download_outlined, color: const Color(0xFFE53935), size: 18.sp),
        ),
      ],
    );
  }

  // Lead Banner Slider
  Widget _buildLeadBannerSlider(HomeScreenProvider homeProvider) {
    return Column(
      children: [
        SizedBox(
          height: 140.h,
          child: PageView.builder(
            controller: homeProvider.leadPageController,
            itemCount: homeProvider.leadBanners.length,
            onPageChanged: (index) => homeProvider.updateLeadBannerIndex(index), // Provider Call
            itemBuilder: (context, index) {
              final banner = homeProvider.leadBanners[index];
              return Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFEF),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner["title"]!,
                      style: TextStyle(color: const Color(0xFF7C4DFF), fontSize: 20.sp, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 6.h),
                    Text(banner["subTitle"]!, style: TextStyle(color: Colors.black87, fontSize: 12.sp)),
                    SizedBox(height: 5.h),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9172FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text(banner["btnText"]!, style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w800)),
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
            homeProvider.leadBanners.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              height: 6.h,
              width: homeProvider.currentLeadBannerIndex == index ? 22.w : 6.w,
              decoration: BoxDecoration(
                color: homeProvider.currentLeadBannerIndex == index
                    ? const Color(0xFF2C3860)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Category Filter Chips
  Widget _buildCategoryChips(HomeScreenProvider homeProvider) {
    return SizedBox(
      height: 38.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeProvider.categories.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          bool isSelected = homeProvider.selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => homeProvider.updateCategoryIndex(index), // Provider Call
            child: Container(
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF555555) : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  homeProvider.categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Brand Posts Grid
  Widget _buildBrandPostsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.asset("assets/images/bakedcaks.png", fit: BoxFit.cover),
          ),
        );
      },
    );
  }
  Widget _buildYoutubePostsGrid() {
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
              color: Colors.grey.shade200,
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
                  color: Colors.grey.shade200,
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
  Widget _buildMyCelebrateList(HomeScreenProvider homeProvider) {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: homeProvider.myCelebrateList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = homeProvider.myCelebrateList[index];
          return Container(
            width: 100.w,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradientColors.isNotEmpty
                    ? item.gradientColors
                    : [Colors.white, Colors.grey.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(item.icon, height: 36.h, width: 36.w, fit: BoxFit.contain),
                SizedBox(height: 6.h),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.w900, height: 1.1),
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
