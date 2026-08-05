import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Api Model/theme_single_model.dart';
import '../../core/api/api_endpoints.dart';

import '../../network/provider/theme_single_provider.dart';

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
    return Consumer<ThemeSingleItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPlans) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: const Color(0xFFE53935)),
            ),
          );
        }
        if (provider.plansErrorMessage != null) {
          return Scaffold(
            backgroundColor: Colors.white,
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

        final String? thumbnail = data?.thumbnailS3Key;
        final businessCategories = data?.businessCategories ?? [];

        return Scaffold(
          backgroundColor: Colors.white,
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
                            color: Colors.red.shade50,
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
                        color: Colors.black,
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
                        color: Colors.black87,
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
                            color: const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.red.shade100),
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

                    MockupSliderWidget(templates: data?.templates ?? []),

                    SizedBox(height: 30.h),

                    // Perfect For Section Header
                    Text(
                      "Perfect For",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
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
                            color: const Color(0xFFFFF0F2),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.red.shade100,
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.phone_iphone_rounded,
          size: 80.sp,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
class MockupSliderWidget extends StatefulWidget {
  final List<dynamic> templates; // or list of images/thumbnails

  const MockupSliderWidget({super.key, required this.templates});

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
        : [null, null, null, null]; // Fallback placeholder items

    return Column(
      children: [
        // 🚀 Slider View (PageView)
        Container(
          width: double.infinity,
          height: 380.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.shade300),
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
                final String? thumbnail = item is Template ? item.thumbnailS3Key : item?.toString();

                return thumbnail != null && thumbnail.isNotEmpty
                    ? Image.network(
                  "${ApiEndpoints.cdnImageUrl}/$thumbnail",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                )
                    : _buildPlaceholderImage();
              },
            ),
          ),
        ),

        SizedBox(height: 15.h),

        // 🚀 Dynamic Page Indicator Dots matching current index
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
                color: isActive ? Colors.red : Colors.grey.shade300,
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
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.phone_iphone_rounded,
          size: 80.sp,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}