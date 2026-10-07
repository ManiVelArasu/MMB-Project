import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/industries.dart';
import '../../Repository/industry_repository.dart';
import '../../core/app_provider/my_notifier.dart';

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

  String? get selectedCategorySlug =>
      _selectedSpecialization?.slug;

  String? _otherError;
  String? get otherError => _otherError;

  void validateOther(String value) {
    if (value.trim().isEmpty) {
      _otherError = "Please enter your business type";
    } else {
      _otherError = null;
    }

    notifyListeners();
  }

  void clearOtherError() {
    _otherError = null;
    notifyListeners();
  }

  // ============================================================
  // SELECT NORMAL SPECIALIZATION
  // ============================================================

  void selectSpecialization(Industries category) {
    _selectedSpecialization = category;

    final isOther =
        category.slug?.trim().toLowerCase() == 'other' ||
            category.name?.trim().toLowerCase() == 'other';

    _showOtherInput = isOther;

    if (!isOther) {
      otherController.clear();
      _otherError = null;
    }

    notifyListeners();
  }

  // ============================================================
  // SELECT OTHER
  // ============================================================

  void selectOther() {
    _selectedSpecialization = null;
    _showOtherInput = true;

    otherController.clear();
    _otherError = null;

    notifyListeners();
  }
  // ============================================================
  // SET SELECTED SPECIALIZATION
  // ============================================================

  void setSelectedSpecialization(String spec) {
    final value = spec.trim().toLowerCase();

    if (value == "other") {
      // IMPORTANT:
      // Clear previously selected category.
      _selectedSpecialization = null;

      // Select Other.
      _showOtherInput = true;

      // Clear old text.
      otherController.clear();
    } else {
      // Find matching category if available.
      Industries? matchingCategory;

      for (final category in _childCategories) {
        final slug = category.slug?.trim().toLowerCase();
        final name = category.name?.trim().toLowerCase();

        if (slug == value || name == value) {
          matchingCategory = category;
          break;
        }
      }

      _selectedSpecialization = matchingCategory;

      // Other should be unselected.
      _showOtherInput = false;

      // Clear Other text.
      otherController.clear();
    }

    notifyListeners();
  }

  // ============================================================
  // FETCH ASSET CATEGORIES
  // ============================================================

  Future<void> fetchAssetCategories() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result =
      await IndustryDropdown.instance.industry();

      if (result.isSuccess && result.data != null) {
        final IndustryResponse response = result.data!;

        if (response.success == true) {
          _allCategories = response.data;
          _filteredCategories =
              List.from(_allCategories);

          if (_allCategories.isEmpty) {
            _errorMessage = "No Data Found";
          } else {
            _errorMessage = null;
          }
        }
      } else if (result.isFailure) {
        _errorMessage =
            result.error?.message ??
                "Network Error Occurred";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // INDUSTRY VIEW
  // ============================================================

  Future<IndustryResponse?> industryView({
    String? parentSlug,
  }) async {
    final slug = parentSlug?.trim();

    if (slug != null && slug.isNotEmpty) {
      _isChildLoading = true;
      _childErrorMessage = null;
      _childCategories = [];

      // Clear previous specialization
      _selectedSpecialization = null;
      _showOtherInput = false;
      otherController.clear();
    } else {
      _isLoading = true;
      _errorMessage = null;
    }

    notifyListeners();

    try {
      final result =
      await IndustryDropdown.instance.industryView(
        parentSlug: slug,
      );

      if (result.isSuccess && result.data != null) {
        final response = result.data!;

        if (response.success == true) {
          if (slug != null && slug.isNotEmpty) {
            _childCategories =
            List<Industries>.from(response.data);

            _childErrorMessage =
            _childCategories.isEmpty
                ? "No Data Found"
                : null;
          } else {
            _allCategories =
            List<Industries>.from(response.data);

            _filteredCategories =
                List.from(_allCategories);

            _errorMessage =
            _allCategories.isEmpty
                ? "No Data Found"
                : null;
          }
        }

        return response;
      }

      final message =
          result.error?.message ??
              "Network Error Occurred";

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

  // ============================================================
  // FILTER
  // ============================================================

  void filterCategories(String query) {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredCategories =
          List.from(_allCategories);
    } else {
      _filteredCategories =
          _allCategories.where((category) {
            final categoryName =
                category.name?.toLowerCase() ?? "";

            final searchLower =
            query.toLowerCase();

            return categoryName.contains(searchLower);
          }).toList();
    }

    notifyListeners();
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  void clearSearch() {
    _searchQuery = "";

    _filteredCategories =
        List.from(_allCategories);

    notifyListeners();
  }

  // ============================================================
  // SELECT MAIN CATEGORY
  // ============================================================

  void selectCategory(Industries category) {
    _selectedCategory = category;

    _savedCategoryName =
        category.name ?? "";

    _savedCategorySlug =
        category.slug ?? "";

    notifyListeners();
  }

  // ============================================================
  // SAVED CATEGORY
  // ============================================================

  String _savedCategoryName = "";

  String get savedCategoryName =>
      _savedCategoryName;

  String _savedCategorySlug = "";

  String get savedCategorySlug =>
      _savedCategorySlug;

  // ============================================================
  // LOAD SAVED CATEGORY
  // ============================================================

  Future<void> loadSavedCategory() async {
    final prefs =
    await SharedPreferences.getInstance();

    _savedCategoryName =
        prefs.getString(
          'saved_category_name',
        ) ??
            '';

    _savedCategorySlug =
        prefs.getString(
          'saved_category_slug',
        ) ??
            '';

    notifyListeners();

    final slug =
    _savedCategorySlug.trim();

    if (slug.isEmpty) {
      debugPrint(
        '⚠️ ChooseView: no saved category slug',
      );
      return;
    }

    debugPrint(
      '➡️ ChooseView: GET /industries?parent=$slug',
    );

    await industryView(
      parentSlug: slug,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }
}