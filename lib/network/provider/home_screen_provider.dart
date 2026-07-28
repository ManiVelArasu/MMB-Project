import 'package:flutter/material.dart';
import '../../Api Model/templatecategories.dart';
import '../../Repository/home_repository.dart';
import '../../model/my_space_model.dart';

import 'package:flutter/material.dart';

class HomeScreenProvider extends ChangeNotifier {

  HomeScreenProvider() {
    fetchTemplateCategories();
  }


  List<TemplateCategories> _templateCategories = [];
  bool _isLoadingCategories = false;
  String? _categoryErrorMessage;

  List<TemplateCategories> get templateCategories => _templateCategories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoryErrorMessage => _categoryErrorMessage;

  int selectedCategoryIndex = 0;

  List<dynamic> _categoryPostsList = [];
  bool _isLoadingPosts = false;

  List<dynamic> get categoryPostsList => _categoryPostsList;
  bool get isLoadingPosts => _isLoadingPosts;

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

          if (_templateCategories.isNotEmpty) {
            fetchPostsByCategory(_templateCategories[0].slug ?? "");
          }
        } else {
          _categoryErrorMessage = "Failed to load categories";
        }
      } else if (result.isFailure) {
        _categoryErrorMessage =
            result.error?.message ?? "Network Error Occurred";
      }
    } catch (e) {
      _categoryErrorMessage = e.toString();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // 🚀 Category Change Handler
  void onCategorySelected(int index) {
    if (selectedCategoryIndex == index) return;

    selectedCategoryIndex = index;
    notifyListeners();

    if (_templateCategories.isNotEmpty) {
      final selectedSlug = _templateCategories[index].slug ?? "";
      fetchPostsByCategory(selectedSlug);
    }
  }

  // 🚀 Category Wise Posts API Call
  Future<void> fetchPostsByCategory(String categorySlug) async {
    _isLoadingPosts = true;
    notifyListeners();

    try {
      // Unga Repository Call Inga Irungkanum:
      // final result = await HomeRepository.instance.getPostsByCategory(categorySlug);
      // _categoryPostsList = result.data ?? [];
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint("Error fetching category posts: $e");
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
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

  final List<Map<String, dynamic>> whatsappStatusList = [
    {"image": "assets/images/whatsapp1.png", "isVideo": true},
    {"image": "assets/images/whatsapp2.png", "isVideo": false},
    {"image": "assets/images/whatsapp2.png", "isVideo": false},
    {"image": "assets/images/whatsapp2.png", "isVideo": false},
  ];

  final List<Map<String, String>> devotionalList = [
    {"title": "DEVOTIONAL\nQUOTES", "image": "assets/images/devational2.png"},
    {"title": "DEVOTIONAL\nSTORY", "image": "assets/images/devational1.png"},
    {"title": "BIBLE\nVERSES", "image": "assets/images/devational1.png"},
    {"title": "QURAN\nVERSES", "image": "assets/images/devational1.png"},
  ];

  final List<String> corporateNeedsList = [
    "assets/images/corporate1.png",
    "assets/images/corporate2.png",
    "assets/images/corporate2.png",
    "assets/images/corporate2.png",
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
