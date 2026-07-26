import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMicTap;
  final VoidCallback? onSearchTap;
  final String prefixAsset;
  final String suffixAsset;
  final Color fillColor;
  final Color? borderColor;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.hintText = "Find your Industry",
    this.onChanged,
    this.onMicTap,
    this.onSearchTap,
    this.prefixAsset = "assets/images/search.png",
    this.suffixAsset = "assets/images/mic.png",
    this.fillColor = Colors.white,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w400,
          ),

          // Prefix Icon
          prefixIcon: InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(30.r),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Image.asset(
                prefixAsset,
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Suffix Icon
          suffixIcon: InkWell(
            onTap: onMicTap,
            borderRadius: BorderRadius.circular(30.r),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Image.asset(
                suffixAsset,
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: EdgeInsets.symmetric(
            vertical: 14.h,
            horizontal: 16.w,
          ),

          // Dynamic Border Setup
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: borderColor != null
                ? BorderSide(color: borderColor!, width: 1.w)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: borderColor != null
                ? BorderSide(color: borderColor!, width: 1.w)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(
              color: borderColor ?? const Color(0xFFE53935),
              width: 1.5.w,
            ),
          ),
        ),
      ),
    );
  }
}
