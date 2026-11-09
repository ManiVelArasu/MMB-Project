import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/search_screen.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:provider/provider.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../component/home_appbar.dart';
import '../../network/provider/custom_screen_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';

import '../../network/provider/custom_theme_provider.dart';
import '../industry/widgets/scaffold_widget.dart';

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

        return CommonScaffold(
          isDarkMode: isDark,
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
                child: _createBackground(
                  isDark,
                  Theme.of(context).scaffoldBackgroundColor,
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
                            hintText: "Search templates, Brand Series...",
                            prefixAsset: "assets/images/search.png",
                            suffixAsset: "assets/images/mic.png",
                            borderColor: const Color(0xFFFFCDD2),
                            showSuffixIcon: false,
                            onSubmitted: (query) {
                              final q = query.trim();
                              if (q.length < 2) return;

                              FocusManager.instance.primaryFocus?.unfocus();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchScreen(initialQuery: q),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 24.h),

                          _buildHeader(
                            title: "Create from Scratch",
                            subtitle: "Choose a canvas size to start designing",

                            iconAsset: "assets/images/myspace.png",
                            isDark: isDark,
                          ),

                          SizedBox(height: 4.h),

                          SizedBox(
                            height: 210.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  templateSizes.length +
                                  1, // +1 for the custom card
                              itemBuilder: (context, index) {
                                // ---------- Custom Size card ----------
                                if (index == templateSizes.length) {
                                  return _buildSizeCard(
                                    isDark: isDark,
                                    imgW: 70.w,
                                    imgH: 90.h,
                                    title: "Custom Size",
                                    image: Image.asset(
                                      "assets/images/custom.png",
                                      fit: BoxFit.contain,
                                    ),
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            const _CustomSizeBottomSheet(),
                                      );
                                    },
                                  );
                                }

                                // ---------- Template size cards (API) ----------
                                final item = templateSizes[index];
                                final width =
                                    int.tryParse(item.width ?? "0") ?? 0;
                                final height =
                                    int.tryParse(item.height ?? "0") ?? 0;

                                final double imgH = getImageHeight(
                                  width,
                                  height,
                                );
                                final double ratio = (width > 0 && height > 0)
                                    ? width / height
                                    : 1.0;
                                final double imgW = imgH * ratio;

                                return _buildSizeCard(
                                  isDark: isDark,
                                  imgW: imgW,
                                  imgH: imgH,
                                  title: item.name ?? "",
                                  subtitle: "${item.width} × ${item.height}",
                                  image: Image.asset(
                                    buildTemplateImage(width, height),
                                    fit: BoxFit.contain,
                                  ),
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
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 10.h),

                          _buildHeader(
                            title: "AI HUB",
                            subtitle: "",
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

  Widget _buildSizeCard({
    required bool isDark,
    required double imgW,
    required double imgH,
    required Widget image,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final double pad = 8.w;
    // text-ku kozhappam illama minimum content width
    final double contentW = imgW < 70.w ? 70.w : imgW;

    // ListView item-ku tight height varum, so Align use panni bottom-la vaikkurom
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(right: 12.w),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                width: 1.5,
              ),
            ),
            child: SizedBox(
              width: contentW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: imgW, height: imgH, child: image),
                  SizedBox(height: 8.h),
                  AppText(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    AppText(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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
      return "assets/images/insta_post.png";
    } else if (width == 1080 && height == 1350) {
      return "assets/images/potrait.png";
    } else if (width == 1080 && height == 1920) {
      return "assets/images/post_1920.png";
    } else if (width == 1440 && height == 1080) {
      return "assets/images/post_1440.png";
    } else if (width == 1920 && height == 1080) {
      return "assets/images/youtube_thumbnail.png";
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
    String? subtitle,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkBlack,
                  fontSize: AppFontSize.fontSize18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (subtitle != null && subtitle.trim().isNotEmpty)
                AppText(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey,
                    fontSize: 11.sp,
                  ),
                ),
            ],
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

  String? selectedPopularSize;

  final List<Map<String, dynamic>> popularSizes = [
    {
      "title": "Youtube Cover",
      "subtitle": "2560 × 1440 PX",
      "width": 2560,
      "height": 1440,
    },
    {
      "title": "Facebook Cover",
      "subtitle": "820 × 315 PX",
      "width": 820,
      "height": 315,
    },
    {
      "title": "Pinterest",
      "subtitle": "1000 × 1500 PX",
      "width": 1000,
      "height": 1500,
    },
    {
      "title": "Linked In Banner",
      "subtitle": "1584 × 396 PX",
      "width": 1584,
      "height": 396,
    },
  ];

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _selectPopularSize(Map<String, dynamic> item) {
    setState(() {
      selectedPopularSize = item["title"];
      widthController.text = item["width"].toString();
      heightController.text = item["height"].toString();
    });
  }

  void _createDesign() {
    final double? width = double.tryParse(widthController.text.trim());

    final double? height = double.tryParse(heightController.text.trim());

    if (width == null ||
        height == null ||
        width <= 0 ||
        height <= 0 ||
        width > 4000 ||
        height > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid width and height (Max 4000)."),
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);

    navigator.pop();

    navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            TemplateEditScreen(canvasWidth: width, canvasHeight: height),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      "Custom Size",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF171A2B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3A2022)
                              : const Color(0xFFFFE5E7),
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

                AppText(
                  "Enter exact dimensions for a billboard, packaging label, or any size we don't have ready-made.",
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white60 : const Color(0xFF666666),
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 20.h),

                // Width and Height
                Row(
                  children: [
                    Expanded(
                      child: _buildSizeInput(
                        title: "Width (px)",
                        controller: widthController,
                        isDark: isDark,
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
                      child: _buildSizeInput(
                        title: "Height (px)",
                        controller: heightController,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Popular title
                Row(
                  children: [
                    AppText(
                      "POPULAR",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: AppFontSize.fontSize14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    AppText(
                      "Select a size",
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Popular selectable list
                // Popular selectable chips - Horizontal Row
                SizedBox(
                  height: 58.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: popularSizes.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final item = popularSizes[index];

                      final bool isSelected =
                          selectedPopularSize == item["title"];

                      return GestureDetector(
                        onTap: () {
                          _selectPopularSize(item);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? const Color(0xFF3A2022)
                                      : const Color(0xFFFFECEE))
                                : (isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.red
                                  : (isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    item["title"],
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.red
                                          : (isDark
                                                ? Colors.white
                                                : const Color(0xFF171A2B)),
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  AppText(
                                    item["subtitle"],
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected) ...[
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.red,
                                  size: 16.sp,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 24.h),

                // Create Design
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _createDesign,
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

                // Footer
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        "Want inspiration? ",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Browse templates action
                        },
                        child: AppText(
                          "BROWSE TEMPLATES",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
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

  // Width / Height input
  Widget _buildSizeInput({
    required String title,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: TextStyle(
            fontSize: AppFontSize.fontSize16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.appBlack,
          ),
        ),

        AppText(
          "Max 4000",
          style: TextStyle(
            fontSize: AppFontSize.fontSize14,
            fontWeight: FontWeight.w300,
            color: isDark ? Colors.white70 : AppColors.appBlack,
          ),
        ),

        SizedBox(height: 6.h),

        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          cursorColor: Colors.red,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFFFD5D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFFFD5D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Header background. The light gradient image would cover the dark scaffold,
/// so dark mode uses a dark gradient that fades into the scaffold colour.
Widget _createBackground(bool isDark, Color scaffoldColor) {
  if (isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF2A1A1C), scaffoldColor],
        ),
      ),
    );
  }
  return Image.asset(
    "assets/images/plan_gradient.png",
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
  );
}
