import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Api Model/theme_single_model.dart';
import '../../component/network_image.dart';
import '../../core/api/api_endpoints.dart';

import '../../network/provider/theme_single_provider.dart';

import 'package:project_mmb/network/provider/custom_theme_provider.dart';


class ThemeSingleitemViewScreen extends StatelessWidget {
  final String variantId;

  const ThemeSingleitemViewScreen({super.key, required this.variantId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeSingleItemProvider(),
      child: Builder(
        builder: (context) {
          return _ThemeSingleItemContent(variantId: variantId);
        },
      ),
    );
  }
}

class _ThemeSingleItemContent extends StatefulWidget {
  final String variantId;

  const _ThemeSingleItemContent({required this.variantId});

  @override
  State<_ThemeSingleItemContent> createState() => _ThemeSingleItemContentState();
}

class _ThemeSingleItemContentState extends State<_ThemeSingleItemContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeSingleItemProvider>(
        context,
        listen: false,
      ).fetchPlans(widget.variantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ThemeDetailView();
  }
}

class ThemeDetailView extends StatelessWidget {
  const ThemeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Consumer<ThemeSingleItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPlans) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }
        if (provider.plansErrorMessage != null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  provider.plansErrorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // 🚀 Extract Data from API Model safely
        final data = provider.plansData?.data;
        final brandSeries = data?.brandSeries;

        final String title =
            data?.name ?? brandSeries?.name ?? "Lemon Buzz-Variant 003";
        final String caption =
            brandSeries?.caption?.toString() ?? "Bold. Bright. Professional.";
        final String description =
            data?.description?.toString() ??
                brandSeries?.description?.toString() ??
                "Perfect for brands that want modern, vibrant, and memorable marketing visuals.";

        final List<dynamic> tags =
        (brandSeries?.tags != null && brandSeries!.tags.isNotEmpty)
            ? brandSeries.tags
            : ["Fresh", "Bright", "Energetic", "Modern", "Friendly"];

        final businessCategories = data?.businessCategories ?? [];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back & Favorite Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 40.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: const Color(0xFFE53935),
                              size: 20.sp,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => provider.toggleFavorite(),
                          child: Container(
                            height: 40.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              color: provider.isFavorite
                                  ? (isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE))
                                  : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              provider.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: provider.isFavorite
                                  ? const Color(0xFFE53935)
                                  : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Popular Badge & Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A1A1C) : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.red,
                                size: 10.sp,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                "POPULAR",
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 4.h),

                    // Subtitle / Caption
                    Text(
                      caption,
                      style: TextStyle(
                        color: const Color(0xFFE53935),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8.h),

                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 14.h),

                    // Tags Wrap
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.center,
                      children: tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isDark ? Colors.red.shade900 : Colors.red.shade100,
                            ),
                          ),
                          child: Text(
                            tag.toString(),
                            style: TextStyle(
                              color: const Color(0xFFE53935),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // Get this Variant Button
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
                              content: Text("Variant Activated Successfully!"),
                            ),
                          );
                        },
                        child: Text(
                          "Get this Variant →",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    MockupSliderWidget(templates: data?.templates ?? [], isDark: isDark),

                    SizedBox(height: 30.h),

                    // Perfect For Section Header
                    Text(
                      "Perfect For",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 14.h),

                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.center,
                      children: (businessCategories.isNotEmpty
                          ? businessCategories.map((bc) => bc.name).toList()
                          : [
                        "Education & Coaching",
                        "Startups & Tech",
                        "Marketing & Creative Agencies",
                        "Fitness & Wellness",
                        "Financial Services",
                        "Retail & Product brands",
                        "Real Estate",
                        "Events & Promotions",
                        "Freelancers & Consultants",
                        "Logistics & Delivery Services",
                      ])
                          .map((category) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isDark ? Colors.red.shade900 : Colors.red.shade100,
                            ),
                          ),
                          child: Text(
                            category ?? '',
                            style: TextStyle(
                              color: const Color(0xFFE53935),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
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

class MockupSliderWidget extends StatefulWidget {
  final List<dynamic> templates;
  final bool isDark;

  const MockupSliderWidget({super.key, required this.templates, required this.isDark});

  @override
  State<MockupSliderWidget> createState() => _MockupSliderWidgetState();
}

class _MockupSliderWidgetState extends State<MockupSliderWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.templates.isNotEmpty
        ? widget.templates
        : [null, null, null, null];

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 380.h,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final item = images[index];
                final String? thumbnail =
                item is Template ? item.thumbnailS3Key : item?.toString();

                return thumbnail != null && thumbnail.isNotEmpty
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
                    : _buildPlaceholderImage();
              },
            ),
          ),
        ),

        SizedBox(height: 15.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            bool isActive = _currentIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              width: isActive ? 16.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: isActive ? Colors.red : (widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: widget.isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.phone_iphone_rounded,
          size: 80.sp,
          color: widget.isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        ),
      ),
    );
  }
}