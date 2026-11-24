import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/Template_model.dart';
import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import '../../Repository/home_repository.dart';
import '../../ui/screens/widget/filter_option.dart';
import 'common_provider.dart';
import 'search_provider.dart' show SearchFilterOption;

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
    _loadLanguages();
    _loadSizes();
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

  // Chip-la kaattura name (API-ku _tag / slug dhaan pogum)
  String? _tagLabel;
  String? get tagLabel => _tagLabel;

  /// Bottom bar CATEGORIES select -> `tags=` ah vechu current category reload.
  Future<void> setTag(String? value, {String? label}) async {
    final v = value?.trim() ?? '';
    final newTag = v.isEmpty ? null : v;
    if (_tag == newTag) return;

    _tag = newTag;
    _tagLabel = newTag == null ? null : label;

    final slug = _selectedSlug;
    if (slug != null) {
      await selectCategory(slug);
    } else {
      notifyListeners();
    }
  }

  Future<void> clearTag() async {
    if (_tag == null) return;
    _tag = null;
    _tagLabel = null;
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

  // ---------------- language / post size filters ----------------
  List<SearchFilterOption> _languageOptions = [];
  List<SearchFilterOption> get languageOptions => _languageOptions;

  List<SearchFilterOption> _sizeOptions = [];
  List<SearchFilterOption> get sizeOptions => _sizeOptions;

  String? _language;
  String? get language => _language;

  String? _size;
  String? get size => _size;

  bool get hasActiveFilters =>
      _tag != null || _language != null || _size != null;

  void setLanguage(String? value) {
    if (_language == value) return;
    _language = value;
    _reload();
  }

  void setSize(String? value) {
    if (_size == value) return;
    _size = value;
    _reload();
  }

  /// Clears language + size (client side) and the tag (reloads the category).
  Future<void> clearAllFilters() async {
    _language = null;
    _size = null;
    _tag = null;
    _tagLabel = null;
    await _reloadNow();
  }

  /// Filters changed -> call the templates API again with the new params.
  void _reload() {
    _reloadNow();
  }

  Future<void> _reloadNow() async {
    final slug = _selectedSlug;
    if (slug != null) {
      await selectCategory(slug);
    } else {
      notifyListeners();
    }
  }

  Future<void> _loadLanguages() async {
    final list = await FilterOptionsLoader.languages();
    if (_disposed) return;
    if (list.isNotEmpty) _languageOptions = list;
    notifyListeners();
  }

  Future<void> _loadSizes() async {
    final list = await FilterOptionsLoader.sizes();
    if (_disposed) return;
    if (list.isNotEmpty) _sizeOptions = list;
    notifyListeners();
  }

  /// Templates after search filter (tab / language / size / tag are sent to the API).
  List<TemplateModel> get visibleTemplates {
    Iterable<TemplateModel> list = _templates;

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
      final result = await _repository.templatesByCategories(
        slug,
        tag: _tag,
        templateType: _tab == 0
            ? 'image'
            : _tab == 1
            ? 'video'
            : null,
        language: _language,
        size: _size,
      );
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
    if (_tab == index) return;
    _tab = index;
    _reload();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }
}