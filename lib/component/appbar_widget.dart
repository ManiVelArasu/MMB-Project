import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../network/provider/custom_theme_provider.dart'; // Ungaloda path-ku etha maadhiri import pannikonga

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;

  /// Right Icon
  final bool showRightIcon;
  final VoidCallback? onRightIconTap;
  final String? badgeCount;

  /// Action Text
  final bool showActionText;
  final String actionText;
  final VoidCallback? onActionTextTap;

  /// Back Button
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    this.title = "Business Frames",
    this.showTitle = true,

    // Back
    this.onBackPressed,

    // Right Icon
    this.showRightIcon = true,
    this.onRightIconTap,
    this.badgeCount = "2",

    // Action Text
    this.showActionText = false,
    this.actionText = "",
    this.onActionTextTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16.w,
      title: Row(
        children: [
          /// Back Button
          InkWell(
            onTap: onBackPressed ?? () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24.r),
            child: Container(
              height: 42.h,
              width: 42.w,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          /// Title
          if (showTitle)
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
        ],
      ),

      /// Right Side
      actions: [
        /// Action Text
        if (showActionText)
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: InkWell(
              onTap: onActionTextTap,
              borderRadius: BorderRadius.circular(8.r),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    actionText,
                    style: theme.titleMedium?.copyWith(
                      color: isDark ? Colors.blueAccent : const Color(0xFF1E2E5F),
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),

        /// Right Icon
        if (showRightIcon)
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: InkWell(
              onTap: onRightIconTap,
              borderRadius: BorderRadius.circular(24.r),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    child: Icon(
                      Icons.layers_rounded,
                      color: const Color(0xFFE53935),
                      size: 30.sp,
                    ),
                  ),

                  /// Badge
                  if (badgeCount != null)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.red.shade800 : const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18.w,
                          minHeight: 18.h,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h);
}