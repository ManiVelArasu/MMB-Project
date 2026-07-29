import 'package:flutter/material.dart';

enum EditorItemType {
  text,
  sticker,
  shape,
}



class EditorItem {
  final String id;
  final String type; // 'text', 'image', 'shape'
  final Offset position;
  final String? text;
  final String? contentUrl;
  final bool isLocal;
  final double width;
  final double height;
  final double scale;
  final double rotation;
  final double borderRadius;
  final Color? color;
  final double fontSize;
  final double opacity;
  final String fontFamily;

  EditorItem({
    required this.id,
    required this.type,
    required this.position,
    this.text,
    this.contentUrl,
    this.isLocal = false,
    this.width = 150.0,
    this.height = 150.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.borderRadius = 0.0,
    this.color,
    this.fontSize = 24.0,
    this.opacity = 1.0,
    this.fontFamily = 'Roboto',
  });

  EditorItem copyWith({
    Offset? position,
    String? text,
    String? contentUrl,
    bool? isLocal,
    double? width,
    double? height,
    double? scale,
    double? rotation,
    double? borderRadius,
    Color? color,
    double? fontSize,
    double? opacity,
    String? fontFamily,
  }) {
    return EditorItem(
      id: id,
      type: type,
      position: position ?? this.position,
      text: text ?? this.text,
      contentUrl: contentUrl ?? this.contentUrl,
      isLocal: isLocal ?? this.isLocal,
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      borderRadius: borderRadius ?? this.borderRadius,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'position_x': position.dx,
    'position_y': position.dy,
    'text': text,
    'content_url': contentUrl,
    'is_local': isLocal,
    'width': width,
    'height': height,
    'scale': scale,
    'rotation': rotation,
    'border_radius': borderRadius,
    'font_size': fontSize,
    'opacity': opacity,
    'font_family': fontFamily,
  };

  factory EditorItem.fromJson(Map<String, dynamic> json) {
    Color? parsedColor;
    if (json['color'] != null) {
      try {
        String hexColor = json['color'].replaceAll('#', '');
        if (hexColor.length == 6) hexColor = 'FF$hexColor';
        parsedColor = Color(int.parse(hexColor, radix: 16));
      } catch (e) {
        parsedColor = Colors.white;
      }
    }

    return EditorItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'text',
      position: Offset(
        (json['position_x'] as num?)?.toDouble() ?? 50.0,
        (json['position_y'] as num?)?.toDouble() ?? 50.0,
      ),
      text: json['text'],
      contentUrl: json['content_url'],
      isLocal: json['is_local'] ?? false,
      width: (json['width'] as num?)?.toDouble() ?? 150.0,
      height: (json['height'] as num?)?.toDouble() ?? 150.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      borderRadius: (json['border_radius'] as num?)?.toDouble() ?? 0.0,
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 24.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      fontFamily: json['font_family'] ?? 'Roboto',
      color: parsedColor,
    );
  }
}
