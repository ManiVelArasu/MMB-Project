import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../Api Model/canva_item.dart';
import '../../Api Model/editor.dart';

class CanvaProvider extends ChangeNotifier {
  EditorDocument _document = const EditorDocument();
  final List<EditorDocument> _undo = [];
  final List<EditorDocument> _redo = [];

  String? _selectedId;
  final Set<String> _multiSelection = {};

  EditorDocument get document => _document;
  List<CanvaItem> get items => List.unmodifiable(_document.items);
  String? get selectedId => _selectedId;
  Set<String> get selectedIds => Set.unmodifiable(_multiSelection);
  CanvaItem? get selectedItem {
    final id = _selectedId;
    if (id == null) return null;
    for (final item in _document.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Color get backgroundColor => Color(_document.backgroundColorValue);

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void _commit(EditorDocument next, {bool history = true}) {
    if (history) {
      _undo.add(_document);
      if (_undo.length > 80) _undo.removeAt(0);
      _redo.clear();
    }
    _document = next;
    notifyListeners();
  }

  String _id() => '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

  void select(String? id, {bool addToSelection = false}) {
    _selectedId = id;
    if (id == null) {
      _multiSelection.clear();
    } else if (addToSelection) {
      _multiSelection.add(id);
    } else {
      _multiSelection
        ..clear()
        ..add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedId = null;
    _multiSelection.clear();
    notifyListeners();
  }

  void addText({String text = 'New Text'}) {
    final item = CanvaItem(
      id: _id(),
      type: EditorItemType.text,
      text: text,
      position: Offset(_document.width / 2 - 140, _document.height / 2 - 30),
      width: 280,
      height: 70,
    );
    _commit(_document.copyWith(items: [..._document.items, item]));
    select(item.id);
  }

  void addEmoji(String emoji) {
    final item = CanvaItem(
      id: _id(),
      type: EditorItemType.emoji,
      text: emoji,
      position: Offset(_document.width / 2 - 70, _document.height / 2 - 70),
      width: 140,
      height: 140,
      fontSize: 90,
    );
    _commit(_document.copyWith(items: [..._document.items, item]));
    select(item.id);
  }

  void addImage(String url, {bool isLocal = false}) {
    final item = CanvaItem(
      id: _id(),
      type: EditorItemType.image,
      contentUrl: url,
      isLocal: isLocal,
      position: Offset(_document.width / 2 - 120, _document.height / 2 - 120),
    );
    _commit(_document.copyWith(items: [..._document.items, item]));
    select(item.id);
  }

  void addShape({EditorShape shape = EditorShape.rectangle}) {
    final item = CanvaItem(
      id: _id(),
      type: EditorItemType.shape,
      text: shape.name,
      position: Offset(_document.width / 2 - 100, _document.height / 2 - 100),
      width: 200,
      height: shape == EditorShape.line ? 6 : 200,
      fillColorValue: 0xFFEDEDED,
    );
    _commit(_document.copyWith(items: [..._document.items, item]));
    select(item.id);
  }

  void setBackgroundColor(Color color) {
    _commit(_document.copyWith(backgroundColorValue: color.value));
  }

  bool isBackground(CanvaItem item) =>
      item.position.dx == 0 &&
          item.position.dy == 0 &&
          item.width >= _document.width * .9 &&
          item.height >= _document.height * .9 &&
          (item.type == EditorItemType.image ||
              item.type == EditorItemType.video);

  void setBackgroundImage(String url, {bool isLocal = false}) {
    final filtered = _document.items.where((e) => !isBackground(e)).toList();
    final bg = CanvaItem(
      id: _id(),
      type: EditorItemType.image,
      contentUrl: url,
      isLocal: isLocal,
      position: Offset.zero,
      width: _document.width,
      height: _document.height,
    );
    _commit(_document.copyWith(items: [bg, ...filtered]));
    select(bg.id);
  }

  void replaceBackgroundWith(String id, String url, {bool isLocal = false}) {
    final old = selectedItem;
    if (old == null || old.id != id) return;
    final filtered = _document.items.where((e) => !isBackground(e)).toList();
    final bg = old.copyWith(
      id: old.id,
      contentUrl: url,
      isLocal: isLocal,
      position: Offset.zero,
      width: _document.width,
      height: _document.height,
      scale: 1,
      rotation: 0,
    );
    _commit(_document.copyWith(items: [bg, ...filtered]));
    select(bg.id);
  }

  void removeBackground() {
    final filtered = _document.items.where((e) => !isBackground(e)).toList();
    _commit(_document.copyWith(items: filtered));
    clearSelection();
  }

  void moveSelected(Offset delta) {
    final item = selectedItem;
    if (item == null || item.locked || isBackground(item)) return;
    updateItem(item.id, position: item.position + delta);
  }

  void updateItem(
      String id, {
        Offset? position,
        double? width,
        double? height,
        double? rotation,
        double? scale,
        double? opacity,
        bool? locked,
        bool? visible,
        String? contentUrl,
        bool? isLocal,
        String? text,
        double? fontSize,
        String? fontFamily,
        Color? textColor,
        bool? bold,
        bool? italic,
        TextAlign? textAlign,
        double? letterSpacing,
        double? lineHeight,
        Color? fillColor,
        Color? borderColor,
        double? borderWidth,
        double? borderRadius,
        double? brightness,
        double? contrast,
        double? saturation,
        String? filterType,
        bool? flipX,
        bool? flipY,
      }) {
    final index = _document.items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final old = _document.items[index];
    if (old.locked && !isBackground(old)) return;

    final updated = old.copyWith(
      contentUrl: contentUrl,
      isLocal: isLocal,
      position: position,
      width: width,
      height: height,
      rotation: rotation,
      scale: scale,
      opacity: opacity,
      locked: locked,
      visible: visible,
      text: text,
      fontSize: fontSize,
      fontFamily: fontFamily,
      textColorValue: textColor?.value,
      bold: bold,
      italic: italic,
      textAlign: textAlign,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      fillColorValue: fillColor?.value,
      borderColorValue: borderColor?.value,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      filterType: filterType,
      flipX: flipX,
      flipY: flipY,
    );
    final list = [..._document.items]..[index] = updated;
    _commit(_document.copyWith(items: list));
  }

  void duplicateSelected() {
    final item = selectedItem;
    if (item == null || isBackground(item)) return;
    final copy = item.copyWith(
      id: _id(),
      position: item.position + const Offset(24, 24),
      zIndex: _document.items.length,
    );
    _commit(_document.copyWith(items: [..._document.items, copy]));
    select(copy.id);
  }

  void deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    final item = selectedItem;
    if (item == null) return;
    if (isBackground(item)) {
      removeBackground();
      return;
    }
    _commit(_document.copyWith(
      items: _document.items.where((e) => e.id != id).toList(),
    ));
    clearSelection();
  }

  void bringToFront(String id) {
    final item = _find(id);
    if (item == null || isBackground(item)) return;
    final list = _document.items.where((e) => e.id != id).toList()..add(item);
    _commit(_document.copyWith(items: list));
  }

  void sendToBack(String id) {
    final item = _find(id);
    if (item == null || isBackground(item)) return;
    final list = _document.items.where((e) => e.id != id).toList()
      ..insert(0, item);
    _commit(_document.copyWith(items: list));
  }

  void bringForward(String id) {
    final list = [..._document.items];
    final index = list.indexWhere((e) => e.id == id);
    if (index < 0 || index >= list.length - 1) return;
    final item = list.removeAt(index);
    list.insert(index + 1, item);
    _commit(_document.copyWith(items: list));
  }

  void sendBackward(String id) {
    final list = [..._document.items];
    final index = list.indexWhere((e) => e.id == id);
    if (index <= 0) return;
    final item = list.removeAt(index);
    list.insert(index - 1, item);
    _commit(_document.copyWith(items: list));
  }

  void toggleLock(String id) {
    final item = _find(id);
    if (item == null) return;
    updateItem(id, locked: !item.locked);
  }

  void toggleVisibility(String id) {
    final item = _find(id);
    if (item == null) return;
    updateItem(id, visible: !item.visible);
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_document);
    _document = _undo.removeLast();
    clearSelection();
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_document);
    _document = _redo.removeLast();
    clearSelection();
    notifyListeners();
  }

  void setFilter(String id, String filter) => updateItem(id, filterType: filter);
  void setOpacity(String id, double value) => updateItem(id, opacity: value);
  void setRotation(String id, double radians) => updateItem(id, rotation: radians);
  void setSize(String id, double w, double h) =>
      updateItem(id, width: w, height: h);
  void setText(String id, String value) => updateItem(id, text: value);
  void setTextColor(String id, Color value) => updateItem(id, textColor: value);
  void setFontSize(String id, double value) => updateItem(id, fontSize: value);
  void setImageAdjustments(
      String id, {
        double? brightness,
        double? contrast,
        double? saturation,
      }) =>
      updateItem(
        id,
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
      );

  CanvaItem? _find(String id) {
    for (final item in _document.items) {
      if (item.id == id) return item;
    }
    return null;
  }
}