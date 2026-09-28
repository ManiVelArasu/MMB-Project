import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/templates_view.dart';
import '../../Repository/template_edit_repository.dart';

class TemplateDetailProvider extends ChangeNotifier {
  TemplateDetailProvider() {
    loadSavedImage();
  }

  // =========================================================
  // SELECTED BOTTOM TAB
  // =========================================================

  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // =========================================================
  // RESIZE
  // =========================================================

  String _selectedResizeSize = "Post Square (1:1)";

  String get selectedResizeSize => _selectedResizeSize;

  void setResizeSize(String size) {
    _selectedResizeSize = size;
    notifyListeners();
  }

  // =========================================================
  // REPOSITORY
  // =========================================================

  final TemplateRepository repository = TemplateRepository.instance;

  // =========================================================
  // SAVED IMAGE
  // =========================================================

  String? _savedImagePath;

  String? get savedImagePath => _savedImagePath;

  Future<void> loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();

    _savedImagePath = prefs.getString('saved_business_image_path');

    notifyListeners();
  }

  // =========================================================
  // TEMPLATES
  // =========================================================

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<TemplatesListView> _templates = [];

  List<TemplatesListView> get templates => _templates;

  String? _categorySlug;

  String? get categorySlug => _categorySlug;

  // =========================================================
  // CATEGORY API
  // =========================================================

  Future<void> getTemplatesByCategory(String slug) async {
    final category = slug.trim();

    if (category.isEmpty) {
      debugPrint("❌ Category slug empty");
      return;
    }

    _categorySlug = category;

    _isLoading = true;
    _templates = [];

    notifyListeners();

    try {
      debugPrint("=================================");
      debugPrint("📡 TEMPLATE CATEGORY API");
      debugPrint("Category : $category");
      debugPrint("Endpoint : templates?category=$category");
      debugPrint("=================================");

      final result = await repository.templateApi(category: category);

      result.when(
        success: (data) {
          // API response:
          // TemplatesList {
          //   success
          //   data: List<TemplatesListView>
          // }

          _templates = data.data;

          debugPrint("✅ Templates loaded: ${_templates.length}");

          for (final template in _templates) {
            debugPrint(
              "Template: ${template.name} | "
              "type: ${template.templateType} | "
              "uid: ${template.uid}",
            );
          }
        },
        failure: (error) {
          _templates = [];

          debugPrint("❌ Template API error: ${error.message}");
        },
      );
    } catch (e, stackTrace) {
      _templates = [];

      debugPrint("❌ Template exception: $e");

      debugPrint(stackTrace.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // IMAGE TEMPLATES
  // =========================================================

  List<TemplatesListView> get imageTemplates {
    return _templates.where((template) {
      final type = template.templateType?.toLowerCase().trim() ?? '';

      return type == "image" || type == "images";
    }).toList();
  }

  // =========================================================
  // VIDEO TEMPLATES
  // =========================================================

  List<TemplatesListView> get videoTemplates {
    return _templates.where((template) {
      final type = template.templateType?.toLowerCase().trim() ?? '';

      return type == "video" || type == "videos";
    }).toList();
  }

  // =========================================================
  // ALL TEMPLATES
  // =========================================================

  List<TemplatesListView> get allTemplates {
    return _templates;
  }

  // =========================================================
  // CLEAR
  // =========================================================

  void clearTemplates() {
    _templates = [];
    _categorySlug = null;
    notifyListeners();
  }
}
