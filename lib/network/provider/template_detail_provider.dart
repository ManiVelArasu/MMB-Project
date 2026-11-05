import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/Template_model.dart';
import '../../Api Model/key_words_model.dart';
import '../../Repository/business_profile_repository.dart';
import '../../Repository/template_edit_repository.dart';
import 'common_provider.dart';

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
  String? _tag;
  String? get tag => _tag;
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
  final CommonProvider commonProvider = CommonProvider.instance;

  final BusinessProfileRepository businessProfileRepository =
      BusinessProfileRepository.instance;

  // ---------------- SAVED IMAGE ----------------
  String? _savedImagePath;
  String? get savedImagePath => _savedImagePath;

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
      var categorySlug =
          commonProvider.business?.businessCategory?.parent?.slug ?? '';

      // business category illana, current screen slug use pannum
      if (categorySlug.isEmpty) categorySlug = _categorySlug ?? '';

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
    _selectedUid = null;
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

  // ---------------- SELECTED (TOP BANNER) TEMPLATE ----------------
  String? _selectedUid;

  /// Template shown in the top banner.
  /// Default → first image template (else first template).
  TemplateModel? get selectedTemplate {
    if (_templates.isEmpty) return null;

    if (_selectedUid != null) {
      for (final t in _templates) {
        if (t.uid == _selectedUid) return t;
      }
    }

    final images = imageTemplates;
    return images.isNotEmpty ? images.first : _templates.first;
  }

  void selectTemplate(String uid) {
    if (uid.isEmpty || uid == selectedTemplate?.uid) return;
    _selectedUid = uid;
    notifyListeners();
  }

  List<TemplateModel> _withoutSelected(List<TemplateModel> list) {
    final uid = selectedTemplate?.uid;
    return list.where((t) => t.uid != uid).toList();
  }

  // Grid lists → banner-la irukkura template thavira mathathu
  List<TemplateModel> get gridImageTemplates => _withoutSelected(imageTemplates);
  List<TemplateModel> get gridVideoTemplates => _withoutSelected(videoTemplates);
  List<TemplateModel> get gridAllTemplates => _withoutSelected(allTemplates);

  void clearTemplates() {
    _templates = [];
    _categorySlug = null;
    _selectedUid = null;
    notifyListeners();
  }
}