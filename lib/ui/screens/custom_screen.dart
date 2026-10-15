import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:provider/provider.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../component/home_appbar.dart';
import '../../network/provider/custom_screen_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

import '../../network/provider/custom_theme_provider.dart';

class CustomCreateScreen extends StatelessWidget {
  const CustomCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // CustomScreenProvider is created once by CustomBottomNavScreen.
    return const _CustomCreateBody();
  }
}

class _CustomCreateBody extends StatelessWidget {
  const _CustomCreateBody();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<CustomScreenProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPlans) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.plansErrorMessage != null && provider.plansData == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text(
                provider.plansErrorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        }
        final templateSizes = provider.plansData?.data ?? [];

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: const HomeCustomAppBar(),
          ),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 300.h,
                child: Image.asset(
                  "assets/images/plan_gradient.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.refresh();
                  },
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
                            suffixAsset: "assets/images/mic.png",
                            borderColor: const Color(0xFFFFCDD2),
                            onChanged: (query) {},
                          ),

                          SizedBox(height: 24.h),

                          _buildHeader(
                            title: "Create from Scratch",
                            iconAsset: "assets/images/myspace.png",
                            isDark: isDark,
                          ),

                          SizedBox(height: 16.h),

                          SizedBox(
                            height: 210.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  templateSizes.length +
                                  1, // Added +1 for the custom card
                              itemBuilder: (context, index) {
                                // If it's the last item, render the Custom Box
                                if (index == templateSizes.length) {
                                  return InkWell(
                                    onTap: () {
                                      // 👉 Ingaethaanga antha custom size bottomsheet-ah open panrom
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) {
                                          return const _CustomSizeBottomSheet(); // KEEZHE IRUKKIRA BOTTOMSHEET CLASS
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: 95.w,
                                      margin: EdgeInsets.only(right: 12.w),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 130.h,
                                            child: Image.asset(
                                              "assets/images/custom.png",
                                              width: 120,
                                              height: 90,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          AppText(
                                            "Custom Size",
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final item = templateSizes[index];

                                final width =
                                    int.tryParse(item.width ?? "0") ?? 0;
                                final height =
                                    int.tryParse(item.height ?? "0") ?? 0;

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TemplateEditScreen(
                                          canvasWidth: width > 0
                                              ? width.toDouble()
                                              : null,
                                          canvasHeight: height > 0
                                              ? height.toDouble()
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
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
                                              height: getImageHeight(
                                                width,
                                                height,
                                              ),
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
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
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
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 10.h),

                          _buildHeader(
                            title: "Generate with AI",
                            iconAsset: "assets/images/special_days.png",
                            isDark: isDark,
                          ),

                          SizedBox(height: 16.h),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: provider.aiToolsList.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12.w,
                                  mainAxisSpacing: 12.h,
                                  childAspectRatio: 0.82,
                                ),
                            itemBuilder: (context, index) {
                              final tool = provider.aiToolsList[index];

                              return InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, tool.routeName);
                                },

                                child: Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey.shade800
                                          : const Color(0xFFE8EEF5),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.02,
                                        ),
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
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => _buildFallbackIcon(),
                                              )
                                            : _buildFallbackIcon(),
                                      ),

                                      SizedBox(height: 10.h),

                                      // 2. TOOL TITLE
                                      AppText(
                                        tool.title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
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
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                          fontSize: 9.5.sp,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
      return "assets/images/landscape.png";
    } else if (width == 1080 && height == 1350) {
      return "assets/images/potrait.png";
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
  Widget _buildHeader({
    required String title,
    required String iconAsset,
    required bool isDark,
  }) {
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
            color: isDark ? Colors.white : AppColors.darkBlack,
            fontSize: AppFontSize.fontSize18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CustomSizeBottomSheet extends StatefulWidget {
  const _CustomSizeBottomSheet();

  @override
  State<_CustomSizeBottomSheet> createState() => _CustomSizeBottomSheetState();
}

class _CustomSizeBottomSheetState extends State<_CustomSizeBottomSheet> {
  final TextEditingController widthController = TextEditingController(
    text: "1080",
  );
  final TextEditingController heightController = TextEditingController(
    text: "1080",
  );

  @override
  Widget build(BuildContext context) {
    // Keyboard open aagumpothu bottomsheet-ku proper padding/spacing kidaikka viewInsets use panrom
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 45.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      "Custom Size",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF171A2B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE5E7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Subtitle
                AppText(
                  "Enter exact dimensions for a billboard, packaging label, or any size we don't have ready-made.",
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20.h),

                // Width & Height Inputs with Cross Icon
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Width (px)",
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.appBlack,
                            ),
                          ),
                          AppText(
                            "Max 4000",
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize14,
                              fontWeight: FontWeight.w300,
                              color: AppColors.appBlack,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: widthController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFD5D8),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFD5D8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 15.h,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Height (px)",
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.appBlack,
                            ),
                          ),
                          AppText(
                            "Max 4000",
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize14,
                              fontWeight: FontWeight.w300,
                              color: AppColors.appBlack,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFD5D8),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFD5D8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Popular Section Title
                AppText(
                  "POPULAR",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10.h),

                // Popular Horizontal Chips
                SizedBox(
                  height: 38.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPopularChip("Youtube Cover", "2560 × 1440 PX"),
                      SizedBox(width: 8.w),
                      _buildPopularChip("Facebook Cover", "820 × 315 PX"),
                      SizedBox(width: 8.w),
                      _buildPopularChip("Pinterest", "1000 × 1500 PX"),
                      SizedBox(width: 8.w),
                      _buildPopularChip("Linked In Banner", "1584 × 396 PX"),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Create Design Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () {
                      final double? w = double.tryParse(widthController.text);
                      final double? h = double.tryParse(heightController.text);

                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TemplateEditScreen(
                            canvasWidth: w,
                            canvasHeight: h,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: AppText(
                      "CREATE DESIGN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Footer Link
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        "Want inspiration? ",
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Action for browse templates
                        },
                        child: AppText(
                          "BROWSE TEMPLATES",
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.appRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularChip(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            title,
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 6.w),
          AppText(
            subtitle,
            style: TextStyle(
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
