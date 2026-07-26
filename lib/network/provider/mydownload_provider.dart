import 'package:flutter/material.dart';

enum DownloadFilter { all, image, video, postSize }

class DownloadItemModel {
  final String id;
  final String thumbnailUrl;
  final String? videoUrl;
  final bool isVideo;

  DownloadItemModel({
    required this.id,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.isVideo,
  });
}

class MyDownloadsProvider extends ChangeNotifier {
  DownloadFilter _selectedFilter = DownloadFilter.all;
  DownloadFilter get selectedFilter => _selectedFilter;

  void setFilter(DownloadFilter filter) {
    if (_selectedFilter == filter) {
      _selectedFilter = DownloadFilter.all;
    } else {
      _selectedFilter = filter;
    }
    notifyListeners();
  }
  final List<DownloadItemModel> _downloads = [
    DownloadItemModel(
      id: "1",
      thumbnailUrl: "assets/images/thumbnail1.png",
      videoUrl: "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
      isVideo: true,
    ),
    DownloadItemModel(
      id: "2",
      thumbnailUrl: "assets/images/thumbnail1.png",
      videoUrl: "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
      isVideo: true,
    ),
    DownloadItemModel(
      id: "3",
      thumbnailUrl: "assets/images/thumbnail1.png",
      isVideo: false,
    ),
    DownloadItemModel(
      id: "4",
      thumbnailUrl: "assets/images/thumbnail1.png",
      videoUrl: "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
      isVideo: true,
    ),
    DownloadItemModel(
      id: "5",
      thumbnailUrl: "assets/images/thumbnail1.png",
      isVideo: false,
    ),
  ];

  List<DownloadItemModel> get downloads {
    if (_selectedFilter == DownloadFilter.image) {
      return _downloads.where((item) => !item.isVideo).toList();
    } else if (_selectedFilter == DownloadFilter.video) {
      return _downloads.where((item) => item.isVideo).toList();
    }
    return _downloads;
  }
}