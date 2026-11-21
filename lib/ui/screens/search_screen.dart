import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/ui/screens/template_detail_screen.dart';
import 'package:mmb_app/ui/screens/widget/search_filter.dart';
import 'package:mmb_app/ui/screens/widget/template_popup.dart';
import 'package:provider/provider.dart';

import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:mmb_app/widgets/button_widget.dart';

import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/search_provider.dart';
import '../industry/widgets/scaffold_widget.dart';
import '../shimmer/app_loading.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(initialQuery: initialQuery),
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

  @override
  void initState() {
    super.initState();
    _searching = context.read<SearchProvider>().controller.text.trim().isEmpty;
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
                    Navigator.pop(context);
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
                                        hintText:
                                            'Search templates, Brand Series...',
                                        hintStyle: TextStyle(
                                          color: sub,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onChanged: provider.onTextChanged,
                                      onSubmitted: (v) {
                                        provider.submit(v);
                                        if (v.trim().isNotEmpty) {
                                          setState(() => _searching = false);
                                        }
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (provider.controller.text.isNotEmpty) {
                                        provider.clearSearch();
                                      } else if (provider.hasSearched) {
                                        setState(() => _searching = false);
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
                if (!_searching)
                  IconButton(
                    icon: Icon(Icons.search_rounded, size: 24, color: fg),
                    onPressed: () => _openSearch(provider),
                  )
                else
                  const SizedBox(width: 12),
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

    return CommonScaffold(
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
            bottom: false,
            child: Column(
              children: [
                // Language filter now lives in the bottom bar.
                const SizedBox(height: 4),
                Expanded(child: _buildBody(context, provider, isDark, fg, sub)),
                // Only shown when result data is on screen (not on the empty/recent,
                // suggestions, loading or no-result states) and keyboard is closed.
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
    final uid = template['uid']?.toString().trim() ?? '';
    final key = template['thumbnail_s3_key']?.toString().trim() ?? '';
    final locked = template['is_locked'] == true;

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    void open() {
      if (uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template UID not available')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateDetailScreen(templateUid: uid),
        ),
      );
    }

    return GestureDetector(
      onTap: open,
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

            // Locked => crown only, not locked => 3-dot menu only
            _buildCardTopBar(context, template, locked: locked, uid: uid),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTopBar(
    BuildContext context,
    Map<String, dynamic> template, {
    required bool locked,
    required String uid,
  }) {
    return Positioned(
      top: 5,
      right: 5,
      child: locked
          ? SizedBox(
              width: 24,
              height: 28,
              child: Image.asset(
                'assets/images/crown.png',
                fit: BoxFit.contain,
              ),
            )
          : SizedBox(
              width: 38,
              height: 25,
              child: TemplateActionPopup(
                isFavorite: true,
                showDownload: false,
                showDelete: false,
                onCustomize: () {
                  if (uid.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TemplateEditScreen(templateUid: uid),
                    ),
                  );
                },
                onDownload: () {},
                onFavorite: () {
                  // TODO: connect your favorite API here
                  // (family uid: template['family_uid'])
                },
              ),
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
                                buttonPress: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/BrowseTemplatesScreen',
                                  );
                                },
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
