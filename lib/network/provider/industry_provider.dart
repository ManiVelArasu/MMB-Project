import 'package:flutter/cupertino.dart';
import 'package:project_mmb/Repository/industry_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/industries.dart';
import '../../core/app_provider/my_notifier.dart';

import 'package:flutter/material.dart';

class IndustryProvider extends ChangeNotifier with MyNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  List<Industries> _allCategories = [];
  List<Industries> _filteredCategories = [];
  List<Industries> get categories => _filteredCategories;
  Industries? _selectedCategory;
  Industries? get selectedCategory => _selectedCategory;
  TextEditingController otherController = TextEditingController();
  String _searchQuery = "";
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.trim().isNotEmpty;

  bool _showOtherInput = false;
  bool get showOtherInput => _showOtherInput;

  bool _isChildLoading = false;
  bool get isChildLoading => _isChildLoading;

  String? _childErrorMessage;
  String? get childErrorMessage => _childErrorMessage;

  List<Industries> _childCategories = [];
  List<Industries> get childCategories => _childCategories;

  Industries? _selectedSpecialization;
  Industries? get selectedSpecialization => _selectedSpecialization;

  String? get selectedCategorySlug => _selectedSpecialization?.slug;

  void selectSpecialization(Industries category) {
    _selectedSpecialization = category;
    _showOtherInput =
        category.slug == 'other' ||
            (category.name?.trim().toLowerCase() == 'other');
    notifyListeners();
  }

  void setSelectedSpecialization(String spec) {
    _showOtherInput = spec.trim().toLowerCase() == "other";
    notifyListeners();
  }

  Future<void> fetchAssetCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await IndustryDropdown.instance.industry();

      if (result.isSuccess && result.data != null) {
        final IndustryResponse response = result.data!;

        if (response.success == true) {
          _allCategories = response.data;
          _filteredCategories = List.from(_allCategories);

          if (_allCategories.isEmpty) {
            _errorMessage = "No Data Found";
          } else {
            _errorMessage = null;
          }
        }
      } else if (result.isFailure) {
        _errorMessage = result.error?.message ?? "Network Error Occurred";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<IndustryResponse?> industryView({String? parentSlug}) async {
    final slug = parentSlug?.trim();

    if (slug != null && slug.isNotEmpty) {
      _isChildLoading = true;
      _childErrorMessage = null;
      _childCategories = [];
    } else {
      _isLoading = true;
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final result = await IndustryDropdown.instance.industryView(
        parentSlug: slug,
      );

      if (result.isSuccess && result.data != null) {
        final response = result.data!;

        if (response.success == true) {
          if (slug != null && slug.isNotEmpty) {
            _childCategories = List<Industries>.from(response.data);
            _childErrorMessage =
            _childCategories.isEmpty ? "No Data Found" : null;
          } else {
            _allCategories = List<Industries>.from(response.data);
            _filteredCategories = List.from(_allCategories);
            _errorMessage = _allCategories.isEmpty ? "No Data Found" : null;
          }
        }

        return response;
      }

      final message = result.error?.message ?? "Network Error Occurred";
      if (slug != null && slug.isNotEmpty) {
        _childErrorMessage = message;
      } else {
        _errorMessage = message;
      }
    } catch (e) {
      if (slug != null && slug.isNotEmpty) {
        _childErrorMessage = e.toString();
      } else {
        _errorMessage = e.toString();
      }
    } finally {
      if (slug != null && slug.isNotEmpty) {
        _isChildLoading = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }

    return null;
  }
  void filterCategories(String query) {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredCategories = List.from(_allCategories);
    } else {
      _filteredCategories = _allCategories.where((category) {
        final categoryName = category.name?.toLowerCase() ?? "";
        final searchLower = query.toLowerCase();
        return categoryName.contains(searchLower);
      }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = "";
    _filteredCategories = List.from(_allCategories);
    notifyListeners();
  }

  void selectCategory(Industries category) {
    _selectedCategory = category;
    _savedCategoryName = category.name ?? "";
    _savedCategorySlug = category.slug ?? "";
    notifyListeners();
  }

  String _savedCategoryName = "";
  String get savedCategoryName => _savedCategoryName;

  String _savedCategorySlug = "";
  String get savedCategorySlug => _savedCategorySlug;

  Future<void> loadSavedCategory() async {
    final prefs = await SharedPreferences.getInstance();

    _savedCategoryName =
        prefs.getString('saved_category_name') ?? '';
    _savedCategorySlug =
        prefs.getString('saved_category_slug') ?? '';

    notifyListeners();

    // If the previous screen saved the slug, call the child API directly.
    if (_savedCategorySlug.trim().isNotEmpty) {
      debugPrint(
        '➡️ ChooseView: GET /industries?parent=${_savedCategorySlug.trim()}',
      );
      await industryView(parentSlug: _savedCategorySlug.trim());
      return;
    }

    // Backward compatibility: older code may have saved only the ID/name.
    // First load the parent industries, resolve the selected industry's slug,
    // save it, then call the child API.
    final savedId =
        prefs.getString('saved_category_id')?.trim() ?? '';

    if (savedId.isEmpty && _savedCategoryName.trim().isEmpty) {
      debugPrint('⚠️ ChooseView: no saved industry id/name');
      return;
    }

    await fetchAssetCategories();

    Industries? selected;

    if (savedId.isNotEmpty) {
      for (final item in _allCategories) {
        if (item.id.toString() == savedId) {
          selected = item;
          break;
        }
      }
    }

    if (selected == null && _savedCategoryName.trim().isNotEmpty) {
      for (final item in _allCategories) {
        if (item.name?.trim().toLowerCase() ==
            _savedCategoryName.trim().toLowerCase()) {
          selected = item;
          break;
        }
      }
    }

    final slug = selected?.slug?.trim() ?? '';

    if (slug.isEmpty) {
      _childErrorMessage = 'Selected industry slug not found';
      notifyListeners();
      debugPrint('❌ ChooseView: industry slug not found');
      return;
    }

    _savedCategoryName = selected?.name ?? _savedCategoryName;
    _savedCategorySlug = slug;

    await prefs.setString('saved_category_slug', slug);

    debugPrint('➡️ ChooseView: resolved slug=$slug');
    debugPrint('➡️ ChooseView: GET /industries?parent=$slug');

    await industryView(parentSlug: slug);
  }
}
