import 'package:flutter/material.dart';
import 'package:mmb_app/Repository/get_me_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/special_days.dart';
import '../../Api Model/templatecategories.dart';
import '../../Api Model/Template_model.dart';
import '../../Repository/home_repository.dart';
import '../../model/my_space_model.dart';
import 'common_provider.dart';

class HomeScreenProvider extends ChangeNotifier {
  HomeScreenProvider({bool loadSpecialDaysOnInit = true}) {
    fetchTemplateCategories();
    loadSavedBusinessData();
    if (loadSpecialDaysOnInit) {
      fetchSpecialDays(range: 'month');
    }
  }

  String _businessName = "";
  String get businessName => _businessName;
  String selectedDate = "2";
  final GetMeRepository getMeRepository = GetMeRepository.instance;
  final CommonProvider provider = CommonProvider.instance;

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

  String? _selectedDates;

  String? get selectedDates => _selectedDates;

  Future<void> setSelectedDate(DateTime date) async {
    final selected = _formatApiDate(date);
    _selectedDates = selected;
    notifyListeners();

    // Keep the month date strip on Home, but fetch only the tapped date data.
    await fetchSpecialDays(
      from: selected,
      to: selected,
      preserveCalendarRange: true,
    );
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

  List<SpecialDaysList> _specialDays = [];

  bool _isLoadingSpecialDays = false;
  String? _specialDaysError;

  String _selectedSpecialDaysRange = "month";

  List<SpecialDaysList> get specialDays => _specialDays;

  bool get isLoadingSpecialDays => _isLoadingSpecialDays;

  String? get specialDaysError => _specialDaysError;

  String get selectedSpecialDaysRange => _selectedSpecialDaysRange;

  Range? _specialDaysRange;

  Range? get specialDaysRange => _specialDaysRange;

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

  Future<void> fetchSpecialDays({
    String? range,
    String? from,
    String? to,
    bool preserveCalendarRange = false,
  }) async {
    _isLoadingSpecialDays = true;
    _specialDaysError = null;

    if (range != null && range.isNotEmpty) {
      _selectedSpecialDaysRange = range;
    }
    notifyListeners();

    try {
      final result = await HomeRepository.instance.specialDaysApi(
        range: range,
        from: from,
        to: to,
      );

      if (result.isSuccess && result.data != null) {
        final response = result.data!;
        if (response.success == true) {
          _specialDays = response.data;
          if (!preserveCalendarRange) {
            _specialDaysRange = response.meta?.range;
          }
        } else {
          _specialDays = [];
          if (!preserveCalendarRange) _specialDaysRange = null;
        }
      } else {
        _specialDays = [];
        _specialDaysError = result.error?.message ?? "No data found";
      }
    } catch (e) {
      debugPrint("❌ Special Days API Error: $e");
      _specialDays = [];
      _specialDaysError = "No data found";
    } finally {
      _isLoadingSpecialDays = false;
      notifyListeners();
    }
  }

  /// Applies the range selected from the Special Days filter.
  /// The first home-screen request intentionally remains `range=week`
  /// without from/to; these values are only sent after the user applies
  /// a filter/date range.
  Future<void> applySpecialDaysFilter({
    required String range,
    required DateTime from,
    required DateTime to,
  }) async {
    final safeFrom = DateTime(from.year, from.month, from.day);
    final safeTo = DateTime(to.year, to.month, to.day);

    await fetchSpecialDays(
      from: _formatApiDate(safeFrom),
      to: _formatApiDate(safeTo),
    );
  }

  Future<void> loadNextSpecialDaysRange() async {
    final current = _specialDaysRange;
    if (current == null) return;

    final currentFrom = DateTime(
      current.from.year,
      current.from.month,
      current.from.day,
    );
    final currentTo = DateTime(
      current.to.year,
      current.to.month,
      current.to.day,
    );

    late DateTime from;
    late DateTime to;

    if (_selectedSpecialDaysRange == 'month') {
      // Move exactly one calendar month forward.
      final nextMonth = DateTime(currentTo.year, currentTo.month + 1, 1);
      from = nextMonth;
      to = DateTime(nextMonth.year, nextMonth.month + 1, 0);
    } else {
      from = currentTo.add(const Duration(days: 1));
      to = from.add(const Duration(days: 6));
    }

    _selectedDates = null;
    await fetchSpecialDays(from: _formatApiDate(from), to: _formatApiDate(to));
  }

  String _formatApiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
      title: "CREATE NEW",
      icon: "assets/images/for_you.png",
      gradientColors: [
        const Color(0xFFF2BA4E).withValues(alpha: 0.2),
        const Color(0xFFF2BA4E),
      ],
    ),
    MySpaceModel(
      title: "FOR YOU",
      icon: "assets/images/user_tag.png",
      gradientColors: [
        const Color(0xFF4ED8F2).withValues(alpha: 0.2),
        const Color(0xFF4ED8F2),
      ],
    ),
    MySpaceModel(
      title: "FESTIVAL",
      icon: "assets/images/festival_calender.png",
      gradientColors: [
        const Color(0xFFF24E86).withValues(alpha: 0.2),
        const Color(0xFFF24E86),
      ],
    ),
    MySpaceModel(
      title: "MY BRAND",
      icon: "assets/images/briefcase.png",
      gradientColors: [
        const Color(0xFFE8F5E9).withValues(alpha: 0.2),
        const Color(0xFFA5D6A7),
      ],
    ),
    MySpaceModel(
      title: "BRAND SERIES",
      icon: "assets/images/corporate.png",
      gradientColors: [
        const Color(0xFFE8F5E9).withValues(alpha: 0.2),
        const Color(0xFFA5D6A7),
      ],
    ),
    MySpaceModel(
      title: "BRAND FRAMES",
      icon: "assets/images/corporate.png",
      gradientColors: [
        const Color(0xFFE8F5E9).withValues(alpha: 0.2),
        const Color(0xFFA5D6A7),
      ],
    ),
    MySpaceModel(
      title: "AI HUB",
      icon: "assets/images/corporate.png",
      gradientColors: [
        const Color(0xFFE8F5E9).withValues(alpha: 0.2),
        const Color(0xFFA5D6A7),
      ],
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
  void clearUserData() {
    // User-specific data
    _businessName = "";

    // Date / special days state
    _selectedDates = null;
    selectedDate = "2";
    _specialDays = [];
    _specialDaysRange = null;
    _selectedSpecialDaysRange = "month";
    _specialDaysError = null;
    _isLoadingSpecialDays = false;

    // Templates
    _templateCategories = [];
    _templatesByCategory.clear();
    _templateLoadingByCategory.clear();
    _templateErrorByCategory.clear();

    _categoryErrorMessage = null;
    _isLoadingCategories = false;

    // Selection state
    selectedCategoryIndex = 0;
    selectedVideoCategoryIndex = 0;
    currentZoneIndex = 0;
    currentLeadBannerIndex = 0;

    notifyListeners();

    debugPrint("✅ HomeScreenProvider user data cleared");
  }

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
