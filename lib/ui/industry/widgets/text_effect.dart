import 'dart:math' as math;

import 'package:flutter/material.dart';

enum TextEffectType {
  none,
  outline,
  textBox,
  shadow,
  curve,
  reflection,
  echo,
  glitch,
}

extension TextEffectTypeX on TextEffectType {
  String get label => switch (this) {
    TextEffectType.none => 'None',
    TextEffectType.outline => 'Outline',
    TextEffectType.textBox => 'Text Box',
    TextEffectType.shadow => 'Shadow',
    TextEffectType.curve => 'Curve',
    TextEffectType.reflection => 'Reflection',
    TextEffectType.echo => 'Echo',
    TextEffectType.glitch => 'Glitch',
  };

  IconData get icon => switch (this) {
    TextEffectType.none => Icons.block,
    TextEffectType.outline => Icons.text_fields,
    TextEffectType.textBox => Icons.title,
    TextEffectType.shadow => Icons.format_color_text,
    TextEffectType.curve => Icons.insights,
    TextEffectType.reflection => Icons.flip,
    TextEffectType.echo => Icons.blur_linear,
    TextEffectType.glitch => Icons.broken_image_outlined,
  };

  bool get hasColor =>
      this == TextEffectType.outline ||
          this == TextEffectType.textBox ||
          this == TextEffectType.shadow;

  bool get hasGlitchPresets => this == TextEffectType.glitch;

  /// Sliders shown in the "<Effect> Settings" section.
  List<TextEffectSliderSpec> get sliders => switch (this) {
    TextEffectType.none => const [],
    TextEffectType.outline => const [
      TextEffectSliderSpec('thickness', 'Thickness', 0, 100),
    ],
    TextEffectType.textBox => const [
      TextEffectSliderSpec('roundness', 'Roundness', 0, 100),
      TextEffectSliderSpec('spread', 'Spread', 0, 100),
      TextEffectSliderSpec('opacity', 'Opacity', 0, 100),
    ],
    TextEffectType.shadow => const [
      TextEffectSliderSpec('offset', 'Offset', 0, 100),
      TextEffectSliderSpec('angle', 'Angle', -180, 180, unit: '°'),
      TextEffectSliderSpec('blur', 'Blur', 0, 100),
      TextEffectSliderSpec('opacity', 'Opacity', 0, 100),
    ],
    TextEffectType.curve => const [
      TextEffectSliderSpec('curve', 'Curve', -100, 100),
    ],
    TextEffectType.reflection => const [
      TextEffectSliderSpec('offset', 'Offset', 0, 100),
      TextEffectSliderSpec('opacity', 'Opacity', 0, 100),
    ],
    TextEffectType.echo => const [
      TextEffectSliderSpec('offset', 'Offset', 0, 100),
      TextEffectSliderSpec('angle', 'Angle', -180, 180, unit: '°'),
    ],
    TextEffectType.glitch => const [
      TextEffectSliderSpec('offset', 'Offset', 0, 100),
      TextEffectSliderSpec('angle', 'Angle', 0, 360, unit: '°'),
    ],
  };
}

class TextEffectSliderSpec {
  final String key;
  final String label;
  final double min;
  final double max;
  final String unit;

  const TextEffectSliderSpec(
      this.key,
      this.label,
      this.min,
      this.max, {
        this.unit = '',
      });
}

/// Glitch colour presets: [first, second].
const List<List<Color>> kGlitchPresets = [
  [Color(0xFF00E5FF), Color(0xFFFF00E5)], // Cyan / Magenta
  [Color(0xFF2979FF), Color(0xFFFF1744)], // Blue / Red
];
const List<String> kGlitchPresetNames = ['Cyan / Magenta', 'Blue / Red'];

/// Colours offered for Outline / Text Box / Shadow.
const List<Color> kTextEffectColors = [
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFE53935),
  Color(0xFFFF9800),
  Color(0xFFFFEB3B),
  Color(0xFF43A047),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
];

@immutable
class TextEffect {
  final TextEffectType type;
  final double offset;
  final double angle;
  final double blur;
  final double opacity; // percent 0..100
  final double thickness;
  final double roundness;
  final double spread;
  final double curve; // -100..100
  final Color color;
  final int glitchPreset;

  const TextEffect({
    this.type = TextEffectType.none,
    this.offset = 50,
    this.angle = -45,
    this.blur = 0,
    this.opacity = 100,
    this.thickness = 50,
    this.roundness = 50,
    this.spread = 50,
    this.curve = 50,
    this.color = Colors.black,
    this.glitchPreset = 0,
  });

  static const TextEffect empty = TextEffect();

  bool get isNone => type == TextEffectType.none;

