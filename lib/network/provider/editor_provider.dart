import 'dart:io';

import 'package:flutter/material.dart';
import '../../Api Model/editor_model.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import '../../Api Model/editor_model.dart';

import 'dart:io';
import 'package:flutter/material.dart';


import 'dart:io';
import 'package:flutter/material.dart';


class EditorProvider extends ChangeNotifier {
  List<EditorItem> _items = [];
  List<EditorItem> get items => _items;

  final List<List<EditorItem>> _history = [];
  final List<List<EditorItem>> _redoStack = [];

  void _saveState() {
    _history.add(List.from(_items.map((e) => e.copyWith())));
    _redoStack.clear();
  }

  void undo() {
    if (_history.isNotEmpty) {
      _redoStack.add(List.from(_items));
      _items = _history.removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _history.add(List.from(_items));
      _items = _redoStack.removeLast();
      notifyListeners();
    }
  }

  void loadItemsFromJson(List<dynamic> jsonList) {
    _items = jsonList.map((json) => EditorItem.fromJson(json)).toList();
    _history.clear();
    notifyListeners();
  }

  void addText({String initialText = "New Text"}) {
    _saveState();
    _items.add(EditorItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'text',
      position: const Offset(100, 150),
      text: initialText,
      fontSize: 28,
      color: Colors.white,
    ));
    notifyListeners();
  }

  void addImage(String pathOrUrl, {bool isLocal = false}) {
    _saveState();
    _items.add(EditorItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'image',
      contentUrl: pathOrUrl,
      isLocal: isLocal,
      position: const Offset(120, 200),
      width: 180,
      height: 180,
      borderRadius: 16.0,
      text: 'rounded',
    ));
    notifyListeners();
  }

  void addEmoji(String emoji) {
    _saveState();
    _items.add(EditorItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'text',
      text: emoji,
      position: const Offset(150, 200),
      fontSize: 50,
    ));
    notifyListeners();
  }

  void duplicateItem(String id) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = _items[index];
      final duplicated = item.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: item.position + const Offset(20, 20),
      );
      _items.add(duplicated);
      notifyListeners();
    }
  }

  void updatePosition(String id, Offset offset) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(position: offset);
      notifyListeners();
    }
  }

  // 🚀 Rotation Feature
  void updateRotation(String id, double angle) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(rotation: angle);
      notifyListeners();
    }
  }

  // 🚀 Zoom / Scale Feature
  void updateScale(String id, double scale) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(scale: scale);
      notifyListeners();
    }
  }

  // 🚀 Alignment Features (Center Horizontal / Vertical)
  void alignItem(String id, String alignmentType) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = _items[index];
      Offset newPos = item.position;
      // Assuming canvas reference width ~ 400, height ~ 600 (Approx center)
      if (alignmentType == 'center_h') {
        newPos = Offset(200 - (item.width / 2), item.position.dy);
      } else if (alignmentType == 'center_v') {
        newPos = Offset(item.position.dx, 300 - (item.height / 2));
      }
      _items[index] = item.copyWith(position: newPos);
      notifyListeners();
    }
  }

  // 🚀 Outline / Border Feature
  void updateOutline(String id, double width, Color color) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(outlineWidth: width, outlineColor: color);
      notifyListeners();
    }
  }

  void setImageShape(String id, String shapeName, {double radius = 0.0}) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(text: shapeName, borderRadius: radius);
      notifyListeners();
    }
  }

  void updateOpacity(String id, double opacity) {
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(opacity: opacity);
      notifyListeners();
    }
  }

  void updateItemColor(String id, Color color) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(color: color);
      notifyListeners();
    }
  }

  void bringToFront(String id) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = _items.removeAt(index);
      _items.add(item);
      notifyListeners();
    }
  }

  void sendToBack(String id) {
    _saveState();
    int index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = _items.removeAt(index);
      _items.insert(0, item);
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _saveState();
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  List<Map<String, dynamic>> getItemsAsJson() {
    return _items.map((item) => item.toJson()).toList();
  }
}
