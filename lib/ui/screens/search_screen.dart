import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmb_app/component/home_appbar.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';

import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/search_provider.dart';
import '../industry/widgets/scaffold_widget.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  /// Text typed on the home search bar; it is shown here and searched.
  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: _SearchView(initialQuery: initialQuery),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({this.initialQuery = ''});

  final String initialQuery;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );

    // Typed on the home screen → load data here straight away.
    final initial = widget.initialQuery.trim();
    if (initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = context.read<SearchProvider>();
        if (initial.length >= 2) {
          provider.search(initial);
        } else {
          provider.onTextChanged(initial); // suggestions work from 1 char
        }
      });
    }

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        context.read<SearchProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final q = text.trim();
    if (q.length < 2) return;
    _focus.unfocus();
    context.read<SearchProvider>().search(q);
  }

  void _pickSuggestion(SearchSuggestion s) {
    _controller.text = s.query;
    _controller.selection = TextSelection.collapsed(offset: s.query.length);
    _submit(s.query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CustomThemeProvider>().isDarkMode;
    final provider = context.watch<SearchProvider>();
    final Size size = MediaQuery.of(context).size;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final fg = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white54 : Colors.black45;

    return CommonScaffold(
      isDarkMode: isDark,
      appBar: const HomeCustomAppBar(),
      body: Stack(
        children: [
          if (!isDark) // Only show the white/light plan gradient when in light mode
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Image.asset(
                "assets/images/plan_gradient.png",
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                // ---------------- search bar ----------------
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              Image.asset(
                                "assets/images/search.png",
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focus,
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
                                  onChanged: (v) {
                                    setState(() {});
                                    provider.onTextChanged(v);
                                  },
                                  onSubmitted: _submit,
                                ),
                              ),
                              if (_controller.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _controller.clear();
                                    provider.onTextChanged('');
                                    setState(() {});
                                    _focus.requestFocus();
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
                    ],
                  ),
                ),

                // ---------------- body ----------------
                Expanded(child: _buildBody(provider, isDark, fg, sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchProvider p, bool isDark, Color fg, Color sub) {
    if (p.suggestions.isNotEmpty) {
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: p.suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
        itemBuilder: (_, i) {
          final s = p.suggestions[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(_iconFor(s.type), size: 20, color: sub),
            title: _highlight(s.label, _controller.text.trim(), fg),
            trailing: Text(
              _captionFor(s.type),
              style: TextStyle(fontSize: 11, color: sub),
            ),
            onTap: () => _pickSuggestion(s),
          );
        },
      );
    }

    if (p.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE53935)),
      );
    }

    if (p.error != null) {
      return _message(p.error!, sub, retry: () => p.search(p.activeQuery));
    }

    if (!p.hasSearched) {
      return _message('Search for templates, festivals, categories...', sub);
    }

    if (p.results.isEmpty) {
      return _message(
        "No designs for '${p.activeQuery}'. Try another word.",
        sub,
      );
    }

    return GridView.builder(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: p.results.length + (p.isLoadingMore ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (_, i) {
        if (i >= p.results.length) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _resultCard(p.results[i], isDark);
      },
    );
  }

  Widget _resultCard(Map<String, dynamic> t, bool isDark) {
    final uid = t['uid']?.toString().trim() ?? '';
    final key = t['thumbnail_s3_key']?.toString().trim() ?? '';
    final locked = t['is_locked'] == true;

    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    return GestureDetector(
      onTap: () {
        if (uid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template UID not available')),
          );
          return;
        }
        if (locked) {
          Navigator.pushNamed(context, '/PlansAndPricingScreen');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditScreen(templateUid: uid),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
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
            if (locked)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
          ],
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

  /// Bold the part of [label] that matches the typed [query].
  Widget _highlight(String label, String query, Color color) {
    final base = TextStyle(fontSize: 15, color: color);
    final idx = query.isEmpty
        ? -1
        : label.toLowerCase().indexOf(query.toLowerCase());

    if (idx < 0) return Text(label, style: base);

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: label.substring(0, idx)),
          TextSpan(
            text: label.substring(idx, idx + query.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: label.substring(idx + query.length)),
        ],
      ),
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
}
