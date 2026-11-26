import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';

import 'brand_form.dart';
import 'frame_content.dart';
import 'frame_helpers.dart';
import 'frame_images.dart';

/// Main preview banner of the selected frame.
///
///  - [content] != null -> frame drawn from its `content` (logo / phone /
///    website / email / name are replaced by the [form] values)
///  - otherwise         -> frame image from frames/{id}
///  - [hasFrame] false  -> default demo banner
class FramePreview extends StatelessWidget {
  const FramePreview({
    super.key,
    required this.height,
    required this.hasFrame,
    required this.imageUrl,
    required this.content,
    required this.isLoading,
    required this.showLegacyOverlay,
    required this.form,
    required this.logoUrl,
    required this.defaultPhone,
    required this.defaultEmail,
  });

  final double height;
  final bool hasFrame;
  final String imageUrl;
  final FrameContent? content;
  final bool isLoading;

  /// Branded frame without `content`: logo / phone / website are drawn as a
  /// simple overlay on the image.
  final bool showLegacyOverlay;

  final BrandForm form;
  final String logoUrl;
  final String defaultPhone;
  final String defaultEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.white)),
            if (hasFrame)
              Positioned.fill(
                child: content != null
                    ? _buildContentFrame(content!)
                    : FrameImage(url: imageUrl, fit: BoxFit.fill),
              ),
            if (isLoading)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (showLegacyOverlay) ..._buildLegacyOverlay(),
            if (!hasFrame) ..._buildDefaultBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentFrame(FrameContent frameContent) {
    return FrameContentView(
      content: frameContent,
      showSlots: form.enabled,
      slotTexts: form.slotTexts,
      // No logoBuilder: the logo / whatsapp / website images that are inside
      // the frame `content` are drawn exactly as the designer made them.
    );
  }

  // ------------------------------------------------------------------
  // OVERLAY for branded frames without content
  // ------------------------------------------------------------------

  List<Widget> _buildLegacyOverlay() {
    final phone = form.phone.text.trim();
    final site = form.website.text.trim();

    return [
      // logo - top right
      Positioned(
        top: 10.h,
        right: 10.w,
        child: BrandAvatar(file: form.logo, url: logoUrl, height: 34.h),
      ),

      // mobile number - bottom left
      if (phone.isNotEmpty)
        Positioned(
          left: 10.w,
          bottom: 10.h,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF2EAD33),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone, size: 12.sp, color: Colors.white),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EAD33),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: AppText(
                  phone,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

      // website - bottom right
      if (site.isNotEmpty)
        Positioned(
          right: 10.w,
          bottom: 10.h,
          child: Row(
            children: [
              Icon(
                Icons.language,
                size: 16.sp,
                color: const Color(0xFF1E3A8A),
              ),
              SizedBox(width: 4.w),
              AppText(
                site,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  // ------------------------------------------------------------------
  // DEFAULT BANNER (no frame from the API yet)
  // ------------------------------------------------------------------

  List<Widget> _buildDefaultBanner() {
    return [
      Positioned(
        top: 20.h,
        left: 16.w,
        child: Image.asset("assets/images/abslogo.png", height: 40.h),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        left: 80.w,
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0066FF),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _bannerItem(
                Icons.phone,
                defaultPhone.isEmpty ? "+91 9876543210" : defaultPhone,
              ),
              _bannerItem(
                Icons.email,
                defaultEmail.isEmpty ? "sarahsteve@gmail.com" : defaultEmail,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _bannerItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 12.sp),
        SizedBox(width: 4.w),
        AppText(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// "Selected Brand Frame  -  Enable/Disable" bar above the preview.
class BrandHeaderBar extends StatelessWidget {
  const BrandHeaderBar({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          AppText(
            'Selected Brand Frame',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          AppText(
            'Enable/Disable',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 6.w),
          Switch(
            value: enabled,
            activeTrackColor: kBrandRed,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}