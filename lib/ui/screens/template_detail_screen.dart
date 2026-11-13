import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/screens/search_screen.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/ui/screens/widget/empty_state.dart';
import 'package:provider/provider.dart';

import '../../Api Model/Template_model.dart';

import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/template_detail_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import '../shimmer/app_loading.dart';
import '../shimmer/template_detail_shimmer.dart';

class TemplateDetailScreen extends StatelessWidget {
  /// Category slug  → GET templates?category=<slug>      (View all)
  final String? categorySlug;

  /// Template uid   → GET templates/<uid> + category list (template tap)
  final String? templateUid;

  /// Optional category id → templates?category=<id>&limit=9&offset=0
  final int? categoryId;

  const TemplateDetailScreen({
    super.key,
    this.categorySlug,
    this.templateUid,
    this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = TemplateDetailProvider();

        final uid = templateUid?.trim() ?? '';

        if (uid.isNotEmpty) {
          provider.loadByTemplate(uid: uid, categoryId: categoryId);
        } else {
          provider.getTemplatesByCategory(categorySlug ?? '');
        }

        return provider;
      },
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

    // First load (or no template to show yet): shimmer.
    // Later loads with a template already on screen: it stays, and a normal
    // loader shows on top.
    final bool showShimmer =
        !provider.hasLoaded ||
            (provider.isLoading && provider.selectedTemplate == null);
    final bool showOverlayLoader =
        provider.isLoading && provider.hasLoaded && !showShimmer;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,

        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 42.h,
            width: 42.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        title: AppText(
          _formatCategoryName(provider.categorySlug ?? ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSize.fontSize22,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.appBlack,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
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
        // Loader until the first load has FINISHED, so "No templates found"
        // can never flash before the data arrives.
        child: AppLoadingView(
          isInitialLoading: showShimmer,
          isRefreshing: showOverlayLoader,
          isDark: isDark,
          skeleton: TemplateDetailShimmer(isDark: isDark),
          child: provider.selectedTemplate == null
              ? EmptyStateWidget(
            isDark: isDark,
            imagePath: 'assets/images/no_templates.png',
            title: 'No Templates Available',
            message:
            'We’re adding more templates for this category. '
                'Explore other categories to find the right design for your business.',
            primaryButtonText: 'GO BACK',
            secondaryButtonText: 'EXPLORE TEMPLATES',
            onPrimaryPressed: () {
              Navigator.pop(context);
            },
            onSecondaryPressed: () {
              Navigator.pop(context);
            },
          )
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
                      // RESIZE + EDIT
                      // =====================================================
                      _buildActionButtons(context, provider, isDark),

                      SizedBox(height: 16.h),

                      // =====================================================
                      // NAME + DETAILS + SIZES + LANGUAGE
                      // =====================================================
                      _buildTemplateInfo(context, provider, isDark),

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
      ),
    );
  }

  // =====================================================================
  // TEMPLATE INFO  (name · details · available sizes · languages)
  // =====================================================================

  List<String> _languagesOf(TemplateModel t) {
    final names = <String>[];

    for (final l in t.availableLanguages) {
      final n = (l.name ?? l.nativeName ?? '').trim();
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
    }

    // available_languages empty-na current language
    if (names.isEmpty) {
      final n = (t.language?.name ?? '').trim();
      if (n.isNotEmpty) names.add(n);
    }

    return names;
  }

  /// API size (width x height) → RESIZE option title
  String _resizeTitleFor(int? w, int? h) {
    if (w == null || h == null || w <= 0 || h <= 0) {
      return 'Post Square (1:1)';
    }
    if (w == h) return 'Post Square (1:1)';
    if (w > h) return 'Post Horizontal';
    final ratio = w / h;
    return ratio < 0.6 ? 'Story / Reel (9:16)' : 'Post Portrait (4:5)';
  }

  Widget _infoChip(
      String label,
      bool isDark, {
        bool selected = false,
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFECEE)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected
                ? Colors.red
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
        ),
        child: AppText(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.red
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateInfo(
      BuildContext context,
      TemplateDetailProvider provider,
      bool isDark,
      ) {
    final template = provider.selectedTemplate;
    if (template == null) return const SizedBox.shrink();

    final name = (template.name ?? '').toString().trim();

    final w = (template.templateSize?.width ?? 0).toDouble();
    final h = (template.templateSize?.height ?? 0).toDouble();

    String details = '';
    if (w > 0 && h > 0) {
      final orientation = w == h
          ? 'Square'
          : (h > w ? 'Portrait' : 'Landscape');
      details = '$orientation · ${w.toInt()} × ${h.toInt()}';
    }

    final languages = _languagesOf(template);

    // API available_sizes; empty-na default options
    final List<({String label, String resize})> sizes = [
      for (final z in template.availableSizes)
        if ((z.name ?? '').trim().isNotEmpty)
          (label: z.name!.trim(), resize: _resizeTitleFor(z.width, z.height)),
    ];

    if (sizes.isEmpty) {
      sizes.addAll(const [
        (label: 'Square (1:1)', resize: 'Post Square (1:1)'),
        (label: 'Portrait (4:5)', resize: 'Post Portrait (4:5)'),
        (label: 'Story (9:16)', resize: 'Story / Reel (9:16)'),
      ]);
    }

    final titleColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            AppText(
              name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),

          if (details.isNotEmpty) ...[
            SizedBox(height: 2.h),
            AppText(
              details,
              style: TextStyle(fontSize: 12.sp, color: subColor),
            ),
          ],

          SizedBox(height: 14.h),

          AppText(
            'Available Sizes',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: sizes.map((e) {
              return _infoChip(
                e.label,
                isDark,
                selected: provider.selectedResizeSize == e.resize,
                onTap: () => provider.setResizeSize(e.resize),
              );
            }).toList(),
          ),

          if (languages.isNotEmpty) ...[
            SizedBox(height: 14.h),
            AppText(
              'Available Language',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: languages.map((l) => _infoChip(l, isDark)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  ({double width, double height}) _canvasSizeFor(String resizeSize) {
    if (resizeSize.contains("4:5")) {
      return (width: 1080, height: 1350);
    }
    if (resizeSize.contains("9:16")) {
      return (width: 1080, height: 1920);
    }
    if (resizeSize.contains("Horizontal")) {
      return (width: 1200, height: 628);
    }
    // Post Square (1:1) / default
    return (width: 1080, height: 1080);
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
            label: AppText(
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
            onPressed: provider.selectedTemplate == null
                ? null
                : () {
              // Same template that is shown in the top banner
              final template = provider.selectedTemplate!;
              final templateUid = template.uid?.trim() ?? '';

              if (templateUid.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: AppText('Template UID not available'),
                  ),
                );
                return;
              }
              final size = _canvasSizeFor(provider.selectedResizeSize);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateEditScreen(
                    templateUid: templateUid,
                    resizeSize: provider.selectedResizeSize,
                    canvasWidth: size.width,
                    canvasHeight: size.height,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.red, size: 18),
            label: AppText(
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
    return _buildImageSection(context, provider, isDark);
  }

  // =====================================================================
  // IMAGE SECTION
  // =====================================================================

  Widget _buildImageSection(
      BuildContext context,
      TemplateDetailProvider provider,
      bool isDark,
      ) {
    final templates = provider.gridImageTemplates;

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
    final templates = provider.gridVideoTemplates;

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
    final templates = provider.gridAllTemplates;

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
      TemplateModel template,
      bool isDark, {
        required bool isVideo,
      }) {
    print(template.isLocked);
    final locked = template.isLocked ?? false;
    final key = template.thumbnailS3Key?.trim() ?? '';
    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final uid = template.uid?.trim() ?? '';
        if (uid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: AppText('Template UID not available')),
          );
          return;
        }

        // Top banner image replace aagum (grid-la irundhu maarum)
        final provider = context.read<TemplateDetailProvider>();
        provider.selectTemplate(uid);
        provider.setResizeSize(
          _resizeTitleFor(
            template.templateSize?.width,
            template.templateSize?.height,
          ),
        );
        final controller = PrimaryScrollController.maybeOf(context);
        if (controller != null && controller.hasClients) {
          controller.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl.isEmpty
                  ? _templateImagePlaceholder(isDark)
                  : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    _templateImagePlaceholder(isDark),
              ),
            ),
            if (isVideo)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
            if (locked)
              Positioned(
                left: 8.h,
                child: Image.asset(
                  "assets/images/crown.png",
                  width: 28.w,
                  height: 28.h,
                  fit: BoxFit.contain,
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

  // =====================================================================
  // SECTION TITLE
  // =====================================================================

  Widget _buildSectionTitle(String title, int? count, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: AppText(
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
            child: AppText(
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
            AppText(
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
            AppText(
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
              provider.loadKeyWords(); // loads once, sheet updates itself
              _showCategorySheet(context, provider, isDark);
              //   showCategoriesBottomSheet(context, isDark);
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
        AppText(
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

    final TemplateModel? firstTemplate = provider.selectedTemplate;

    final key = firstTemplate?.thumbnailS3Key?.trim() ?? '';

    final String? thumbnail = key.isEmpty
        ? null
        : (key.startsWith('http://') || key.startsWith('https://'))
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    // Selected RESIZE option -> target canvas ratio (same sizes the editor uses).
    final target = _canvasSizeFor(resizeSize);
    final double aspectRatio = target.width / target.height;

    // COMMON CONTAINER: fixed size that never changes when the user picks a
    // different size. The design is fitted INSIDE it (letter-boxed), and only
    // the design frame animates to the new ratio.
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
      ),
      child: AspectRatio(
        aspectRatio: 4 / 5, // fixed container shape
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: LayoutBuilder(
            builder: (context, c) {
              // Largest frame of the chosen ratio that fits the container.
              final double frameW = c.maxWidth < c.maxHeight * aspectRatio
                  ? c.maxWidth
                  : c.maxHeight * aspectRatio;
              final double frameH = frameW / aspectRatio;

              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: frameW,
                  height: frameH,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: isDark ? Colors.black26 : Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 8),
                    ],
                  ),
                  child: thumbnail == null
                      ? _buildBannerPlaceholder(resizeSize, isDark)
                      : Image.network(
                    thumbnail,
                    width: double.infinity,
                    height: double.infinity,
                    // Image is resized to fill the chosen frame.
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
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
            },
          ),
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
          AppText(
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
// SLUG
// =====================================================================
}

// ========================================================================
// CATEGORIES BOTTOM SHEET
// ========================================================================

void _showCategorySheet(
    BuildContext context,
    TemplateDetailProvider p,
    bool isDark,
    ) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return ListenableBuilder(
        listenable: p,
        builder: (_, __) => Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle
                Center(
                  child: Container(
                    height: 4,
                    width: 50,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // title + close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(sheetContext),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A1C)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (p.isKeyWordsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    ),
                  )
                else if (p.keyWords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('No categories found')),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: p.keyWords.map((k) {
                          final name = k.name?.trim() ?? '';
                          if (name.isEmpty) return const SizedBox.shrink();

                          final selected = p.tag == name;

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              //  p.selectTag(name); // sent as `tags`
                            },
                            child: _CategoryChip(
                              title: name,
                              isDark: isDark,
                              selected: selected,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final bool isDark;
  final bool selected;

  const _CategoryChip({
    required this.title,
    required this.isDark,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFFECEE)
            : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: selected
              ? Colors.red
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          width: 1.2,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
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
                    AppText(
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
              ? Colors.red.withValues(alpha: .1)
              : (isDark
              ? Colors.white.withValues(alpha: .05)
              : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          Icons.aspect_ratio,
          color: isSelected ? Colors.red : Colors.grey,
        ),
      ),
      title: AppText(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isSelected
              ? Colors.red
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      subtitle: AppText(
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