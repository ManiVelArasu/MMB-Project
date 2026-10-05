import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ButtonWidget extends StatefulWidget {
  final VoidCallback? buttonPress;
  final double? width;
  final double? height;
  final Decoration? decoration;
  final String title;
  final TextStyle? textStyle;
  final bool isRightIconVisible;
  final bool isLeftIconVisible;
  final String? icon;
  final bool isLoading;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? iconHeight;
  final double? iconWidth;
  final Color? loaderColor;
  final Color? buttonColor;
  final Color? textColor;

  const ButtonWidget({
    super.key,
    required this.buttonPress,
    this.width,
    this.height,
    this.decoration,
    required this.title,
    this.textStyle,
    this.isRightIconVisible = false,
    this.isLeftIconVisible = false,
    this.icon = "assets/icons/basket.svg",
    this.isLoading = false,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconHeight = 24,
    this.iconWidth = 24,
    this.loaderColor = Colors.white,
    this.buttonColor = Colors.black,
    this.textColor = Colors.black,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  final Duration _duration = const Duration(milliseconds: 100);

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : _onTapDown,
      onTapUp: widget.isLoading
          ? null
          : (details) {
        _onTapUp(details);
        widget.buttonPress?.call();
      },
      onTapCancel: widget.isLoading ? null : _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: _duration,
        curve: Curves.easeInOut,
        child: Container(
          width: widget.width,
          height: widget.height ?? 48.h,
          decoration: widget.decoration ??
              BoxDecoration(
                color: widget.buttonColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
          child: widget.isLoading
              ? Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: widget.loaderColor,
              ),
            ),
          )
              : Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isLeftIconVisible)
                  Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: SvgPicture.asset(
                      widget.icon!,
                      height: widget.iconHeight!.h,
                      width: widget.iconWidth!.w,
                      color: widget.iconColor,
                    ),
                  ),

                // IMPORTANT:
                // Flexible is directly inside Row
                Flexible(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: widget.textStyle ??
                        TextStyle(
                          color: widget.textColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),

                if (widget.isRightIconVisible)
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: SvgPicture.asset(
                      widget.icon!,
                      height: widget.iconHeight!.h,
                      width: widget.iconWidth!.w,
                      color: widget.iconColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}