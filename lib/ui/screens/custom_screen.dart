import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/Api%20Model/template_size_model.dart';
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
    return ChangeNotifierProvider(
      create: (_) => CustomScreenProvider()..fetchPlans(),
      child: const _CustomCreateBody(),
    );
  }
}

class _CustomCreateBody extends StatelessWidget {
  const _CustomCreateBody();
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Consumer<CustomScreenProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPlans) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.plansErrorMessage != null) {
          return Scaffold(
            body: Center(child: Text(provider.plansErrorMessage!)),
          );
        }
        final templateSizes = provider.plansData?.data ?? [];
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

                    _buildHeader(
                      title: "Create your Own",
                      iconAsset: "assets/images/myspace.png",
                    ),

                    SizedBox(height: 16.h),

                    SizedBox(
                      height: 210.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: templateSizes.length,
                        itemBuilder: (context, index) {
                          final item = templateSizes[index];

                          final width = int.tryParse(item.width ?? "0") ?? 0;
                          final height = int.tryParse(item.height ?? "0") ?? 0;

                          return Container(
                            width: 95.w,
                            margin: EdgeInsets.only(right: 12.w),
                            child: Column(
                              children: [

                                /// Fixed Preview Area
                                SizedBox(
                                  height: 130.h,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Image.asset(
                                      buildTemplateImage(width, height),
                                      height: getImageHeight(width, height),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 8.h),

                                AppText(
                                  item.name ?? "",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                SizedBox(height: 2.h),

                                AppText(
                                  "${item.width} × ${item.height}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 10.h),

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
                        childAspectRatio:
                            0.82, // Card proportion-a exact-a match பண்ணும்
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
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildFallbackIcon(),
                                      )
                                    : _buildFallbackIcon(),
                              ),

                              SizedBox(height: 10.h),

                              // 2. TOOL TITLE
                              AppText(
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
                              AppText(
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
  double getImageHeight(int width, int height) {
    if (width == 1080 && height == 1080) {
      return 70;
    }

    if (width == 1080 && height == 1440) {
      return 95;
    }

    if (width == 1080 && height == 1920) {
      return 120;
    }

    if (width == 1080 && height == 566) {
      return 45;
    }

    return 80;
  }
  String buildTemplateImage(int width, int height) {
    if (width == 1080 && height == 1080) {
      return "assets/images/post_square.png";
    } else if (width == 1080 && height == 1350) {
      return "assets/images/post_portrait.png";
    } else if (width == 1080 && height == 1920) {
      return "assets/images/post_1920.png";
    } else if (width == 1440 && height == 1080) {
      return "assets/images/post_1440.png";
    }
    return "assets/images/post_1440.png";
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
            child: Icon(
              Icons.auto_awesome,
              color: const Color(0xFFE53935),
              size: 16.sp,
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
      ],
    );
  }
}
