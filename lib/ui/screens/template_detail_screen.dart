import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../network/provider/template_detail_provider.dart';
import '../../utils/theme/app.colors.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Brownies",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset("assets/icons/translate.svg"),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black),
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
                    _buildTopBanner(provider.selectedResizeSize),

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
                              color: Colors.grey.shade300,
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
                        // RESIZE Button onTap
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showResizeBottomSheet(
                              context,
                            ), // 🚀 Call Bottom Sheet here
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
                              backgroundColor: const Color(0xFFFFECEE),
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
                              Navigator.pushNamed(context, "/TemplateEditScreen");
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
                              backgroundColor: const Color(0xFFFFECEE),
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

                    // 2. 🚀 DYNAMIC BOTTOM LIST / GRID BUILDER (Changes based on selection)
                    _buildDynamicBottomContent(provider.selectedIndex),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.black,
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
                      showCategoriesBottomSheet(context);
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

  // 🚀 Switcher function that changes ONLY the bottom list based on click
  Widget _buildDynamicBottomContent(int selectedIndex) {
    if (selectedIndex == 0) {
      // IMAGE LIST (Only Image Templates)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Image Templates",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Center(
                  child: Text(
                    "Image Post ${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else if (selectedIndex == 1) {
      // VIDEO LIST (Only Video Templates)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Video Templates",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.red.shade200),
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
                          color: Colors.red.shade800,
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
      // POST SIZE LIST (Image + Video combination list items)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Post Size Templates (Image + Video)",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
                      ? Colors.purple.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isVideo
                        ? Colors.purple.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.image,
                        color: isVideo ? Colors.purple : Colors.orange,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isVideo
                            ? "Video Post ${index + 1}"
                            : "Image Post ${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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

  void showCategoriesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    height: 4.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
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

                // Categories Chips using Wrap
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
                                "Cupcakes",
                                "Muffins",
                                "Birthday Special",
                                "Sweets",
                                "Today Special",
                              ]
                              .map((category) => _buildCategoryChip(category))
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

  // Chip Widget Builder
  Widget _buildCategoryChip(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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

void showResizeBottomSheet(BuildContext context) {
  // 1. Parent context-la irundha provider-a fetch pannikrom
  final templateProvider = context.read<TemplateDetailProvider>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      // 🚀 2. Wrap with ChangeNotifierProvider.value so BottomSheet has access to TemplateDetailProvider
      return ChangeNotifierProvider.value(
        value: templateProvider,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    height: 4.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Resize Template",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(modalContext),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
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

                const _ResizeOptionItem(
                  title: "Post Square (1:1)",
                  subtitle: "1080 x 1080 px",
                ),
                const _ResizeOptionItem(
                  title: "Post Portrait (4:5)",
                  subtitle: "1080 x 1350 px",
                ),
                const _ResizeOptionItem(
                  title: "Story / Reel (9:16)",
                  subtitle: "1080 x 1920 px",
                ),
                const _ResizeOptionItem(
                  title: "Post Horizontal",
                  subtitle: "1200 x 628 px",
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

  const _ResizeOptionItem({
    required this.title,
    required this.subtitle,
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
          color: isSelected ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
      ),
      trailing: Icon(
        Icons.info_outline,
        size: 18.sp,
        color: Colors.grey,
      ),
      onTap: () {
        provider.setResizeSize(title);
        Navigator.pop(context);
      },
    );
  }
}


Widget _buildTopBanner(String resizeSize) {
  double bannerHeight = 320.h; // Default Square (1:1)

  if (resizeSize.contains("4:5")) {
    bannerHeight = 380.h; // Portrait
  } else if (resizeSize.contains("9:16")) {
    bannerHeight = 450.h; // Story / Reel
  } else if (resizeSize.contains("Horizontal")) {
    bannerHeight = 220.h; // Horizontal
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: bannerHeight,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16.r),
      color: Colors.blue.shade700,
    ),
    child: Center(
      child: Text(
        resizeSize,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
