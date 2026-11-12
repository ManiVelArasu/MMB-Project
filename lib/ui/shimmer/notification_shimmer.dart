import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_loading.dart';

/// Shimmer placeholder for the Notification screen's first load.
class NotificationShimmer extends StatelessWidget {
  final bool isDark;
  final int itemCount;

  const NotificationShimmer({
    super.key,
    required this.isDark,
    this.itemCount = 7,
  });

  Widget _row() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        ShimmerBox(width: 44.w, height: 44.w, radius: 22.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: double.infinity, height: 14.h, radius: 6.r),
              SizedBox(height: 8.h),
              ShimmerBox(width: 200.w, height: 12.h, radius: 6.r),
              SizedBox(height: 8.h),
              ShimmerBox(width: 70.w, height: 10.h, radius: 6.r),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      isDark: isDark,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label (TODAY / YESTERDAY)
            ShimmerBox(width: 64.w, height: 12.h, radius: 6.r),
            SizedBox(height: 16.h),
            for (var i = 0; i < itemCount; i++) ...[
              _row(),
              SizedBox(height: 20.h),
            ],
          ],
        ),
      ),
    );
  }
}