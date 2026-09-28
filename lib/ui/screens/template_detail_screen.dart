import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:provider/provider.dart';

import '../../Api Model/templates_view.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/template_detail_provider.dart';
import '../../utils/theme/app.colors.dart';

class TemplateDetailScreen extends StatelessWidget {
  final String categorySlug;

  const TemplateDetailScreen({super.key, required this.categorySlug});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          TemplateDetailProvider()..getTemplatesByCategory(categorySlug),
      child: const _TemplateDetailBody(),
    );
  }
}

class _TemplateDetailBody extends StatelessWidget {
  const _TemplateDetailBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TemplateDetailProvider>();
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          _formatCategoryName(provider.categorySlug ?? ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: SvgPicture.asset(
              "assets/icons/translate.svg",
              colorFilter: ColorFilter.mode(
                isDark ? Colors.white70 : Colors.black87,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {},
          ),

          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              _showSearchDialog(context, isDark);
            },
          ),

          IconButton(
            icon: Icon(
              Icons.download,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: provider.isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),

                          // =====================================================
                          // TOP BUSINESS IMAGE / BANNER
                          // =====================================================
                          _buildTopBanner(
                            context,
                            provider.selectedResizeSize,
                            isDark,
                          ),

                          SizedBox(height: 12.h),

                          // =====================================================
                          // PAGE INDICATORS
                          // =====================================================
                          _buildPageIndicators(provider, isDark),

                          SizedBox(height: 12.h),

                          // =====================================================
                          // RESIZE + EDIT
                          // =====================================================
                          _buildActionButtons(context, provider, isDark),

                          SizedBox(height: 18.h),

                          // =====================================================
                          // CONTENT
                          // =====================================================
                          _buildDynamicBottomContent(
                            context,
                            provider,
                            provider.selectedIndex,
                            isDark,
                          ),

                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),

