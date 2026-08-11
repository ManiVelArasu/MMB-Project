import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

enum EditorItemType {
  text,
  sticker,
  shape,
}



class EditorItem {
  final String? id;
  final String? type; // 'text', 'image', 'shape'
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
  String fontFamily;
  final double outlineWidth;
  final Color outlineColor;
  final String filterType;
  final double brightness;
  final double contrast;
  final double saturation;

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
    this.outlineWidth = 0.0,
    this.outlineColor = Colors.transparent,
    this.filterType = 'normal',
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  EditorItem copyWith({
    String? id,
    String? type, // 🚀 இதை இங்கே சேர்க்கவும்
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
    double? outlineWidth,
    Color? outlineColor,
    String? filterType,
    double? brightness,
    double? contrast,
    double? saturation,
  }) {
    return EditorItem(
      id: id ?? this.id,
      type: type ?? this.type, // 🚀 இதை இங்கே அப்டேட் செய்யவும்
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
      outlineWidth: outlineWidth ?? this.outlineWidth,
      outlineColor: outlineColor ?? this.outlineColor,
      filterType: filterType ?? this.filterType,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
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
    'outline_width': outlineWidth,
    'filter_type': filterType,
  };

  factory EditorItem.fromJson(Map<String, dynamic> json) {
    return EditorItem(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      position: Offset(
        (json['position_x'] as num?)?.toDouble() ?? 50.0,
        (json['position_y'] as num?)?.toDouble() ?? 50.0,
      ),
      text: json['text'],
      contentUrl: json['content_url'] ?? json['image_url'],
      isLocal: json['is_local'] ?? false,
      width: (json['width'] as num?)?.toDouble() ?? 150.0,
      height: (json['height'] as num?)?.toDouble() ?? 150.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      borderRadius: (json['border_radius'] as num?)?.toDouble() ?? 0.0,
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 24.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      fontFamily: json['font_family'] ?? 'Roboto',
      outlineWidth: (json['outline_width'] as num?)?.toDouble() ?? 0.0,
      filterType: json['filter_type'] ?? 'normal',
    );
  }
}

