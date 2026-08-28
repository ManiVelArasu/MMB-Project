import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/templatecategories.dart';
import '../../Api Model/Template_model.dart';
import '../../Repository/home_repository.dart';
import '../../model/my_space_model.dart';

class HomeScreenProvider extends ChangeNotifier {
  HomeScreenProvider() {
    fetchTemplateCategories();
    loadSavedBusinessData();
  }

  String _businessName = "";
  String get businessName => _businessName;
  String selectedDate = "2";
  Future<void> loadSavedBusinessData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? name = prefs.getString('saved_business_name');
      if (name == null || name.isEmpty) {
        name = prefs.getString('business_name');
      }

      _businessName = name ?? "";
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading business name: $e");
    }
  }
  void updateSelectedDate(String date) {
    selectedDate = date;
    notifyListeners();
  }
  // ============================================================
  // TEMPLATE CATEGORIES
  // ============================================================

  List<TemplateCategories> _templateCategories = [];
  bool _isLoadingCategories = false;
  String? _categoryErrorMessage;

  List<TemplateCategories> get templateCategories => _templateCategories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoryErrorMessage => _categoryErrorMessage;

  // ============================================================
  // CATEGORY -> TEMPLATES
  // ============================================================

  /// Key = category slug
  /// Value = templates returned by:
  /// GET /templates?category=<slug>
  final Map<String, List<TemplateModel>> _templatesByCategory = {};

  /// Key = category slug
  final Map<String, bool> _templateLoadingByCategory = {};

  final Map<String, String?> _templateErrorByCategory = {};

  Map<String, List<TemplateModel>> get templatesByCategory =>
      Map.unmodifiable(_templatesByCategory);

  List<TemplateModel> templatesForCategory(String slug) {
    return _templatesByCategory[slug] ?? const <TemplateModel>[];
  }

  bool isTemplateLoading(String slug) {
    return _templateLoadingByCategory[slug] ?? false;
  }

  String? templateError(String slug) {
    return _templateErrorByCategory[slug];
  }

  // ============================================================
  // LOAD CATEGORIES
  // ============================================================

  Future<void> fetchTemplateCategories() async {
    _isLoadingCategories = true;
    _categoryErrorMessage = null;
    notifyListeners();

    try {
      final result = await HomeRepository.instance.templateCategory();

      if (result.isSuccess && result.data != null) {
        final response = result.data!;

        if (response.success == true) {
          _templateCategories = response.data ?? [];
          _categoryErrorMessage = null;

          notifyListeners();

          // Load templates for every category using its slug.
          // We intentionally don't use category index.
          for (final category in _templateCategories) {
            final slug = category.slug?.trim();

            if (slug != null && slug.isNotEmpty) {
              await fetchTemplatesByCategory(slug);
            }
          }
        } else {
          _categoryErrorMessage = "Failed to load categories";
        }
      } else if (result.isFailure) {
        _categoryErrorMessage =
            result.error?.message ?? "Network Error Occurred";
      }
    } catch (e, stackTrace) {
      debugPrint("Category API error: $e");
      debugPrintStack(stackTrace: stackTrace);
      _categoryErrorMessage = e.toString();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> fetchTemplatesByCategory(String slug) async {
    final categorySlug = slug.trim();

    if (categorySlug.isEmpty) return;

    _templateLoadingByCategory[categorySlug] = true;
    _templateErrorByCategory[categorySlug] = null;
    notifyListeners();

    try {
      final result = await HomeRepository.instance.templatesByCategory(
        categorySlug,
      );

      if (result.isSuccess && result.data != null) {
        final response = result.data!;

        if (response.success == true) {
          _templatesByCategory[categorySlug] = response.data;
        } else {
          _templatesByCategory[categorySlug] = [];
          _templateErrorByCategory[categorySlug] = "Failed to load templates";
        }
      } else {
        _templatesByCategory[categorySlug] = [];
        _templateErrorByCategory[categorySlug] =
            result.error?.message ?? "Network Error Occurred";
      }
    } catch (e, stackTrace) {
      debugPrint("Template API error [$categorySlug]: $e");
      debugPrintStack(stackTrace: stackTrace);

      _templatesByCategory[categorySlug] = [];
      _templateErrorByCategory[categorySlug] = e.toString();
    } finally {
      _templateLoadingByCategory[categorySlug] = false;
      notifyListeners();
    }
  }

  Future<void> refreshTemplateCategory(String slug) async {
    final categorySlug = slug.trim();

    if (categorySlug.isEmpty) return;

    _templatesByCategory.remove(categorySlug);

    await fetchTemplatesByCategory(categorySlug);
  }

  int selectedCategoryIndex = 0;

  void onCategorySelected(int index) {
    if (index < 0 || index >= _templateCategories.length) {
      return;
    }

    selectedCategoryIndex = index;

    final slug = _templateCategories[index].slug?.trim();

    notifyListeners();

    if (slug != null && slug.isNotEmpty) {
      fetchTemplatesByCategory(slug);
    }
  }

  // Existing Lists & Controllers
  final List<MySpaceModel> _mySpaceList = [
    MySpaceModel(
      title: "MY OWN\nPOST",
      icon: "assets/images/myownpost.png",
      gradientColors: [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)],
    ),
    MySpaceModel(
      title: "MY OWN\nVIDEO",
      icon: "assets/images/video.png",
      gradientColors: [const Color(0xFFFFECEE), const Color(0xFFFF80AB)],
    ),
    MySpaceModel(
      title: "WHATSAPP\nSTICKERS",
      icon: "assets/images/whatsapp_sticker.png",
      gradientColors: [const Color(0xFFFFF8E1), const Color(0xFFFFE082)],
    ),
    MySpaceModel(
      title: "CORPORATE\nNEEDS",
      icon: "assets/images/corporate.png",
      gradientColors: [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)],
    ),
  ];

  final List<Map<String, String>> mySpecialDaysList = [
    {"icon": "assets/images/specialday1.png", "dayCount": "5"},
    {"icon": "assets/images/specialdays2.png", "dayCount": "5"},
    {"icon": "assets/images/specialdays2.png", "dayCount": "6"},
    {"icon": "assets/images/specialdays2.png", "dayCount": "7"},
  ];

  final List<String> myZoneBanners = [
    "assets/images/bakedcaks.png",
    "assets/images/bakedcaks.png",
    "assets/images/bakedcaks.png",
    "assets/images/bakedcaks.png",
    "assets/images/bakedcaks.png",
  ];

  final PageController zonePageController = PageController();
  int currentZoneIndex = 0;

  final List<Map<String, String>> leadBanners = [
    {
      "title": "Make My Lead",
      "subTitle":
          "Go Premium and list your business for free on our platform to boost your leads.",
      "btnText": "BOOST MY BUSINESS",
    },
    {
      "title": "Grow Your Business",
      "subTitle":
          "Get verified badge and double your client engagement effortlessly.",
      "btnText": "UPGRADE NOW",
    },
  ];

  final PageController leadPageController = PageController();
  int currentLeadBannerIndex = 0;

  final List<MyCelebrateModel> _myCelebrateList = [
    MyCelebrateModel(
      title: "Birthday\n Wishes",
      icon: "assets/images/birthday.png",
      gradientColors: [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)],
    ),
    MyCelebrateModel(
      title: "Birthday\n ThankYou",
      icon: "assets/images/thankyou.png",
      gradientColors: [const Color(0xFFFFECEE), const Color(0xFFFF80AB)],
    ),
    MyCelebrateModel(
      title: "Wedding\n Anniversary",
      icon: "assets/images/wedding.png",
      gradientColors: [const Color(0xFFFFF8E1), const Color(0xFFFFE082)],
    ),
    MyCelebrateModel(
      title: "Mothers\n Day",
      icon: "assets/images/mom.png",
      gradientColors: [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)],
    ),
  ];

  List<MySpaceModel> get mySpaceList => _mySpaceList;
  List<MyCelebrateModel> get myCelebrateList => _myCelebrateList;

  void updateZoneIndex(int index) {
    currentZoneIndex = index;
    notifyListeners();
  }

  void updateLeadBannerIndex(int index) {
    currentLeadBannerIndex = index;
    notifyListeners();
  }

  int selectedVideoCategoryIndex = 0;

  final List<String> videoCategories = [
    "Bakery and Cake",
    "Reviews",
    "Offers",
    "New Arrivals",
  ];

  final List<Map<String, String>> brandVideoPostsList = [
    {
      "thumbnail": "assets/images/bakedcaks.png",
      "videoUrl":
          "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
    },
    {
      "thumbnail": "assets/images/bakedcaks.png",
      "videoUrl":
          "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
    },
    {
      "thumbnail": "assets/images/bakedcaks.png",
      "videoUrl":
          "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
    },
    {
      "thumbnail": "assets/images/bakedcaks.png",
      "videoUrl":
          "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
    },
  ];

  void updateVideoCategoryIndex(int index) {
    selectedVideoCategoryIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    zonePageController.dispose();
    leadPageController.dispose();
    super.dispose();
  }
}
