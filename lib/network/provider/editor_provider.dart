
import 'package:flutter/material.dart';

import '../../Api Model/editor_model.dart';
import '../../Repository/freeoic.dart';
import '../../core/app_provider/my_notifier.dart';

class EditorProvider extends ChangeNotifier with MyNotifier {
  final List<EditorItem> _items = [];
  List<EditorItem> get items => _items;

  final List<List<EditorItem>> _history = [];
  int _historyIndex = -1;
  Color _backgroundColor = Colors.white;
  final Map<String, double> _textLetterSpacing = {};
  final Map<String, double> _textLineSpacing = {};
  final Map<String, TextAlign> _textAlignment = {};
  final Map<String, FontWeight> _textWeight = {};
  final Map<String, FontStyle> _textStyle = {};
  final Map<String, bool> _textUnderline = {};

  double textLetterSpacing(String id) => _textLetterSpacing[id] ?? 0.0;
  double textLineSpacing(String id) => _textLineSpacing[id] ?? 1.0;
  TextAlign textAlignment(String id) => _textAlignment[id] ?? TextAlign.left;
  FontWeight textWeight(String id) => _textWeight[id] ?? FontWeight.bold;
  FontStyle textStyle(String id) => _textStyle[id] ?? FontStyle.normal;
  bool textUnderline(String id) => _textUnderline[id] ?? false;
  EditorItem? _copiedItem;
  int? _copiedFromPageIndex;

  List<EditorItem>? _copiedPageItems;
  int? _copiedPageIndex;
  Color? _copiedPageBackgroundColor;

  final Map<String, double> _copiedLetterSpacing = {};
  final Map<String, double> _copiedLineSpacing = {};
  final Map<String, TextAlign> _copiedAlignment = {};
  final Map<String, FontWeight> _copiedWeight = {};
  final Map<String, FontStyle> _copiedStyle = {};
  final Map<String, bool> _copiedUnderline = {};
  final Map<String, double> _copiedFilterIntensity = {};

  bool get hasCopiedPage =>
      _copiedPageItems != null && _copiedPageItems!.isNotEmpty;

  bool get canPasteCopiedPage => hasCopiedPage;

  bool get hasCopiedItem => _copiedItem != null;

  bool get canPasteCopiedItem {
    return _copiedItem != null &&
        _copiedFromPageIndex != null &&
        _copiedFromPageIndex != _currentPageIndex;
  }
  void updateTextLetterSpacing(String id, double value) {
    _textLetterSpacing[id] = value.clamp(-2.0, 20.0);
    notifyListeners();
  }

  void updateTextLineSpacing(String id, double value) {
    _textLineSpacing[id] = value.clamp(0.7, 3.0);
    notifyListeners();
  }

  void updateTextAlignment(String id, TextAlign value) {
    _textAlignment[id] = value;
    notifyListeners();
  }

  void toggleTextBold(String id) {
    _textWeight[id] = textWeight(id) == FontWeight.bold
        ? FontWeight.normal
        : FontWeight.bold;
    notifyListeners();
  }

  void toggleTextItalic(String id) {
    _textStyle[id] = textStyle(id) == FontStyle.italic
        ? FontStyle.normal
        : FontStyle.italic;
    notifyListeners();
  }

  void toggleTextUnderline(String id) {
    _textUnderline[id] = !textUnderline(id);
    notifyListeners();
  }

  void setTextNormal(String id) {
    _textWeight[id] = FontWeight.normal;
    _textStyle[id] = FontStyle.normal;
    _textUnderline[id] = false;
    notifyListeners();
  }
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
  // Keep background search results completely separate from element results.
  List<String> backgroundAssets = [];
  bool isBackgroundLoading = false;
  String _backgroundQuery = '';
  final Map<String, int> _backgroundRequestIds = {};

  // Element categories keep their own results/loading state.
  final Map<String, List<String>> _elementCategoryAssets = {};
  final Map<String, bool> _elementCategoryLoading = {};
  final Map<String, int> _elementCategoryRequestIds = {};

  List<String> elementCategoryAssets(String query) =>
      List.unmodifiable(_elementCategoryAssets[query] ?? const <String>[]);

  bool isElementCategoryLoading(String query) =>
      _elementCategoryLoading[query] ?? false;


  // Background category assets loaded from the existing Freepik API.
  List<String> freePikShapes = [];
  List<String> freePikSocialMedia = [];
  List<String> freePikEcommerce = [];

