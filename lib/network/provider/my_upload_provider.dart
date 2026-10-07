import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class UploadItem {
  final String id;
  final String path;
  final bool isVideo;

  UploadItem({
    required this.id,
    required this.path,
    required this.isVideo,
  });
}

class UploadProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final List<UploadItem> _uploads = [];

  List<UploadItem> get uploads => List.unmodifiable(_uploads);

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  String _selectedTab = "Images";
  String get selectedTab => _selectedTab;

  void selectTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    await uploadFile(File(file.path), isVideo: false);
  }

  Future<void> pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (file == null) return;
    await uploadFile(File(file.path), isVideo: true);
  }

  Future<void> uploadFile(
      File file, {
        required bool isVideo,
      }) async {
    _isUploading = true;
    notifyListeners();

    try {
      // Replace this delay with your actual upload repository/API.
      await Future.delayed(const Duration(seconds: 1));

      _uploads.insert(
        0,
        UploadItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: file.path,
          isVideo: isVideo,
        ),
      );
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void deleteUpload(String id) {
    _uploads.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
