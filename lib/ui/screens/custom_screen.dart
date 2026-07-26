import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../component/home_appbar.dart';
import '../../network/provider/custom_screen_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';



class CustomCreateScreen extends StatelessWidget {
  const CustomCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Consumer<CustomScreenProvider>(
      builder: (context, provider, child) {
        return Scaffold(
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
                    CustomSearchBar(
                      hintText: "Find your Industry",
                      prefixAsset: "assets/images/search.png",
                      suffixAsset: "assets/images/search.png",
                      borderColor: const Color(0xFFFFCDD2),
                      onChanged: (query) {},
                    ),

                    SizedBox(height: 24.h),

                    // 2. CREATE YOUR OWN HEADER
                    _buildHeader(
                      title: "Create your Own",
                      iconAsset: "assets/images/myspace.png",
                    ),

                    SizedBox(height: 16.h),

                    // 3. CREATE YOUR OWN CANVAS RATIOS (Dynamic Aspect Cards)
                    SizedBox(
                      height: 160.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.canvasRatios.length,
                        itemBuilder: (context, index) {
                          final item = provider.canvasRatios[index];
                          return Container(
                            width: 95.w,
                            margin: EdgeInsets.only(right: 12.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // 1. DYNAMIC SIZE BASED ON INDIVIDUAL IMAGE ASSET
                                SizedBox(
                                  height: 110.h, // Fixed frame space for dynamic ratio rendering
                                  child: Center(
                                    child: Image.asset(
                                      item.imagePath, // Thani-thani asset image load aagum
                                      fit: BoxFit.contain, // Image-oda natural ratio-va maintain pannum
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 80.h,
                                        width: 70.w,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECEE),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: const Color(0xFFFFCDD2)),
                                        ),
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: const Color(0xFFFFB2B9),
                                          size: 28.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 8.h),

                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  item.dimension,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 28.h),

                    _buildHeader(
                      title: "Generate with AI",
                      iconAsset: "assets/images/special_days.png",
                    ),

                    SizedBox(height: 16.h),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.aiToolsList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.82, // Card proportion-a exact-a match பண்ணும்
                    ),
                    itemBuilder: (context, index) {
                      final tool = provider.aiToolsList[index];

                      return Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE8EEF5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 52.h,
                              width: 52.w,
                              child: tool.imagePath.trim().isNotEmpty
                                  ? Image.asset(
                                tool.imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackIcon(),
                              )
                                  : _buildFallbackIcon(),
                            ),

                            SizedBox(height: 10.h),

                            // 2. TOOL TITLE
                            Text(
                              tool.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: 4.h),

                            // 3. TOOL SUBTITLE
                            Text(
                              tool.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

// Helper Widget for Empty / Error Images


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
  Widget _buildFallbackIcon() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.auto_awesome,
        color: const Color(0xFFE53935),
        size: 26.sp,
      ),
    );
  }
  // Section Header Helper
  Widget _buildHeader({required String title, required String iconAsset}) {
    return Row(
      children: [
        Image.asset(
          iconAsset,
          height: 30.h,
          width: 30.w,
          errorBuilder: (_, __, ___) => Container(
            height: 30.h,
            width: 30.w,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECEE),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: const Color(0xFFE53935), size: 16.sp),
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
      ],
    );
  }
}