  bool isShapesLoading = false;
  bool isSocialMediaLoading = false;
  bool isEcommerceLoading = false;

  Future<List<String>> _fetchFreepikCategory(
      String query, {
        required void Function(bool) setLoading,
        required void Function(List<String>) setData,
      }) async {
    setLoading(true);
    notifyListeners();
    try {
      final result = await FreePikService.searchAssets(
        query,
        limit: 20,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => <String>[],
      );
      setData(result);
      return result;
    } catch (e) {
      debugPrint('Freepik category error [$query]: $e');
      setData(<String>[]);
      return <String>[];
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Loads background assets into a dedicated state.
  /// A request token prevents a late response from an older search from
  /// replacing the currently selected category/search results.
  Future<void> fetchBackgroundAssets(String query) async {
    final normalized =
    query.trim().isEmpty ? 'abstract background' : query.trim();

    final requestId = (_backgroundRequestIds[normalized] ?? 0) + 1;
    _backgroundRequestIds[normalized] = requestId;

    _backgroundQuery = normalized;
    isBackgroundLoading = true;
    backgroundAssets = <String>[];
    notifyListeners();

    try {
      final result = await FreePikService.searchAssets(
        normalized,
        limit: 30,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => <String>[],
      );

      // Only apply the response if this is still the latest request for
      // this query and the user has not moved to another background query.
      if (_backgroundRequestIds[normalized] == requestId &&
          _backgroundQuery == normalized) {
        backgroundAssets = result.toSet().toList();
      }
    } catch (e) {
      debugPrint('Background Freepik error [$normalized]: $e');
      if (_backgroundRequestIds[normalized] == requestId &&
          _backgroundQuery == normalized) {
        backgroundAssets = <String>[];
      }
    } finally {
      if (_backgroundRequestIds[normalized] == requestId &&
          _backgroundQuery == normalized) {
        isBackgroundLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads one element category without touching backgroundAssets or the
  /// generic freePikAssets list.
  Future<void> fetchElementCategory(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final requestId = (_elementCategoryRequestIds[normalized] ?? 0) + 1;
    _elementCategoryRequestIds[normalized] = requestId;

    _elementCategoryLoading[normalized] = true;
    _elementCategoryAssets[normalized] = <String>[];
    notifyListeners();

    try {
      final result = await FreePikService.searchAssets(
        normalized,
        limit: 20,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => <String>[],
      );

      if (_elementCategoryRequestIds[normalized] == requestId) {
        _elementCategoryAssets[normalized] = result.toSet().toList();
      }
    } catch (e) {
      debugPrint('Element category error [$normalized]: $e');
      if (_elementCategoryRequestIds[normalized] == requestId) {
        _elementCategoryAssets[normalized] = <String>[];
      }
    } finally {
      if (_elementCategoryRequestIds[normalized] == requestId) {
        _elementCategoryLoading[normalized] = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchFreePikBackgroundCategories() async {
    await Future.wait([
      fetchFreePikShapes(),
      fetchFreePikSocialMedia(),
      fetchFreePikEcommerce(),
      fetchFreePikStickers('stickers'),
    ]);
  }

  Future<void> fetchFreePikShapes() async {
    await _fetchFreepikCategory(
      'shapes vector icons elements',
      setLoading: (value) => isShapesLoading = value,
      setData: (value) => freePikShapes = value,
    );
  }

  Future<void> fetchFreePikSocialMedia() async {
    await _fetchFreepikCategory(
      'social media icons stickers',
      setLoading: (value) => isSocialMediaLoading = value,
      setData: (value) => freePikSocialMedia = value,
    );
  }

  Future<void> fetchFreePikEcommerce() async {
    await _fetchFreepikCategory(
      'ecommerce shopping online store icons',
      setLoading: (value) => isEcommerceLoading = value,
      setData: (value) => freePikEcommerce = value,
    );
  }

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
      _pages
        ..clear()
        ..add(_items.map((e) => e.copyWith()).toList());
      _currentPageIndex = 0;
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
        width: 600,
        height: 180,
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
    final imageId = DateTime.now().millisecondsSinceEpoch.toString();
    _items.add(
      EditorItem(
        id: imageId,
        type: 'image',
        contentUrl: url,
        position: const Offset(100, 150),
        width: 220,
        height: 220,
        isLocal: isLocal,
        text: 'rounded',
      ),
    );

    // Newly uploaded/added media is selected immediately.
    // The selection toolbar will then appear above the main bottom navigation,
    // including REPLACE BG / CROP / EDIT IMAGE / REMOVE.
    selectedItemType = 'image';
    selectedItemId = imageId;
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
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
      _items[index] = _items[index].copyWith(filterType: filterName);
      _syncCurrentPage();
      notifyListeners();
    }
  }

  void updateImageColorAdjustments(
      String id, {
        double? brightness,
        double? contrast,
        double? saturation,
      }) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _saveState();
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
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _saveState();
    _items.removeAt(index);

    if (selectedItemId == id) {
      selectedItemId = null;
      selectedItemType = null;
    }

    notifyListeners();
  }

  /// Exportable JSON for the current editor page.
  /// This intentionally keeps the existing EditorItem model untouched.
  Map<String, dynamic> exportCurrentPageJson() {
    String colorToHex(Color? color) {
      if (color == null) return '#FFFFFFFF';
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }

    return {
      'version': 1,
      'page': currentPageIndex + 1,
      'backgroundColor': colorToHex(_backgroundColor),
      'items': _items.map((item) {
        final id = item.id ?? '';
        return {
          'id': id,
          'type': item.type,
          'text': item.text,
          'contentUrl': item.contentUrl,
          'isLocal': item.isLocal,
          'left': item.position.dx,
          'top': item.position.dy,
          'width': item.width,
          'height': item.height,
          'scale': item.scale,
          'rotation': item.rotation,
          'opacity': item.opacity,
          'fontSize': item.fontSize,
          'fontFamily': item.fontFamily,
          'color': colorToHex(item.color),
          'filterType': item.filterType,
          'brightness': item.brightness,
          'contrast': item.contrast,
          'saturation': item.saturation,
          'borderRadius': item.borderRadius,
          'outlineWidth': item.outlineWidth,
          'outlineColor': colorToHex(item.outlineColor),
          'textFormatting': {
            'letterSpacing': textLetterSpacing(id),
            'lineSpacing': textLineSpacing(id),
            'alignment': textAlignment(id).name,
            'fontWeight': textWeight(id).value,
            'fontStyle': textStyle(id).name,
            'underline': textUnderline(id),
          },
        };
      }).toList(),
    };
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
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    // Generic/legacy element search. Keep this list independent from
    // backgroundAssets. Also guard against stale responses.
    final requestId = (_elementCategoryRequestIds['__generic__'] ?? 0) + 1;
    _elementCategoryRequestIds['__generic__'] = requestId;

    isFreePikLoading = true;
    freePikAssets = <String>[];
    notifyListeners();

    try {
      final result = await FreePikService.searchAssets(
        normalized,
        limit: 20,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => <String>[],
      );

      if (_elementCategoryRequestIds['__generic__'] == requestId) {
        freePikAssets = result.toSet().toList();
      }
    } catch (e) {
      debugPrint("Error fetching assets: $e");
      if (_elementCategoryRequestIds['__generic__'] == requestId) {
        freePikAssets = <String>[];
      }
    } finally {
      if (_elementCategoryRequestIds['__generic__'] == requestId) {
        isFreePikLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchFreePikStickers(String query) async {
    final normalized = query.trim().isEmpty ? 'stickers' : query.trim();
    final requestId = (_elementCategoryRequestIds['__stickers__'] ?? 0) + 1;
    _elementCategoryRequestIds['__stickers__'] = requestId;

    isStickersLoading = true;
    freePikStickers = <String>[];
    notifyListeners();

    try {
      final result = await FreePikService.searchAssets(
        '$normalized stickers',
        limit: 20,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => <String>[],
      );

      if (_elementCategoryRequestIds['__stickers__'] == requestId) {
        freePikStickers = result.toSet().toList();
      }
    } catch (e) {
      debugPrint("Error fetching stickers: $e");
      if (_elementCategoryRequestIds['__stickers__'] == requestId) {
        freePikStickers = <String>[];
      }
    } finally {
      if (_elementCategoryRequestIds['__stickers__'] == requestId) {
        isStickersLoading = false;
        notifyListeners();
      }
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
    if (index == -1) return;

    _saveState();
    items[index] = items[index].copyWith(borderRadius: radius.clamp(0.0, 500.0));
    notifyListeners();
  }

  void updateImageShape(String id, String shape) {
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _saveState();
    final radius = items[index].borderRadius;
    items[index] = items[index].copyWith(
      text: shape,
      borderRadius: radius,
    );
    _syncCurrentPage();
    notifyListeners();
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

  final bool _isVideoLoading = false;
  bool get isVideoLoading => _isVideoLoading;

  bool _isVideosLoading = false;
  bool get isVideosLoading => _isVideosLoading;

  Future<void> fetchFreePikVideos(String query) async {
    if (_isVideosLoading) return;

    _isVideosLoading = true;
    notifyListeners();

    try {
      final searchQuery = query.trim().isEmpty ? "background" : query.trim();

      debugPrint("Searching Freepik videos: $searchQuery");

      _freePikVideos = await FreePikService.searchVideos(searchQuery).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("Freepik video search timeout");
          return [];
        },
      );

      debugPrint("Freepik videos found: ${_freePikVideos.length}");
    } catch (e, stackTrace) {
      debugPrint("Fetch Freepik Videos Error: $e");
      debugPrint("$stackTrace");

      _freePikVideos = [];
    } finally {
      _isVideosLoading = false;
      notifyListeners();
    }
  }

  void setBackgroundImage(String imageUrl) {
    _saveState();

    // Replace the previous background completely.
    // A background image must not leave the previous color behind.
    _removeBackgroundLayers();
    _backgroundColor = Colors.transparent;

    final bgId =
        'bg_${DateTime.now().millisecondsSinceEpoch}';

    _items.insert(
      0,
      EditorItem(
        id: bgId,
        type: 'image',
        position: const Offset(0, 0),
        width: 1080.0,
        height: 1080.0,
        contentUrl: imageUrl,
        isLocal: !imageUrl.startsWith('http'),
      ),
    );

    selectedItemType = 'image';
    selectedItemId = bgId;

    _syncCurrentPage();
    notifyListeners();
  }

  void setBackgroundVideo(String videoUrl) {
    _saveState();

    // Replace the previous background completely.
    _removeBackgroundLayers();
    _backgroundColor = Colors.transparent;

    // புதிய பேக்ரவுண்ட் வீடியோவை முதல் லேயராக சேர்ப்பது
    final bgId = 'bg_video_${DateTime.now().millisecondsSinceEpoch}';

    _items.insert(
      0,
      EditorItem(
        id: bgId,
        type: 'video',
        position: const Offset(0, 0),
        width: 1080.0,
        height: 1080.0,
        contentUrl: videoUrl,
        isLocal: !videoUrl.startsWith('http'),
      ),
    );

    selectedItemType = 'video';
    selectedItemId = bgId;
    _syncCurrentPage();
    notifyListeners();
  }

  Color get backgroundColor => _backgroundColor;

  String? get backgroundImageUrl {
    final bgItem = _items.firstWhere(
          (item) =>
      item.position.dx == 0 &&
          item.position.dy == 0 &&
          item.type == 'image',
      orElse: () => EditorItem(id: '', type: '', position: Offset.zero),
    );
    return bgItem.contentUrl;
  }

  String? get backgroundVideoUrl {
    final bgItem = _items.firstWhere(
          (item) =>
      item.position.dx == 0 &&
          item.position.dy == 0 &&
          item.type == 'video',
      orElse: () => EditorItem(id: '', type: '', position: Offset.zero),
    );
    return bgItem.contentUrl;
  }

  // 🚀 ----------------------------------------------------
  // 🚀 புதிய REPLACE BG வசதிக்காக மட்டும் சேர்க்கப்பட்ட பாதுகாப்பு மெத்தடுகள் (Existing code பாதிக்கப்படாது)
  // 🚀 ----------------------------------------------------
  void replaceBackgroundImage(
      String imageUrl,
      String selectedItemIdToRemove,
      ) {
    _saveState();

    // Remove the old background even if it was moved, scaled or rotated.
    _removeBackgroundLayers();

    // If the selected item was a normal media image, remove it too.
    _items.removeWhere(
          (item) => item.id == selectedItemIdToRemove,
    );

    final bgId =
        'bg_${DateTime.now().millisecondsSinceEpoch}';

    _items.insert(
      0,
      EditorItem(
        id: bgId,
        type: 'image',
        position: const Offset(0, 0),
        width: 1080.0,
        height: 1080.0,
        contentUrl: imageUrl,
        isLocal: !imageUrl.startsWith('http'),
      ),
    );

    selectedItemType = 'image';
    selectedItemId = bgId;

    notifyListeners();
  }

  final Map<String, double> _imageFilterIntensity = {};

  double imageFilterIntensity(String id) => _imageFilterIntensity[id] ?? 1.0;

  void updateImageFilterIntensity(String id, double value) {
    _saveState();
    _imageFilterIntensity[id] = value.clamp(0.0, 1.0);
    _syncCurrentPage();
    notifyListeners();
  }

  final Map<String, bool> _imageFlipX = {};
  final Map<String, bool> _imageFlipY = {};

  bool isImageFlippedX(String id) => _imageFlipX[id] ?? false;
  bool isImageFlippedY(String id) => _imageFlipY[id] ?? false;

  void flipImageHorizontal(String id) {
    _saveState();
    _imageFlipX[id] = !(_imageFlipX[id] ?? false);
    notifyListeners();
  }

  void flipImageVertical(String id) {
    _saveState();
    _imageFlipY[id] = !(_imageFlipY[id] ?? false);
    notifyListeners();
  }

  bool _isBackgroundLayer(EditorItem item) {
    final isBackgroundType =
        item.type == 'image' ||
            item.type == 'video' ||
            item.type == 'shape';

    // bg_ IDs are stable even after drag/scale/rotate.
    if (item.id?.startsWith('bg_') == true && isBackgroundType) {
      return true;
    }

    // Backward compatibility for older saved projects.
    return item.position.dx == 0 &&
        item.position.dy == 0 &&
        item.width >= 1000 &&
        item.height >= 1000 &&
        isBackgroundType;
  }

  void _removeBackgroundLayers() {
    _items.removeWhere(_isBackgroundLayer);
  }

  void setBackgroundColor(Color color) {
    _saveState();

    // A color background replaces any image/video background.
    _removeBackgroundLayers();
    _backgroundColor = color;
    selectedItemId = null;
    selectedItemType = null;
    selectedFrameUrl = null;

    // Keep the current page state in sync immediately.
    _syncCurrentPage();
    notifyListeners();
  }
  // ========================= PAGE MANAGEMENT =========================
  final List<List<EditorItem>> _pages = [];
  int _currentPageIndex = 0;

  int get pageCount => _pages.isEmpty ? 1 : _pages.length;
  int get currentPageIndex => _currentPageIndex;

  void _syncCurrentPage() {
    if (_pages.isEmpty) {
      _pages.add(_items.map((e) => e.copyWith()).toList());
      _currentPageIndex = 0;
      return;
    }
    _pages[_currentPageIndex] =
        _items.map((e) => e.copyWith()).toList();
  }

  void addPage({bool duplicateCurrent = false}) {
    _syncCurrentPage();
    final source = duplicateCurrent
        ? _items.map((e) => e.copyWith(
      id: '${DateTime.now().microsecondsSinceEpoch}_${e.id}',
    )).toList()
        : <EditorItem>[];
    _pages.add(source);
    _currentPageIndex = _pages.length - 1;
    _items
      ..clear()
      ..addAll(source.map((e) => e.copyWith()));
    clearSelection();
    notifyListeners();
  }

  void duplicateCurrentPage() => addPage(duplicateCurrent: true);

  void switchPage(int index) {
    if (index < 0 || index >= pageCount || index == _currentPageIndex) return;
    _syncCurrentPage();
    _currentPageIndex = index;
    final page = _pages[index];
    _items
      ..clear()
      ..addAll(page.map((e) => e.copyWith()));
    clearSelection();
    notifyListeners();
  }

  void deleteCurrentPage() {
    if (pageCount <= 1) {
      _items.clear();
      clearSelection();
      notifyListeners();
      return;
    }
    _pages.removeAt(_currentPageIndex);
    if (_currentPageIndex >= _pages.length) {
      _currentPageIndex = _pages.length - 1;
    }
    _items
      ..clear()
      ..addAll(_pages[_currentPageIndex].map((e) => e.copyWith()));
    clearSelection();
    notifyListeners();
  }

  // ============================================================
  // COPY ENTIRE CURRENT PAGE
  // ============================================================
  void copyCurrentPage() {
    _syncCurrentPage();

    if (_items.isEmpty) {
      debugPrint('Copy page: no items');
      return;
    }

    _copiedPageItems = _items.map((item) => item.copyWith()).toList();
    _copiedPageIndex = _currentPageIndex;
    _copiedPageBackgroundColor = _backgroundColor;

    _copiedLetterSpacing.clear();
    _copiedLineSpacing.clear();
    _copiedAlignment.clear();
    _copiedWeight.clear();
    _copiedStyle.clear();
    _copiedUnderline.clear();
    _copiedFilterIntensity.clear();

    for (final item in _items) {
      final id = item.id;
      if (id == null) continue;

      _copiedLetterSpacing[id] = textLetterSpacing(id);
      _copiedLineSpacing[id] = textLineSpacing(id);
      _copiedAlignment[id] = textAlignment(id);
      _copiedWeight[id] = textWeight(id);
      _copiedStyle[id] = textStyle(id);
      _copiedUnderline[id] = textUnderline(id);
      _copiedFilterIntensity[id] = imageFilterIntensity(id);
    }

    notifyListeners();
  }

  // ============================================================
  // PASTE ENTIRE COPIED PAGE INTO ANOTHER PAGE
  // ============================================================
  bool pasteCopiedPage() {
    if (!hasCopiedPage) {
      debugPrint('Paste page: nothing copied');
      return false;
    }

    _saveState();

    final pastedItems = <EditorItem>[];

    for (var i = 0; i < _copiedPageItems!.length; i++) {
      final source = _copiedPageItems![i];
      final oldId = source.id ?? 'item_$i';
      final newId =
          'page_${_currentPageIndex}_${DateTime.now().microsecondsSinceEpoch}_$i';

      pastedItems.add(source.copyWith(id: newId));

      _textLetterSpacing[newId] =
          _copiedLetterSpacing[oldId] ?? 0.0;
      _textLineSpacing[newId] =
          _copiedLineSpacing[oldId] ?? 1.0;
      _textAlignment[newId] =
          _copiedAlignment[oldId] ?? TextAlign.left;
      _textWeight[newId] =
          _copiedWeight[oldId] ?? FontWeight.bold;
      _textStyle[newId] =
          _copiedStyle[oldId] ?? FontStyle.normal;
      _textUnderline[newId] =
          _copiedUnderline[oldId] ?? false;
      _imageFilterIntensity[newId] =
          _copiedFilterIntensity[oldId] ?? 1.0;
    }

    // Paste means duplicate into the current page. Do not wipe existing
    // content; this also works when copying and pasting on the same page.
    _items.addAll(pastedItems);

    // Restore the copied page background.
    if (_copiedPageBackgroundColor != null) {
      _backgroundColor = _copiedPageBackgroundColor!;
    }

    selectedItemId = pastedItems.isNotEmpty ? pastedItems.first.id : null;
    selectedItemType =
    pastedItems.isNotEmpty ? pastedItems.first.type : null;

    _syncCurrentPage();
    notifyListeners();

    debugPrint(
      'FULL PAGE PASTED: ${pastedItems.length} items -> '
          'Page ${_currentPageIndex + 1}',
    );

    return true;
  }

  void copySelectedItem() {
    final id = selectedItemId;

    if (id == null) return;

    final index = _items.indexWhere((e) => e.id == id);

    if (index == -1) return;

    // Store a copy, don't duplicate on current page.
    _copiedItem = _items[index].copyWith();

    // Remember which page copied from.
    _copiedFromPageIndex = _currentPageIndex;

    notifyListeners();
  }
  bool pasteCopiedItem() {
    if (_copiedItem == null) return false;

    _saveState();

    final source = _copiedItem!;

    final newItem = source.copyWith(
      id: 'item_${DateTime.now().microsecondsSinceEpoch}',
      position: source.position + const Offset(30, 30),
    );

    _items.add(newItem);

    selectedItemId = newItem.id;
    selectedItemType = newItem.type;

    _syncCurrentPage();

    notifyListeners();

    return true;
  }



  /// Updates position, scale and rotation in a single provider notification.
  /// Used by interactive canvas/background gestures.
  void updateItemTransform(
      String id, {
        Offset? position,
        double? scale,
        double? rotation,
      }) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = _items[index];

    _items[index] = current.copyWith(
      position: position ?? current.position,
      scale: scale ?? current.scale,
      rotation: rotation ?? current.rotation,
    );

    notifyListeners();
  }

}


