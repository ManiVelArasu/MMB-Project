import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';

import '../../../Api Model/theme_screen_model.dart';
import '../../../component/custom_widget.dart';
import '../../../component/network_image.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../utils/theme/app.fonts.dart';

import '../theme_single_item_view_screen.dart';

class BrandSeriesCard extends StatelessWidget {
  final String? thumbnail;
  final String title;
  final String description;
  final String perfectFor;
  final bool isLocked;
  final bool isDark;
  final VoidCallback? onTap;

  const BrandSeriesCard({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.description,
    required this.perfectFor,
    required this.isLocked,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150.w,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
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
                      child: thumbnail != null && thumbnail!.isNotEmpty
                          ? Image.network(
                              thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return _buildPlaceholder();
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                  ),

                  // ==================================================
                  // CROWN
                  // ==================================================
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

                  // ==================================================
                  // LOCK
                  // ==================================================
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
                    // TITLE + POPULAR
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AppText(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize14,
                              fontWeight: FontWeight.w600,
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
                              color: AppColors.appBlack,
                              fontSize: AppFontSize.fontSize11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // DESCRIPTION
                    AppText(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize13,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                        color: isDark ? Colors.white70 : AppColors.appBlack,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // PERFECT FOR
                    AppText(
                      "Perfect For $perfectFor",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize12,
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

  Widget _buildPlaceholder() {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28.sp,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
    );
  }
}
