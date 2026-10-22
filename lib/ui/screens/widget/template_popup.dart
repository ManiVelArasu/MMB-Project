import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../component/custom_widget.dart';
import '../../../utils/theme/app.colors.dart';
import '../../../utils/theme/app.fonts.dart';

class TemplateActionPopup extends StatefulWidget {
  final VoidCallback onCustomize;
  final VoidCallback onFavorite;
  final VoidCallback? onDownload;
  final bool showDownload;

  const TemplateActionPopup({
    super.key,
    required this.onCustomize,
    required this.onFavorite,
    this.onDownload,
    this.showDownload = false,
  });
  @override
  State<TemplateActionPopup> createState() => _TemplateActionPopupState();
}

class _TemplateActionPopupState extends State<TemplateActionPopup> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _togglePopup() {
    if (_overlayEntry != null) {
      _closePopup();
    } else {
      _showPopup();
    }
  }

  void _showPopup() {
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closePopup,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: Offset(0, 4.h),
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(8.r),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 145.w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _menuItem(
                        icon: 'assets/images/customise.png',
                        title: 'Customize',
                        onTap: () {
                          _closePopup();
                          widget.onCustomize();
                        },
                      ),
                      if (widget.showDownload && widget.onDownload != null) ...[
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey.shade300,
                        ),
                        _menuItem(
                          icon: 'assets/images/download.png',
                          title: 'Download',
                          onTap: () {
                            _closePopup();
                            widget.onDownload!();
                          },
                        ),
                      ],
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey.shade300,
                      ),
                      _menuItem(
                        icon: 'assets/images/heart_circle.png',
                        title: 'Favorite',
                        onTap: () {
                          _closePopup();
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
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _closePopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _togglePopup,
        child: Container(
          width: 30.w,
          height: 25.h,
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(7.r),
          ),
          child: Icon(Icons.more_horiz, color: Colors.white, size: 21.sp),
        ),
      ),
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
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        child: Row(
          children: [
            Image.asset(
              icon,
              width: 18.w,
              height: 18.h,
              errorBuilder: (_, __, ___) => Icon(
                title == 'Favorite'
                    ? Icons.favorite_border
                    : Icons.edit_outlined,
                size: 18.sp,
                color: AppColors.appBlack,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.appBlack,
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
