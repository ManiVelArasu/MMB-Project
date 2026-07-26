import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitle;
  final bool showRightIcon;
  final VoidCallback? onBackPressed;
  final VoidCallback? onRightIconTap;
  final String? badgeCount;

  const CustomAppBar({
    super.key,
    this.title = "Business Frames",
    this.showTitle = true,
    this.showRightIcon = true,
    this.onBackPressed,
    this.onRightIconTap,
    this.badgeCount = "2",
  });

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16.w,
      title: Row(
        children: [
          // Back Button
          InkWell(
            onTap: onBackPressed ?? () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24.r),
            child: Container(
              height: 42.h,
              width: 42.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEE),
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

          // Title Text
          if (showTitle)
            Expanded(
              child: Text(
                title,
                style: theme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                  color: customColor.blackColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      // Right Actions Section (Renders only if showRightIcon is TRUE)
      actions: showRightIcon
          ? [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: InkWell(
            onTap: onRightIconTap,
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
                if (badgeCount != null)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
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
      ]
          : null, // 👈 Returns null if showRightIcon is false
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h);
}