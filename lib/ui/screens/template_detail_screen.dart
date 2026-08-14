import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../network/provider/template_detail_provider.dart';
import '../../utils/theme/app.colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../network/provider/custom_theme_provider.dart';

class TemplateDetailScreen extends StatelessWidget {
  const TemplateDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TemplateDetailProvider(),
      child: const _TemplateDetailBody(),
    );
  }
}

class _TemplateDetailBody extends StatelessWidget {
  const _TemplateDetailBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TemplateDetailProvider>();
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Brownies",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              "assets/icons/translate.svg",
              colorFilter: ColorFilter.mode(
                isDark ? Colors.white70 : Colors.black87,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    _buildTopBanner(
                      context,
                      provider.selectedResizeSize,
                      isDark,
                    ),

                    SizedBox(height: 12.h),

                    // Page Indicators Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        ...List.generate(
                          3,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 3.w),
                            width: 6.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Resize & Edit Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                showResizeBottomSheet(context, isDark),
                            icon: const Icon(
                              Icons.aspect_ratio,
                              color: Colors.red,
                              size: 18,
                            ),
                            label: Text(
                              "RESIZE",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF2A1A1C)
                                  : const Color(0xFFFFECEE),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                "/TemplateEditScreen",
                                arguments: provider.selectedResizeSize,
                              );
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.red,
                              size: 18,
                            ),
                            label: Text(
                              "EDIT",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF2A1A1C)
                                  : const Color(0xFFFFECEE),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // 2. DYNAMIC BOTTOM CONTENT
                    _buildDynamicBottomContent(provider.selectedIndex, isDark),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () => context
                        .read<TemplateDetailProvider>()
                        .setSelectedIndex(0),
                    child: _buildBottomNavItem(
                      Icons.image,
                      "IMAGE",
                      provider.selectedIndex == 0,
                    ),
                  ),
                  InkWell(
                    onTap: () => context
                        .read<TemplateDetailProvider>()
                        .setSelectedIndex(1),
                    child: _buildBottomNavItem(
                      Icons.videocam,
                      "VIDEO",
                      provider.selectedIndex == 1,
                    ),
                  ),
                  InkWell(
                    onTap: () => context
                        .read<TemplateDetailProvider>()
                        .setSelectedIndex(2),
                    child: _buildBottomNavItem(
                      Icons.aspect_ratio,
                      "POST SIZE",
                      provider.selectedIndex == 2,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      context.read<TemplateDetailProvider>().setSelectedIndex(
                        3,
                      );
                      showCategoriesBottomSheet(context, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.category,
                      "CATEGORIES",
                      provider.selectedIndex == 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBottomContent(int selectedIndex, bool isDark) {
    if (selectedIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Image Templates",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey[800],
            ),
          ),
          SizedBox(height: 10.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2A38) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? Colors.blue.shade900 : Colors.blue.shade200,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Image Post ${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.blue.shade200
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else if (selectedIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Video Templates",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey[800],
            ),
          ),
          SizedBox(height: 10.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1A1C) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? Colors.red.shade900 : Colors.red.shade200,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.red),
                      Text(
                        "Video ${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.red.shade200
                              : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Post Size Templates (Image + Video)",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey[800],
            ),
          ),
          SizedBox(height: 10.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final isVideo = index % 2 != 0;
              return Container(
                decoration: BoxDecoration(
                  color: isVideo
                      ? (isDark
                            ? const Color(0xFF231B38)
                            : Colors.purple.shade50)
                      : (isDark
                            ? const Color(0xFF332211)
                            : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isVideo
                        ? (isDark
                              ? Colors.purple.shade900
                              : Colors.purple.shade200)
                        : (isDark
                              ? Colors.orange.shade900
                              : Colors.orange.shade200),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.image,
                        color: isVideo
                            ? Colors.purpleAccent
                            : Colors.orangeAccent,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isVideo
                            ? "Video Post ${index + 1}"
                            : "Image Post ${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    }
  }

  void showCategoriesBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A1C)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 10.w,
                      runSpacing: 12.h,
                      children:
                          [
                                "Cakes",
                                "Cookies",
                                "Smoothie",
                                "Brownies",
                                "Cupcakes",
                                "Muffins",
                                "Birthday Special",
                                "Sweets",
                                "Today Special",
                                "Wedding Special",
                                "Deal of the Day",
                                "Offers",
                              ]
                              .map(
                                (category) =>
                                    _buildCategoryChip(category, isDark),
                              )
                              .toList(),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String title, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

void showResizeBottomSheet(BuildContext context, bool isDark) {
  final templateProvider = context.read<TemplateDetailProvider>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return ChangeNotifierProvider.value(
        value: templateProvider,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Resize Template",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(modalContext),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A1C)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                _ResizeOptionItem(
                  title: "Post Square (1:1)",
                  subtitle: "1080 x 1080 px",
                  isDark: isDark,
                ),
                _ResizeOptionItem(
                  title: "Post Portrait (4:5)",
                  subtitle: "1080 x 1350 px",
                  isDark: isDark,
                ),
                _ResizeOptionItem(
                  title: "Story / Reel (9:16)",
                  subtitle: "1080 x 1920 px",
                  isDark: isDark,
                ),
                _ResizeOptionItem(
                  title: "Post Horizontal",
                  subtitle: "1200 x 628 px",
                  isDark: isDark,
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ResizeOptionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _ResizeOptionItem({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TemplateDetailProvider>();
    final isSelected = provider.selectedResizeSize == title;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4.h),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? Colors.red
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
      ),
      trailing: Icon(Icons.info_outline, size: 18.sp, color: Colors.grey),
      onTap: () {
        provider.setResizeSize(title);
        Navigator.pop(context);
      },
    );
  }
}

Widget _buildTopBanner(BuildContext context, String resizeSize, bool isDark) {
  final provider = context.watch<TemplateDetailProvider>();
  final String? savedImagePath = provider.savedImagePath;

  double bannerHeight = 320.h;

  if (resizeSize.contains("4:5")) {
    bannerHeight = 380.h;
  } else if (resizeSize.contains("9:16")) {
    bannerHeight = 450.h;
  } else if (resizeSize.contains("Horizontal")) {
    bannerHeight = 220.h;
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: bannerHeight,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16.r),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
      image: savedImagePath != null && savedImagePath.isNotEmpty
          ? DecorationImage(
              image: FileImage(File(savedImagePath)),
              fit: BoxFit.cover,
            )
          : null,
    ),
    child: savedImagePath == null || savedImagePath.isEmpty
        ? Center(
            child: Text(
              resizeSize,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : null,
  );
}
