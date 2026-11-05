import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mmb_app/component/appbar_widget.dart';
import 'package:mmb_app/ui/screens/template_edit.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';

import '../../Api Model/Template_model.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/browse_template_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../industry/widgets/scaffold_widget.dart';

/// "Browse Categories" screen: category dropdown + IMAGES / VIDEOS /
/// POST SIZE tabs + templates grid (HomeRepository.templatesByCategory).
class BrowseTemplatesScreen extends StatelessWidget {
  const BrowseTemplatesScreen({super.key, this.initialSlug});

  final String? initialSlug;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrowseTemplatesProvider(initialSlug: initialSlug),
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _searchField(context, p, isDark, sub),
                  const SizedBox(height: 10),
                  _categoryDropdown(context, p, isDark),
                  const SizedBox(height: 12),
                  _tabs(p, isDark),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(child: _body(context, p, isDark, sub)),
          ],
        ),
      ),
    );
  }

  // ---------------- search ----------------
  Widget _searchField(
    BuildContext context,
    BrowseTemplatesProvider p,
    bool isDark,
    Color sub,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.searchBorderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: Colors.red.shade200),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: p.setQuery,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Search for Category, theme or image',
                hintStyle: TextStyle(fontSize: 13, color: sub),
              ),
            ),
          ),
        ],
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
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: p.categories.length,
                    itemBuilder: (_, i) {
                      final c = p.categories[i];
                      final selected = c.slug == p.selectedSlug;
                      return ListTile(
                        contentPadding: EdgeInsets.only(
                          left: c.isChild ? 18 : 0,
                        ),
                        title: Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: c.isChild
                                ? FontWeight.w400
                                : FontWeight.w700,
                            color: selected
                                ? Colors.red
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check, color: Colors.red)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          p.selectCategory(c.slug);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- tabs ----------------
  Widget _tabs(BrowseTemplatesProvider p, bool isDark) {
    const labels = ['IMAGES', 'VIDEOS', 'POST SIZE'];
    return Row(
      children: List.generate(labels.length, (i) {
        final selected = p.tab == i;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => p.setTab(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFE5E7)
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.red
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------- body ----------------
  Widget _body(
    BuildContext context,
    BrowseTemplatesProvider p,
    bool isDark,
    Color sub,
  ) {
    if (p.isLoading || p.isCategoriesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE53935)),
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
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
    final name = BrowseTemplatesProvider.nameOf(t);

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
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
            if (name.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) => Container(
    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
    child: Icon(Icons.image_outlined, size: 36, color: Colors.grey.shade400),
  );
}
