import 'dart:ui';
import 'canva_item.dart';


class EditorDocument {
  final double width;
  final double height;
  final int backgroundColorValue;
  final List<CanvaItem> items;

  const EditorDocument({
    this.width = 1080,
    this.height = 1080,
    this.backgroundColorValue = 0xFFFFFFFF,
    this.items = const [],
  });

  EditorDocument copyWith({
    double? width,
    double? height,
    int? backgroundColorValue,
    List<CanvaItem>? items,
  }) {
    return EditorDocument(
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColorValue:
      backgroundColorValue ?? this.backgroundColorValue,
      items: items ?? this.items,
    );
  }
}