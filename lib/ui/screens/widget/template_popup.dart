import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../component/custom_widget.dart';
import '../../../utils/theme/app.colors.dart';

class TemplateActionPopup extends StatelessWidget {
  final VoidCallback onCustomize;
  final VoidCallback onFavorite;

  const TemplateActionPopup({
    super.key,
    required this.onCustomize,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 80.w),
      iconSize: 20.sp,
      offset: Offset(0, 28.h),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      icon: Container(
        width: 30.w,
        height: 25.h,
        decoration: BoxDecoration(
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Icon(Icons.more_horiz, color: Colors.white, size: 21.sp),
      ),
      onSelected: (value) {
        if (value == 'customize') {
          onCustomize();
        } else if (value == 'favorite') {
          onFavorite();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'customize',
          child: Row(
            children: [
              Image.asset('assets/images/customise.png', width: 18, height: 18),
              const SizedBox(width: 8),
              AppText('Customize', style: TextStyle(color: AppColors.appBlack)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'favorite',
          child: Row(
            children: [
              Image(
                image: AssetImage('assets/images/document-download1.png'),
                width: 18,
                height: 18,
              ),
              SizedBox(width: 8),
              AppText('Favorite', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ],
    );
  }
}
