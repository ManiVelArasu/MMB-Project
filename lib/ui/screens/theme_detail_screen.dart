import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:provider/provider.dart';

import '../../Api Model/theme_screen_model.dart';
import '../../component/home_appbar.dart';
import '../../component/network_image.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/theme_screen_provider.dart';

import '../../network/provider/custom_theme_provider.dart';

class ThemeDetailScreen extends StatelessWidget {
  final ThemeItem? themeItem;

  const ThemeDetailScreen({super.key, this.themeItem});

  @override
  Widget build(BuildContext context) {
    final ThemeItem? item =
        themeItem ?? (ModalRoute.of(context)?.settings.arguments as ThemeItem?);

    return ChangeNotifierProvider(
      create: (_) => ThemesScreenProvider(),
      child: Builder(
        builder: (context) {
          return ThemeDetailView(themeItem: item);
        },
      ),
    );
  }
}

class ThemeDetailView extends StatelessWidget {
  final ThemeItem? themeItem;
  const ThemeDetailView({super.key, this.themeItem});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<ThemesScreenProvider>(
      builder: (context, provider, child) {
        final String title = themeItem?.name ?? "";
        final String caption =
            themeItem?.caption ?? "Bright ideas deserve bright branding";
        final String description =
            themeItem?.description ??
            "Fresh, vibrant, energetic visuals for businesses that want to grab attention instantly, while keeping every single post consistent, lively, and unmistakably you.";

        final List<dynamic> tags = themeItem?.tags.isNotEmpty == true
            ? themeItem!.tags
            : ["Fresh", "Bright", "Energetic", "Modern", "Friendly"];

        final List<Variant> variants = themeItem?.variants ?? [];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: const HomeCustomAppBar(
              businessCategory: "Cake and Sweets",
              notificationCount: "2",
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Theme Title
                    AppText(
                      themeItem?.name ?? "",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),

                    SizedBox(height: 6.h),

                    // Caption / Subtitle
                    AppText(
                      caption,
                      style: TextStyle(
                        color: const Color(0xFFE53935),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 10.h),

                    // Description
                    AppText(
                      description,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16.h),

                    // Tags Wrap (Centered)
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.center,
                      children: themeItem!.stylePersonalities
                          .where((tag) => tag.name != null && tag.name!.isNotEmpty)
                          .map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A1C)
                                : const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.red.shade900
                                  : Colors.red.shade100,
                            ),
                          ),
                          child: AppText(
                            tag.name!,
                            style: TextStyle(
                              color: const Color(0xFFE53935),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20.h),

                    // Unlock Button matching screenshot
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: AppText("Theme Unlocked Successfully!"),
                            ),
                          );
                        },
                        child: AppText(
                          "Unlock $title →",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Variants / Templates Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: variants.isNotEmpty ? variants.length : 4,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final variant = variants.isNotEmpty
                            ? variants[index]
                            : null;
                        final thumbnail = variant?.thumbnailS3Key;
                        final variantName = variant?.name ?? "$title-0$index";

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.grey.shade100,
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16.r),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              "/ThemeSingleitemViewScreen",
                                              arguments: variant?.uid,
                                            );
                                          },
                                          child:
                                              thumbnail != null &&
                                                  thumbnail.isNotEmpty
                                              ? NetworkAssetImage(
                                                  url:
                                                      "${ApiEndpoints.cdnImageUrl}/${thumbnail ?? ''}",
                                                  fit: BoxFit.cover,
                                                  errorWidget: const Icon(
                                                    Icons.category,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Container(
                                                  color: isDark
                                                      ? const Color(0xFF2C2C2C)
                                                      : Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 40.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8.h,
                                        left: 8.w,
                                        child: Image.asset(
                                          "assets/images/crown.png",
                                          width: 14,
                                          height: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: AppText(
                                            variantName,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w900,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2A1A1C)
                                                : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4.r,
                                            ),
                                          ),
                                          child: AppText(
                                            "POPULAR",
                                            style: TextStyle(
                                              fontSize: 7.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    AppText(
                                      "8 Ready-to-Use Templates",
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    AppText(
                                      "Perfect for Cafes, Bakeries & Organic Brands.",
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 30.h),

                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: AppText(
                          "Also works great for",
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    AppText(
                      "Beyond the obvious",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Business Category Chips
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.center,
                      children:
                          [
                            "Cafe",
                            "Juice Shop",
                            "Organic Store",
                            "Bakery",
                            "Dessert Shop",
                            "Smoothie Bar",
                          ].map((category) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: AppText(
                                category,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
