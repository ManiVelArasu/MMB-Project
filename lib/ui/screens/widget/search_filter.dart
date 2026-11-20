import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/network/provider/search_provider.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';

/// Slim row under the search box. Post type / size / categories live in the
/// bottom bar ([SearchBottomBar]); language has no tab there, so it stays here.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.isDark,
    this.horizontalPadding = 16,
  });

  final bool isDark;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SearchProvider>();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        physics: const BouncingScrollPhysics(),
        children: [
          _FilterChip(
            isDark: isDark,
            icon: Icons.translate_rounded,
            title: 'LANGUAGE',
            allLabel: 'All languages',
            options: SearchProvider.languageOptions,
            selected: p.language,
            onChanged: p.setLanguage,
          ),
          if (p.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: p.clearFilters,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.appRed,
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        'Clear',
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.appRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// "All ..." entry uses '' because PopupMenuButton cannot return null.
const String _all = '';

PopupMenuItem<String> _menuItem({
  required String value,
  required String label,
  String? trailing,
  required bool selected,
  required bool isDark,
}) {
  final base = isDark ? Colors.white : Colors.black87;
  final red = AppColors.appRed;
  return PopupMenuItem<String>(
    value: value,
    height: 44,
    child: Row(
      children: [
        Expanded(
          child: AppText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppFontSize.fontSize13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? red : base,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 16),
          AppText(
            trailing,
            style: TextStyle(
              fontSize: AppFontSize.fontSize11,
              color: selected
                  ? red
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
        if (selected) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_rounded, size: 18, color: red),
        ],
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.allLabel,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.minMenuWidth = 200,
    this.maxChipWidth = 190,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String allLabel;
  final List<SearchFilterOption> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final double minMenuWidth;
  final double maxChipWidth;

  @override
  Widget build(BuildContext context) {
    String? selectedLabel;
    for (final o in options) {
      if (o.value == selected) selectedLabel = o.label;
    }
    final active = selectedLabel != null;
    final red = AppColors.appRed;

    final bg = active
        ? red.withValues(alpha: isDark ? 0.18 : 0.09)
        : (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    final border = active
        ? red.withValues(alpha: 0.45)
        : (isDark ? Colors.white12 : const Color(0xFFE6E6E6));
    final fg = active
        ? red
        : (isDark ? Colors.white70 : const Color(0xFF4A4A4A));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        tooltip: '',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        elevation: 8,
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        constraints: BoxConstraints(minWidth: minMenuWidth, maxHeight: 320),
        onSelected: (v) => onChanged(v == _all ? null : v),
        itemBuilder: (_) => [
          _menuItem(
            value: _all,
            label: allLabel,
            selected: selected == null,
            isDark: isDark,
          ),
          for (final o in options)
            _menuItem(
              value: o.value ?? '',
              label: o.label,
              trailing: o.trailing,
              selected: o.value == selected,
              isDark: isDark,
            ),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: AppText(
                  (selectedLabel ?? title).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.2,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}


// ===========================================================================
// BOTTOM BAR:  IMAGE | VIDEO | POST SIZE | CATEGORIES
// ===========================================================================

class SearchBottomBar extends StatelessWidget {
  const SearchBottomBar({super.key});

  static const Color _idle = Color(0xFF8C8C8C);

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SearchProvider>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget tab({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final color = selected ? Colors.white : _idle;
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 6),
                AppText(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10, 10, 10, 8 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF5A5A5A),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              tab(
                icon: Icons.image_rounded,
                label: 'IMAGE',
                selected: p.templateType == 'image',
                onTap: () =>
                    p.setTemplateType(p.templateType == 'image' ? null : 'image'),
              ),
              tab(
                icon: Icons.videocam_rounded,
                label: 'VIDEO',
                selected: p.templateType == 'video',
                onTap: () =>
                    p.setTemplateType(p.templateType == 'video' ? null : 'video'),
              ),
              tab(
                icon: Icons.aspect_ratio_rounded,
                label: 'POST SIZE',
                selected: p.size != null,
                onTap: () => showSearchOptionSheet(
                  context,
                  title: 'Post size',
                  allLabel: 'All sizes',
                  options: SearchProvider.sizeOptions,
                  selected: p.size,
                  onChanged: p.setSize,
                ),
              ),
              tab(
                icon: Icons.category_rounded,
                label: 'CATEGORIES',
                selected: p.tag != null,
                onTap: () => showSearchOptionSheet(
                  context,
                  title: 'Categories',
                  allLabel: 'All categories',
                  options: p.tagOptions,
                  selected: p.tag,
                  onChanged: p.setTag,
                  emptyText: 'No categories available',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dark rounded bottom sheet that matches [SearchBottomBar].
Future<void> showSearchOptionSheet(
    BuildContext context, {
      required String title,
      required String allLabel,
      required List<SearchFilterOption> options,
      required String? selected,
      required ValueChanged<String?> onChanged,
      String emptyText = 'Nothing to show',
    }) {
  final red = AppColors.appRed;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      Widget row({
        required String label,
        String? trailing,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
        return InkWell(
          onTap: () {
            Navigator.pop(sheetContext);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize14,
                      fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  AppText(
                    trailing,
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize12,
                      color: Colors.white38,
                    ),
                  ),
                ],
                if (isSelected) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.check_circle_rounded, size: 20, color: red),
                ],
              ],
            ),
          ),
        );
      }

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.62,
        ),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A5A5A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: AppText(
                    emptyText,
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize13,
                      color: Colors.white54,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      row(
                        label: allLabel,
                        isSelected: selected == null,
                        onTap: () => onChanged(null),
                      ),
                      for (final o in options)
                        row(
                          label: o.label,
                          trailing: o.trailing,
                          isSelected: o.value == selected,
                          onTap: () => onChanged(o.value),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}