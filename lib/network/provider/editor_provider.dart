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

import '../../Repository/freeoic.dart';

class EditorProvider extends ChangeNotifier {
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

  void loadItemsFromJson(List<Map<String, dynamic>> jsonList) {
    _items.clear();
    for (var json in jsonList) {
      // 🚀 Using your new EditorItem.fromJson factory constructor
      EditorItem item = EditorItem.fromJson(json);

      // Optional: Handle color parsing if color exists in json
      if (json['color'] != null) {
        try {
          Color parsedColor = Color(
            int.parse(json['color'].replaceFirst('#', '0xFF')),
          );
          item = item.copyWith(color: parsedColor);
        } catch (_) {}
      }

      _items.add(item);
    }
    _saveState();
    notifyListeners();
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

  List<String> freepikAssets = [];
  bool isFreepikLoading = false;

  Future<void> fetchFreepikAssets(String query) async {
    isFreepikLoading = true;
    notifyListeners();

    try {
      freepikAssets = await FreepikService.searchAssets(query);
    } catch (e) {
      debugPrint("Error fetching assets: $e");
      freepikAssets = [];
    } finally {
      isFreepikLoading = false;
      notifyListeners();
    }
  }

  // Inside EditorProvider class:
  List<String> freepikStickers = [];
  bool isStickersLoading = false;

  Future<void> fetchFreepikStickers(String query) async {
    isStickersLoading = true;
    notifyListeners();

    try {
      // Freepik API moolama stickers search panrom
      freepikStickers = await FreepikService.searchAssets("$query stickers");
    } catch (e) {
      debugPrint("Error fetching stickers: $e");
      freepikStickers = [];
    } finally {
      isStickersLoading = false;
      notifyListeners();
    }
  }
}
