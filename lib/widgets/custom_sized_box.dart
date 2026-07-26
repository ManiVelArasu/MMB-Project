import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSizedBox extends StatelessWidget {
  const CustomSizedBox({super.key, this.height=0, this.width = 0, this.child});

  final double? height;
  final double? width;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height!.h,
      width: width!.w,
      child: child,
    );
  }
}