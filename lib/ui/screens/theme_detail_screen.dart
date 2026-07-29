import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:provider/provider.dart';

import '../../network/provider/theme_detail_screen_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

class ThemeDetailScreen extends StatelessWidget {
  const ThemeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeDetailProvider(),
      child: const ThemeDetailView(),
    );
  }
}

class ThemeDetailView extends StatelessWidget {
  const ThemeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeDetailProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Arrow Circle Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 40.h,
                            width: 40.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFECEE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: const Color(0xFFE53935),
                              size: 20.sp,
                            ),
                          ),
                        ),

                        // Favorite Heart Circle Button
                        GestureDetector(
                          onTap: () => provider.toggleFavorite(),
                          child: Container(
                            height: 40.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              color: provider.isFavorite
                                  ? const Color(0xFFFFECEE)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              provider.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: provider.isFavorite
                                  ? const Color(0xFFE53935)
                                  : Colors.grey.shade400,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    AppText(
                      provider.themeTitle,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // 3. DESCRIPTIONS
                    AppText(
                      provider.description1,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: 14.h),

                    AppText(
                      provider.description2,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: provider.tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: AppText(
                            tag,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 24.h),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.templatesList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 1.0, // Square Posters
                      ),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Stack(
                              children: [
                                // Poster Asset Image
                                Positioned.fill(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        "/TemplateDetailScreen",
                                      );
                                    },
                                    child: Image.asset(
                                      provider.templatesList[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade300,
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 40.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: 10.h,
                                  left: 10.w,
                                  child: Image.asset(
                                    "assets/images/crown.png",
                                    width: 15,
                                    height: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20.h),

                    _buildSectionHeader(
                      title: "More Themes",
                      iconAsset: "assets/images/myspace.png",
                      hasViewAll: true,
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      height: 160.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.midnightRebelList.length,
                        itemBuilder: (context, index) {
                          final item = provider.midnightRebelList[index];

                          return Container(
                            width: 150.w,
                            margin: EdgeInsets.only(right: 14.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Theme Preview Image Card
                                Container(
                                  height: 120.h,
                                  width: 150.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Stack(
                                      children: [
                                        // Poster Image
                                        Positioned.fill(
                                          child: Image.asset(
                                            item.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 40.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),

                                        // Crown Badge (Top-Left)
                                        if (item.isPremium)
                                          Positioned(
                                            top: 10.h,
                                            left: 10.w,
                                            child: Image.asset(
                                              "assets/images/crown.png",
                                              width: 15,
                                              height: 15,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 8.h),

                                // Title & Likes Counter Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Heart Likes Badge
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: const Color(0xFFE53935),
                                          size: 14.sp,
                                        ),
                                        SizedBox(width: 3.w),
                                        AppText(
                                          item.likesCount,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2.h),

                                // Subtitle: Template Count
                                AppText(
                                  item.templateCount,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
            width: 32.h,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECEE),
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
}
