import '../../Api Model/template_edit_model.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../Api Model/editor_model.dart';
import '../../Repository/freePic.dart';
import '../../Repository/template_edit_repository.dart';
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

  double canvasWidth = 1080.0;
  double canvasHeight = 1080.0;

  void setCanvasSize(double width, double height) {
    final w = width.isFinite && width > 0 ? width : 1080.0;
    final h = height.isFinite && height > 0 ? height : 1080.0;

    if ((canvasWidth - w).abs() < 0.01 && (canvasHeight - h).abs() < 0.01) {
      return;
    }

    canvasWidth = w;
    canvasHeight = h;

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (_isBackgroundLayer(item)) {
        _items[i] = item.copyWith(position: Offset.zero);
        continue;
      }

      final safeScale = _maxScaleForFrame(item, item.scale);
      final scaled = item.copyWith(scale: safeScale);
      _items[i] = scaled.copyWith(
        position: _clampPositionForFrame(scaled, scaled.position),
      );
    }
  }

  double _rotationExtentX(EditorItem item, double scale) {
    final w = math.max(1.0, item.width);
    final h = math.max(1.0, item.height);
    final angle = item.rotation.isFinite ? item.rotation : 0.0;
    final c = math.cos(angle).abs();
    final s = math.sin(angle).abs();
    return ((w * c) + (h * s)) * scale / 2.0;
  }

  double _rotationExtentY(EditorItem item, double scale) {
    final w = math.max(1.0, item.width);
    final h = math.max(1.0, item.height);
    final angle = item.rotation.isFinite ? item.rotation : 0.0;
    final c = math.cos(angle).abs();
    final s = math.sin(angle).abs();
    return ((w * s) + (h * c)) * scale / 2.0;
  }

  Offset _clampPositionForFrame(EditorItem item, Offset position) {
    if (_isBackgroundLayer(item)) return Offset.zero;

    final scale = (item.scale.isFinite ? item.scale : 1.0)
        .clamp(0.05, 10.0)
        .toDouble();

    final baseW = math.max(1.0, item.width);
    final baseH = math.max(1.0, item.height);

    final extentX = _rotationExtentX(item, scale);
    final extentY = _rotationExtentY(item, scale);

    var centerX = position.dx + baseW / 2.0;
    var centerY = position.dy + baseH / 2.0;

    if (extentX * 2.0 >= canvasWidth) {
      centerX = canvasWidth / 2.0;
    } else {
      centerX = centerX.clamp(extentX, canvasWidth - extentX).toDouble();
    }

    if (extentY * 2.0 >= canvasHeight) {
      centerY = canvasHeight / 2.0;
    } else {
      centerY = centerY.clamp(extentY, canvasHeight - extentY).toDouble();
    }

    return Offset(centerX - baseW / 2.0, centerY - baseH / 2.0);
  }

  double _maxScaleForFrame(EditorItem item, double requested) {
    if (_isBackgroundLayer(item)) {
      return requested.clamp(0.01, 10.0).toDouble();
    }

    final safeRequested = requested.isFinite
        ? requested.clamp(0.05, 10.0).toDouble()
        : 1.0;

    final baseW = math.max(1.0, item.width);
    final baseH = math.max(1.0, item.height);

    final centerX = item.position.dx + baseW / 2.0;
    final centerY = item.position.dy + baseH / 2.0;

    final angle = item.rotation.isFinite ? item.rotation : 0.0;
    final c = math.cos(angle).abs();
    final s = math.sin(angle).abs();

    final extentXAtOne = (baseW * c + baseH * s) / 2.0;
    final extentYAtOne = (baseW * s + baseH * c) / 2.0;

    final limitX = extentXAtOne <= 0
        ? 10.0
        : math.min(
      centerX / extentXAtOne,
      (canvasWidth - centerX) / extentXAtOne,
    );

    final limitY = extentYAtOne <= 0
        ? 10.0
        : math.min(
      centerY / extentYAtOne,
      (canvasHeight - centerY) / extentYAtOne,
    );

    final maxAllowed = math.max(0.05, math.min(10.0, math.min(limitX, limitY)));

    return math.min(safeRequested, maxAllowed).clamp(0.05, 10.0).toDouble();
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

  // Media -> Images (Pexels) keeps its own state so it never conflicts
  // with the Background panel results.
  List<String> mediaImageAssets = [];
  bool isMediaImagesLoading = false;
  String _mediaImagesQuery = '';
  String get mediaImagesQuery => _mediaImagesQuery;
  int _mediaImagesRequestId = 0;

  // Element categories keep their own results/loading state.
  final Map<String, List<String>> _elementCategoryAssets = {};
  final Set<String> _elementCategoryRequested = <String>{};
  final Map<String, List<AssetCategoryItem>> _assetCategoryItems = {};
  final Map<String, bool> _elementCategoryLoading = {};
  // Loading state for the backend Freepik sticker proxy categories.
  // Keys: stickers, social media, e-commerce
  final Map<String, bool> _isFreePikStickerCategoryLoading = {};
  final Map<String, int> _elementCategoryRequestIds = {};

  List<String> elementCategoryAssets(String query) =>
      List.unmodifiable(_elementCategoryAssets[query] ?? const <String>[]);

  List<AssetCategoryItem> assetCategoryItems(String query) => List.unmodifiable(
    _assetCategoryItems[query] ?? const <AssetCategoryItem>[],
  );

  bool isElementCategoryLoading(String query) =>
      _elementCategoryLoading[query.trim().toLowerCase()] ?? false;

  // Public getter used by the Elements UI.
  Map<String, bool> get isFreePikStickerCategoryLoading =>
      Map.unmodifiable(_isFreePikStickerCategoryLoading);

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
        page: 1,
        limit: 30,
      ).timeout(const Duration(seconds: 20), onTimeout: () => <String>[]);
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
    final normalized = query.trim().isEmpty
        ? 'abstract background'
        : query.trim();

    final requestId = (_backgroundRequestIds[normalized] ?? 0) + 1;
    _backgroundRequestIds[normalized] = requestId;

    _backgroundQuery = normalized;
    isBackgroundLoading = true;
    backgroundAssets = <String>[];
    notifyListeners();

    try {
      final result = await FreePikService.searchPexelsPhotos(
        normalized,
        page: 1,
        limit: 24,
      ).timeout(const Duration(seconds: 15), onTimeout: () => <String>[]);

      // Only apply the response if this is still the latest request for
      // this query and the user has not moved to another background query.
      if (_backgroundRequestIds[normalized] == requestId &&
          _backgroundQuery == normalized) {
        backgroundAssets = result.toSet().toList();
      }
    } catch (e) {
      debugPrint('Background Pexels error [$normalized]: $e');
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

  Future<void> fetchMediaImages(String query) async {
    final normalized = query.trim().isEmpty ? 'background' : query.trim();
    final requestId = ++_mediaImagesRequestId;

    _mediaImagesQuery = normalized;
    isMediaImagesLoading = true;
    mediaImageAssets = <String>[];
    notifyListeners();

    try {
      final result = await FreePikService.searchPexelsPhotos(
        normalized,
        page: 1,
        limit: 24,
      ).timeout(const Duration(seconds: 20), onTimeout: () => <String>[]);

      if (requestId == _mediaImagesRequestId &&
          _mediaImagesQuery == normalized) {
        mediaImageAssets = result
            .where((url) => url.trim().isNotEmpty)
            .toSet()
            .toList();
      }
    } catch (e) {
      debugPrint('Media Pexels images error [$normalized]: $e');
      if (requestId == _mediaImagesRequestId &&
          _mediaImagesQuery == normalized) {
        mediaImageAssets = <String>[];
      }
    } finally {
      if (requestId == _mediaImagesRequestId &&
          _mediaImagesQuery == normalized) {
        isMediaImagesLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads one element category without touching backgroundAssets or the
  /// generic freePikAssets list.
  Future<void> fetchElementCategory(
      String query, {
        int page = 1,
        int limit = 4,
        bool append = false,
      }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return;

    // Prevent StatefulBuilder rebuilds from starting the same empty/error
    // request again and again.
    if (!append &&
        page == 1 &&
        _elementCategoryRequested.contains(normalized)) {
      return;
    }
    if (!append && page == 1) {
      _elementCategoryRequested.add(normalized);
    }

    final requestKey = '${normalized}__$page';
    final requestId = (_elementCategoryRequestIds[requestKey] ?? 0) + 1;
    _elementCategoryRequestIds[requestKey] = requestId;

    if (!append) {
      _elementCategoryLoading[normalized] = true;
      if (normalized == 'stickers' ||
          normalized == 'social media' ||
          normalized == 'e-commerce') {
        _isFreePikStickerCategoryLoading[normalized] = true;
      }
      _elementCategoryAssets[normalized] = <String>[];
      _assetCategoryItems[normalized] = <AssetCategoryItem>[];
    }
    notifyListeners();

    try {
      if (normalized == 'shapes' || normalized == 'masks' || normalized == 'mask') {
        // Shapes, masks, social media and e-commerce all come from the
        // backend assets API. Keep records without an S3 source so the UI
        // can show LOCKED instead of incorrectly saying "No data found".
        final apiCategory = normalized == 'masks' ? 'mask' : normalized;
        final result = await FreePikService.fetchAssetsByCategory(
          apiCategory,
          page: page,
          perPage: limit,
        );

        if (_elementCategoryRequestIds[requestKey] != requestId) return;

        final current =
            _assetCategoryItems[normalized] ?? <AssetCategoryItem>[];
        final merged = append ? [...current, ...result] : result;
        final unique = <String, AssetCategoryItem>{};

        for (final item in merged) {
          final key = item.id?.toString() ??
              '${item.name}|${item.s3Key}|${item.s3Key ?? ''}';
          unique[key] = item;
        }

        final items = unique.values.toList();
        _assetCategoryItems[normalized] = items;

        // Only unlocked/source-backed assets are returned to legacy string
        // consumers. The UI uses assetCategoryItems for LOCKED rendering.
        _elementCategoryAssets[normalized] = items
            .map((e) => e.previewKey)
            .where((e) => e.trim().isNotEmpty && !items.any((x) => x.previewKey == e && x.isLocked))
            .toSet()
            .toList();
      } else {
        final result = await FreePikService.searchStickers(
          term: normalized == 'stickers' ? null : normalized,
          page: page,
          perPage: limit,
        ).timeout(const Duration(seconds: 15), onTimeout: () => <String>[]);

        if (_elementCategoryRequestIds[requestKey] != requestId) return;

        final current = _elementCategoryAssets[normalized] ?? <String>[];
        _elementCategoryAssets[normalized] = append
            ? [...current, ...result].toSet().toList()
            : result.toSet().toList();
      }
    } catch (e) {
      debugPrint('Element category error [$normalized, page=$page]: $e');
      if (!append && _elementCategoryRequestIds[requestKey] == requestId) {
        _elementCategoryAssets[normalized] = <String>[];
        _assetCategoryItems[normalized] = <AssetCategoryItem>[];
      }
    } finally {
      if (_elementCategoryRequestIds[requestKey] == requestId) {
        _elementCategoryLoading[normalized] = false;
        if (normalized == 'stickers' ||
            normalized == 'social media' ||
            normalized == 'e-commerce') {
          _isFreePikStickerCategoryLoading[normalized] = false;
        }
        notifyListeners();
      }
    }
  }

  void resetElementCategoryRequest(String query) {
    _elementCategoryRequested.remove(query.trim().toLowerCase());
  }

  Future<void> fetchElementCategoryAll(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final requestId =
        (_elementCategoryRequestIds['${normalized}__all'] ?? 0) + 1;
    _elementCategoryRequestIds['${normalized}__all'] = requestId;
    _elementCategoryLoading[normalized] = true;
    _elementCategoryAssets[normalized] = <String>[];
    notifyListeners();

    try {
      final all = <String>[];
      // Fetch several pages so View all is not limited to the first 4 results.
      // Shapes/masks are supplied by /api/assets as AssetCategoryItem objects.
      // The backend may cap per_page, so page-by-page loading is intentional.
      final allAssetItems = <AssetCategoryItem>[];

      for (var page = 1; page <= 10; page++) {
        if (_elementCategoryRequestIds['${normalized}__all'] != requestId)
          return;

        if (normalized == 'stickers' ||
            normalized == 'social media' ||
            normalized == 'e-commerce') {
          final result = await FreePikService.searchStickers(
            term: normalized == 'stickers' ? null : normalized,
            page: page,
            perPage: 30,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () => <String>[],
          );
          if (result.isEmpty) break;

          final before = all.length;
          all.addAll(result);
          final unique = all.toSet().toList();
          all
            ..clear()
            ..addAll(unique);
          _elementCategoryAssets[normalized] = List.unmodifiable(all);

          notifyListeners();
          if (all.length == before) break;
          if (result.length < 2) break;
        } else {
          final result = await FreePikService.fetchAssetsByCategory(
            normalized,
            page: page,
            perPage: 30,
          );
          if (result.isEmpty) break;

          final before = allAssetItems.length;
          allAssetItems.addAll(result);

          final unique = <String, AssetCategoryItem>{};
          for (final item in allAssetItems) {
            final key = item.id?.toString() ??
                '${item.name}|${item.s3Key}|${item.s3Key ?? ''}';
            unique[key] = item;
          }

          allAssetItems
            ..clear()
            ..addAll(unique.values);

          _assetCategoryItems[normalized] =
              List.unmodifiable(allAssetItems);

          // Keep only source-backed URLs for legacy consumers.
          all
            ..clear()
            ..addAll(
              allAssetItems
                  .where((e) => !e.isLocked && e.previewKey.isNotEmpty)
                  .map((e) => e.previewKey),
            );

          _elementCategoryAssets[normalized] =
              List.unmodifiable(all.toSet().toList());

          notifyListeners();
          if (allAssetItems.length == before) break;
          if (result.length < 2) break;
        }
      }
    } catch (e) {
      debugPrint('Element category all error [$normalized]: $e');
    } finally {
      if (_elementCategoryRequestIds['${normalized}__all'] == requestId) {
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
      'social media',
      setLoading: (value) => isSocialMediaLoading = value,
      setData: (value) => freePikSocialMedia = value,
    );
  }

  Future<void> fetchFreePikEcommerce() async {
    await _fetchFreepikCategory(
      'e-commerce',
      setLoading: (value) => isEcommerceLoading = value,
      setData: (value) => freePikEcommerce = value,
    );
  }

  TemplateEdit? _templateDetail;
  TemplateEdit? get templateDetail => _templateDetail;

  bool _isTemplateDetailLoading = false;
  bool get isTemplateDetailLoading => _isTemplateDetailLoading;

  String? _templateDetailError;
  String? get templateDetailError => _templateDetailError;

  /// Loads the template detail API and converts its Fabric JSON `content`
  /// into the editor's existing EditorItem list.
  Future<bool> loadTemplateByUid(
      String uid, {
        double? canvasWidth,
        double? canvasHeight,
      }) async {
    final safeUid = uid.trim();
    if (safeUid.isEmpty) {
      _templateDetailError = 'Template UID is empty';
      notifyListeners();
      return false;
    }

    _isTemplateDetailLoading = true;
    _templateDetailError = null;
    isTemplateLoaded = false;
    notifyListeners();

    try {
      debugPrint('📄 Loading template: $safeUid');
      final result = await TemplateRepository.instance.getTemplateByUid(
        uid: safeUid,
      );

      final detail = result.data;
      if (detail == null) {
        throw Exception('Template API returned no data');
      }

      final content = detail.data.content!.trim();
      if (content.isEmpty) {
        throw Exception('Template content is empty');
      }

      _templateDetail = detail;
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        throw Exception('Invalid template content JSON');
      }

      final root = Map<String, dynamic>.from(decoded);
      final objects = root['objects'];
      if (objects is! List) {
        throw Exception('Template content has no objects array');
      }

      // Prefer the exact size supplied by the previous screen.
      if (canvasWidth != null && canvasHeight != null) {
        setCanvasSize(canvasWidth, canvasHeight);
      } else {
        final detected = _detectTemplateCanvasSize(objects);
        if (detected != null) {
          setCanvasSize(detected.width, detected.height);
        }
      }

      loadItemsFromJson(
        objects
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );

      debugPrint(
        '✅ Template loaded: ${detail.data.name} | '
            '${_items.length} objects',
      );
      return true;
    } catch (e, stackTrace) {
      _templateDetailError = e.toString();
      isTemplateLoaded = false;
      debugPrint('❌ Template load failed [$safeUid]: $e');
      debugPrint('$stackTrace');
      notifyListeners();
      return false;
    } finally {
      _isTemplateDetailLoading = false;
      notifyListeners();
    }
  }

  Size? _detectTemplateCanvasSize(List<dynamic> objects) {
    for (final raw in objects) {
      if (raw is! Map) continue;
      final object = Map<String, dynamic>.from(raw);
      final name = object['name']?.toString().toLowerCase();
      if (name == 'clip' || object['type'] == 'rect') {
        final width = _toDouble(object['width']);
        final height = _toDouble(object['height']);
        if (width != null && height != null && width > 0 && height > 0) {
          return Size(width, height);
        }
      }
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
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
      _textLetterSpacing.clear();
      _textLineSpacing.clear();
      _textAlignment.clear();
      _textWeight.clear();
      _textStyle.clear();
      _textUnderline.clear();

      var idIndex = 0;
      for (final json in jsonList) {
        final type = (json['type']?.toString() ?? '').trim().toLowerCase();
        final left = _toDouble(json['left']) ?? 0.0;
        final top = _toDouble(json['top']) ?? 0.0;
        final width = _toDouble(json['width']) ?? 100.0;
        final height = _toDouble(json['height']) ?? 100.0;
        final scaleX = _toDouble(json['scaleX']) ?? 1.0;
        final scaleY = _toDouble(json['scaleY']) ?? 1.0;
        final scale = scaleX.abs() < 0.0001 ? scaleY.abs() : scaleX.abs();
        final angleDegrees = _toDouble(json['angle']) ?? 0.0;
        final rotation = angleDegrees * math.pi / 180.0;
        final opacity = (_toDouble(json['opacity']) ?? 1.0).clamp(0.0, 1.0);
        final id =
            'template_${DateTime.now().microsecondsSinceEpoch}_${idIndex++}';

        if (type == 'textbox' || type == 'i-text' || type == 'text') {
          final fontSize = _toDouble(json['fontSize']) ?? 36.0;
          final text = json['text']?.toString() ?? '';
          final item = EditorItem(
            id: id,
            type: 'text',
            text: text,
            position: Offset(left, top),
            width: width,
            height: height,
            scale: scale.clamp(0.05, 10.0).toDouble(),
            rotation: rotation,
            opacity: opacity,
            fontSize: fontSize,
            color: _parseColor(json['fill']),
          );
          _items.add(item);
          _textLetterSpacing[id] =
              (_toDouble(json['charSpacing']) ?? 0.0) / 10.0;
          _textLineSpacing[id] = (_toDouble(json['lineHeight']) ?? 1.0).clamp(
            0.7,
            3.0,
          );
          _textAlignment[id] = _parseTextAlign(json['textAlign']);
          _textWeight[id] = _parseFontWeight(json['fontWeight']);
          _textStyle[id] = (json['fontStyle']?.toString() == 'italic')
              ? FontStyle.italic
              : FontStyle.normal;
          _textUnderline[id] = json['underline'] == true;
        } else if (type == 'image') {
          final imageUrl = json['src']?.toString().trim() ?? '';
          if (imageUrl.isNotEmpty) {
            _items.add(
              EditorItem(
                id: id,
                type: 'image',
                contentUrl: imageUrl,
                position: Offset(left, top),
                width: width,
                height: height,
                scale: scale.clamp(0.05, 10.0).toDouble(),
                rotation: rotation,
                opacity: opacity,
                isLocal: false,
              ),
            );
          }
        } else if (type == 'rect' ||
            type == 'circle' ||
            type == 'ellipse' ||
            type == 'path') {
          _items.add(
            EditorItem(
              id: id,
              type: 'shape',
              position: Offset(left, top),
              width: width,
              height: height,
              scale: scale.clamp(0.05, 10.0).toDouble(),
              rotation: rotation,
              opacity: opacity,
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
    } catch (e, stackTrace) {
      isTemplateLoaded = false;
      debugPrint('JSON Load Error: $e');
      debugPrint('$stackTrace');
      notifyListeners();
    }
  }

  TextAlign _parseTextAlign(dynamic value) {
    switch (value?.toString()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  FontWeight _parseFontWeight(dynamic value) {
    final weight = int.tryParse(value?.toString() ?? '700') ?? 700;
    return weight >= 700 ? FontWeight.bold : FontWeight.normal;
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
    final textId = DateTime.now().millisecondsSinceEpoch.toString();
    _items.add(
      EditorItem(
        id: textId,
        type: 'text',
        text: initialText,
        position: const Offset(120, 200),
        width: 600,
        height: 180,
        color: Colors.black87,
      ),
    );
    // New text must use exactly the same selection/transform system as
    // template text, images, shapes and stickers.
    selectedItemType = 'text';
    selectedItemId = textId;
    _saveState();
    notifyListeners();
  }

  void addEmoji(String emojiText) {
    addText(initialText: emojiText);
  }

  /// Add a Freepik asset as a selectable group.
  ///
  /// The API currently returns PNG thumbnails for many assets (`free_svg:
  /// false`). We still create a `svg_group`/group-like item so the same
  /// toolbar is shown. If an SVG payload is available it is used directly;
  /// otherwise the PNG is kept as the group's source and can be split into
  /// raster child elements when the user presses UNGROUP ELEMENTS.
  void addFreePikElement(String thumbnailUrl) {
    final svg = FreePikService.svgForThumbnail(thumbnailUrl);

    _saveState();
    final id = 'svg_group_${DateTime.now().microsecondsSinceEpoch}';
    _items.add(
      EditorItem(
        id: id,
        type: 'svg_group',
        contentUrl: (svg != null && svg.trim().isNotEmpty) ? svg : thumbnailUrl,
        position: const Offset(100, 150),
        width: 220,
        height: 220,
        isLocal: false,
        text: (svg != null && svg.trim().isNotEmpty)
            ? 'svg_group'
            : 'raster_group',
      ),
    );
    selectedItemType = 'svg_group';
    selectedItemId = id;
    notifyListeners();
  }

  /// Ungroups the SVG into individual drawable SVG elements. Every fragment
  /// keeps the original viewBox and group transforms, so all pieces retain
  /// their original positions when they become separate editor items.
  Future<void> ungroupSvgElement(String groupId) async {
    final index = _items.indexWhere((e) => e.id == groupId);
    if (index == -1) return;
    final group = _items[index];
    if (group.type != 'svg_group') return;

    final source = group.contentUrl ?? '';
    final isSvg = source.trimLeft().startsWith('<svg');

    if (isSvg) {
      final fragments = _extractSvgLeafFragments(source);
      if (fragments.isEmpty) return;

      _saveState();
      _items.removeAt(index);

      final created = <EditorItem>[];
      for (var i = 0; i < fragments.length; i++) {
        created.add(
          EditorItem(
            id: 'svg_${DateTime.now().microsecondsSinceEpoch}_$i',
            type: 'svg_element',
            contentUrl: fragments[i],
            position: group.position,
            width: group.width,
            height: group.height,
            scale: group.scale,
            rotation: group.rotation,
            opacity: group.opacity,
            isLocal: false,
          ),
        );
      }

      _items.insertAll(index, created);
      selectedItemId = created.first.id;
      selectedItemType = 'svg_element';
      notifyListeners();
      return;
    }

    // Current Freepik proxy returns PNG thumbnails for many assets. Split
    // the transparent raster into connected visual components so the user
    // can still ungroup/edit the pieces individually without another API
    // request.
    await _ungroupRasterGroup(index, group);
  }

  Future<void> _ungroupRasterGroup(int index, EditorItem group) async {
    final source = group.contentUrl ?? '';
    if (source.isEmpty) return;

    try {
      final bytes = await _readImageBytes(source, group.isLocal);
      if (bytes == null || bytes.isEmpty) return;

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (raw == null) return;

      final rgba = raw.buffer.asUint8List();
      final boxes = _findAlphaComponents(rgba, width, height);
      image.dispose();
      codec.dispose();

      if (boxes.isEmpty) return;

      _saveState();
      _items.removeAt(index);

      final tempDir = await getTemporaryDirectory();
      final created = <EditorItem>[];
      var componentIndex = 0;

      for (final box in boxes) {
        final cropBytes = await _cropImageToPng(bytes, box);
        if (cropBytes == null || cropBytes.isEmpty) continue;

        final file = File(
          '${tempDir.path}/ungroup_${DateTime.now().microsecondsSinceEpoch}_${componentIndex++}.png',
        );
        await file.writeAsBytes(cropBytes, flush: true);

        final relX = box.left / width;
        final relY = box.top / height;
        final relW = box.width / width;
        final relH = box.height / height;

        created.add(
          EditorItem(
            id: 'raster_${DateTime.now().microsecondsSinceEpoch}_${created.length}',
            type: 'image',
            contentUrl: file.path,
            position: Offset(
              group.position.dx + group.width * relX,
              group.position.dy + group.height * relY,
            ),
            width: group.width * relW,
            height: group.height * relH,
            scale: group.scale,
            rotation: group.rotation,
            opacity: group.opacity,
            isLocal: true,
            text: 'rounded',
          ),
        );
      }

      if (created.isEmpty) {
        _items.insert(index, group);
        return;
      }

      _items.insertAll(index, created);
      selectedItemId = created.first.id;
      selectedItemType = 'image';
      notifyListeners();
    } catch (e) {
      debugPrint('Raster ungroup failed: $e');
    }
  }

  Future<Uint8List?> _readImageBytes(String source, bool isLocal) async {
    try {
      if (isLocal || source.startsWith('/') || source.startsWith('file://')) {
        return await File(source.replaceFirst('file://', '')).readAsBytes();
      }
      final response = await HttpClient()
          .getUrl(Uri.parse(source))
          .then((r) => r.close());
      if (response.statusCode != 200) return null;
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    } catch (e) {
      debugPrint('Image bytes load failed: $e');
      return null;
    }
  }

  List<ui.Rect> _findAlphaComponents(Uint8List rgba, int width, int height) {
    final pixelCount = width * height;
    final visited = Uint8List(pixelCount);
    final boxes = <ui.Rect>[];
    const alphaThreshold = 12;
    const minPixels = 8;

    final queue = List<int>.filled(pixelCount, 0);

    for (var start = 0; start < pixelCount; start++) {
      if (visited[start] != 0) continue;
      final alpha = rgba[start * 4 + 3];
      if (alpha < alphaThreshold) {
        visited[start] = 1;
        continue;
      }

      var head = 0;
      var tail = 0;
      queue[tail++] = start;
      visited[start] = 1;

      var minX = start % width;
      var maxX = minX;
      var minY = start ~/ width;
      var maxY = minY;
      var count = 0;

      while (head < tail) {
        final p = queue[head++];
        final x = p % width;
        final y = p ~/ width;
        count++;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;

        void visit(int nx, int ny) {
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) return;
          final n = ny * width + nx;
          if (visited[n] != 0) return;
          visited[n] = 1;
          if (rgba[n * 4 + 3] >= alphaThreshold) queue[tail++] = n;
        }

        visit(x - 1, y);
        visit(x + 1, y);
        visit(x, y - 1);
        visit(x, y + 1);
      }

      if (count >= minPixels) {
        boxes.add(
          ui.Rect.fromLTRB(
            minX.toDouble(),
            minY.toDouble(),
            (maxX + 1).toDouble(),
            (maxY + 1).toDouble(),
          ),
        );
      }
    }

    boxes.sort((a, b) => (a.top + a.left).compareTo(b.top + b.left));
    return boxes;
  }

  Future<Uint8List?> _cropImageToPng(Uint8List source, ui.Rect box) async {
    try {
      final codec = await ui.instantiateImageCodec(source);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final dst = ui.Rect.fromLTWH(0, 0, box.width, box.height);
      canvas.drawImageRect(image, box, dst, Paint());
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(
        box.width.ceil(),
        box.height.ceil(),
      );
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      cropped.dispose();
      codec.dispose();
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Image crop failed: $e');
      return null;
    }
  }

  List<String> _extractSvgLeafFragments(String source) {
    final svgMatch = RegExp(
      r'''<svg\b([^>]*)>''',
      caseSensitive: false,
    ).firstMatch(source);
    final attrs = svgMatch?.group(1) ?? '';
    final viewBox =
        RegExp(
          r'''\bviewBox\s*=\s*["']([^"']+)["']''',
          caseSensitive: false,
        ).firstMatch(attrs)?.group(1) ??
            '0 0 512 512';

    final root = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox">';
    final tokens = RegExp(
      r'<[^>]+>',
      multiLine: true,
    ).allMatches(source).toList();
    final groups = <String>[];
    final fragments = <String>[];
    const drawable = <String>{
      'path',
      'rect',
      'circle',
      'ellipse',
      'polygon',
      'polyline',
      'line',
      'text',
      'image',
      'use',
    };

    for (final token in tokens) {
      final tag = token.group(0) ?? '';
      final closing = RegExp(r'</\s*([A-Za-z0-9:_-]+)\s*>').firstMatch(tag);
      if (closing != null) {
        if (closing.group(1)!.toLowerCase() == 'g' && groups.isNotEmpty) {
          groups.removeLast();
        }
        continue;
      }

      final opening = RegExp(r'<\s*([A-Za-z0-9:_-]+)\b').firstMatch(tag);
      if (opening == null) continue;
      final name = opening.group(1)!.toLowerCase();

      if (name == 'g') {
        if (!tag.trimRight().endsWith('/>')) groups.add(tag);
        continue;
      }

      if (!drawable.contains(name)) continue;

      final out = StringBuffer(root);
      for (final parent in groups) out.write(parent);
      out.write(tag);
      if (!tag.trimRight().endsWith('/>')) {
        final endTag = '</$name>';
        final after = source.substring(token.end);
        final end = after.toLowerCase().indexOf(endTag.toLowerCase());
        if (end >= 0) out.write(after.substring(0, end + endTag.length));
      }
      out.write('</svg>');
      fragments.add(out.toString());
    }
    return fragments;
  }

  void addShape(String url, {bool isLocal = false}) {
    if (url.trim().isEmpty) return;

    _saveState();
    final shapeId = 'shape_${DateTime.now().microsecondsSinceEpoch}';

    _items.add(
      EditorItem(
        id: shapeId,
        type: 'shape',
        contentUrl: url,
        position: const Offset(100, 150),
        width: 220,
        height: 220,
        isLocal: isLocal,
        text: 'rounded',
      ),
    );

    selectedItemType = 'shape';
    selectedItemId = shapeId;
    _saveState();
    notifyListeners();
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

    selectedItemType = 'image';
    selectedItemId = imageId;
    _saveState();
    notifyListeners();
  }

  void addVideo(
      String videoUrl, {
        bool isLocal = false,
        double width = 600,
        double height = 400,
      }) {
    if (videoUrl.trim().isEmpty) return;

    _saveState();

    final videoItem = EditorItem(
      id: "video_${DateTime.now().millisecondsSinceEpoch}",
      type: "video",
      contentUrl: videoUrl,
      position: const Offset(100, 100),
      width: width,
      height: height,
      isLocal: isLocal,
    );

    _items.add(videoItem);

    selectedItemType = "video";
    selectedItemId = videoItem.id;

    notifyListeners();
  }

  void updatePosition(String id, Offset newPos) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = _items[index];
    final bounded = _clampPositionForFrame(item, newPos);

    _items[index] = item.copyWith(
      position: _isBackgroundLayer(item) ? Offset.zero : bounded,
    );
    notifyListeners();
  }

  void updateRotation(String id, double rot) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _saveState();

    final current = _items[index];
    if (_isBackgroundLayer(current)) {
      _items[index] = current.copyWith(rotation: rot);
    } else {
      final rotated = current.copyWith(rotation: rot);
      final safeScale = _maxScaleForFrame(rotated, rotated.scale);
      final resized = rotated.copyWith(scale: safeScale);
      _items[index] = resized.copyWith(
        position: _clampPositionForFrame(resized, resized.position),
      );
    }
    notifyListeners();
  }

  void updateScale(String id, double scl) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _saveState();

    final current = _items[index];
    final requested = scl.isFinite ? scl : current.scale;
    final safeScale = _maxScaleForFrame(current, requested);

    final scaled = current.copyWith(scale: safeScale);
    _items[index] = scaled.copyWith(
      position: _clampPositionForFrame(scaled, scaled.position),
    );
    notifyListeners();
  }

  /// Updates the selected text's font size.
  /// Keeps the value finite and within a practical editor range.
  void updateFontSize(String id, double newSize) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final safeSize = newSize.isFinite
        ? newSize.clamp(8.0, 300.0).toDouble()
        : _items[index].fontSize;

    if ((_items[index].fontSize - safeSize).abs() < 0.01) return;

    _saveState();
    _items[index] = _items[index].copyWith(fontSize: safeSize);
    notifyListeners();
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

  Color textColor(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return Colors.white;
    return _items[index].color ?? Colors.white;
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
        page: 1,
        limit: 30,
      ).timeout(const Duration(seconds: 20), onTimeout: () => <String>[]);

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
    final normalized = query.trim();

    final requestId = (_elementCategoryRequestIds['__stickers__'] ?? 0) + 1;
    _elementCategoryRequestIds['__stickers__'] = requestId;

    isStickersLoading = true;
    freePikStickers = <String>[];
    notifyListeners();

    try {
      // IMPORTANT:
      // Use the dedicated /api/freepik/stickers endpoint.
      // Do NOT append "stickers" to the search term; that was causing
      // requests such as "stickers stickers".
      final result = await FreePikService.searchStickers(
        term: normalized.isEmpty || normalized == 'stickers'
            ? null
            : normalized,
        page: 1,
        perPage: 30,
      ).timeout(const Duration(seconds: 20), onTimeout: () => <String>[]);

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
    final index = _items.indexWhere((e) => e.id == itemId);
    if (index == -1) return;

    final safeFont = fontFamily.trim();
    if (safeFont.isEmpty) return;

    if ((_items[index].fontFamily ?? '').trim() == safeFont) {
      return;
    }

    _saveState();

    // Use copyWith so the whole editor item is replaced. This guarantees
    // EditableItemWidget rebuilds immediately and the selected font is also
    // preserved by page/history/export state.
    _items[index] = _items[index].copyWith(fontFamily: safeFont);

    _syncCurrentPage();
    notifyListeners();
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
    items[index] = items[index].copyWith(
      borderRadius: radius.clamp(0.0, 500.0),
    );
    notifyListeners();
  }

  void updateImageShape(String id, String shape) {
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _saveState();
    final radius = items[index].borderRadius;
    items[index] = items[index].copyWith(text: shape, borderRadius: radius);
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

  List<PexelsVideoAsset> _pexelsVideoAssets = [];
  List<PexelsVideoAsset> get pexelsVideoAssets => _pexelsVideoAssets;

  // Kept for existing callers.
  List<String> get freePikVideos =>
      _pexelsVideoAssets.map((e) => e.videoUrl).toList();

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

      debugPrint("Searching Pexels videos: $searchQuery");

      _pexelsVideoAssets =
      await FreePikService.searchPexelsVideoAssets(
        searchQuery,
        page: 1,
        limit: 24,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("Pexels video search timeout");
          return <PexelsVideoAsset>[];
        },
      );

      debugPrint("Pexels videos found: ${_pexelsVideoAssets.length}");
    } catch (e, stackTrace) {
      debugPrint("Fetch Freepik Videos Error: $e");
      debugPrint("$stackTrace");

      _pexelsVideoAssets = [];
    } finally {
      _isVideosLoading = false;
      notifyListeners();
    }
  }

  void setBackgroundImage(
      String imageUrl, {
        double canvasWidth = 1080.0,
        double canvasHeight = 1080.0,
      }) {
    _saveState();

    // Replace the previous background completely.
    // A background image must not leave the previous color behind.
    _removeBackgroundLayers();
    _backgroundColor = Colors.transparent;

    final bgId = 'bg_${DateTime.now().millisecondsSinceEpoch}';

    _items.insert(
      0,
      EditorItem(
        id: bgId,
        type: 'image',
        position: const Offset(0, 0),
        width: canvasWidth,
        height: canvasHeight,
        contentUrl: imageUrl,
        isLocal: !imageUrl.startsWith('http'),
      ),
    );

    selectedItemType = 'image';
    selectedItemId = bgId;

    _syncCurrentPage();
    notifyListeners();
  }

  void setBackgroundVideo(
      String videoUrl, {
        double canvasWidth = 1080.0,
        double canvasHeight = 1080.0,
      }) {
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
        width: canvasWidth,
        height: canvasHeight,
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

  void replaceBackgroundImage(
      String imageUrl,
      String selectedItemIdToRemove, {
        double canvasWidth = 1080.0,
        double canvasHeight = 1080.0,
      }) {
    _saveState();

    // Remove old background image/video/shape
    _removeBackgroundLayers();

    // Remove the currently selected normal image
    _items.removeWhere((item) => item.id == selectedItemIdToRemove);

    // Remove background color
    _backgroundColor = Colors.transparent;

    final bgId = 'bg_${DateTime.now().millisecondsSinceEpoch}';

    // Add new image as background
    _items.insert(
      0,
      EditorItem(
        id: bgId,
        type: 'image',
        position: const Offset(0, 0),
        width: canvasWidth,
        height: canvasHeight,
        scale: 1.0,
        rotation: 0.0,
        contentUrl: imageUrl,
        isLocal: !imageUrl.startsWith('http'),
      ),
    );

    // Select new background
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
        item.type == 'image' || item.type == 'video' || item.type == 'shape';

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
    _pages[_currentPageIndex] = _items.map((e) => e.copyWith()).toList();
  }

  void addPage({bool duplicateCurrent = false}) {
    _syncCurrentPage();
    final source = duplicateCurrent
        ? _items
        .map(
          (e) => e.copyWith(
        id: '${DateTime.now().microsecondsSinceEpoch}_${e.id}',
      ),
    )
        .toList()
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

      _textLetterSpacing[newId] = _copiedLetterSpacing[oldId] ?? 0.0;
      _textLineSpacing[newId] = _copiedLineSpacing[oldId] ?? 1.0;
      _textAlignment[newId] = _copiedAlignment[oldId] ?? TextAlign.left;
      _textWeight[newId] = _copiedWeight[oldId] ?? FontWeight.bold;
      _textStyle[newId] = _copiedStyle[oldId] ?? FontStyle.normal;
      _textUnderline[newId] = _copiedUnderline[oldId] ?? false;
      _imageFilterIntensity[newId] = _copiedFilterIntensity[oldId] ?? 1.0;
    }

    // Paste means duplicate into the current page. Do not wipe existing
    // content; this also works when copying and pasting on the same page.
    _items.addAll(pastedItems);

    // Restore the copied page background.
    if (_copiedPageBackgroundColor != null) {
      _backgroundColor = _copiedPageBackgroundColor!;
    }

    selectedItemId = pastedItems.isNotEmpty ? pastedItems.first.id : null;
    selectedItemType = pastedItems.isNotEmpty ? pastedItems.first.type : null;

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

    if (_isBackgroundLayer(current)) {
      _items[index] = current.copyWith(
        position: Offset.zero,
        scale: scale ?? current.scale,
        rotation: rotation ?? current.rotation,
      );
      notifyListeners();
      return;
    }

    final nextRotation = rotation ?? current.rotation;
    final rotated = current.copyWith(rotation: nextRotation);

    final requestedScale = (scale ?? current.scale).isFinite
        ? (scale ?? current.scale)
        : current.scale;
    final safeScale = _maxScaleForFrame(rotated, requestedScale);
    final transformed = rotated.copyWith(scale: safeScale);

    final nextPosition = _clampPositionForFrame(
      transformed,
      position ?? current.position,
    );

    _items[index] = transformed.copyWith(position: nextPosition);
    notifyListeners();
  }
}
