import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/Template_model.dart';
import '../../Repository/template_edit_repository.dart';

class TemplateDetailProvider extends ChangeNotifier {
  TemplateDetailProvider() {
    loadSavedImage();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  // ---------------- BOTTOM TAB ----------------
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // ---------------- RESIZE ----------------
  String _selectedResizeSize = "Post Square (1:1)";
  String get selectedResizeSize => _selectedResizeSize;

  void setResizeSize(String size) {
    _selectedResizeSize = size;
    notifyListeners();
  }

  // ---------------- REPOSITORY ----------------
  final TemplateRepository repository = TemplateRepository.instance;

  // ---------------- SAVED IMAGE ----------------
  String? _savedImagePath;
  String? get savedImagePath => _savedImagePath;

  Future<void> loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    _savedImagePath = prefs.getString('saved_business_image_path');
    notifyListeners();
  }

  // ---------------- TEMPLATES ----------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TemplateModel> _templates = [];
  List<TemplateModel> get templates => _templates;

  String? _categorySlug;
  String? get categorySlug => _categorySlug;

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
      final result = await repository.templateApi(category: category);

      result.when(
        success: (TemplatesResponseModel response) {
          _templates = response.data;
          debugPrint("✅ Templates loaded: ${_templates.length}");
        },
        failure: (error) {
          _templates = [];
          debugPrint("❌ Template API error: ${error.message}");
        },
      );
    } catch (e, st) {
      _templates = [];
      debugPrint("❌ Template exception: $e\n$st");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- FILTERS ----------------
  bool _isType(TemplateModel t, List<String> types) {
    final type = t.templateType?.toLowerCase().trim() ?? '';
    return types.contains(type);
  }

  List<TemplateModel> get imageTemplates =>
      _templates.where((t) => _isType(t, ['image', 'images'])).toList();

  List<TemplateModel> get videoTemplates =>
      _templates.where((t) => _isType(t, ['video', 'videos'])).toList();

  List<TemplateModel> get allTemplates => _templates;

  void clearTemplates() {
    _templates = [];
    _categorySlug = null;
    notifyListeners();
  }
}