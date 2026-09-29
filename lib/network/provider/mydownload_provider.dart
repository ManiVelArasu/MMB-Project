import 'package:flutter/foundation.dart';

import 'prpject_provider.dart';

class MyDownloadsProvider extends ChangeNotifier {
  // =====================================================
  // PROJECT PROVIDER
  // =====================================================

  final ProjectProvider projectProvider = ProjectProvider();

  // =====================================================
  // FILTER
  // =====================================================

  DownloadFilter _selectedFilter = DownloadFilter.image;

  DownloadFilter get selectedFilter => _selectedFilter;

  // =====================================================
  // PROJECT DATA
  // =====================================================

  bool get isLoading => projectProvider.isLoadingPlans;

  dynamic get projects {
    return projectProvider.plansData?.data ?? [];
  }

  // =====================================================
  // GET PROJECT LIST
  // =====================================================

  Future<void> fetchProjects() async {
    await projectProvider.fetchProject();

    notifyListeners();
  }

  // =====================================================
  // FILTER
  // =====================================================

  void setFilter(DownloadFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  @override
  void dispose() {
    projectProvider.dispose();
    super.dispose();
  }
}

// =====================================================
// DOWNLOAD FILTER
// =====================================================

enum DownloadFilter {
  image,
  video,
  postSize,
}