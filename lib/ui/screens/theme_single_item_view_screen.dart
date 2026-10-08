import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';

import '../../Api Model/theme_screen_model.dart';
import '../../Api Model/theme_single_model.dart';
import '../../component/network_image.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/theme_screen_provider.dart';
import '../../network/provider/theme_single_provider.dart';

// ============================================================
// SCREEN
// ============================================================

class ThemeSingleitemViewScreen extends StatelessWidget {
  final String variantId;

  const ThemeSingleitemViewScreen({super.key, required this.variantId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ======================================================
        // CURRENT VARIANT PROVIDER
        // ======================================================

        ChangeNotifierProvider(create: (_) => ThemeSingleItemProvider()),

        // ======================================================
        // BRAND SERIES PROVIDER
        // industry() API
        // ======================================================
        ChangeNotifierProvider(
          create: (_) => ThemesScreenProvider()..fetchPlans(),
        ),
      ],

      child: _ThemeSingleItemContent(variantId: variantId),
    );
  }
}

// ============================================================
// CONTENT
// ============================================================

class _ThemeSingleItemContent extends StatefulWidget {
  final String variantId;

  const _ThemeSingleItemContent({required this.variantId});

  @override
  State<_ThemeSingleItemContent> createState() =>
      _ThemeSingleItemContentState();
}

class _ThemeSingleItemContentState extends State<_ThemeSingleItemContent> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Current variant API
      context.read<ThemeSingleItemProvider>().fetchPlans(widget.variantId);

      // Brand Series API is already called from
      // ThemesScreenProvider create:
      //
      // ThemesScreenProvider()..fetchPlans()
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ThemeDetailView();
  }
}

// ============================================================
// DETAIL VIEW
// ============================================================

class ThemeDetailView extends StatelessWidget {
  const ThemeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();

    final bool isDark = themeProvider.isDarkMode;

