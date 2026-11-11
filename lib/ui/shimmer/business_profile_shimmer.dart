import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_loading.dart';

class BusinessProfileShimmer extends StatelessWidget {
  final bool isDark;

  const BusinessProfileShimmer({super.key, required this.isDark});

  Widget _actionCard() {
    return ShimmerBox(width: double.infinity, height: 64.h, radius: 14.r);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pad = size.width * 0.04;

    return AppShimmer(
      isDark: isDark,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 12.h),
        child: Column(
          children: [
            // Logo / avatar
            ShimmerBox(width: 70.w, height: 70.w, radius: 35.w),
            SizedBox(height: 10.h),

            // Business name + sub text
            ShimmerBox(width: 160.w, height: 18.h, radius: 6.r),
            SizedBox(height: 8.h),
            ShimmerBox(width: 110.w, height: 12.h, radius: 6.r),
            SizedBox(height: 12.h),

            // Contact chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(width: 90.w, height: 28.h, radius: 14.r),
                SizedBox(width: 10.w),
                ShimmerBox(width: 90.w, height: 28.h, radius: 14.r),
                SizedBox(width: 10.w),
                ShimmerBox(width: 90.w, height: 28.h, radius: 14.r),
              ],
            ),
            SizedBox(height: 20.h),

            // Brand Frames header
            Row(
              children: [
                ShimmerBox(width: 24.w, height: 24.w, radius: 12.w),
                SizedBox(width: 8.w),
                ShimmerBox(width: 120.w, height: 16.h, radius: 6.r),
                const Spacer(),
                ShimmerBox(width: 32.w, height: 32.w, radius: 16.w),
              ],
            ),
            SizedBox(height: 14.h),

            // Frames row
            SizedBox(
              height: 145.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (_, __) =>
                    ShimmerBox(width: 110.w, height: 145.h, radius: 10.r),
              ),
            ),
            SizedBox(height: 20.h),

            // Action cards (uploads, downloads, ...)
            _actionCard(),
            SizedBox(height: 12.h),
            _actionCard(),
            SizedBox(height: 12.h),
            _actionCard(),
          ],
        ),
      ),
    );
  }
}
