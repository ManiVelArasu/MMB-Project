
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../component/custom_widget.dart';
import '../../../utils/theme/app.colors.dart';
import '../../../utils/theme/app.fonts.dart';

class TemplateActionPopup extends StatefulWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onFavorite;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onCustomize;
  final bool isFavorite;
  final bool showDownload;
  final bool showDelete;

  const TemplateActionPopup({
    super.key,
    this.onEdit,
    this.onFavorite,
    this.onDownload,
    this.onDelete,
    this.isFavorite = false,
    this.showDownload = true,
    this.showDelete = true,
    this.onCustomize,
  });

  @override
  State<TemplateActionPopup> createState() =>
      _TemplateActionPopupState();
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
        final dark =
            Theme.of(overlayContext).brightness == Brightness.dark;

        final backgroundColor =
        dark ? const Color(0xFF242424) : Colors.white;

        final textColor =
        dark ? Colors.white : AppColors.appBlack;

        final dividerColor =
        dark ? Colors.grey.shade700 : Colors.grey.shade300;

        // Build menu items based on isFavorite
        final List<Widget> menuItems = [];

        void addItem({
          required String image,
          required String title,
          required Color color,
          required VoidCallback onTap,
        }) {
          if (menuItems.isNotEmpty) {
            menuItems.add(
              Divider(
                height: 1,
                thickness: 0.5,
                color: dividerColor,
              ),
            );
          }

          menuItems.add(
            _menuItem(
              image: image,
              title: title,
              textColor: color,
              onTap: () {
                _closePopup();
                onTap();
              },
            ),
          );
        }

        // Favorite true = Favorite option
        // Favorite false = Edit option
        // Favorite
        // Favorite
        if (widget.isFavorite && widget.onFavorite != null) {
          addItem(
            image: 'assets/images/heart_circle.png',
            title: 'Favorite',
            color: textColor,
            onTap: widget.onFavorite!,
          );
        }

// Edit
        if (!widget.isFavorite && widget.onEdit != null) {
          addItem(
            image: 'assets/images/edits.png',
            title: 'Edit',
            color: textColor,
            onTap: widget.onEdit!,
          );
        }

// Customize
        if (widget.onCustomize != null) {
          addItem(
            image: 'assets/images/customise.png',
            title: 'Customize',
            color: textColor,
            onTap: widget.onCustomize!,
          );
        }

// Download
        if (widget.showDownload && widget.onDownload != null) {
          addItem(
            image: 'assets/images/edits.png',
            title: 'Download',
            color: textColor,
            onTap: widget.onDownload!,
          );
        }

// Delete
        if (widget.showDelete && widget.onDelete != null) {
          addItem(
            image: 'assets/images/trash.png',
            title: 'Delete',
            color: textColor,
            onTap: widget.onDelete!,
          );
        }

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
                color: backgroundColor,
                elevation: 8,
                borderRadius: BorderRadius.circular(8.r),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 145.w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: menuItems,
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
          child: Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: 21.sp,
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required String image,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 11.h,
        ),
        child: Row(
          children: [
            Image.asset(
              image,
              width: 18.w,
              height: 18.h,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: AppText(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor,
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