  /// Sensible starting values for each effect.
  factory TextEffect.defaults(TextEffectType type) {
    switch (type) {
      case TextEffectType.none:
        return TextEffect.empty;
      case TextEffectType.outline:
        return const TextEffect(
          type: TextEffectType.outline,
          thickness: 50,
          color: Colors.black,
        );
      case TextEffectType.textBox:
        return const TextEffect(
          type: TextEffectType.textBox,
          roundness: 50,
          spread: 50,
          opacity: 100,
          color: Color(0xFFFFEB3B),
        );
      case TextEffectType.shadow:
        return const TextEffect(
          type: TextEffectType.shadow,
          offset: 50,
          angle: -45,
          blur: 0,
          opacity: 40,
          color: Colors.black,
        );
      case TextEffectType.curve:
        return const TextEffect(type: TextEffectType.curve, curve: 50);
      case TextEffectType.reflection:
        return const TextEffect(
          type: TextEffectType.reflection,
          offset: 0,
          opacity: 50,
        );
      case TextEffectType.echo:
        return const TextEffect(
          type: TextEffectType.echo,
          offset: 50,
          angle: -45,
        );
      case TextEffectType.glitch:
        return const TextEffect(
          type: TextEffectType.glitch,
          offset: 30,
          angle: 0,
          glitchPreset: 0,
        );
    }
  }

  double valueOf(String key) => switch (key) {
    'offset' => offset,
    'angle' => angle,
    'blur' => blur,
    'opacity' => opacity,
    'thickness' => thickness,
    'roundness' => roundness,
    'spread' => spread,
    'curve' => curve,
    _ => 0,
  };

  TextEffect withValue(String key, double v) => switch (key) {
    'offset' => copyWith(offset: v),
    'angle' => copyWith(angle: v),
    'blur' => copyWith(blur: v),
    'opacity' => copyWith(opacity: v),
    'thickness' => copyWith(thickness: v),
    'roundness' => copyWith(roundness: v),
    'spread' => copyWith(spread: v),
    'curve' => copyWith(curve: v),
    _ => this,
  };

  TextEffect copyWith({
    TextEffectType? type,
    double? offset,
    double? angle,
    double? blur,
    double? opacity,
    double? thickness,
    double? roundness,
    double? spread,
    double? curve,
    Color? color,
    int? glitchPreset,
  }) {
    return TextEffect(
      type: type ?? this.type,
      offset: offset ?? this.offset,
      angle: angle ?? this.angle,
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      thickness: thickness ?? this.thickness,
      roundness: roundness ?? this.roundness,
      spread: spread ?? this.spread,
      curve: curve ?? this.curve,
      color: color ?? this.color,
      glitchPreset: glitchPreset ?? this.glitchPreset,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'offset': offset,
    'angle': angle,
    'blur': blur,
    'opacity': opacity,
    'thickness': thickness,
    'roundness': roundness,
    'spread': spread,
    'curve': curve,
    'color': color.toARGB32(),
    'glitchPreset': glitchPreset,
  };

  factory TextEffect.fromJson(dynamic json) {
    if (json is! Map) return TextEffect.empty;
    double d(String k, double fallback) =>
        (json[k] as num?)?.toDouble() ?? fallback;
    final typeName = json['type']?.toString();
    final type = TextEffectType.values.firstWhere(
          (e) => e.name == typeName,
      orElse: () => TextEffectType.none,
    );
    final base = TextEffect.defaults(type);
    return TextEffect(
      type: type,
      offset: d('offset', base.offset),
      angle: d('angle', base.angle),
      blur: d('blur', base.blur),
      opacity: d('opacity', base.opacity),
      thickness: d('thickness', base.thickness),
      roundness: d('roundness', base.roundness),
      spread: d('spread', base.spread),
      curve: d('curve', base.curve),
      color: json['color'] is num
          ? Color((json['color'] as num).toInt())
          : base.color,
      glitchPreset: ((json['glitchPreset'] as num?)?.toInt() ?? 0)
          .clamp(0, kGlitchPresets.length - 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TextEffect &&
              other.type == type &&
              other.offset == offset &&
              other.angle == angle &&
              other.blur == blur &&
              other.opacity == opacity &&
              other.thickness == thickness &&
              other.roundness == roundness &&
              other.spread == spread &&
              other.curve == curve &&
              other.color == color &&
              other.glitchPreset == glitchPreset;

  @override
  int get hashCode => Object.hash(
    type,
    offset,
    angle,
    blur,
    opacity,
    thickness,
    roundness,
    spread,
    curve,
    color,
    glitchPreset,
  );
}

/// Builds the text with the chosen effect applied.
///
/// All effects draw outside the text box with `Clip.none` so the item's
/// measured size / selection box never changes when an effect is applied.
Widget buildTextWithEffect({
  required TextEffect effect,
  required String text,
  required TextStyle style,
  required bool multiline,
  required TextAlign textAlign,
}) {
  Text t(TextStyle s) => Text(
    text,
    maxLines: multiline ? null : 1,
    softWrap: multiline,
    textAlign: textAlign,
    overflow: TextOverflow.visible,
    style: s,
  );

  if (effect.isNone) return t(style);

  final fontSize = style.fontSize ?? 14.0;
  final unit = fontSize * 0.4 / 100.0;
  final rad = effect.angle * math.pi / 180.0;
  // Positive angle = counter-clockwise (up), so -45 is "down-right".
  final dir = Offset(math.cos(rad), -math.sin(rad));
  final baseColor = style.color ?? Colors.black;

  switch (effect.type) {
    case TextEffectType.none:
      return t(style);

    case TextEffectType.outline:
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = effect.thickness / 100.0 * fontSize * 0.2
        ..color = effect.color;
      return Stack(
        clipBehavior: Clip.none,
        children: [t(style.copyWith(foreground: stroke)), t(style)],
      );

    case TextEffectType.textBox:
      final padX = effect.spread / 100.0 * fontSize * 0.5;
      final padY = padX * 0.6;
      final radius = effect.roundness / 100.0 * (fontSize * 0.6 + padX);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -padX,
            right: -padX,
            top: -padY,
            bottom: -padY,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: effect.color.withValues(alpha: effect.opacity / 100.0),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          t(style),
        ],
      );

    case TextEffectType.shadow:
      final d = effect.offset * unit;
      return t(
        style.copyWith(
          shadows: [
            Shadow(
              color: effect.color.withValues(alpha: effect.opacity / 100.0),
              offset: Offset(dir.dx * d, dir.dy * d),
              blurRadius: effect.blur / 100.0 * fontSize * 0.3,
            ),
          ],
        ),
      );

    case TextEffectType.curve:
      return _CurvedText(text: text, style: style, amount: effect.curve);

    case TextEffectType.reflection:
      final gap = effect.offset / 100.0 * fontSize * 0.5;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          t(style),
          // heightFactor 0: the reflection paints below the text without
          // changing the layout height of the item.
          Align(
            alignment: Alignment.topLeft,
            heightFactor: 0.0,
            child: Padding(
              padding: EdgeInsets.only(top: gap),
              child: Opacity(
                opacity: (effect.opacity / 100.0).clamp(0.0, 1.0),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
                  ).createShader(rect),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(1.0, -1.0, 1.0),
                    child: t(style),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

    case TextEffectType.echo:
      final d = effect.offset * unit;
      Widget layer(int i, double alpha) => Transform.translate(
        offset: Offset(dir.dx * d * i, dir.dy * d * i),
        child: t(style.copyWith(color: baseColor.withValues(alpha: alpha))),
      );
      return Stack(
        clipBehavior: Clip.none,
        children: [layer(3, 0.15), layer(2, 0.3), layer(1, 0.5), t(style)],
      );

    case TextEffectType.glitch:
      final d = effect.offset * unit;
      final colors = kGlitchPresets[effect.glitchPreset.clamp(
        0,
        kGlitchPresets.length - 1,
      )];
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(dir.dx * d, dir.dy * d),
            child: t(style.copyWith(color: colors[0].withValues(alpha: .9))),
          ),
          Transform.translate(
            offset: Offset(-dir.dx * d, -dir.dy * d),
            child: t(style.copyWith(color: colors[1].withValues(alpha: .9))),
          ),
          t(style),
        ],
      );
  }
}

/// Lays the characters of a single line of text along a circular arc.
class _CurvedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double amount; // -100..100

