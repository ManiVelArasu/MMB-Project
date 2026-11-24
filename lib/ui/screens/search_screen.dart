import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/widget/search_filter.dart';
import 'package:mmb_app/ui/screens/widget/template_popup.dart';
import 'package:mmb_app/ui/screens/widget/template_single_view_sheet.dart';
import 'package:provider/provider.dart';

import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:mmb_app/widgets/button_widget.dart';

import '../../component/custom_searchbar.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/search_provider.dart';
import '../industry/widgets/scaffold_widget.dart';
import '../shimmer/app_loading.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../Api Model/industries.dart';
// TODO: unga project-la IndustryProvider file enga irukko andha path podunga
import '../../network/provider/industry_provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SearchProvider(initialQuery: initialQuery),
        ),
        ChangeNotifierProvider(create: (_) => IndustryProvider()),
      ],
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  // Search field lives inside the app bar. Open by default when nothing has
  // been searched yet; otherwise the bar shows the query + a search icon.
  late bool _searching;

  // Browse Categories grid ippo search screen-layae kaattum
  bool _showCategories = false;
  String _queryBeforeCategories = '';

  @override
  void initState() {
    super.initState();
    _searching = true; // search field eppavum kaattum (hide aagaadhu)
  }

  void _openSearch(SearchProvider provider) {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) provider.focusNode.requestFocus();
    });
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SearchProvider provider,
    bool isDark,
    Color fg,
    Color sub,
  ) {
    final title = provider.hasSearched && provider.activeQuery.isNotEmpty
        ? provider.activeQuery
        : 'Search';

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    if (_showCategories) {
                      _closeCategories(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    height: 40.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A1A1C)
                          : const Color(0xFFFFECEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back,
                        color: Color(0xFFE53935),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: _searching
                      ? Hero(
                          tag: 'search_bar_hero',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.searchBorderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: provider.controller,
                                      focusNode: provider.focusNode,
                                      autofocus: true,
                                      textInputAction: TextInputAction.search,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(
                                          SearchProvider.maxQueryLength,
                                        ),
                                      ],
                                      style: TextStyle(color: fg, fontSize: 15),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: _showCategories
                                            ? 'Search categories...'
                                            : 'Search templates, Brand Series...',
                                        hintStyle: TextStyle(
                                          color: sub,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onChanged: (v) {
                                        // Categories grid-la irundha ingaye filter
                                        if (_showCategories) {
                                          context
                                              .read<IndustryProvider>()
                                              .filterCategories(v);
                                          return;
                                        }
                                        provider.onTextChanged(v);
                                      },
                                      onSubmitted: (v) {
                                        if (_showCategories) {
                                          FocusScope.of(context).unfocus();
                                          return;
                                        }
                                        provider.submit(v);
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (_showCategories) {
                                        provider.controller.clear();
                                        context
                                            .read<IndustryProvider>()
                                            .clearSearch();
                                      } else if (provider
                                          .controller
                                          .text
                                          .isNotEmpty) {
                                        provider.clearSearch();
                                      }
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: sub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;
    final fg = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white54 : Colors.black45;

    return PopScope(
      canPop: !_showCategories,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showCategories) {
          _closeCategories(context);
        }
      },
      child: CommonScaffold(
        isDarkMode: isDark,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context, provider, isDark, fg, sub),
        body: Stack(
          children: [
            if (!isDark)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 300,
                child: Image.asset(
                  'assets/images/plan_gradient.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            SafeArea(
              bottom: true,
              child: Column(
                children: [
                  // Language filter now lives in the bottom bar.
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildBody(context, provider, isDark, fg, sub),
                  ),
                  if (MediaQuery.of(context).viewInsets.bottom == 0 &&
                      provider.suggestions.isEmpty &&
                      !provider.isLoading &&
                      provider.error == null &&
                      provider.results.isNotEmpty)
                    const SearchBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, SearchProvider searchProvider) {
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

  Widget _buildInitialEmptyState(
    BuildContext context,
    SearchProvider provider,
    bool isDark,
    Color fg,
    Color sub,
  ) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Header (small + compact, near the top) ----------
          Center(
            child: Image.asset(
              'assets/images/no_downloads.png',
              width: 90,
              height: 90,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: AppText(
              'What are you looking for?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.fontSize16,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: AppText(
              'Search by industry, occasion or design type.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: sub),
            ),
          ),

          // ---------- Recent searches ----------
          if (provider.recentSearches.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: sub),
                const SizedBox(width: 6),
                Expanded(
                  child: AppText(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: provider.clearRecent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: AppText(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: provider.recentSearches.map((item) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                        onTap: () {
                          provider.controller.text = item;
                          provider.submit(item);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * .55,
                            ),
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize13,
                                color: fg,
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(20),
                        ),
                        onTap: () => provider.removeRecent(item),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: sub,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SearchProvider provider,
    bool isDark,
    Color fg,
    Color sub,
  ) {
    if (_showCategories) {
      return _buildCategoryGrid(context, isDark, fg);
    }

    if (provider.isWaitingForFirstResult && !provider.hasSearched) {
      return _searchShimmer(isDark);
    }

    if (provider.suggestions.isNotEmpty) {
      final query = provider.controller.text.trim();
      final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      final divider = isDark ? Colors.white10 : const Color(0xFFEFEFEF);

      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFEDEDED),
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < provider.suggestions.length; i++) ...[
                  _suggestionTile(
                    provider.suggestions[i],
                    query,
                    isDark,
                    fg,
                    sub,
                    () => provider.pickSuggestion(provider.suggestions[i]),
                  ),
                  if (i != provider.suggestions.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 66,
                      endIndent: 0,
                      color: divider,
                    ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (provider.isLoading) {
      return _searchShimmer(isDark);
    }

    if (provider.error != null) {
      return _message(provider.error!, sub, retry: provider.retry);
    }

    if (!provider.hasSearched && provider.controller.text.trim().isEmpty) {
      return _buildInitialEmptyState(context, provider, isDark, fg, sub);
    }

    if (provider.results.isEmpty) {
      return _buildEmptyState(context, provider, isDark, fg, sub);
    }

    return GridView.builder(
      controller: provider.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: provider.results.length + (provider.isLoadingMore ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (_, index) {
        if (index >= provider.results.length) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _resultCard(context, provider.results[index], isDark);
      },
    );
  }

  Widget _searchShimmer(bool isDark) => AppShimmerGrid(
    isDark: isDark,
    itemCount: 6,
    crossAxisCount: 2,
    childAspectRatio: 0.8,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
  );

  Widget _resultCard(
    BuildContext context,
    Map<String, dynamic> template,
    bool isDark,
  ) {
    final key = template['thumbnail_s3_key']?.toString().trim() ?? '';

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      onTap: () => _openQuickView(context, template),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
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

            // 3-dot menu ella card-kum, crown locked-ku mattum
            _buildCardTopBar(context, template),
          ],
        ),
      ),
    );
  }

  // Card tap + "Customize" rendum inga dhaan varum
  void _openQuickView(BuildContext context, Map<String, dynamic> template) {
    final uid = template['uid']?.toString().trim() ?? '';
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template UID not available')),
      );
      return;
    }

    TemplateQuickViewSheet.show(
      context,
      templateUid: uid,
      categoryId: _categoryIdOf(template),
    );
  }

  // TODO: API response-la category id key vera irundha inga maathunga
  int? _categoryIdOf(Map<String, dynamic> template) {
    final raw = template['category_id'] ?? template['categoryId'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  Widget _buildCardTopBar(BuildContext context, Map<String, dynamic> template) {
    final locked = template['is_locked'] == true;

    return Positioned(
      top: 5,
      left: 5,
      right: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 28,
            child: locked
                ? Image.asset('assets/images/crown.png', fit: BoxFit.contain)
                : null,
          ),
          SizedBox(
            width: 38,
            height: 25,
            child: TemplateActionPopup(
              isFavorite: true,
              showDownload: false,
              showDelete: false,
              onCustomize: () => _openQuickView(context, template),
              onDownload: () {},
              onFavorite: () {
                // TODO: connect your favorite API here
                // (family uid: template['family_uid'])
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(bool isDark) => Container(
    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
    child: Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
  );

  Widget _message(String text, Color color, {VoidCallback? retry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: color),
            ),
            if (retry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: retry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _suggestionTile(
    SearchSuggestion s,
    String query,
    bool isDark,
    Color fg,
    Color sub,
    VoidCallback onTap,
  ) {
    final caption = _captionFor(s.type);
    final soft = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF4F4F6);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(s.type), size: 19, color: sub),
            ),
            const SizedBox(width: 16),
            Expanded(child: _highlight(s.label, query, fg)),
            if (caption.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  caption,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: sub,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BROWSE CATEGORIES (open / close)
  // ============================================================

  void _openCategories(BuildContext context) {
    final provider = context.read<SearchProvider>();
    final ip = context.read<IndustryProvider>();

    _queryBeforeCategories = provider.controller.text; // back-ku restore
    provider.controller.clear();
    ip.clearSearch();

    setState(() => _showCategories = true);
    ip.fetchAssetCategories();
  }

  void _closeCategories(BuildContext context) {
    final provider = context.read<SearchProvider>();
    context.read<IndustryProvider>().clearSearch();

    provider.controller.value = TextEditingValue(
      text: _queryBeforeCategories,
      selection: TextSelection.collapsed(offset: _queryBeforeCategories.length),
    );

    setState(() => _showCategories = false);
  }

  // ============================================================
  // BROWSE CATEGORIES GRID
  // ============================================================

  Widget _buildCategoryGrid(BuildContext context, bool isDark, Color fg) {
    return Consumer<IndustryProvider>(
      builder: (context, ip, _) {
        if (ip.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ip.errorMessage != null) {
          return _message(ip.errorMessage!, fg, retry: ip.fetchAssetCategories);
        }
        final list = ip.categories;
        if (list.isEmpty) {
          return _message('No categories found', fg);
        }
        return GridView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const BouncingScrollPhysics(),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (_, i) => _categoryItem(context, list[i], fg),
        );
      },
    );
  }

  Widget _categoryItem(BuildContext context, Industries c, Color fg) {
    final url = _categoryImageUrl(c);
    final fallback = Icon(Icons.category_outlined, size: 40, color: fg);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openCategory(context, c),
      child: Column(
        children: [
          Expanded(
            child: url.isEmpty
                ? fallback
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox(),
                    errorWidget: (_, __, ___) => fallback,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            (c.name ?? '').toUpperCase(),
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Industries model-la image field name vera irundha inga maathunga
  String _categoryImageUrl(Industries c) {
    final key = (c.iconS3Key ?? '').toString().trim();
    if (key.isEmpty) return '';
    return key.startsWith('http') ? key : '${ApiEndpoints.cdnImageUrl}/$key';
  }

  Future<void> _openCategory(BuildContext context, Industries c) async {
    final ip = context.read<IndustryProvider>();
    ip.selectCategory(c);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_category_name', c.name ?? '');
    await prefs.setString('saved_category_slug', c.slug ?? '');

    if (!context.mounted) return;
    Navigator.pushNamed(context, '/BrowseTemplatesScreen');
  }

  Widget _highlight(String label, String query, Color color) {
    final base = TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w400,
      color: color,
    );
    final index = query.isEmpty
        ? -1
        : label.toLowerCase().indexOf(query.toLowerCase());

    if (index < 0) {
      return Text(
        label,
        style: base,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: label.substring(0, index)),
          TextSpan(
            text: label.substring(index, index + query.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: label.substring(index + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'event':
        return Icons.celebration_outlined;
      case 'category':
        return Icons.category_outlined;
      case 'industry':
        return Icons.business_center_outlined;
      case 'tag':
        return Icons.sell_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  String _captionFor(String type) {
    switch (type) {
      case 'event':
        return 'Festival';
      case 'category':
        return 'Category';
      case 'industry':
        return 'Industry';
      case 'tag':
        return 'Tag';
      case 'design':
        return 'Design';
      default:
        return '';
    }
  }

  // Put the sad-magnifier illustration here (add it to pubspec assets).
  static const String _noResultImage = 'assets/images/no_results.png';

  Widget _buildEmptyState(
    BuildContext context,
    SearchProvider provider,
    bool isDark,
    Color fg,
    Color sub,
  ) {
    final query = provider.activeQuery;
    final filtered = provider.hasActiveFilters;

    return Column(
      children: [
        if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppText(
              filtered
                  ? 'No designs for \u201c$query\u201d with these filters.'
                  : 'No designs for \u201c$query\u201d.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: sub),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          'We couldn\u2019t find any templates matching your search. '
                          'Try a different keyword or explore our categories.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: fg),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Flexible(
                              child: ButtonWidget(
                                buttonPress: () => _openCategories(context),
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
                            const SizedBox(width: 8),
                            Flexible(
                              child: ButtonWidget(
                                buttonPress: filtered
                                    ? provider.clearFilters
                                    : provider.clearSearch,
                                title: filtered
                                    ? 'Clear Filters'
                                    : 'Clear Search',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
