
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicTap;
  final VoidCallback? onSearchTap;
  final String prefixAsset;
  final String suffixAsset;
  final Color fillColor;
  final Color? borderColor;
  final bool showSuffixIcon;

  // Suggestions
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;
  final bool showSuggestions;
  final bool isLoading;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.hintText = "Find your Industry",
    this.onChanged,
    this.onSubmitted,
    this.onMicTap,
    this.onSearchTap,
    this.prefixAsset = "assets/images/search.png",
    this.suffixAsset = "assets/images/mic.png",
    this.fillColor = Colors.white,
    this.borderColor,
    this.showSuffixIcon = true,
    this.suggestions = const [],
    this.onSuggestionTap,
    this.showSuggestions = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final query = controller?.text.trim() ?? '';

    final shouldShowSuggestions =
        showSuggestions &&
            query.length >= 3 &&
            (suggestions.isNotEmpty || isLoading);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
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
              ),
              prefixIcon: InkWell(
                onTap: onSearchTap,
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Image.asset(
                    prefixAsset,
                    width: 20.w,
                    height: 20.h,
                  ),
                ),
              ),
              suffixIcon: showSuffixIcon
                  ? InkWell(
                onTap: onMicTap,
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Image.asset(
                    suffixAsset,
                    width: 20.w,
                    height: 20.h,
                  ),
                ),
              )
                  : null,
              filled: true,
              fillColor: fillColor,
              contentPadding: EdgeInsets.symmetric(
                vertical: 14.h,
                horizontal: 16.w,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.r),
                borderSide: BorderSide(
                  color: borderColor ?? Colors.transparent,
                ),
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
        ),

        if (shouldShowSuggestions)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isLoading
                ? Padding(
              padding: EdgeInsets.all(16.r),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: suggestions.map((suggestion) {
                return InkWell(
                  onTap: () {
                    onSuggestionTap?.call(suggestion);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 13.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 18.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.north_west,
                          size: 15.sp,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
