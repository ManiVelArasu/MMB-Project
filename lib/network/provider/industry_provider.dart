import 'package:flutter/cupertino.dart';
import 'package:project_mmb/Repository/industry_repository.dart';

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

  String _searchQuery = "";
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.trim().isNotEmpty;
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
    notifyListeners();
  }
}
