import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/Template_model.dart';
import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import '../../Repository/home_repository.dart';
import 'common_provider.dart';

class BrowseCategory {
  BrowseCategory({
    required this.name,
    required this.slug,
    this.isChild = false,
  });

  final String name;
  final String slug;
  final bool isChild;
}

/// Provider for the "Browse Categories" screen.
/// Uses HomeRepository.templatesByCategory(slug).
class BrowseTemplatesProvider extends ChangeNotifier {
  BrowseTemplatesProvider({String? initialSlug, String? initialTag}) {
    final tag = initialTag?.trim() ?? '';
    _tag = tag.isEmpty ? null : tag;
    _init(initialSlug);
  }

  final HomeRepository _repository = HomeRepository.instance;
  final CommonProvider commonProvider = CommonProvider.instance;

  final BusinessProfileRepository businessProfileRepository =
      BusinessProfileRepository.instance;
  bool _disposed = false;

  // ---------------- categories ----------------
  List<BrowseCategory> _categories = [];
  List<BrowseCategory> get categories => _categories;

  // Categories are not loaded now (the loader was removed), so this must
  // start as false. When it stayed true the screen showed the spinner forever.
  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  String? _selectedSlug;
  String? get selectedSlug => _selectedSlug;

  String get selectedName {
    for (final c in _categories) {
      if (c.slug == _selectedSlug) return c.name;
    }

    // Categories list is empty → make a title from the slug
    final slug = _selectedSlug?.trim() ?? '';
    if (slug.isEmpty) return 'Templates';

    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String? _tag;
  String? get tag => _tag;

  Future<void> clearTag() async {
    if (_tag == null) return;
    _tag = null;
    final slug = _selectedSlug;
    if (slug != null) await selectCategory(slug);
  }

  // ---------------- templates ----------------
  List<TemplateModel> _templates = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _tab = 0;
  int get tab => _tab;

  String _query = '';
  String get query => _query;

  /// Templates after tab + search filter.
  List<TemplateModel> get visibleTemplates {
    Iterable<TemplateModel> list = _templates;

    if (_tab == 0) {
      list = list.where((t) => !_isVideo(t));
    } else if (_tab == 1) {
      list = list.where(_isVideo);
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => nameOf(t).toLowerCase().contains(q));
    }
    return list.toList();
  }

  // ---------------- helpers ----------------
  static bool _isVideo(TemplateModel t) {
    try {
      final type = ((t as dynamic).templateType?.toString() ?? '')
          .toLowerCase()
          .trim();
      return type == 'video' || type == 'videos';
    } catch (_) {
      return false;
    }
  }

  static String nameOf(TemplateModel t) {
    try {
      return ((t as dynamic).name?.toString() ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ---------------- actions ----------------
  Future<void> _init(String? initialSlug) async {
    var slug = initialSlug?.trim() ?? '';

    if (slug.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      slug = (prefs.getString('saved_category_slug') ?? '').trim();
    }

    if (slug.isEmpty && _categories.isNotEmpty) {
      slug = _categories.first.slug;
    }

    if (slug.isEmpty) return;

    await selectCategory(slug);
  }

  List<KeyWordsData> _keyWords = [];

  List<KeyWordsData> get keyWords => _keyWords;

  bool _isKeyWordsLoading = false;

  bool get isKeyWordsLoading => _isKeyWordsLoading;

  String? _keyWordsError;

  String? get keyWordsError => _keyWordsError;

  Future<bool> loadKeyWords({bool forceRefresh = false}) async {
    // =======================================================
    // PERSONAL → DO NOT CALL API
    // =======================================================

    if ((_keyWords.isNotEmpty || _isKeyWordsLoading) && !forceRefresh) {
      return true;
    }

    _isKeyWordsLoading = true;
    _keyWordsError = null;

    notifyListeners();

    try {
      final categorySlug =
          commonProvider.business?.businessCategory?.parent?.slug ?? '';

      // Category slug இல்லையென்றால் API call வேண்டாம்
      if (categorySlug.isEmpty) {
        _keyWordsError = "Business category slug not found";

        debugPrint("⚠️ Category slug empty → Keywords API SKIPPED");

        return false;
      }

      debugPrint("🏢 BUSINESS → Calling Keywords API");

      debugPrint("Category Slug: $categorySlug");

      final result = await businessProfileRepository.industryKeyWords(
        categorySlug,
      );

      final KeyWordsModel? data = result.data;

      if (data == null) {
        _keyWordsError = "Keywords data not found";

        return false;
      }

      _keyWords = data.data;

      debugPrint("================================");

      debugPrint("✅ KEYWORDS API SUCCESS");

      debugPrint(
        "Total Keywords : "
        "${_keyWords.length}",
      );

      for (final keyword in _keyWords) {
        debugPrint(
          "Keyword : ${keyword.name} | "
          "Slug : ${keyword.slug}",
        );
      }

      debugPrint("================================");

      return true;
    } catch (e, stackTrace) {
      _keyWordsError = e.toString();

      debugPrint("❌ Keywords API failed: $e");

      debugPrint("$stackTrace");

      return false;
    } finally {
      _isKeyWordsLoading = false;

      notifyListeners();
    }
  }

  Future<void> selectCategory(String slug) async {
    _selectedSlug = slug;
    _isLoading = true;
    _error = null;
    _templates = [];
    notifyListeners();

    try {
      final result = await _repository.templatesByCategories(slug, tag: _tag);
      if (slug != _selectedSlug) return; // user picked another meanwhile

      if (result.isSuccess && result.data != null) {
        final raw = (result.data as dynamic).data;
        _templates = raw is List
            ? raw.whereType<TemplateModel>().toList()
            : <TemplateModel>[];
      } else {
        _error = result.error?.message ?? 'Unable to load templates';
      }
    } catch (e) {
      debugPrint('❌ Browse templates error: $e');
      if (slug != _selectedSlug) return;
      _error = 'Unable to load templates';
    } finally {
      if (slug == _selectedSlug) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setTab(int index) {
    _tab = index;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }
}
