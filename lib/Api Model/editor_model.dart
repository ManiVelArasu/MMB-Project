import 'package:flutter/material.dart';

enum EditorItemType { text, sticker, shape, image, video, svg_group, svg_element }

class EditorItem {
  final String? id;
  final String? type; // 'text', 'image', 'shape', 'video', 'svg_group', 'svg_element', 'textbox'
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
  final bool isLocked;
  final bool isVisible;
  final Color? shadowColor;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final Color? textBackgroundColor;
  final String textCase; // 'none', 'upper', 'lower', 'title'
  final Color? svgFillColor;

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
    this.isLocked = false,
    this.isVisible = true,
    this.shadowColor,
    this.shadowBlur = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.textBackgroundColor,
    this.textCase = 'none',
    this.svgFillColor,
  });

  EditorItem copyWith({
    String? id,
    String? type,
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
    bool? isLocked,
    bool? isVisible,
    Color? shadowColor,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    Color? textBackgroundColor,
    String? textCase,
    Color? svgFillColor,
  }) {
    return EditorItem(
      id: id ?? this.id,
      type: type ?? this.type,
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
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      textBackgroundColor: textBackgroundColor ?? this.textBackgroundColor,
      textCase: textCase ?? this.textCase,
      svgFillColor: svgFillColor ?? this.svgFillColor,
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
    'is_locked': isLocked,
    'is_visible': isVisible,
    'shadow_blur': shadowBlur,
    'shadow_offset_x': shadowOffsetX,
    'shadow_offset_y': shadowOffsetY,
    'text_case': textCase,
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
      isLocked: json['is_locked'] ?? false,
      isVisible: json['is_visible'] ?? true,
      shadowBlur: (json['shadow_blur'] as num?)?.toDouble() ?? 0.0,
      shadowOffsetX: (json['shadow_offset_x'] as num?)?.toDouble() ?? 0.0,
      shadowOffsetY: (json['shadow_offset_y'] as num?)?.toDouble() ?? 0.0,
      textCase: json['text_case'] ?? 'none',
    );
  }
}
