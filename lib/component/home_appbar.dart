import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String businessCategory;
  final String notificationCount;
  final VoidCallback? onMagicWandTap;
  final VoidCallback? onNotificationTap;

  const HomeCustomAppBar({
    super.key,
    this.businessCategory = "Cake and Sweets",
    this.notificationCount = "2",
    this.onMagicWandTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 SharedPreferences-la irundhu saved Name & Image path-ai fetch panrom
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        String businessName = "Business Name";
        String? savedImagePath;

        if (snapshot.hasData) {
          final prefs = snapshot.data!;
          // Save aana business name-ai eduthu varrom
          String? name = prefs.getString('saved_business_name');
          if (name != null && name.isNotEmpty) {
            businessName = name;
          }
          // Save aana image path-ai eduthu varrom
          savedImagePath = prefs.getString('saved_business_image_path');
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // 1. BUSINESS LOGO (Circular Avatar - Supports File & Asset)
                Container(
                  height: 48.h,
                  width: 48.w,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: savedImagePath != null && savedImagePath.isNotEmpty
                        ? Image.file(
                      File(savedImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        "assets/images/BName.png",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE91E63),
                          child: const Icon(Icons.business, color: Colors.white),
                        ),
                      ),
                    )
                        : Image.asset(
                      "assets/images/BName.png",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE91E63),
                        child: const Icon(Icons.business, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // 2. SAVED BUSINESS NAME & CATEGORY SUBTITLE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        businessName, // 🚀 SharedPreferences-la irundhu vantha name
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        businessCategory,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 3. MAGIC WAND ICON
                InkWell(
                  onTap: onMagicWandTap,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    height: 40.h,
                    width: 40.w,
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECEE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_fix_high_rounded,
                        color: const Color(0xFFE53935),
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 10.w),

                // 4. NOTIFICATION BELL ICON WITH RED BADGE
                InkWell(
                  onTap: onNotificationTap ?? () {
                    Navigator.pushNamed(context, "/NotificationScreen");
                  },
                  borderRadius: BorderRadius.circular(24.r),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 40.h,
                        width: 40.w,
                        padding: EdgeInsets.all(8.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFECEE),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.notifications_rounded,
                            color: const Color(0xFFE53935),
                            size: 22.sp,
                          ),
                        ),
                      ),
                      if (notificationCount.isNotEmpty)
                        Positioned(
                          top: -2.h,
                          left: -2.w,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 18.w,
                              minHeight: 18.h,
                            ),
                            child: Center(
                              child: Text(
                                notificationCount,
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
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(65.h);
}
