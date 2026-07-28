import 'package:flutter/material.dart';

enum EditorItemType {
  text,
  sticker,
  shape,
}

class EditorItem {
  final String id;
  final EditorItemType type;

  Offset position;
  double scale;
  double rotation;

  String? text;
  String? image;

  Color color;

  EditorItem({
    required this.id,
    required this.type,
    required this.position,
    this.scale = 1,
    this.rotation = 0,
    this.text,
    this.image,
    this.color = Colors.black,
  });
}