import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ButtonWidget extends StatefulWidget {
  final VoidCallback buttonPress;
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
              widget.buttonPress();
            },
      onTapCancel: widget.isLoading ? null : _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: _duration,
        curve: Curves.easeInOut,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 48.h,
          decoration:
              widget.decoration ??
              BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20.r),
              ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: widget.loaderColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    widget.isLeftIconVisible
                        ? Padding(
                            padding: EdgeInsets.only(left: 6,top: 6,bottom: 6),
                            child: SvgPicture.asset(
                              widget.icon!,
                              height: widget.iconHeight!.h,
                              width: widget.iconWidth!.w,
                              color: widget.iconColor,
                            ),
                          )
                        : SizedBox(width: 24.w),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: widget.isLeftIconVisible ? 12.0 : 0,
                        ),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style:
                              widget.textStyle ??
                              TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),

                    widget.isRightIconVisible
                        ? Padding(
                            padding: EdgeInsets.only(right: 16.w),
                            child: SvgPicture.asset(
                              widget.icon!,
                              height: widget.iconHeight!.h,
                              width: widget.iconHeight!.w,
                              color: widget.iconColor,
                            ),
                          )
                        : SizedBox(width: 24.w),
                  ],
                ),
        ),
      ),
    );
  }
}
