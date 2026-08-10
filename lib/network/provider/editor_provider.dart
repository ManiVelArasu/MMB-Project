import 'package:flutter/material.dart';
import 'package:project_mmb/core/app_provider/my_notifier.dart';
import '../../Api Model/editor_model.dart';
import '../../Repository/freeoic.dart';

class EditorProvider extends ChangeNotifier with MyNotifier {
  final List<EditorItem> _items = [];
  List<EditorItem> get items => _items;

  final List<List<EditorItem>> _history = [];
  int _historyIndex = -1;

  void _saveState() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(_items.map((e) => e.copyWith()).toList());
    _historyIndex = _history.length - 1;
  }

  String? selectedItemType;
  String? selectedItemId;
  String? selectedFrameUrl;

  List<String> freePikAssets = [];
  bool isFreePikLoading = false;
  List<String> freePikStickers = [];
  bool isStickersLoading = false;

  void setSelectedItem(String? type, String? id) {
    selectedItemType = type;
    selectedItemId = id;
    notifyListeners();
  }

  void setSelectedFrame(String frameUrl) {
    selectedFrameUrl = frameUrl;
    notifyListeners();
  }

  void clearSelection() {
    selectedItemType = null;
    selectedItemId = null;
    notifyListeners();
  }

  bool isTemplateLoaded = false;

  void loadItemsFromJson(List<Map<String, dynamic>> jsonList) {
    try {
      _items.clear();
      for (var json in jsonList) {
        String type = json['type'] ?? '';
        double left = (json['left'] ?? 0.0).toDouble();
        double top = (json['top'] ?? 0.0).toDouble();
        double width = (json['width'] ?? 100.0).toDouble();
        double height = (json['height'] ?? 100.0).toDouble();
        double scaleX = (json['scaleX'] ?? 1.0).toDouble();
        double scaleY = (json['scaleY'] ?? 1.0).toDouble();

        if (type == 'textbox') {
          double originalFontSize = (json['fontSize'] ?? 36.0).toDouble();

          _items.add(
            EditorItem(
              id: "${DateTime.now().millisecondsSinceEpoch}_$left",
              type: 'text',
              text: json['text'] ?? '',
              position: Offset(left, top),
              fontSize: originalFontSize > 50
                  ? originalFontSize * 0.45
                  : originalFontSize,
              color: _parseColor(json['fill']),
            ),
          );
        } else if (type == 'image') {
          String imageUrl = json['src'] ?? '';
          if (imageUrl.isNotEmpty) {
            _items.add(
              EditorItem(
                id: "${DateTime.now().millisecondsSinceEpoch}_$left",
                type: 'image',
                contentUrl: imageUrl,
                position: Offset(left, top),
                width: width * scaleX,
                height: height * scaleY,
                isLocal: false,
              ),
            );
          }
        } else if (type == 'rect' || type == 'circle') {
          _items.add(
            EditorItem(
              id: "${DateTime.now().millisecondsSinceEpoch}_$left",
              type: 'shape',
              position: Offset(left, top),
              width: width * scaleX,
              height: height * scaleY,
              color: _parseColor(json['fill']),
            ),
          );
        }
      }
      isTemplateLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint("JSON Load Error: $e");
    }
  }

  Color _parseColor(dynamic fillColor) {
    if (fillColor is String) {
      if (fillColor == 'white') return Colors.white;
      if (fillColor == 'black') return Colors.black;
      if (fillColor.startsWith('rgba')) {
        try {
          final cleaned = fillColor.replaceAll(RegExp(r'rgba\(|\)'), '');
          final parts = cleaned
              .split(',')
              .map((e) => double.parse(e.trim()))
              .toList();
          return Color.fromRGBO(
            parts[0].toInt(),
            parts[1].toInt(),
            parts[2].toInt(),
            parts[3],
          );
        } catch (_) {}
      }
    }
    return Colors.black;
  }

  void addText({String initialText = "New Text"}) {
    _saveState();
    _items.add(
      EditorItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'text',
        text: initialText,
        position: const Offset(120, 200),
        color: Colors.black87,
      ),
    );
    _saveState();
    notifyListeners();
  }

  void addEmoji(String emojiText) {
    addText(initialText: emojiText);
  }

  void addImage(String url, {bool isLocal = false}) {
    _saveState();
    _items.add(
      EditorItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'image',
        contentUrl: url,
        position: const Offset(100, 150),
        width: 220,
        height: 220,
        isLocal: isLocal,
        text: 'rounded',
      ),
    );
    _saveState();
    notifyListeners();
  }

  void addVideo(String videoUrl, {bool isLocal = false}) {
    if (videoUrl.trim().isEmpty) return;

    _saveState();

    final videoItem = EditorItem(
      id: "video_${DateTime.now().millisecondsSinceEpoch}",
      type: "video",
      contentUrl: videoUrl,
      position: const Offset(100, 100),
      width: 600,
      height: 400,
      isLocal: isLocal,
    );

    _items.add(videoItem);

    selectedItemType = "video";
    selectedItemId = videoItem.id;

    notifyListeners();
  }

  void updatePosition(String id, Offset newPos) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(position: newPos);
      notifyListeners();
    }
  }

  void updateRotation(String id, double rot) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(rotation: rot);
      notifyListeners();
    }
  }

  void updateScale(String id, double scl) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(scale: scl);
      notifyListeners();
    }
  }

  void updateFontSize(String id, double newSize) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(fontSize: newSize);
      notifyListeners();
    }
  }

  void updateOpacity(String id, double op) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(opacity: op);
      notifyListeners();
    }
  }

  void updateTextContent(String id, String newText) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(text: newText);
      notifyListeners();
    }
  }

  void setImageFilter(String id, String filterName) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(filterType: filterName);
      notifyListeners();
    }
  }

  void updateImageColorAdjustments(
    String id, {
    double? brightness,
    double? contrast,
    double? saturation,
  }) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        brightness: brightness ?? _items[index].brightness,
        contrast: contrast ?? _items[index].contrast,
        saturation: saturation ?? _items[index].saturation,
      );
      notifyListeners();
    }
  }

  void regenerateImageWithAi(String id, String prompt) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      String encodedPrompt = Uri.encodeComponent(prompt);
      int seed = DateTime.now().millisecondsSinceEpoch % 10000;
      String aiImageUrl =
          "https://image.pollinations.ai/prompt/$encodedPrompt?seed=$seed&nologo=true";

      _items[index] = _items[index].copyWith(
        contentUrl: aiImageUrl,
        isLocal: false,
      );
      notifyListeners();
    }
  }

  void updateTextColor(String id, Color newColor) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(color: newColor);
      notifyListeners();
    }
  }

  void setImageShape(String id, String shape, {double radius = 16.0}) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(text: shape, borderRadius: radius);
      notifyListeners();
    }
  }

  void updateOutline(String id, double width, Color color) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(
        outlineWidth: width,
        outlineColor: color,
      );
      notifyListeners();
    }
  }

  void bringToFront(String id) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      EditorItem item = _items.removeAt(index);
      _items.add(item);
      notifyListeners();
    }
  }

  void sendToBack(String id) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      EditorItem item = _items.removeAt(index);
      _items.insert(0, item);
      notifyListeners();
    }
  }

  void duplicateItem(String id) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      EditorItem newItem = _items[index].copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: _items[index].position + const Offset(20, 20),
      );
      _items.add(newItem);
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _saveState();
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _items.clear();
      _items.addAll(_history[_historyIndex].map((e) => e.copyWith()));
      notifyListeners();
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _items.clear();
      _items.addAll(_history[_historyIndex].map((e) => e.copyWith()));
      notifyListeners();
    }
  }

  Future<void> fetchFreePikAssets(String query) async {
    if (isFreePikLoading) return;
    isFreePikLoading = true;
    notifyListeners(); // 🚀 Loading start

    try {
      freePikAssets = await FreePikService.searchAssets(
        query,
      ).timeout(const Duration(seconds: 10), onTimeout: () => []);
    } catch (e) {
      debugPrint("Error fetching assets: $e");
      freePikAssets = [];
    } finally {
      isFreePikLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> fetchFreePikStickers(String query) async {
    if (isStickersLoading) return;
    isStickersLoading = true;
    notifyListeners(); // 🚀 Loading start

    try {
      freePikStickers = await FreePikService.searchAssets(
        "$query stickers",
      ).timeout(const Duration(seconds: 10), onTimeout: () => []);
    } catch (e) {
      debugPrint("Error fetching stickers: $e");
      freePikStickers = [];
    } finally {
      isStickersLoading = false;

      Future.microtask(() => notifyListeners());
    }
  }

  void updateImageContent(String id, String newUrl) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(
        contentUrl: newUrl,
        isLocal: !newUrl.startsWith('http'),
      );
      notifyListeners();
    }
  }

  void updateFontFamily(String itemId, String fontFamily) {
    final index = items.indexWhere((e) => e.id == itemId);
    if (index != -1) {
      items[index].fontFamily = fontFamily;
      notifyListeners();
    }
  }

  void updateFilter(String itemId, String filterType) {
    final index = items.indexWhere((e) => e.id == itemId);
    if (index != -1) {
      items[index] = items[index].copyWith(filterType: filterType);
      notifyListeners();
    }
  }

  void updateBrightness(String itemId, double value) {
    final index = items.indexWhere((e) => e.id == itemId);
    if (index != -1) {
      items[index] = items[index].copyWith(brightness: value);
      notifyListeners();
    }
  }

  void updateBorderRadius(String itemId, double radius) {
    final index = items.indexWhere((e) => e.id == itemId);

    if (index != -1) {
      items[index] = items[index].copyWith(borderRadius: radius);
      notifyListeners();
    }
  }

  void updateImageShape(String id, String shape) {
    int index = items.indexWhere((e) => e.id == id);

    if (index != -1) {
      items[index] = items[index].copyWith(text: shape);
      notifyListeners();
    }
  }

  void updateSize(String id, double width, double height) {
    int index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(width: width, height: height);
      notifyListeners();
    }
  }

  void updateCroppedImage(String id, String newImagePath) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(
        contentUrl: newImagePath,
        isLocal: true,
      );
      notifyListeners();
    }
  }

  List<String> _freePikVideos = [];
  List<String> get freePikVideos => _freePikVideos;

  bool _isVideoLoading = false;
  bool get isVideoLoading => _isVideoLoading;

  bool _isVideosLoading = false; // 🚀 லோடிங் ஸ்டேட் பெயர் தெளிவுக்காக
  bool get isVideosLoading => _isVideosLoading;

  Future<void> fetchFreePikVideos(String query) async {
    if (_isVideosLoading) return;

    _isVideosLoading = true;
    notifyListeners();

    try {
      final searchQuery =
      query.trim().isEmpty ? "background" : query.trim();

      debugPrint("Searching Freepik videos: $searchQuery");

      _freePikVideos = await FreePikService.searchVideos(
        searchQuery,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("Freepik video search timeout");
          return [];
        },
      );

      debugPrint(
        "Freepik videos found: ${_freePikVideos.length}",
      );
    } catch (e, stackTrace) {
      debugPrint("Fetch Freepik Videos Error: $e");
      debugPrint("$stackTrace");

      _freePikVideos = [];
    } finally {
      _isVideosLoading = false;
      notifyListeners();
    }
  }

  // 🚀 1. Background Image-ஐ முழு ஸ்கிரீனுக்கு செட் செய்ய
  // 🚀 1. Background Image-ஐ முழு ஸ்கிரீனுக்கு செட் செய்ய
  // 🚀 1. Background Image-ஐ முழு ஸ்கிரீனுக்கு செட் செய்ய
  void setBackgroundImage(String imageUrl) {
    _saveState(); // Undo/Redo க்காக

    // 0,0 பொசிஷனில் உள்ள முதல் பேக்ரவுண்ட் லேயரைத் தேடுதல்
    int bgIndex = _items.indexWhere(
      (item) =>
          item.position.dx == 0 &&
          item.position.dy == 0 &&
          (item.type == 'image' ||
              item.type == 'shape' ||
              item.type == 'video'),
    );

    if (bgIndex != -1) {
      _items[bgIndex] = _items[bgIndex].copyWith(
        type: 'image',
        contentUrl: imageUrl,
        isLocal: false,
      );
    } else {
      _items.insert(
        0,
        EditorItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'image',
          position: const Offset(0, 0),
          width: 1080.0,
          height: 1080.0,
          contentUrl: imageUrl,
          isLocal: false,
        ),
      );
    }
    notifyListeners();
  }

  void setBackgroundVideo(String videoUrl) {
    _saveState(); // Undo/Redo க்காக

    int bgIndex = _items.indexWhere(
      (item) =>
          item.position.dx == 0 &&
          item.position.dy == 0 &&
          (item.type == 'image' ||
              item.type == 'shape' ||
              item.type == 'video'),
    );

    if (bgIndex != -1) {
      _items[bgIndex] = _items[bgIndex].copyWith(
        type: 'video', // 🚀 named parameter சரியாகக் கொடுக்கப்பட்டுள்ளது
        contentUrl: videoUrl,
        isLocal: false,
      );
    } else {
      _items.insert(
        0,
        EditorItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'video',
          position: const Offset(0, 0),
          width: 1080.0,
          height: 1080.0,
          contentUrl: videoUrl,
          isLocal: false,
        ),
      );
    }
    notifyListeners();
  }
  String? get backgroundImageUrl {
    final bgItem = _items.firstWhere(
          (item) => item.position.dx == 0 && item.position.dy == 0 && item.type == 'image',
      orElse: () => EditorItem(id: '', type: '', position: Offset.zero),
    );
    return bgItem.contentUrl;
  }

  String? get backgroundVideoUrl {
    final bgItem = _items.firstWhere(
          (item) => item.position.dx == 0 && item.position.dy == 0 && item.type == 'video',
      orElse: () => EditorItem(id: '', type: '', position: Offset.zero),
    );
    return bgItem.contentUrl;
  }
}
