import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/Template_model.dart';
import '../../Repository/home_repository.dart';

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
  BrowseTemplatesProvider({String? initialSlug}) {
    _init(initialSlug);
  }

  final HomeRepository _repository = HomeRepository.instance;
  bool _disposed = false;

  // ---------------- categories ----------------
  List<BrowseCategory> _categories = [];
  List<BrowseCategory> get categories => _categories;

  bool _isCategoriesLoading = true;
  bool get isCategoriesLoading => _isCategoriesLoading;

  String? _selectedSlug;
  String? get selectedSlug => _selectedSlug;

  String get selectedName {
    for (final c in _categories) {
      if (c.slug == _selectedSlug) return c.name;
    }
    return 'Templates';
  }

  // ---------------- templates ----------------
  List<TemplateModel> _templates = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // 0 = images, 1 = videos, 2 = post size (all)
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
    await _loadCategories();

    // 1) slug passed to the screen, 2) saved category slug, 3) first category
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

  Future<void> _loadCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();

    try {
      final result = await _repository.templateCategoryTree();

      if (result.isSuccess && result.data != null) {
        final raw = (result.data as dynamic).data;
        final list = <BrowseCategory>[];

        if (raw is List) {
          for (final item in raw) {
            final name = ((item as dynamic).name?.toString() ?? '').trim();
            final slug = ((item as dynamic).slug?.toString() ?? '').trim();
            if (name.isNotEmpty && slug.isNotEmpty) {
              list.add(BrowseCategory(name: name, slug: slug));
            }

            final children = (item as dynamic).children;
            if (children is List) {
              for (final child in children) {
                final cName = ((child as dynamic).name?.toString() ?? '')
                    .trim();
                final cSlug = ((child as dynamic).slug?.toString() ?? '')
                    .trim();
                if (cName.isNotEmpty && cSlug.isNotEmpty) {
                  list.add(
                    BrowseCategory(name: cName, slug: cSlug, isChild: true),
                  );
                }
              }
            }
          }
        }
        _categories = list;
      }
    } catch (e) {
      debugPrint('❌ Browse categories error: $e');
    } finally {
      _isCategoriesLoading = false;
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
      final result = await _repository.templatesByCategories(slug);
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
