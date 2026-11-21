import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/ui/screens/widget/empty_state.dart';
import 'package:mmb_app/ui/screens/widget/favorite_button.dart';
import 'package:mmb_app/ui/screens/widget/search_filter.dart';
import 'package:provider/provider.dart';

import '../../Api Model/Template_model.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/home_screen_provider.dart';
import '../../network/provider/search_provider.dart';
import '../../network/provider/template_detail_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../utils/theme/app.fonts.dart';
import '../shimmer/app_loading.dart';
import '../shimmer/template_detail_shimmer.dart';

// ========================================================================
// SHARED HELPERS
// ========================================================================

const _kRed = Color(0xFFE53935);

Color _tint(bool isDark) =>
    isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE);

String _imageUrl(String? key) {
  final k = key?.trim() ?? '';
  if (k.isEmpty) return '';
  return k.startsWith('http') ? k : '${ApiEndpoints.cdnImageUrl}/$k';
}

String _formatCategoryName(String slug) {
  if (slug.trim().isEmpty) return 'Templates';
  return slug
      .replaceAll('-', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

// ========================================================================
// SIZE HELPERS  (sizes always come from the API, nothing is hardcoded)
// `provider.selectedResizeSize` stores a key like "1080x1920"
// ========================================================================

class _SizeOption {
  final String label;
  final int width;
  final int height;

  const _SizeOption(this.label, this.width, this.height);

  String get key => '${width}x$height';
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

String _ratioLabel(int w, int h) {
  final r = w / h;
  bool near(double v) => (r - v).abs() < 0.02;

  if (near(1.0)) return 'Square (1:1)';
  if (near(4 / 5)) return 'Portrait (4:5)';
  if (near(9 / 16)) return 'Story (9:16)';
  if (near(1.91)) return 'Landscape (1.91:1)';
  if (near(16 / 9)) return 'Landscape (16:9)';

  final g = _gcd(w, h);
  return '${w > h ? 'Landscape' : 'Portrait'} (${w ~/ g}:${h ~/ g})';
}

/// Template's own size (first) + API available_sizes, without duplicates.
List<_SizeOption> _sizeOptionsFor(TemplateModel? t) {
  final list = <_SizeOption>[];
  if (t == null) return list;

  final seen = <String>{};

  void add(int? w, int? h, {bool first = false}) {
    if (w == null || h == null || w <= 0 || h <= 0) return;
    if (!seen.add('${w}x$h')) return;
    final opt = _SizeOption(_ratioLabel(w, h), w, h);
    first ? list.insert(0, opt) : list.add(opt);
  }

  for (final z in t.availableSizes) {
    add(z.width, z.height);
  }
  add(t.templateSize?.width, t.templateSize?.height, first: true);

  return list;
}

String _defaultKeyFor(TemplateModel? t) {
  final w = t?.templateSize?.width;
  final h = t?.templateSize?.height;
  if (w != null && h != null && w > 0 && h > 0) return '${w}x$h';
  final opts = _sizeOptionsFor(t);
  return opts.isNotEmpty ? opts.first.key : '';
}

({double width, double height}) _parseKey(String key) {
  final p = key.split('x');
  if (p.length == 2) {
    final w = double.tryParse(p[0]);
    final h = double.tryParse(p[1]);
    if (w != null && h != null && w > 0 && h > 0) {
      return (width: w, height: h);
    }
  }
  return (width: 1080, height: 1080);
}

String _labelForKey(TemplateModel? t, String key) {
  for (final o in _sizeOptionsFor(t)) {
    if (o.key == key) return o.label;
  }
  return key;
}

// ========================================================================
// SCREEN
// ========================================================================

class TemplateDetailScreen extends StatelessWidget {
  /// Category slug -> templates?category=<slug>  (View all)
  final String? categorySlug;

  /// Template uid -> templates/<uid> + category list (template tap)
  final String? templateUid;

  /// Optional category id
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

class _TemplateDetailBody extends StatefulWidget {
  const _TemplateDetailBody();

  @override
  State<_TemplateDetailBody> createState() => _TemplateDetailBodyState();
}

class _TemplateDetailBodyState extends State<_TemplateDetailBody> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TemplateDetailProvider>();
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;

    _ensureValidSize(provider);

    final showShimmer =
        !provider.hasLoaded ||
            (provider.isLoading && provider.selectedTemplate == null);
    final showOverlayLoader =
        provider.isLoading && provider.hasLoaded && !showShimmer;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(provider, isDark),
      body: SafeArea(
        child: AppLoadingView(
          isInitialLoading: showShimmer,
          isRefreshing: showOverlayLoader,
          isDark: isDark,
          skeleton: TemplateDetailShimmer(isDark: isDark),
          child: provider.selectedTemplate == null
              ? _buildEmptyState(isDark)
              : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      _buildTopBanner(provider, isDark),
                      SizedBox(height: 12.h),
                      _buildActionRow(provider, isDark),

                      SizedBox(height: 18.h),
                      _buildContent(provider, isDark),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              // Always visible (IMAGE / VIDEO / LANGUAGE / POST SIZE /
              // CATEGORIES).
              _buildBottomBar(provider, isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps the selected size valid for the current template.
  void _ensureValidSize(TemplateDetailProvider provider) {
    final opts = _sizeOptionsFor(provider.selectedTemplate);
    if (opts.isEmpty || opts.any((o) => o.key == provider.selectedResizeSize)) {
      return;
    }
    final fallback = _defaultKeyFor(provider.selectedTemplate);
    if (fallback.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => provider.setResizeSize(fallback),
    );
  }

  // =====================================================================
  // APP BAR
  // =====================================================================

  PreferredSizeWidget _buildAppBar(
      TemplateDetailProvider provider,
      bool isDark,
      ) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: _AppBarButton(
          isDark: isDark,
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: _kRed, size: 20),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: AppText(
          _formatCategoryName(provider.categorySlug ?? ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSize.fontSize22,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.appWhite : AppColors.appBlack,
          ),
        ),
      ),
      actions: [
        _AppBarButton(
          isDark: isDark,
          onTap: () {
            // TODO: translate action
          },
          child: Image.asset(
            'assets/images/translate_image.png',
            width: 20,
            height: 20,
          ),
        ),
        const SizedBox(width: 10),
        _AppBarButton(
          isDark: isDark,
          onTap: () => Navigator.pushNamed(context, '/SearchScreen'),
          child: const Icon(Icons.search, color: _kRed, size: 20),
        ),
        const SizedBox(width: 10),
        _AppBarButton(
          isDark: isDark,
          onTap: () {
            _onDownloadMyZone(context);
          },
          child: const Icon(
            Icons.file_download_outlined,
            color: _kRed,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return EmptyStateWidget(
      isDark: isDark,
      imagePath: 'assets/images/no_templates.png',
      title: 'No Templates Available',
      message:
      'We’re adding more templates for this category. '
          'Explore other categories to find the right design for your business.',
      primaryButtonText: 'GO BACK',
      secondaryButtonText: 'EXPLORE TEMPLATES',
      onPrimaryPressed: () => Navigator.pop(context),
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  // =====================================================================
  // TOP BANNER
  // =====================================================================

  Widget _buildTopBanner(TemplateDetailProvider provider, bool isDark) {
    final template = provider.selectedTemplate;
    final thumbnail = _imageUrl(template?.thumbnailS3Key);

    final target = _parseKey(provider.selectedResizeSize);
    final aspectRatio = target.width / target.height;
    final label = _labelForKey(template, provider.selectedResizeSize);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
      ),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: LayoutBuilder(
            builder: (context, c) {
              final frameW = c.maxWidth < c.maxHeight * aspectRatio
                  ? c.maxWidth
                  : c.maxHeight * aspectRatio;

              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: frameW,
                  height: frameW / aspectRatio,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: isDark ? Colors.black26 : Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 8),
                    ],
                  ),
                  child: thumbnail.isEmpty
                      ? _bannerPlaceholder(label, isDark)
                      : CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) =>
                        _bannerPlaceholder(label, isDark),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _bannerPlaceholder(String label, bool isDark) {
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
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // ACTION ROW  (FRAME | heart | edit)
  // =====================================================================

  Widget _buildActionRow(TemplateDetailProvider provider, bool isDark) {
    final template = provider.selectedTemplate;

    final heart = FavoriteButton(
      templateId: template?.familyUid?.trim(),
      initialLikes: template?.likesCount,
      isDark: isDark,
      size: 40.w,
      radius: 12.r,
    );

    return Row(
      children: [
        _buildFramePill(isDark),
        const Spacer(),
        heart,
        SizedBox(width: 10.w),
        _roundIconButton(
          isDark: isDark,
          onTap: () => _openEditor(provider),
          child: Image.asset('assets/images/frame_edit.png'),
        ),
      ],
    );
  }

  Widget _roundIconButton({
    required bool isDark,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 40.w,
        height: 40.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _tint(isDark),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: child,
      ),
    );
  }

  Widget _buildFramePill(bool isDark) {
    Widget arrow(IconData icon, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Container(
        width: 18.w,
        height: 18.w,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12.sp, color: Colors.red),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: _tint(isDark),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left, () {
            // TODO: previous frame
          }),
          SizedBox(width: 14.w),
          AppText(
            'FRAME',
            style: TextStyle(
              fontSize: AppFontSize.fontSize13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(width: 14.w),
          arrow(Icons.chevron_right, () {
            // TODO: next frame
          }),
        ],
      ),
    );
  }

  void _openEditor(TemplateDetailProvider provider) {
    final template = provider.selectedTemplate;
    if (template == null) return;

    final uid = template.uid?.trim() ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Template UID not available')),
      );
      return;
    }

    final size = _parseKey(provider.selectedResizeSize);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditScreen(
          templateUid: uid,
          resizeSize: provider.selectedResizeSize,
          canvasWidth: size.width,
          canvasHeight: size.height,
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

    if (names.isEmpty) {
      final n = (t.language?.name ?? '').trim();
      if (n.isNotEmpty) names.add(n);
    }
    return names;
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
            fontSize: AppFontSize.fontSize12,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.red
                : (isDark ? Colors.white70 : AppColors.appGrey),
          ),
        ),
      ),
    );
  }

  Widget _chipGroup(String title, List<Widget> chips, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14.h),
        AppText(
          title,
          style: TextStyle(
            fontSize: AppFontSize.fontSize14,
            fontWeight: FontWeight.w400,
            color: titleColor,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(spacing: 8.w, runSpacing: 8.h, children: chips),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildTemplateInfo(TemplateDetailProvider provider, bool isDark) {
    final template = provider.selectedTemplate;
    if (template == null) return const SizedBox.shrink();

    final name = (template.name ?? '').toString().trim();
    final w = (template.templateSize?.width ?? 0).toInt();
    final h = (template.templateSize?.height ?? 0).toInt();

    var details = '';
    if (w > 0 && h > 0) {
      final orientation = w == h
          ? 'Square'
          : (h > w ? 'Portrait' : 'Landscape');
      details = '$orientation · $w × $h';
    }

    final languages = _languagesOf(template);
    final sizes = _sizeOptionsFor(template);

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
                fontSize: AppFontSize.fontSize18,
                fontWeight: FontWeight.w500,
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
          if (sizes.isNotEmpty)
            _chipGroup(
              'Available Sizes',

              sizes
                  .map(
                    (e) => _infoChip(
                  e.label,
                  isDark,
                  selected: provider.selectedResizeSize == e.key,
                  onTap: () => provider.setResizeSize(e.key),
                ),
              )
                  .toList(),
              AppColors.appGrey,
            ),
          if (languages.isNotEmpty)
            _chipGroup(
              'Available Language',
              languages.map((l) => _infoChip(l, isDark)).toList(),
              AppColors.appGrey,
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // TEMPLATE GRID  (image / video / post size share one builder)
  // =====================================================================

  Widget _buildContent(TemplateDetailProvider provider, bool isDark) {
    switch (provider.selectedIndex) {
      case 1:
        return _buildTemplateGrid(
          provider: provider,
          isDark: isDark,
          title: 'Video Templates',
          templates: provider.gridVideoTemplates,
          emptyText: 'No video templates found',
          emptyIcon: Icons.video_library_outlined,
          isVideo: true,
        );
      case 2:
        return _buildTemplateGrid(
          provider: provider,
          isDark: isDark,
          title: 'All Templates',
          templates: provider.gridAllTemplates,
          emptyText: 'No templates found',
          emptyIcon: Icons.collections_outlined,
        );
      default:
        return _buildTemplateGrid(
          provider: provider,
          isDark: isDark,
          title: 'Image Templates',
          templates: provider.gridImageTemplates,
          emptyText: 'No image templates found',
          emptyIcon: Icons.image_not_supported_outlined,
          isVideo: false,
        );
    }
  }

  Widget _buildTemplateGrid({
    required TemplateDetailProvider provider,
    required bool isDark,
    required String title,
    required List<TemplateModel> templates,
    required String emptyText,
    required IconData emptyIcon,
    bool? isVideo, // null -> decided per template type
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, templates.length, isDark),
        SizedBox(height: 10.h),
        if (provider.isLoading)
          _buildLoadingWidget(isDark)
        else if (templates.isEmpty)
          _buildEmptyWidget(emptyText, emptyIcon, isDark)
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
              final type = template.templateType?.toLowerCase().trim() ?? '';
              return _buildTemplateCard(
                template,
                isDark,
                isVideo: isVideo ?? (type == 'video' || type == 'videos'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTemplateCard(
      TemplateModel template,
      bool isDark, {
        required bool isVideo,
      }) {
    final locked = template.isLocked ?? false;
    final imageUrl = _imageUrl(template.thumbnailS3Key);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTemplateTap(template),
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
                  ? _imagePlaceholder(isDark)
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
                errorWidget: (_, __, ___) => _imagePlaceholder(isDark),
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
                top: 8.h,
                left: 8.w,
                child: Image.asset(
                  'assets/images/crown.png',
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

  void _onTemplateTap(TemplateModel template) {
    final uid = template.uid?.trim() ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Template UID not available')),
      );
      return;
    }

    final provider = context.read<TemplateDetailProvider>();
    provider.selectTemplate(uid);

    final sizeKey = _defaultKeyFor(template);
    if (sizeKey.isNotEmpty) provider.setResizeSize(sizeKey);

    final controller = PrimaryScrollController.maybeOf(context);
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 36.sp,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            title,
            style: TextStyle(
              fontSize: AppFontSize.fontSize15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: AppText(
            '$count',
            style: TextStyle(
              fontSize: AppFontSize.fontSize11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

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
              'Loading templates...',
              style: TextStyle(
                fontSize: AppFontSize.fontSize13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                fontSize: AppFontSize.fontSize13,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // BOTTOM BAR  (always visible)
  // =====================================================================
  Widget _buildBottomBar(TemplateDetailProvider provider, bool isDark) {
    final p = provider;
    final template = p.selectedTemplate;

    final languageOptions = template == null
        ? <SearchFilterOption>[]
        : _languagesOf(template)
        .map((n) => SearchFilterOption(label: n, value: n))
        .toList();

    final sizeOptions = _sizeOptionsFor(template)
        .map(
          (o) => SearchFilterOption(
        label: o.label,
        value: o.key,
        trailing: '${o.width} × ${o.height}',
      ),
    )
        .toList();

    final defaultSizeKey = _defaultKeyFor(template);

    // Same size for every tab icon
    Image tabIcon(String asset) =>
        Image.asset(asset, width: 20, height: 20, fit: BoxFit.contain);

    return FilterBottomBar(
      tabs: [
        FilterBarTab(
          icon: tabIcon('assets/images/gallery.png'),
          label: 'IMAGE',
          selected: p.selectedIndex == 0,
          onTap: () => p.setSelectedIndex(p.selectedIndex == 0 ? 2 : 0),
        ),
        FilterBarTab(
          icon: tabIcon('assets/images/video.png'),
          label: 'VIDEO',
          selected: p.selectedIndex == 1,
          onTap: () => p.setSelectedIndex(p.selectedIndex == 1 ? 2 : 1),
        ),
        FilterBarTab(
          icon: tabIcon('assets/images/translate_black.png'),
          label: 'LANGUAGE',
          selected: p.language != null,
          onTap: () => showSearchOptionSheet(
            context,
            title: 'Available languages',
            allLabel: 'All languages',
            options: languageOptions,
            selected: p.language,
            onChanged: p.setLanguage,
            emptyText: 'No languages for this template',
          ),
        ),
        FilterBarTab(
          icon: tabIcon('assets/images/monitor-mobbile.png'),
          label: 'POST SIZE',
          selected:
          defaultSizeKey.isNotEmpty && p.selectedResizeSize != defaultSizeKey,
          onTap: () => showSearchOptionSheet(
            context,
            title: 'Available sizes',
            allLabel: 'Original size',
            options: sizeOptions,
            selected: p.selectedResizeSize,
            onChanged: (v) => p.setResizeSize(
              (v == null || v.isEmpty) ? defaultSizeKey : v,
            ),
            emptyText: 'No sizes for this template',
          ),
        ),
        FilterBarTab(
          icon: tabIcon('assets/images/educare-(ekt).png'),
          label: 'CATEGORIES',
          selected: p.tag != null,
          onTap: () async {
            await p.loadKeyWords();
            if (!mounted) return;
            showSearchOptionSheet(
              context,
              title: 'Categories',
              allLabel: 'All categories',
              options: p.tagOptions,
              selected: p.tag,
              onChanged: p.setTag,
              emptyText: 'No categories available',
            );
          },
        ),
      ],
    );
  }
}
Future<void> _onDownloadMyZone(BuildContext context) async {
  try {
    final provider = context.read<TemplateDetailProvider>();
    final template = provider.selectedTemplate;

    if (template == null) return;

    final imageUrl = _imageUrl(template.thumbnailS3Key);

    if (imageUrl.isEmpty) {
      throw Exception('Template image not available');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading image...')),
    );

    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      throw Exception('Image download failed');
    }

    await Gal.putImageBytes(
      response.bodyBytes,
      name: 'MMB_${template.uid ?? 'template'}',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image saved to Gallery successfully!'),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download failed: $e')),
    );
  }
}
class _AppBarButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  final Widget child;

  const _AppBarButton({
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _tint(isDark), shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}