                  // =============================================================
                  // BOTTOM NAVIGATION
                  // =============================================================
                  _buildBottomNavigation(context, provider, isDark),
                ],
              ),
      ),
    );
  }

  // =====================================================================
  // PAGE INDICATORS
  // =====================================================================

  Widget _buildPageIndicators(TemplateDetailProvider provider, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isSelected = provider.selectedIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: isSelected ? 24.w : 6.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10.r),
          ),
        );
      }),
    );
  }

  // =====================================================================
  // ACTION BUTTONS
  // =====================================================================

  Widget _buildActionButtons(
    BuildContext context,
    TemplateDetailProvider provider,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              showResizeBottomSheet(context, isDark);
            },
            icon: const Icon(Icons.aspect_ratio, color: Colors.red, size: 18),
            label: Text(
              "RESIZE",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF2A1A1C)
                  : const Color(0xFFFFECEE),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: provider.templates.isEmpty
                ? null
                : () {
                    Navigator.pushNamed(
                      context,
                      "/TemplateEditScreen",
                      arguments: provider.selectedResizeSize,
                    );
                  },
            icon: const Icon(Icons.edit, color: Colors.red, size: 18),
            label: Text(
              "EDIT",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF2A1A1C)
                  : const Color(0xFFFFECEE),
              disabledBackgroundColor: isDark
                  ? const Color(0xFF222222)
                  : Colors.grey.shade200,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // DYNAMIC CONTENT
  // =====================================================================

  Widget _buildDynamicBottomContent(
    BuildContext context,
    TemplateDetailProvider provider,
    int selectedIndex,
    bool isDark,
  ) {
    if (selectedIndex == 0) {
      return _buildImageSection(context, provider, isDark);
    }

    if (selectedIndex == 1) {
      return _buildVideoSection(context, provider, isDark);
    }

    if (selectedIndex == 2) {
      return _buildPostSizeSection(context, provider, isDark);
    }

    return _buildCategoryInfo(context, provider, isDark);
  }

  // =====================================================================
  // IMAGE SECTION
  // =====================================================================

  Widget _buildImageSection(
    BuildContext context,
    TemplateDetailProvider provider,
    bool isDark,
  ) {
    final templates = provider.imageTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Image Templates", templates.length, isDark),

        SizedBox(height: 10.h),

        if (provider.isLoading)
          _buildLoadingWidget(isDark)
        else if (templates.isEmpty)
          _buildEmptyWidget(
            "No image templates found",
            Icons.image_not_supported_outlined,
            isDark,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templates.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final template = templates[index];

              return _buildTemplateCard(
                context,
                template,
                isDark,
                isVideo: false,
              );
            },
          ),
      ],
    );
  }

  // =====================================================================
  // VIDEO SECTION
  // =====================================================================

  Widget _buildVideoSection(
    BuildContext context,
    TemplateDetailProvider provider,
    bool isDark,
  ) {
    final templates = provider.videoTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Video Templates", templates.length, isDark),

        SizedBox(height: 10.h),

        if (provider.isLoading)
          _buildLoadingWidget(isDark)
        else if (templates.isEmpty)
          _buildEmptyWidget(
            "No video templates found",
            Icons.video_library_outlined,
            isDark,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templates.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final template = templates[index];

              return _buildTemplateCard(
                context,
                template,
                isDark,
                isVideo: true,
              );
            },
          ),
      ],
    );
  }

  // =====================================================================
  // POST SIZE
  // =====================================================================

  Widget _buildPostSizeSection(
    BuildContext context,
    TemplateDetailProvider provider,
    bool isDark,
  ) {
    final templates = provider.allTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Post Size Templates", templates.length, isDark),

        SizedBox(height: 10.h),

        if (provider.isLoading)
          _buildLoadingWidget(isDark)
        else if (templates.isEmpty)
          _buildEmptyWidget(
            "No templates found",
            Icons.collections_outlined,
            isDark,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templates.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final template = templates[index];

              final type = template.templateType?.toLowerCase().trim() ?? "";

              final isVideo = type == "video" || type == "videos";

              return _buildTemplateCard(
                context,
                template,
                isDark,
                isVideo: isVideo,
              );
            },
          ),
      ],
    );
  }

  // =====================================================================
  // TEMPLATE CARD
  // =====================================================================
  String _formatCategoryName(String slug) {
    if (slug.trim().isEmpty) {
      return "Templates";
    }

    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Widget _buildTemplateCard(
    BuildContext context,
    TemplatesListView template,
    bool isDark, {
    required bool isVideo,
  }) {
    return GestureDetector(
      onTap: () {
        final templateUid = template.uid?.trim() ?? '';
        print(templateUid);
        if (templateUid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template UID not available')),
          );

          return;
        }
        debugPrint("Selected template UID: ${template.uid}");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditScreen(templateUid: templateUid),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildTemplatePreview(template, isDark),
                  ),

                  // =====================================================
                  // VIDEO ICON
                  // =====================================================
                  if (isVideo)
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),

                  // =====================================================
                  // PREMIUM
                  // =====================================================
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(9.w, 8.h, 9.w, 3.h),
              child: Text(
                template.name ?? "Template",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),

            // ===========================================================
            // TYPE
            // ===========================================================
            Padding(
              padding: EdgeInsets.fromLTRB(9.w, 0, 9.w, 8.h),
              child: Text(
                isVideo ? "Video" : "Image",
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // TEMPLATE PREVIEW
  // =====================================================================

  Widget _buildTemplatePreview(TemplatesListView template, bool isDark) {
    final key = template.thumbnailS3Key?.trim() ?? '';

    final imageUrl = key.isEmpty ? '' : '${ApiEndpoints.cdnImageUrl}/$key';

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF303030) : Colors.grey.shade100,
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return const Center(child: CircularProgressIndicator());
              },
              errorWidget: (context, url, error) {
                return _templateImagePlaceholder(isDark);
              },
            )
          : _templateImagePlaceholder(isDark),
    );
  }

  Widget _templateImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 36.sp,
        color: Colors.grey.shade400,
      ),
    );
  }
  // =====================================================================
  // CATEGORY INFO
  // =====================================================================

  Widget _buildCategoryInfo(
    BuildContext context,
    TemplateDetailProvider provider,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Categories", null, isDark),

        SizedBox(height: 12.h),

        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children:
              [
                "Cakes",
                "Cookies",
                "Smoothie",
                "Brownies",
                "Cupcakes",
                "Muffins",
                "Birthday Special",
                "Sweets",
                "Today Special",
                "Wedding Special",
                "Deal of the Day",
                "Offers",
              ].map((category) {
                return GestureDetector(
                  onTap: () {
                    final slug = _createSlug(category);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TemplateDetailScreen(categorySlug: slug),
                      ),
                    );
                  },
                  child: _buildCategoryChip(category, isDark),
                );
              }).toList(),
        ),
      ],
    );
  }

  // =====================================================================
  // SECTION TITLE
  // =====================================================================

  Widget _buildSectionTitle(String title, int? count, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              "$count",
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
      ],
    );
  }

  // =====================================================================
  // LOADING
  // =====================================================================

  Widget _buildLoadingWidget(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 28.w,
              height: 28.w,
              child: const CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12.h),
            Text(
              "Loading templates...",
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // EMPTY
  // =====================================================================

  Widget _buildEmptyWidget(String title, IconData icon, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 50.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 42.sp,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // CATEGORY CHIP
  // =====================================================================

  Widget _buildCategoryChip(String title, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  // =====================================================================
  // BOTTOM NAVIGATION
  // =====================================================================

  Widget _buildBottomNavigation(
    BuildContext context,
    TemplateDetailProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () {
              provider.setSelectedIndex(0);
            },
            child: _buildBottomNavItem(
              Icons.image,
              "IMAGE",
              provider.selectedIndex == 0,
            ),
          ),

          InkWell(
            onTap: () {
              provider.setSelectedIndex(1);
            },
            child: _buildBottomNavItem(
              Icons.videocam,
              "VIDEO",
              provider.selectedIndex == 1,
            ),
          ),

          InkWell(
            onTap: () {
              provider.setSelectedIndex(2);
            },
            child: _buildBottomNavItem(
              Icons.aspect_ratio,
              "POST SIZE",
              provider.selectedIndex == 2,
            ),
          ),

          InkWell(
            onTap: () {
              provider.setSelectedIndex(3);

              showCategoriesBottomSheet(context, isDark);
            },
            child: _buildBottomNavItem(
              Icons.category,
              "CATEGORIES",
              provider.selectedIndex == 3,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // BOTTOM NAV ITEM
  // =====================================================================

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // TOP BANNER
  // =====================================================================

  Widget _buildTopBanner(BuildContext context, String resizeSize, bool isDark) {
    final provider = context.watch<TemplateDetailProvider>();

    final TemplatesListView? firstTemplate = provider.imageTemplates.isNotEmpty
        ? provider.imageTemplates.first
        : null;

    final String? thumbnail =
        "${ApiEndpoints.cdnImageUrl}/${firstTemplate?.thumbnailS3Key?.toString()}";

    double aspectRatio = 1 / 1;

    if (resizeSize.contains("4:5")) {
      aspectRatio = 4 / 5;
    } else if (resizeSize.contains("9:16")) {
      aspectRatio = 9 / 16;
    } else if (resizeSize.contains("Horizontal")) {
      aspectRatio = 16 / 9;
    }

    // ============================================================
    // API THUMBNAIL
    // ============================================================

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.network(
          thumbnail ?? '',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,

          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },

          errorBuilder: (context, error, stackTrace) {
            return _buildBannerPlaceholder(resizeSize, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder(String resizeSize, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 40.sp,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          SizedBox(height: 8.h),
          Text(
            resizeSize,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  // =====================================================================
  // SEARCH
  // =====================================================================

  void _showSearchDialog(BuildContext context, bool isDark) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF242424) : Colors.white,
          title: Text(
            "Search Templates",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "Search...",
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("CLOSE"),
            ),
            ElevatedButton(
              onPressed: () {
                final query = controller.text.trim();

                debugPrint("Search template: $query");

                Navigator.pop(dialogContext);
              },
              child: const Text("SEARCH"),
            ),
          ],
        );
      },
    );
  }

  // =====================================================================
  // SLUG
  // =====================================================================

  String _createSlug(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

// ========================================================================
// CATEGORIES BOTTOM SHEET
// ========================================================================

void showCategoriesBottomSheet(BuildContext context, bool isDark) {
  final categories = [
    {"name": "Cakes", "slug": "cakes"},
    {"name": "Cookies", "slug": "cookies"},
    {"name": "Smoothie", "slug": "smoothie"},
    {"name": "Brownies", "slug": "brownies"},
    {"name": "Cupcakes", "slug": "cupcakes"},
    {"name": "Muffins", "slug": "muffins"},
    {"name": "Birthday Special", "slug": "birthday-special"},
    {"name": "Sweets", "slug": "sweets"},
    {"name": "Today Special", "slug": "today-special"},
    {"name": "Wedding Special", "slug": "wedding-special"},
    {"name": "Deal of the Day", "slug": "deal-of-the-day"},
    {"name": "Offers", "slug": "offers"},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4.h,
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1A1C)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.red, size: 20.sp),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 10.w,
                    runSpacing: 12.h,
                    children: categories.map((category) {
                      final name = category["name"]!;
                      final slug = category["slug"]!;

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TemplateDetailScreen(categorySlug: slug),
                            ),
                          );
                        },
                        child: _CategoryChip(title: name, isDark: isDark),
                      );
                    }).toList(),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      );
    },
  );
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final bool isDark;

  const _CategoryChip({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

// ========================================================================
// RESIZE BOTTOM SHEET
// ========================================================================

void showResizeBottomSheet(BuildContext context, bool isDark) {
  final templateProvider = context.read<TemplateDetailProvider>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return ChangeNotifierProvider.value(
        value: templateProvider,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Resize Template",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(modalContext);
                      },
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A1C)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                _ResizeOptionItem(
                  title: "Post Square (1:1)",
                  subtitle: "1080 x 1080 px",
                  isDark: isDark,
                ),

                _ResizeOptionItem(
                  title: "Post Portrait (4:5)",
                  subtitle: "1080 x 1350 px",
                  isDark: isDark,
                ),

                _ResizeOptionItem(
                  title: "Story / Reel (9:16)",
                  subtitle: "1080 x 1920 px",
                  isDark: isDark,
                ),

                _ResizeOptionItem(
                  title: "Post Horizontal",
                  subtitle: "1200 x 628 px",
                  isDark: isDark,
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ========================================================================
// RESIZE ITEM
// ========================================================================

class _ResizeOptionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _ResizeOptionItem({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TemplateDetailProvider>();

    final isSelected = provider.selectedResizeSize == title;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4.h),
      leading: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withOpacity(0.1)
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          Icons.aspect_ratio,
          color: isSelected ? Colors.red : Colors.grey,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? Colors.red
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.red)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () {
        provider.setResizeSize(title);
        Navigator.pop(context);
      },
    );
  }
}
