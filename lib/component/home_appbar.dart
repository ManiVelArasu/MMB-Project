import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/core/api/api_endpoints.dart';
import 'package:provider/provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../network/provider/getMe_provider.dart';

class HomeCustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String notificationCount;
  final VoidCallback? onMagicWandTap;
  final VoidCallback? onNotificationTap;

  const HomeCustomAppBar({
    super.key,
    this.notificationCount = "2",
    this.onMagicWandTap,
    this.onNotificationTap,
  });

  @override
  State<HomeCustomAppBar> createState() => _HomeCustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(65.h);
}

class _HomeCustomAppBarState extends State<HomeCustomAppBar> {
  @override
  void initState() {
    super.initState();

    // Screen open aagumbothu Business API call
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    debugPrint("🏢 HOME APP BAR → Loading Business API...");

    final success = await CommonProvider.instance.loadBusiness(
      forceRefresh: true,
    );

    if (!mounted) return;

    if (success) {
      final business = CommonProvider.instance.business;

      debugPrint("======================================");
      debugPrint("✅ HOME BUSINESS API SUCCESS");
      debugPrint("Business UID  : ${business?.uid}");
      debugPrint("Business Name : ${business?.name}");
      debugPrint("Logo S3 Key   : ${business?.logoS3Key}");
      debugPrint("Industry      : ${business?.businessCategory?.name}");
      debugPrint("Industry Slug : ${business?.businessCategory?.slug}");
      debugPrint("======================================");
    } else {
      debugPrint(
        "❌ HOME BUSINESS API FAILED: "
        "${CommonProvider.instance.businessError}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<CustomThemeProvider>();

    final isDark = themeProvider.isDarkMode;

    final commonProvider = context.watch<CommonProvider>();

    final business = commonProvider.business;

    final String businessName = business?.name?.isNotEmpty == true
        ? business!.name!
        : "Business Name";

    final String businessCategory =
        business?.businessCategory?.name?.isNotEmpty == true
        ? business!.businessCategory!.name!
        : "Business Category";

    final String? logoS3Key = business?.logoS3Key;

    debugPrint("🏢 Business Name : $businessName");

    debugPrint("🏷️ Industry : $businessCategory");

    debugPrint("🖼️ Logo S3 Key : $logoS3Key");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // =================================================
            // BUSINESS LOGO
            // =================================================

            SizedBox(
              width: 50.w,
              height: 50.w,
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: logoS3Key != null && logoS3Key.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: getS3ImageUrl(logoS3Key),

                        cacheKey: logoS3Key,

                        width: 50.w,
                        height: 50.w,

                        fit: BoxFit.cover,

                        placeholder: (context, url) {
                          return _defaultLogo();
                        },

                        errorWidget: (context, url, error) {
                          debugPrint("❌ Logo load failed: $error");

                          debugPrint("Logo URL: $url");

                          return _defaultLogo();
                        },
                      )
                    : _defaultLogo(),
              ),
            ),

            SizedBox(width: 12.w),

            // =================================================
            // BUSINESS NAME + INDUSTRY
            // =================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    businessName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.h),

                  AppText(
                    businessCategory,
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.w),

            // =================================================
            // NOTIFICATION
            // =================================================
            InkWell(
              onTap:
                  widget.onNotificationTap ??
                  () {
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
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A1A1C)
                          : const Color(0xFFFFECEE),
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

                  if (widget.notificationCount.isNotEmpty)
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
                          child: AppText(
                            widget.notificationCount,
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
  }

  Widget _defaultLogo() {
    return Image.asset(
      "assets/images/BName.png",
      width: 50.w,
      height: 50.w,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50.w,
          height: 50.w,
          color: const Color(0xFFE91E63),
          child: const Icon(Icons.business, color: Colors.white),
        );
      },
    );
  }
}

String getS3ImageUrl(String key) {
  return "${ApiEndpoints.cdnImageUrl}/$key";
}