  const _CurvedText({
    required this.text,
    required this.style,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final plain = text.replaceAll(RegExp(r'[\r\n]+'), ' ');
    final tp = TextPainter(
      text: TextSpan(text: plain, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return CustomPaint(
      size: Size(tp.width, tp.height),
      painter: _CurvedTextPainter(plain, style, amount),
    );
  }
}

class _CurvedTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double amount;

  _CurvedTextPainter(this.text, this.style, this.amount);

  @override
  void paint(Canvas canvas, Size size) {
    final painters = <TextPainter>[];
    var total = 0.0;
    for (final ch in text.characters) {
      final p = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(p);
      total += p.width;
    }
    if (painters.isEmpty || total <= 0) return;

    final a = amount / 100.0;
    if (a.abs() < 0.01) {
      var x = 0.0;
      for (final p in painters) {
        p.paint(canvas, Offset(x, 0));
        x += p.width;
      }
      return;
    }

    final theta = a.abs() * math.pi; // total sweep, up to 180°
    final r = total / theta;
    final cx = size.width / 2;
    var travelled = 0.0;

    for (final p in painters) {
      final mid = travelled + p.width / 2;
      travelled += p.width;
      final phi = mid / r - theta / 2;

      canvas.save();
      if (a > 0) {
        // Rainbow: chars sit on top of the circle, tops pointing outwards.
        canvas.translate(cx + r * math.sin(phi), r * (1 - math.cos(phi)));
        canvas.rotate(phi);
        p.paint(canvas, Offset(-p.width / 2, 0));
      } else {
        // Smile: chars hang on the bottom of the circle.
        canvas.translate(
          cx + r * math.sin(phi),
          size.height - r * (1 - math.cos(phi)),
        );
        canvas.rotate(-phi);
        p.paint(canvas, Offset(-p.width / 2, -size.height));
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedTextPainter old) =>
      old.text != text || old.amount != amount || old.style != style;
}