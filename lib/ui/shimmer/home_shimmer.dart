import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_loading.dart';

/// Shimmer placeholder for the Home screen's first load. Mirrors the real
/// layout: search bar, My Space, Special Days, My Zone, banner, template rows.
class HomeShimmer extends StatelessWidget {
  final bool isDark;

  const HomeShimmer({super.key, required this.isDark});

  Widget _sectionTitle() {
    return Row(
      children: [
        ShimmerBox(width: 32.w, height: 32.w, radius: 16.w),
        SizedBox(width: 8.w),
        ShimmerBox(width: 120.w, height: 16.h, radius: 6.r),
      ],
    );
  }

  Widget _row({
    required double height,
    required double itemWidth,
    int count = 3,
  }) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, __) =>
            ShimmerBox(width: itemWidth, height: height, radius: 16.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AppShimmer(
      isDark: isDark,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.015,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            ShimmerBox(width: double.infinity, height: 48.h, radius: 14.r),
            SizedBox(height: 20.h),

            // My Space
            _sectionTitle(),
            SizedBox(height: 12.h),
            _row(height: 90.h, itemWidth: 100.w, count: 4),
            SizedBox(height: 20.h),

            // Special Days
            _sectionTitle(),
            SizedBox(height: 12.h),
            ShimmerBox(width: double.infinity, height: 40.h, radius: 15.r),
            SizedBox(height: 12.h),
            _row(height: 180.h, itemWidth: 145.w),
            SizedBox(height: 24.h),

            // Banner
            ShimmerBox(width: double.infinity, height: 165.h, radius: 12.r),
            SizedBox(height: 24.h),

            // Template rows
            _sectionTitle(),
            SizedBox(height: 12.h),
            _row(height: 165.h, itemWidth: 145.w),
            SizedBox(height: 24.h),
            _sectionTitle(),
            SizedBox(height: 12.h),
            _row(height: 165.h, itemWidth: 145.w),
          ],
        ),
      ),
    );
  }
}