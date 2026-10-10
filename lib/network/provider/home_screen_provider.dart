import 'package:flutter/material.dart';
import 'package:mmb_app/Repository/get_me_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Api Model/key_words_model.dart';
import '../../Api Model/special_days.dart';
import '../../Api Model/templatecategories.dart';
import '../../Api Model/Template_model.dart';
import '../../Api Model/templates_children.dart';
import '../../Repository/business_profile_repository.dart';
import '../../Repository/home_repository.dart';
import '../../model/my_space_model.dart';
import 'common_provider.dart';

class HomeScreenProvider extends ChangeNotifier {
  bool _initialized = false;

  HomeScreenProvider({bool loadSpecialDaysOnInit = true}) {
    initialize(loadSpecialDaysOnInit: loadSpecialDaysOnInit);
  }
  String _selectedMySpace = '';

  String get selectedMySpace => _selectedMySpace;

  void setSelectedMySpace(String title) {
    _selectedMySpace = title;
    notifyListeners();
  }

  Future<void> initialize({bool loadSpecialDaysOnInit = true}) async {
    if (_initialized) {
      debugPrint("⚠️ HomeScreenProvider already initialized");
      return;
    }

    _initialized = true;

    debugPrint("========================================");
    debugPrint("🚀 HOME SCREEN INITIAL LOAD");
    debugPrint("========================================");

    try {
      await Future.wait([
        fetchTemplateCategories(),
        loadSavedBusinessData(),
        fetchTemplatesByPopular(),
        if (loadSpecialDaysOnInit) fetchSpecialDays(range: 'month'),
      ]);

      await _waitAndLoadKeywords();
    } catch (e, stackTrace) {
      debugPrint("❌ Home initialization error: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _waitAndLoadKeywords() async {
    const maxRetries = 20;

    for (int i = 0; i < maxRetries; i++) {
      final accountType = provider.accountType?.trim().toLowerCase();

      final categorySlug =
          provider.business?.businessCategory?.parent?.slug?.trim() ?? '';

      debugPrint(
        "🔑 KEYWORDS CHECK [$i/$maxRetries] "
        "accountType=$accountType "
        "categorySlug=$categorySlug",
      );

      if (accountType == 'personal') {
        debugPrint("👤 PERSONAL ACCOUNT → Keywords API skipped");
        return;
      }

      if (accountType == 'business' && categorySlug.isNotEmpty) {
        debugPrint("✅ Business data ready → Calling Keywords API");

        await loadKeyWords();

        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint(
      "❌ Keywords API not called. "
      "CommonProvider data was not ready.",
    );
  }

  List<KeyWordsData> _keyWords = [];

  List<KeyWordsData> get keyWords => _keyWords;

  bool _isKeyWordsLoading = false;

  bool get isKeyWordsLoading => _isKeyWordsLoading;

  String? _keyWordsError;

  String? get keyWordsError => _keyWordsError;
  String _businessName = "";
  String get businessName => _businessName;
  String selectedDate = "2";
  final GetMeRepository getMeRepository = GetMeRepository.instance;
  final CommonProvider provider = CommonProvider.instance;

  final BusinessProfileRepository businessProfileRepository =
      BusinessProfileRepository.instance;
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

    await fetchSpecialDays(
      from: selected,
      to: selected,
      preserveCalendarRange: true,
    );
  }

  Future<bool> loadKeyWords({bool forceRefresh = false}) async {
    try {
      final accountType = provider.accountType?.trim().toLowerCase();

      debugPrint("🔑 LOAD KEYWORDS");
      debugPrint("Account Type: $accountType");

      if (accountType == 'personal') {
        debugPrint("👤 PERSONAL → Keywords API skipped");
        return false;
      }

      if (accountType != 'business') {
        debugPrint("⚠️ Account type is not business");
        return false;
      }

      if (_keyWords.isNotEmpty && !forceRefresh) {
        return true;
      }

      final categorySlug =
          provider.business?.businessCategory?.parent?.slug?.trim() ?? '';

      debugPrint("🏢 Business Category Slug: $categorySlug");

      if (categorySlug.isEmpty) {
        _keyWordsError = "Business category slug not found";

        debugPrint("⚠️ Category slug empty");

        return false;
      }

      _isKeyWordsLoading = true;
      _keyWordsError = null;
      notifyListeners();

      debugPrint("🚀 Calling Keywords API...");

      final result = await businessProfileRepository.industryKeyWords(
        categorySlug,
      );

      if (result.isSuccess && result.data != null) {
        _keyWords = result.data!.data;

        debugPrint("✅ KEYWORDS API SUCCESS");

        debugPrint("Total Keywords: ${_keyWords.length}");

        for (final keyword in _keyWords) {
          debugPrint(
            "Keyword: ${keyword.name} | "
            "Slug: ${keyword.slug}",
          );
        }

        return true;
      }

      _keyWords = [];

      _keyWordsError = result.error?.message ?? "Keywords not found";

      debugPrint("❌ Keywords API failed: $_keyWordsError");

      return false;
    } catch (e, stackTrace) {
      _keyWords = [];
      _keyWordsError = e.toString();

      debugPrint("❌ Keywords API error: $e");

      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isKeyWordsLoading = false;
      notifyListeners();
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
  List<TemplateCategories> _popularTemplates = [];

  List<TemplateCategories> get popularTemplates => _popularTemplates;

  bool _isLoadingPopularTemplates = false;

  String? _popularTemplatesError;

  bool get isLoadingPopularTemplates => _isLoadingPopularTemplates;

  String? get popularTemplatesError => _popularTemplatesError;

  List<TemplatedChildrenList> _celebrateChildren = [];
  List<TemplatedChildrenList> _devotionalChildren = [];

  List<TemplatedChildrenList> get celebrateChildren => _celebrateChildren;

  List<TemplatedChildrenList> get devotionalChildren => _devotionalChildren;
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
          final homepageCategories = response.data ?? [];

          final treeResult = await HomeRepository.instance
              .templateCategoryTree();

          if (treeResult.isSuccess && treeResult.data?.success == true) {
            final treeCategories = treeResult.data?.data ?? [];

            final treeBySlug = <String, dynamic>{};
            final treeByName = <String, dynamic>{};

            for (final treeCategory in treeCategories) {
              final slug = treeCategory.slug?.trim().toLowerCase() ?? '';
              final name = treeCategory.name?.trim().toLowerCase() ?? '';

              if (slug.isNotEmpty) {
                treeBySlug[slug] = treeCategory;
              }
              if (name.isNotEmpty) {
                treeByName[name] = treeCategory;
              }
            }

            _templateCategories = homepageCategories.map((category) {
              final slug = category.slug?.trim().toLowerCase() ?? '';
              final name = category.name?.trim().toLowerCase() ?? '';

              final treeCategory =
                  (slug.isNotEmpty ? treeBySlug[slug] : null) ??
                  (name.isNotEmpty ? treeByName[name] : null);

              if (treeCategory != null && treeCategory.children.isNotEmpty) {
                return category.copyWith(children: treeCategory.children);
              }

              return category;
            }).toList();
          } else {
            // Keep homepage categories even if the optional tree request fails.
            _templateCategories = homepageCategories;
            debugPrint(
              "⚠️ Tree category API failed: "
              "${treeResult.error?.message ?? 'Unknown error'}",
            );
          }

          debugPrint("✅ Homepage Categories: ${_templateCategories.length}");

          for (final category in _templateCategories) {
            final categoryName = category.name?.trim().toLowerCase() ?? '';

            final categorySlug = category.slug?.trim() ?? '';

            // =====================================================
            // CELEBRATE MOMENTS / DEVOTIONAL DAILY POSTS
            // FETCH THEIR CHILDREN
            // =====================================================

            final bool isSpecialParent =
                categoryName == 'celebrate moments' ||
                categoryName == 'devotional/daily posts' ||
                categoryName == 'devotional / daily posts';

            if (isSpecialParent) {
              debugPrint("⭐ SPECIAL CATEGORY: ${category.name}");

              debugPrint("⭐ CHILD COUNT: ${category.children.length}");

              for (final child in category.children) {
                final childSlug = child.slug?.trim() ?? '';

                if (childSlug.isEmpty) continue;

                debugPrint(
                  "   └── CHILD: ${child.name} "
                  "[$childSlug]",
                );

                await fetchTemplatesByCategory(childSlug);
              }

              continue;
            }

            // =====================================================
            // NORMAL CATEGORY
            // =====================================================

            if (categorySlug.isNotEmpty) {
              await fetchTemplatesByCategory(categorySlug);
            }
          }

          _categoryErrorMessage = null;
        } else {
          _categoryErrorMessage = "Failed to load categories";
        }
      } else {
        _categoryErrorMessage =
            result.error?.message ?? "Network Error Occurred";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Category API error: $e");

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

  Future<void> favoriteTemplate(String templateId) async {
    try {
      final response = await HomeRepository.instance.favorite(templateId);

      if (response.data != null) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Favorite Template Error: $e');
    }
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

  Future<void> fetchTemplatesByPopular() async {
    debugPrint('🔥 fetchTemplatesByPopular START');

    _isLoadingPopularTemplates = true;
    _popularTemplatesError = null;
    notifyListeners();

    try {
      final industrySlug =
          provider.business?.businessCategory?.parent?.slug?.trim() ?? '';

      debugPrint('🏭 Industry Slug: "$industrySlug"');

      if (industrySlug.isEmpty) {
        _popularTemplates = [];
        _popularTemplatesError = 'Industry not available';

        debugPrint('❌ Industry slug is empty');
        return;
      }

      debugPrint('======================================');
      debugPrint('🔥 FETCH POPULAR TEMPLATES');
      debugPrint('🏭 Industry: $industrySlug');
      debugPrint('======================================');

      final result = await HomeRepository.instance.myBrandCategory(
        industrySlug: industrySlug,
      );

      debugPrint('📦 API Success: ${result.isSuccess}');
      debugPrint('📦 API Data: ${result.data}');
      debugPrint('📦 API Error: ${result.error?.message}');

      if (result.isSuccess && result.data != null) {
        final response = result.data!;

        debugPrint('🔥 POPULAR RESPONSE: $response');
        debugPrint('🔥 Response success: ${response.success}');
        debugPrint('🔥 Categories: ${response.data?.length}');

        if (response.success == true) {
          _popularTemplates = response.data ?? [];

          debugPrint(
            '✅ Popular categories count: '
            '${_popularTemplates.length}',
          );

          for (final category in _popularTemplates) {
            debugPrint(
              '➡️ ${category.name} | '
              'slug=${category.slug} | '
              'uid=${category.uid}',
            );
          }

          _popularTemplatesError = null;
        } else {
          _popularTemplates = [];
          _popularTemplatesError = 'Failed to load popular templates';
        }
      } else {
        _popularTemplates = [];

        _popularTemplatesError =
            result.error?.message ?? 'Network Error Occurred';

        debugPrint('❌ Popular API failed: $_popularTemplatesError');
      }
    } catch (e, stackTrace) {
      _popularTemplates = [];
      _popularTemplatesError = e.toString();

      debugPrint('❌ Popular Templates API Error: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoadingPopularTemplates = false;
      notifyListeners();

      debugPrint('🔥 fetchTemplatesByPopular END');
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
      icon: "assets/images/brand_series.png",
      gradientColors: [
        const Color(0xFFF2BA4E).withValues(alpha: 0.2),
        const Color(0xFFF2BA4E),
      ],
    ),

    MySpaceModel(
      title: "BRAND FRAMES",
      icon: "assets/images/b_brush.png",
      gradientColors: [
        const Color(0xFF4ED8F2).withValues(alpha: 0.2),
        const Color(0xFF4ED8F2),
      ],
    ),

    MySpaceModel(
      title: "AI HUB",
      icon: "assets/images/ai_tool.png",
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
    _celebrateChildren = [];
    _devotionalChildren = [];

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
