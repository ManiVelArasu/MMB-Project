import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/theme/app.fonts.dart';
import 'custom_widget.dart';


class StatusWidget extends StatelessWidget {
  const StatusWidget({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textStyle,
    this.borderColor,
    this.widthS,
    this.borderRadius,
    this.horizontalPadding,
  });

  final String status;
  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final double? widthS;
  final double? borderRadius;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final bool isCategoryMode = borderColor == null;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCategoryMode ? 4.h : 3.h,
        horizontal: horizontalPadding ?? (isCategoryMode ? 8.w : 0),
      ),
      decoration: BoxDecoration(
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
        borderRadius: BorderRadius.circular(
          borderRadius ?? (isCategoryMode ? 30.r : 12.r),
        ),
        color: backgroundColor,
      ),
      child: SizedBox(
        width: widthS ?? (isCategoryMode ? null : MediaQuery.of(context).size.width * 0.25),
        child: Center(
          child: AppText(
            status,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: (textStyle ?? const TextStyle()).copyWith(
              fontSize: AppFontSize.fontSize12,
            ),
          ),
        ),
      ),
    );
  }
}