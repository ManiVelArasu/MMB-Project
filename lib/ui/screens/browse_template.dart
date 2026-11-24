import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/ui/screens/widget/download.dart';
import 'package:mmb_app/ui/screens/widget/search_filter.dart';
import 'package:mmb_app/network/provider/search_provider.dart'
    show SearchFilterOption;
import 'package:mmb_app/ui/screens/widget/template_popup.dart';
import 'package:mmb_app/ui/screens/widget/template_single_view_sheet.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:mmb_app/widgets/button_widget.dart';
import 'package:provider/provider.dart';

import '../../Api Model/Template_model.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/browse_template_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/favorite_provider.dart';
import '../industry/widgets/scaffold_widget.dart';
import '../shimmer/app_loading.dart';

/// "Browse Categories" screen: category sheet + IMAGE / VIDEO / POST SIZE
/// tabs + templates grid (HomeRepository.templatesByCategory).
class BrowseTemplatesScreen extends StatelessWidget {
  const BrowseTemplatesScreen({super.key, this.initialSlug, this.initialTag});

  final String? initialSlug;
  final String? initialTag;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    String? slug = initialSlug;
    String? tag = initialTag;

    if (args is Map) {
      final s = args['slug']?.toString().trim() ?? '';
      final t = args['tag']?.toString().trim() ?? '';
      if (s.isNotEmpty) slug = s;
      if (t.isNotEmpty) tag = t;
    }

    return ChangeNotifierProvider(
      create: (_) =>
          BrowseTemplatesProvider(initialSlug: slug, initialTag: tag),
      child: const _BrowseView(),
    );
  }
}

class _BrowseView extends StatelessWidget {
  const _BrowseView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;
    final p = context.watch<BrowseTemplatesProvider>();
    final sub = isDark ? Colors.white54 : Colors.black45;

