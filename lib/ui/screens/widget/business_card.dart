import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';

class BusinessCategoryCard extends StatelessWidget {
  final String category;
  final String subCategories;
  final VoidCallback onEditTap;

  const BusinessCategoryCard({
    super.key,
    required this.category,
    required this.subCategories,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 15,right: 15,top: 10,bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFDDE0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Business Category',
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.appBlack,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: AppText(
                  'EDIT',
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF252D),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // Main Category
          AppText(
            category,
            style: TextStyle(
              fontSize: AppFontSize.fontSize22,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFFF252D),
              height: 1.15,
            ),
          ),

          // Subcategories
          AppText(
            subCategories,
            style: TextStyle(
              fontSize: AppFontSize.fontSize18,
              fontWeight: FontWeight.w400,
              color: AppColors.lightedGrey,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
