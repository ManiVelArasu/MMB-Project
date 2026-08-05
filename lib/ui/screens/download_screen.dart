import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_mmb/ui/screens/video_widget/video_widget.dart';
import 'package:provider/provider.dart';

import '../../component/custom_widget.dart';
import '../../network/provider/mydownload_provider.dart';
class MyDownloadsScreen extends StatelessWidget {
  const MyDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyDownloadsProvider(),
      child: const MyDownloadsView(),
    );
  }
}

class MyDownloadsView extends StatelessWidget {
  const MyDownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyDownloadsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // TOP APP BAR
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 38.h,
                              width: 38.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFECEE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: const Color(0xFFE53935),
                                size: 20.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          AppText(
                            "My Downloads",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // DOWNLOADS GRID VIEW
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          top: 10.h,
                          bottom: 100.h, // Bottom Floating Pill Padding
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.downloads.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14.w,
                          mainAxisSpacing: 14.h,
                          childAspectRatio: 1.0, // Square Grid items
                        ),
                        itemBuilder: (context, index) {
                          final item = provider.downloads[index];

                          // A) VIDEO CARD
                          if (item.isVideo && item.videoUrl != null) {
                            return BrandVideoCard(
                              videoUrl: item.videoUrl!,
                              thumbnailUrl: item.thumbnailUrl,
                            );
                          }

                          // B) PURE IMAGE CARD (WITH TAP TO FULL SCREEN)
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              item.thumbnailUrl,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: Colors.black12,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Image.asset(
                                  item.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 30.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // FLOATING BOTTOM FILTER PILL BAR
                Positioned(
                  bottom: 20.h,
                  left: 30.w,
                  right: 30.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFilterButton(
                          title: "IMAGE",
                          icon: Icons.image_rounded,
                          isSelected:
                          provider.selectedFilter == DownloadFilter.image,
                          onTap: () => provider.setFilter(DownloadFilter.image),
                        ),
                        _buildFilterButton(
                          title: "VIDEO",
                          icon: Icons.videocam_rounded,
                          isSelected:
                          provider.selectedFilter == DownloadFilter.video,
                          onTap: () => provider.setFilter(DownloadFilter.video),
                        ),
                        _buildFilterButton(
                          title: "POST SIZE",
                          icon: Icons.aspect_ratio_rounded,
                          isSelected:
                          provider.selectedFilter ==
                              DownloadFilter.postSize,
                          onTap: () =>
                              provider.setFilter(DownloadFilter.postSize),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Filter Button Helper Widget
  Widget _buildFilterButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade400,
              size: 20.sp,
            ),
            SizedBox(height: 2.h),
            AppText(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full Screen Zoomable Image Dialog
  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Zoomable Image
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

              // Top Right Close Button
              Positioned(
                top: 40.h,
                right: 20.w,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 36.h,
                    width: 36.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}