    return Consumer<ThemeSingleItemProvider>(
      builder: (context, provider, child) {
        // ======================================================
        // CURRENT VARIANT LOADING
        // ======================================================

        if (provider.isLoadingPlans) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,

            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }

        // ======================================================
        // CURRENT VARIANT ERROR
        // ======================================================

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

        // ======================================================
        // CURRENT VARIANT DATA
        // ======================================================

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

        // ======================================================
        // MAIN SCREEN
        // ======================================================

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
                    // ==================================================
                    // BACK + FAVORITE
                    // ==================================================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },

                          child: Container(
                            height: 40.h,
                            width: 40.w,

                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A1A1C)
                                  : const Color(0xFFFFECEE),

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
                          onTap: () {
                            provider.toggleFavorite();
                          },

                          child: Container(
                            height: 40.h,
                            width: 40.w,

                            decoration: BoxDecoration(
                              color: provider.isFavorite
                                  ? (isDark
                                        ? const Color(0xFF2A1A1C)
                                        : const Color(0xFFFFECEE))
                                  : (isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.grey.shade100),

                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              provider.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,

                              color: provider.isFavorite
                                  ? const Color(0xFFE53935)
                                  : (isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400),

                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // ==================================================
                    // POPULAR
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),

                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A1C)
                                : Colors.red.shade50,

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

                              AppText(
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

                    // ==================================================
                    // TITLE
                    // ==================================================
                    AppText(
                      title,

                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,

                        fontSize: AppFontSize.fontSize22,

                        fontWeight: FontWeight.w900,
                      ),

                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 4.h),

                    // ==================================================
                    // CAPTION
                    // ==================================================
                    AppText(
                      caption,

                      style: TextStyle(
                        color: const Color(0xFFE53935),

                        fontSize: AppFontSize.fontSize13,

                        fontWeight: FontWeight.w700,
                      ),

                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8.h),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================
                    AppText(
                      description,

                      style: TextStyle(
                        color: isDark ? Colors.grey.shade300 : Colors.black87,

                        fontSize: AppFontSize.fontSize16,

                        height: 1.4,
                      ),

                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 14.h),

                    // ==================================================
                    // TAGS
                    // ==================================================
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      alignment: WrapAlignment.center,
                      children: tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A1C)
                                : const Color(0xFFFFE9EB),
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.red.shade900
                                  : Colors.red.shade100,
                            ),
                          ),
                          child: AppText(
                            tag.toString(),
                            style: TextStyle(
                              color:AppColors.appBlack,
                              fontSize:AppFontSize.fontSize14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // ==================================================
                    // GET THIS VARIANT
                    // ==================================================
                    IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 250.w,
                        ),
                        child: SizedBox(
                          height: 42.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: AppText(
                                    "Theme Unlocked Successfully!",
                                  ),
                                ),
                              );
                            },
                            child: AppText(
                              "Get This Varient →",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // ==================================================
                    // MOCKUP
                    // ==================================================
                    MockupSliderWidget(
                      templates: data?.templates ?? [],

                      isDark: isDark,
                    ),

                    SizedBox(height: 30.h),

                    // ==================================================
                    // PERFECT FOR
                    // ==================================================
                    AppText(
                      "Perfect For",

                      style: TextStyle(
                        fontSize: AppFontSize.fontSize22,

                        fontWeight: FontWeight.w900,

                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    SizedBox(height: 14.h),

                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,

                      alignment: WrapAlignment.center,

                      children:
                          (businessCategories.isNotEmpty
                                  ? businessCategories
                                        .map((bc) => bc.name)
                                        .toList()
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

                                  child: Text(
                                    category ?? '',

                                    style: TextStyle(
                                      color: const Color(0xFFE53935),

                                      fontSize: 11.sp,

                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                    ),

                    // ==================================================
                    // BRAND SERIES
                    // ==================================================
                    SizedBox(height: 30.h),

                    _buildBrandSeriesSection(context, isDark),
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

// ============================================================
// BRAND SERIES SECTION
// ============================================================

Widget _buildBrandSeriesSection(BuildContext context, bool isDark) {
  return Consumer<ThemesScreenProvider>(
    builder: (context, provider, child) {
      if (provider.isLoadingPlans) {
        return SizedBox(
          height: 250.h,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE53935)),
          ),
        );
      }

      if (provider.plansErrorMessage != null) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text(
            provider.plansErrorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 12.sp),
          ),
        );
      }

      final brandSeries = provider.groups;

      if (brandSeries.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
             Image.asset("assets/images/brand.png",width: 20,height: 20,),

              SizedBox(width: 5.w),

              AppText(
                "More Brand Series",
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // ======================================================
          // HORIZONTAL CARDS
          // ======================================================
          // ======================================================
// HORIZONTAL BRAND SERIES
// ======================================================

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: List.generate(
                brandSeries.length,
                    (index) {
                  final item = brandSeries[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == brandSeries.length - 1
                          ? 0
                          : 8.w,
                    ),

                    child: _buildBrandSeriesCard(
                      context,
                      item,
                      isDark,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}

// ============================================================
// BRAND SERIES CARD
// ============================================================

Widget _buildBrandSeriesCard(
  BuildContext context,
  ThemeItem item,
  bool isDark,
) {
  // ============================================================
  // GET FIRST VARIANT
  // ============================================================

  final variants = item.variants ?? [];

  final variant = variants.isNotEmpty ? variants.first : null;

  final String? thumbnail = variant?.thumbnailS3Key;

  // ============================================================
  // NAME
  // ============================================================

  final String seriesName = item.name ?? "Brand Series";

  // ============================================================
  // VARIANT NAME
  // ============================================================

  final String variantName = variant?.name ?? seriesName;

  // ============================================================
  // DESCRIPTION
  // ============================================================

  final String description =
      variant?.description ?? item.description ?? item.caption ?? "";

  // ============================================================
  // BADGE
  // ============================================================

  final bool isLocked = item.isLocked == true;

  return SizedBox(
    width: 150.w,

    child: GestureDetector(
      onTap: () {
        // ======================================================
        // VIEW SERIES / VARIANT
        // ======================================================

        if (variant?.uid != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ThemeSingleitemViewScreen(variantId: variant!.uid!),
            ),
          );
        }
      },

      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

          borderRadius: BorderRadius.circular(10.r),

          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),

              blurRadius: 5,

              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.r),
                    topRight: Radius.circular(10.r),
                  ),

                  child: SizedBox(
                    width: double.infinity,
                    height: 105.h,

                    child: thumbnail != null && thumbnail.isNotEmpty
                        ? NetworkAssetImage(
                            url: "${ApiEndpoints.cdnImageUrl}/$thumbnail",

                            fit: BoxFit.cover,

                            errorWidget: _buildSeriesPlaceholder(isDark),
                          )
                        : _buildSeriesPlaceholder(isDark),
                  ),
                ),

                // ==============================================
                // CROWN
                // ==============================================
                Positioned(
                  top: 5.h,
                  left: 5.w,

                  child: Container(
                    width: 22.w,
                    height: 22.w,

                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),

                    child: Center(
                      child: Text("👑", style: TextStyle(fontSize: 12.sp)),
                    ),
                  ),
                ),

                // ==============================================
                // LOCK
                // ==============================================
                if (isLocked)
                  Positioned(
                    top: 6.h,
                    right: 6.w,

                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 3.h,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),

                        borderRadius: BorderRadius.circular(5.r),
                      ),

                      child: Icon(
                        Icons.lock_outline,
                        size: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            // ==================================================
            // DETAILS
            // ==================================================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ============================================
                  // VARIANT NAME + POPULAR
                  // ============================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                      Expanded(
                        child: Text(
                          variantName,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 10.sp,

                            fontWeight: FontWeight.w800,

                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),

                      SizedBox(width: 2.w),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8E8),

                          borderRadius: BorderRadius.circular(3.r),
                        ),

                        child: AppText(
                          "POPULAR",

                          style: TextStyle(
                            color: const Color(0xFFE53935),

                            fontSize: 5.sp,

                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // ============================================
                  // DESCRIPTION
                  // ============================================
                  AppText(
                    _cleanDescription(description),

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 7.5.sp,

                      height: 1.25,

                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // ============================================
                  // PERFECT FOR
                  // ============================================
                  AppText(
                    _getPerfectFor(item),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 7.5.sp,

                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _getPerfectFor(ThemeItem item) {
  final caption = item.caption?.trim() ?? "";

  if (caption.isNotEmpty) {
    return "Perfect for ${caption}";
  }

  return "Perfect for modern brands";
}

Widget _buildSeriesPlaceholder(bool isDark) {
  return Container(
    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,

    child: Center(
      child: Icon(
        Icons.palette_outlined,

        size: 35.sp,

        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
      ),
    ),
  );
}

String _cleanDescription(String value) {
  return value.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ============================================================
// MOCKUP SLIDER
// ============================================================

class MockupSliderWidget extends StatefulWidget {
  final List<dynamic> templates;
  final bool isDark;

  const MockupSliderWidget({
    super.key,
    required this.templates,
    required this.isDark,
  });

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
          width: 280,
          height: 380.h,

          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF1E1E1E)
                : Colors.grey.shade100,

            borderRadius: BorderRadius.circular(20.r),

            border: Border.all(
              color: widget.isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
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

                final String? thumbnail = item is Template
                    ? item.thumbnailS3Key
                    : item?.toString();

                if (thumbnail != null && thumbnail.isNotEmpty) {
                  return NetworkAssetImage(
                    url: "${ApiEndpoints.cdnImageUrl}/$thumbnail",

                    fit: BoxFit.cover,

                    errorWidget: const Icon(
                      Icons.category,
                      size: 16,
                      color: Colors.white,
                    ),
                  );
                }

                return _buildPlaceholderImage();
              },
            ),
          ),
        ),

        SizedBox(height: 15.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: List.generate(images.length, (index) {
            final bool isActive = _currentIndex == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),

              margin: EdgeInsets.symmetric(horizontal: 2.w),

              width: isActive ? 16.w : 6.w,

              height: 6.h,

              decoration: BoxDecoration(
                color: isActive
                    ? Colors.red
                    : (widget.isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300),

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
