import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import '../../../component/custom_widget.dart';
import '../../../utils/theme/app.colors.dart';

class TemplateActionPopup extends StatefulWidget {
  final VoidCallback onCustomize;
  final VoidCallback onFavorite;

  const TemplateActionPopup({
    super.key,
    required this.onCustomize,
    required this.onFavorite,
  });

  @override
  State<TemplateActionPopup> createState() =>
      _TemplateActionPopupState();
}

class _TemplateActionPopupState extends State<TemplateActionPopup> {
  bool isPopupOpen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Three-dot button
        GestureDetector(
          onTap: () {
            setState(() {
              isPopupOpen = !isPopupOpen;
            });
          },
          child: Container(
            width: 30.w,
            height: 25.h,
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: Icon(
              Icons.more_horiz,
              color: Colors.white,
              size: 21.sp,
            ),
          ),
        ),

        // Popup inside the card
        if (isPopupOpen)
          Positioned(
            top: 29.h,
            right: 0,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(8.r),
              child: SizedBox(
                width: 135.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuItem(
                      icon: 'assets/images/customise.png',
                      title: 'Customize',
                      onTap: () {
                        setState(() => isPopupOpen = false);
                        widget.onCustomize();
                      },
                    ),
                    _menuItem(
                      icon: 'assets/images/heart_circle.png',
                      title: 'Favorite',
                      onTap: () {
                        setState(() => isPopupOpen = false);
                        widget.onFavorite();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _menuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 10.h,
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: 18.w,
              height: 18.h,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.appBlack,
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w400
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
