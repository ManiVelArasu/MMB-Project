import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/theme/app.colors.dart';

class ShareItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const ShareItem(this.title, this.icon, {this.onTap});
}

class CommonShareBottomSheet {
  static void show({
  required BuildContext context,
  required bool isDark,
  required VoidCallback onDownload,
  required VoidCallback onInstagram,
  required VoidCallback onFacebook,
  required VoidCallback onX,
  required VoidCallback onLinkedIn,
  required VoidCallback onPinterest,
  required VoidCallback onBoost,
  required VoidCallback onWhatsApp,
  required VoidCallback onMessenger,
  required VoidCallback onDrive,
  required VoidCallback onCopyLink,
  required VoidCallback onCaption,
  required VoidCallback onSchedule,
  }) {
  final shareItems = <ShareItem>[
  ShareItem('Download', Icons.download_rounded,
  onTap: onDownload),
  ShareItem('Instagram', Icons.camera_alt_rounded,
  onTap: onInstagram),
  ShareItem('Facebook', Icons.facebook_rounded,
  onTap: onFacebook),
  ShareItem('X (Twitter)', Icons.close_rounded,
  onTap: onX),
  ShareItem('LinkedIn', Icons.link_rounded,
  onTap: onLinkedIn),
  ShareItem('Pinterest', Icons.push_pin_rounded,
  onTap: onPinterest),
  ShareItem('Boost', Icons.rocket_launch_rounded,
  onTap: onBoost),
  ];

  final messageItems = <ShareItem>[
  ShareItem('WhatsApp', Icons.chat_rounded,
  onTap: onWhatsApp),
  ShareItem('Messenger', Icons.message_rounded,
  onTap: onMessenger),
  ShareItem('Drive', Icons.drive_file_move_rounded,
  onTap: onDrive),
  ShareItem('Link', Icons.link_rounded,
  onTap: onCopyLink),
  ];

  final manageItems = <ShareItem>[
  ShareItem('Caption', Icons.description_rounded,
  onTap: onCaption),
  ShareItem('Schedule', Icons.calendar_month_rounded,
  onTap: onSchedule),
  ShareItem('Link', Icons.link_rounded,
  onTap: onCopyLink),
  ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Text(
                        'Share',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkBlack,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _section(
                    context: sheetContext,
                    items: shareItems ?? _defaultShareItems,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _section(
                    context: sheetContext,
                    title: 'Message',
                    items: messageItems ?? _defaultMessageItems,
                    isDark: isDark,
                  ),
                  SizedBox(height: 16.h),
                  _section(
                    context: sheetContext,
                    title: 'Manage',
                    items: manageItems ?? _defaultManageItems,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static final List<ShareItem> _defaultShareItems = [
    ShareItem('Download', Icons.download_rounded),
    ShareItem('Instagram', Icons.camera_alt_rounded),
    ShareItem('Facebook', Icons.facebook_rounded),
    ShareItem('X (Twitter)', Icons.close_rounded),
    ShareItem('LinkedIn', Icons.link_rounded),
    ShareItem('Pinterest', Icons.push_pin_rounded),
    ShareItem('Boost', Icons.rocket_launch_rounded),
  ];

  static final List<ShareItem> _defaultMessageItems = [
    ShareItem('WhatsApp', Icons.chat_rounded),
    ShareItem('Messenger', Icons.message_rounded),
    ShareItem('Drive', Icons.drive_file_move_rounded),
    ShareItem('Link', Icons.link_rounded),
  ];

  static final List<ShareItem> _defaultManageItems = [
    ShareItem('Caption', Icons.description_rounded),
    ShareItem('Schedule', Icons.calendar_month_rounded),
    ShareItem('Link', Icons.link_rounded),
  ];

  static Widget _section({
    required BuildContext context,
    required List<ShareItem> items,
    required bool isDark,
    String? title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.darkBlack,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16.h,
            crossAxisSpacing: 8.w,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: item.onTap == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      item.onTap!();
                    },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF303030)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      item.icon,
                      size: 25.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
