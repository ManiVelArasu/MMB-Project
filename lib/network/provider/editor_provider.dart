import 'dart:io';

import 'package:flutter/material.dart';
import '../../Api Model/editor_model.dart';


class EditorProvider extends ChangeNotifier {
  final List<EditorItem> items = [];
  File? backgroundImage;

  void setBackground(File file) {
    backgroundImage = file;
    notifyListeners();
  }
  void addText() {
    items.add(
      EditorItem(
        id: DateTime.now().toString(),
        type: EditorItemType.text,
        position: const Offset(100, 150),
        text: "New Text",
      ),
    );

    notifyListeners();
  }

  void updatePosition(String id, Offset offset) {
    final item = items.firstWhere((e) => e.id == id);
    item.position = offset;
    notifyListeners();
  }
  void addSticker(String assetPath) {
    items.add(
      EditorItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: EditorItemType.sticker,
        position: const Offset(120, 150),
        image: assetPath,
        scale: 1,
      ),
    );

    notifyListeners();
  }
}