    return CommonScaffold(
      isDarkMode: isDark,
      appBar: CustomAppBar(title: p.selectedName, showRightIcon: false),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      children: [
                        _buildSearchBar(context),
                        const SizedBox(height: 10),
                        if (p.tag != null) ...[
                          _tagChip(p),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  Expanded(child: _body(context, p, isDark, sub)),
                ],
              ),
            ),
          ),
          _buildBottomNavigation(context, p, isDark),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR (tap opens SearchScreen)
  // ============================================================

  Widget _buildSearchBar(BuildContext context) {
    return Hero(
      tag: 'search_bar_hero',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pushNamed(context, '/SearchScreen'),
          child: AbsorbPointer(
            child: CustomSearchBar(
              hintText: "Search templates, Brand Series...",
              prefixAsset: "assets/images/search.png",
              showSuffixIcon: false,
              borderColor: AppColors.searchBorderColor,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED TAG
  // ============================================================

  Widget _tagChip(BrowseTemplatesProvider p) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 6, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.tagLabel ?? p.tag!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: p.clearTag,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR (search screen-la irukkura adhe FilterBottomBar)
  // ============================================================

  Widget _buildBottomNavigation(
    BuildContext context,
    BrowseTemplatesProvider p,
    bool isDark,
  ) {
    // tab: 0 = image, 1 = video, 2 = ellam (re-tap panna filter off)
    return FilterBottomBar(
      tabs: [
        FilterBarTab(
          icon: Image.asset('assets/images/gallery.png'),
          label: 'IMAGE',
          selected: p.tab == 0,
          onTap: () => p.setTab(p.tab == 0 ? 2 : 0),
        ),
        FilterBarTab(
          icon: Image.asset('assets/images/video.png'),
          label: 'VIDEO',
          selected: p.tab == 1,
          onTap: () => p.setTab(p.tab == 1 ? 2 : 1),
        ),
        FilterBarTab(
          icon: Image.asset('assets/images/educare-(ekt).png'),
          label: 'CATEGORIES',
          selected: p.tag != null,
          onTap: () => _openCategories(context, p),
        ),
      ],
    );
  }

  Future<void> _openCategories(
    BuildContext context,
    BrowseTemplatesProvider p,
  ) async {
    await p.loadKeyWords(); // options ready aana pinnaadi sheet open aagum
    if (!context.mounted) return;

    final options = <SearchFilterOption>[];
    for (final k in p.keyWords) {
      final label = '${k.name}'.trim();
      final slug = '${k.slug}'.trim();
      if (label.isEmpty || label == 'null') continue;
      if (slug.isEmpty || slug == 'null') continue;
      options.add(SearchFilterOption(label: label, value: slug));
    }

    showSearchOptionSheet(
      context,
      title: 'Categories',
      allLabel: 'All categories',
      options: options,
      selected: p.tag,
      emptyText: 'No categories available',
      onChanged: (slug) {
        if (slug == null) {
          p.clearTag();
          return;
        }
        final label = options.firstWhere((o) => o.value == slug).label;
        p.setTag(slug, label: label);
      },
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _body(
    BuildContext context,
    BrowseTemplatesProvider p,
    bool isDark,
    Color sub,
  ) {
    if (p.isLoading) {
      return AppShimmerGrid(
        isDark: isDark,
        itemCount: 8,
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      );
    }

    if (p.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(p.error!, style: TextStyle(color: sub)),
            TextButton(
              onPressed: () {
                final slug = p.selectedSlug;
                if (slug != null) p.selectCategory(slug);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = p.visibleTemplates;

    if (items.isEmpty) return _buildEmptyState(context, p, isDark, sub);

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1, // increase height by lowering this value
      ),
      itemBuilder: (_, i) => _card(context, items[i], isDark),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  static const String _noResultImage = 'assets/images/no_results.png';

  Widget _buildEmptyState(
    BuildContext context,
    BrowseTemplatesProvider p,
    bool isDark,
    Color sub,
  ) {
    final fg = isDark ? Colors.white : Colors.black;
    final hasTag = p.tag != null;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _noResultImage,
                    width: 140,
                    height: 140,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/no_downloads.png',
                      width: 140,
                      height: 140,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'No Templates Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'We couldn\u2019t find any templates here. '
                    'Try a different category or explore our categories.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: fg),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Flexible(
                        child: ButtonWidget(
                          buttonPress: () => Navigator.pop(context),
                          title: 'Browse Categories',
                          textStyle: TextStyle(
                            fontSize: AppFontSize.fontSize14,
                            color: AppColors.appRed,
                            fontWeight: FontWeight.w600,
                          ),
                          textColor: AppColors.appRed,
                          buttonColor: AppColors.appWhite,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.appRed),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      if (hasTag) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: ButtonWidget(
                            buttonPress: p.clearTag,
                            title: 'Clear Filter',
                            textStyle: TextStyle(
                              fontSize: AppFontSize.fontSize14,
                              color: AppColors.appWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            textColor: AppColors.appWhite,
                            buttonColor: AppColors.appRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEMPLATE CARD
  // ============================================================

  Widget _card(BuildContext context, TemplateModel t, bool isDark) {
    final imageUrl = _cdnUrl(t.thumbnailS3Key);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final uid = t.uid?.trim() ?? '';
        if (uid.isEmpty) {
          _showUidMissing(context);
          return;
        }
        TemplateQuickViewSheet.show(context, templateUid: uid);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isEmpty
                  ? _placeholder(isDark)
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(isDark),
                      errorWidget: (_, __, ___) => _placeholder(isDark),
                    ),
              _buildCardTopBar(context, t), // popup on every card
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTopBar(BuildContext context, dynamic template) {
    final locked = (template.isLocked as bool?) ?? false;
    final familyUid = (template.familyUid as String?)?.trim() ?? '';

    return Positioned(
      top: 5.h,
      left: 5.w,
      right: 5.w,
      child: SizedBox(
        height: 38.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // crown only for locked templates
            SizedBox(
              width: 24.w,
              height: 28.h,
              child: locked
                  ? Image.asset('assets/images/crown.png', fit: BoxFit.contain)
                  : null,
            ),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 38.w,
                  height: 25.h,
                  child: TemplateActionPopup(
                    isFavorite: true,
                    showDownload: false,
                    showDelete: false,
                    onCustomize: () => _customizeTemplate(context, template),
                    onDownload: () => _downloadTemplate(template),
                    onFavorite: () => _toggleFavorite(context, familyUid),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS / HELPERS
  // ============================================================

  Future<void> _toggleFavorite(BuildContext context, String familyUid) async {
    if (familyUid.isEmpty) return;

    final ok = await context.read<FavoriteProvider>().toggle(familyUid);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Something went wrong. Try again.')),
      );
    }
  }

  Future<void> _downloadTemplate(dynamic template) async {
    final url = _cdnUrl(template.thumbnailS3Key as String?);
    if (url.isEmpty) return;
    await downloadThumbnail(url);
  }

  /// Opens the quick view (premium templates show the upgrade dialog).
  void _customizeTemplate(BuildContext context, dynamic template) {
    final uid = (template.uid as String?)?.trim() ?? '';
    if (uid.isEmpty) {
      _showUidMissing(context);
      return;
    }

    int? categoryId;
    try {
      final dynamic raw = template.categoryId;
      categoryId = raw is int ? raw : int.tryParse('$raw');
    } catch (_) {
      categoryId = null;
    }

    TemplateQuickViewSheet.show(
      context,
      templateUid: uid,
      categoryId: categoryId,
    );
  }

  String _cdnUrl(String? key) {
    final k = key?.trim() ?? '';
    if (k.isEmpty) return '';
    if (k.startsWith('http://') || k.startsWith('https://')) return k;
    return '${ApiEndpoints.cdnImageUrl}/$k';
  }

  void _showUidMissing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: AppText('Template UID not available')),
    );
  }

  Widget _placeholder(bool isDark) => Container(
    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
    child: Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
  );
}
