import 'package:flutter/foundation.dart';

import '../../../Api Model/language_model.dart';
import '../../../Api Model/template_size_model.dart';
import '../../../Repository/custom_theme_repository.dart';
import '../../../Repository/profile_repository.dart';
import '../../../network/provider/search_provider.dart' show SearchFilterOption;

/// Languages / post sizes for the bottom-bar filters, straight from the APIs.
/// Shared by the search screen and the template detail screen so both show the
/// very same options. Returns an empty list when a call fails.
class FilterOptionsLoader {
  FilterOptionsLoader._();

  /// Languages API. value = language code, label = name, trailing = native name.
  static Future<List<SearchFilterOption>> languages() async {
    try {
      final result = await ProfileRepository.instance.getLanguage();
      final LanguageModel? data = result.data;
      if (!result.isSuccess || data == null) return [];

      final items = data.data.where((e) => e.isActive == 1).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return items
          .where((e) => e.code.trim().isNotEmpty && e.name.trim().isNotEmpty)
          .map(
            (e) => SearchFilterOption(
              label: e.name.trim(),
              value: e.code.trim(),
              trailing: e.nativeName.trim().isEmpty
                  ? null
                  : e.nativeName.trim(),
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Filter languages error: $error');
      return [];
    }
  }

  /// Sizes API. value = slug, label = name, trailing = "1080 × 1350".
  static Future<List<SearchFilterOption>> sizes() async {
    try {
      final result = await CustomThemeRepository.instance.industry();
      final TemplateSizeModel? data = result.data;
      if (!result.isSuccess || data == null) return [];

      String dim(String? v) {
        final n = double.tryParse((v ?? '').trim());
        if (n == null) return (v ?? '').trim();
        return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
      }

      return data.data
          .where((e) {
            final active = (e.isActive ?? '').trim().toLowerCase();
            return active.isEmpty || active == '1' || active == 'true';
          })
          .where(
            (e) =>
                (e.name ?? '').trim().isNotEmpty &&
                (e.slug ?? '').trim().isNotEmpty,
          )
          .map((e) {
            final w = dim(e.width), h = dim(e.height);
            return SearchFilterOption(
              label: e.name!.trim(),
              value: e.slug!.trim(),
              trailing: (w.isEmpty || h.isEmpty) ? null : '$w × $h',
            );
          })
          .toList();
    } catch (error) {
      debugPrint('Filter sizes error: $error');
      return [];
    }
  }
}
