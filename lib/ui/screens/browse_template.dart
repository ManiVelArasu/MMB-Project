import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/ui/screens/search_screen.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';

import '../../Api Model/Template_model.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/browse_template_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../industry/widgets/scaffold_widget.dart';
import '../shimmer/app_loading.dart';

/// "Browse Categories" screen: category dropdown + IMAGES / VIDEOS /
/// POST SIZE tabs + templates grid (HomeRepository.templatesByCategory).
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
                        CustomSearchBar(
                          hintText: "Search templates, Brand Series...",
                          prefixAsset: "assets/images/search.png",
                          suffixAsset: "assets/images/mic.png",
                          borderColor: AppColors.searchBorderColor,
                          showSuffixIcon: false,
                          onChanged: (query) {},
                          onSubmitted: (query) {
                            final q = query.trim();
                            if (q.length < 2) return;

                            FocusManager.instance.primaryFocus?.unfocus();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchScreen(initialQuery: q),
                              ),
                            );
                          },
                        ),
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

          // IMAGE / VIDEO / POST SIZE / CATEGORIES
          _buildBottomNavigation(context, p, isDark),
        ],
      ),
    );
  }

  // ---------------- selected tag ----------------
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
              p.tag!,
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

  // ---------------- categories dropdown ----------------
  Widget _categoryDropdown(
    BuildContext context,
    BrowseTemplatesProvider p,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: p.categories.isEmpty
          ? null
          : () => _showCategorySheet(context, p, isDark),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                p.isCategoriesLoading ? 'Loading...' : 'Categories',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChipsShimmer(bool isDark) {
    const widths = <double>[90, 120, 80, 110, 100, 130, 85, 115, 95, 105];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: AppShimmer(
        isDark: isDark,
        child: Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            for (final w in widths)
              ShimmerBox(width: w, height: 40, radius: 30),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(
    BuildContext context,
    BrowseTemplatesProvider p,
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                    _categoryChipsShimmer(isDark)
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

  // ---------------- bottom navigation ----------------
  Widget _buildBottomNavigation(
    BuildContext context,
    BrowseTemplatesProvider provider,
    bool isDark,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => provider.setTab(0),
            child: _buildBottomNavItem(Icons.image, "IMAGE", provider.tab == 0),
          ),
          InkWell(
            onTap: () => provider.setTab(1),
            child: _buildBottomNavItem(
              Icons.videocam,
              "VIDEO",
              provider.tab == 1,
            ),
          ),
          InkWell(
            onTap: () => provider.setTab(2),
            child: _buildBottomNavItem(
              Icons.aspect_ratio,
              "POST SIZE",
              provider.tab == 2,
            ),
          ),
          InkWell(
            onTap: () {
              provider.loadKeyWords(); // loads once, sheet updates itself
              _showCategorySheet(context, provider, isDark);
            },
            child: _buildBottomNavItem(Icons.category, "CATEGORIES", false),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------- body ----------------
  Widget _body(
    BuildContext context,
    BrowseTemplatesProvider p,
    bool isDark,
    Color sub,
  ) {
    // Shimmer (same layout as the real grid) instead of a spinner.
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

    if (items.isEmpty) {
      return Center(
        child: AppText(
          'No templates found',
          style: TextStyle(fontSize: 14, color: sub),
        ),
      );
    }

    // All cards the same size (2 columns).
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1, // change this value to make the cards taller
      ),
      itemBuilder: (_, i) => _card(context, items[i], isDark),
    );
  }

  Widget _card(BuildContext context, TemplateModel t, bool isDark) {
    final key = t.thumbnailS3Key?.trim() ?? '';
    final imageUrl = key.isEmpty
        ? ''
        : key.startsWith('http')
        ? key
        : '${ApiEndpoints.cdnImageUrl}/$key';

    final locked = t.isLocked ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final uid = t.uid?.trim() ?? '';
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
            builder: (_) => TemplateEditScreen(
              templateUid: uid,
              canvasWidth: (t.templateSize?.width ?? 1080).toDouble(),
              canvasHeight: (t.templateSize?.height ?? 1080).toDouble(),
            ),
          ),
        );
      },
      // Only the rounded image: no name, no border, no shadow box.
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
              if (locked)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) => Container(
    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
    child: Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
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
