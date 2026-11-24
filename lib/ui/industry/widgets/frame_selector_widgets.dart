import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';

import '../../../utils/theme/app.fonts.dart';
import 'frame_helpers.dart';
import 'frame_images.dart';

// ========================================================================
// TABS  (Static / Animated / My Brand Frames)
// ========================================================================

class FrameTabs extends StatelessWidget {
  const FrameTabs({super.key, required this.selected, required this.onChanged});

  static const _titles = ['Static Frames', 'Animated Frames', 'My Brand Frames'];

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _titles.length; i++) ...[
            if (i > 0) SizedBox(width: 20.w),
            _TabItem(
              title: _titles[i],
              isSelected: selected == i,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.black : Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 4.h),
          if (isSelected)
            Container(
              height: 3.h,
              width: 60.w,
              decoration: BoxDecoration(
                color: kBrandRed,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
        ],
      ),
    );
  }
}

// ========================================================================
// CATEGORY CHIPS  (Branding / Promotional ...)
// ========================================================================

class FrameCategoryChips extends StatelessWidget {
  const FrameCategoryChips({
    super.key,
    required this.categories,
    required this.isLoading,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<dynamic> categories;
  final bool isLoading;

  /// -1 = no category selected
  final int selectedIndex;
  final void Function(int index, String slug) onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      if (!isLoading) return const SizedBox.shrink();
      return SizedBox(
        height: 40.h,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        for (var i = 0; i < categories.length; i++)
          _buildChip(categories[i], i),
      ],
    );
  }

  Widget _buildChip(dynamic category, int index) {
    final title = pick(category, [
      (c) => c.name,
      (c) => c.title,
      (c) => c.label,
    ]);
    final slug = pick(category, [
      (c) => c.slug,
      (c) => c.uid,
      (c) => c.id,
      (c) => c.name,
    ]);
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTap(index, slug),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A4A4A) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade400,
          ),
        ),
        child: AppText(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: AppFontSize.fontSize14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ========================================================================
// FRAMES STRIP  (horizontal list of frame thumbnails)
// ========================================================================

class FramesStrip extends StatelessWidget {
  const FramesStrip({
    super.key,
    required this.frames,
    required this.selectedIndex,
    required this.isLoading,
    required this.error,
    required this.onTap,
    required this.onRetry,
  });

  final List<dynamic> frames;
  final int selectedIndex;
  final bool isLoading;
  final String? error;
  final void Function(int index, dynamic frame) onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _buildEmpty();
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: frames.length,
      itemBuilder: (context, index) => _FrameItem(
        frame: frames[index],
        isSelected: selectedIndex == index,
        onTap: () => onTap(index, frames[index]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            error ?? 'No frames available',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
          ),
          if (error != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _FrameItem extends StatelessWidget {
  const _FrameItem({
    required this.frame,
    required this.isSelected,
    required this.onTap,
  });

  final dynamic frame;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? kBrandRed : Colors.grey.shade300,
                    width: isSelected ? 2 : 1.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.grey.shade50),
                      FrameImage(url: frameThumbUrl(frame), fit: BoxFit.fill),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            AppText(
              frameLabel(frame),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
