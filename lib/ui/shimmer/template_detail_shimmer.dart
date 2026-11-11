import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_loading.dart';

/// Shimmer placeholder for the Template Detail screen's first load.
class TemplateDetailShimmer extends StatelessWidget {
  final bool isDark;

  const TemplateDetailShimmer({super.key, required this.isDark});

  Widget _chips(List<double> widths) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final w in widths) ShimmerBox(width: w, height: 30.h, radius: 20.r),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      isDark: isDark,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),

                  // Top banner / preview
                  AspectRatio(
                    aspectRatio: 1,
                    child: ShimmerBox(width: double.infinity, radius: 16.r),
                  ),
                  SizedBox(height: 12.h),

                  // Resize + edit buttons
                  Row(
                    children: [
                      Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 44.h,
                          radius: 12.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 44.h,
                          radius: 12.r,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Name + details
                  ShimmerBox(width: 180.w, height: 16.h, radius: 6.r),
                  SizedBox(height: 6.h),
                  ShimmerBox(width: 120.w, height: 12.h, radius: 6.r),
                  SizedBox(height: 14.h),

                  // Available sizes
                  ShimmerBox(width: 110.w, height: 13.h, radius: 6.r),
                  SizedBox(height: 8.h),
                  _chips([90.w, 100.w, 90.w]),
                  SizedBox(height: 14.h),

                  // Available language
                  ShimmerBox(width: 130.w, height: 13.h, radius: 6.r),
                  SizedBox(height: 8.h),
                  _chips([70.w, 80.w]),
                  SizedBox(height: 18.h),

                  // Template grid
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 0.68,
                          child: ShimmerBox(
                            width: double.infinity,
                            radius: 14.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 0.68,
                          child: ShimmerBox(
                            width: double.infinity,
                            radius: 14.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),

          // Bottom navigation
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 4; i++)
                  ShimmerBox(width: 56.w, height: 36.h, radius: 12.r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}