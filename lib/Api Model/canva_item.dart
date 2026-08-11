import 'dart:ui';

enum EditorItemType { text, image, video, shape, emoji }

enum EditorShape { rectangle, circle, line }

class CanvaItem {
  final String id;
  final EditorItemType type;
  final Offset position;
  final double width;
  final double height;
  final double rotation;
  final double scale;
  final double opacity;
  final bool locked;
  final bool visible;
  final int zIndex;

  final String contentUrl;
  final bool isLocal;

  final String text;
  final double fontSize;
  final String fontFamily;
  final int textColorValue;
  final bool bold;
  final bool italic;
  final TextAlign textAlign;
  final double letterSpacing;
  final double lineHeight;

  final int fillColorValue;
  final int borderColorValue;
  final double borderWidth;
  final double borderRadius;

  final double brightness;
  final double contrast;
  final double saturation;
  final String filterType;

  final bool flipX;
  final bool flipY;
  final String? groupId;

  const CanvaItem({
    required this.id,
    required this.type,
    this.position = Offset.zero,
    this.width = 220,
    this.height = 220,
    this.rotation = 0,
    this.scale = 1,
    this.opacity = 1,
    this.locked = false,
    this.visible = true,
    this.zIndex = 0,
    this.contentUrl = '',
    this.isLocal = false,
    this.text = '',
    this.fontSize = 32,
    this.fontFamily = 'sans-serif',
    this.textColorValue = 0xFF111111,
    this.bold = false,
    this.italic = false,
    this.textAlign = TextAlign.center,
    this.letterSpacing = 0,
    this.lineHeight = 1.2,
    this.fillColorValue = 0xFFFFFFFF,
    this.borderColorValue = 0x00000000,
    this.borderWidth = 0,
    this.borderRadius = 0,
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
    this.filterType = 'none',
    this.flipX = false,
    this.flipY = false,
    this.groupId,
  });

  CanvaItem copyWith({
    String? id,
    EditorItemType? type,
    Offset? position,
    double? width,
    double? height,
    double? rotation,
    double? scale,
    double? opacity,
    bool? locked,
    bool? visible,
    int? zIndex,
    String? contentUrl,
    bool? isLocal,
    String? text,
    double? fontSize,
    String? fontFamily,
    int? textColorValue,
    bool? bold,
    bool? italic,
    TextAlign? textAlign,
    double? letterSpacing,
    double? lineHeight,
    int? fillColorValue,
    int? borderColorValue,
    double? borderWidth,
    double? borderRadius,
    double? brightness,
    double? contrast,
    double? saturation,
    String? filterType,
    bool? flipX,
    bool? flipY,
    String? groupId,
  }) {
    return CanvaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
      visible: visible ?? this.visible,
      zIndex: zIndex ?? this.zIndex,
      contentUrl: contentUrl ?? this.contentUrl,
      isLocal: isLocal ?? this.isLocal,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textColorValue: textColorValue ?? this.textColorValue,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      textAlign: textAlign ?? this.textAlign,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      fillColorValue: fillColorValue ?? this.fillColorValue,
      borderColorValue: borderColorValue ?? this.borderColorValue,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      filterType: filterType ?? this.filterType,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      groupId: groupId ?? this.groupId,
    );
  }
}
