import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Canva-style colour panel: saturation/value square, hue slider, opacity
/// slider, hex field with preview + eyedropper, and colour presets.

const List<Color> kCanvaColorPresets = <Color>[
  Color(0xFFE53935),
  Color(0xFFFFA000),
  Color(0xFFFFEE58),
  Color(0xFF66BB6A),
  Color(0xFF26A69A),
  Color(0xFF03A9F4),
  Color(0xFF3F3FA8),
  Color(0xFF673AB7),
  Color(0xFFAB1FB0),
  Color(0xFFEC407A),
  Color(0xFF795548),
  Color(0xFFD9D9D9),
];

class _PickerResult {
  _PickerResult(this.color);
  Color color;
  bool changed = false;
}

/// Opens the panel as a bottom sheet. Returns the chosen colour when it was
/// changed (also when the sheet is dismissed by swiping / tapping outside),
/// or null when nothing changed.
///
/// [captureCanvas] enables the eyedropper: it must return a picture of the
/// design page. [allowReset] adds a "Remove colour" button which returns
/// [Colors.transparent].
Future<Color?> showCanvaColorPicker(
    BuildContext context, {
      required Color initial,
      bool isDark = false,
      String title = 'COLOR',
      bool allowReset = false,
      Future<ui.Image?> Function()? captureCanvas,
      ValueChanged<Color>? onChanged,
    }) async {
  final result = _PickerResult(initial);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _CanvaColorSheet(
      result: result,
      isDark: isDark,
      title: title,
      allowReset: allowReset,
      captureCanvas: captureCanvas,
      onChanged: onChanged,
    ),
  );
  return result.changed ? result.color : null;
}

/// Bottom-sheet wrapper around [CanvaColorPanel].
class _CanvaColorSheet extends StatelessWidget {
  const _CanvaColorSheet({
    required this.result,
    required this.isDark,
    required this.title,
    required this.allowReset,
    required this.captureCanvas,
    required this.onChanged,
  });

  final _PickerResult result;
  final bool isDark;
  final String title;
  final bool allowReset;
  final Future<ui.Image?> Function()? captureCanvas;
  final ValueChanged<Color>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SingleChildScrollView(
            child: CanvaColorPanel(
              initial: result.color,
              isDark: isDark,
              title: title,
              captureCanvas: captureCanvas,
              onBack: () => Navigator.of(context).pop(),
              onChanged: (c) {
                result
                  ..color = c
                  ..changed = true;
                onChanged?.call(c);
              },
              onReset: allowReset
                  ? () {
                result
                  ..color = Colors.transparent
                  ..changed = true;
                Navigator.of(context).pop();
              }
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The picker itself (no surrounding sheet) so it can also be embedded inside
/// other screens, e.g. the "background colour" tab.
class CanvaColorPanel extends StatefulWidget {
  const CanvaColorPanel({
    super.key,
    required this.initial,
    required this.onChanged,
    this.isDark = false,
    this.title,
    this.onBack,
    this.onReset,
    this.captureCanvas,
  });

  final Color initial;
  final ValueChanged<Color> onChanged;
  final bool isDark;

  /// Header text. The header (with the back arrow) shows when [onBack] is set.
  final String? title;
  final VoidCallback? onBack;

  /// Shows a "Remove color" button when set.
  final VoidCallback? onReset;
  final Future<ui.Image?> Function()? captureCanvas;

  @override
  State<CanvaColorPanel> createState() => _CanvaColorPanelState();
}

class _CanvaColorPanelState extends State<CanvaColorPanel> {
  late HSVColor _hsv;
  late final TextEditingController _hex;
  final FocusNode _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hex = TextEditingController(text: _hexOf(_hsv.toColor()));
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  static String _hexOf(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  void _set(HSVColor next, {bool updateHex = true}) {
    setState(() => _hsv = next);
    final c = next.toColor();
    widget.onChanged(c);
    if (updateHex) {
      final t = _hexOf(c);
      if (_hex.text != t) {
        _hex.value = TextEditingValue(
          text: t,
          selection: TextSelection.collapsed(offset: t.length),
        );
      }
    }
  }

  void _setColor(Color c) => _set(HSVColor.fromColor(c));

  void _onHexChanged(String v) {
    final t = v.replaceAll('#', '').trim();
    if (t.length != 6) return;
    final n = int.tryParse(t, radix: 16);
    if (n == null) return;
    final base = HSVColor.fromColor(Color(0xFF000000 | n));
    _set(base.withAlpha(_hsv.alpha), updateHex: false);
  }

  Future<void> _eyedrop() async {
    final capture = widget.captureCanvas;
    if (capture == null) return;
    FocusScope.of(context).unfocus();
    final img = await capture();
    if (img == null || !mounted) return;
    final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null || !mounted) return;
    final picked = await Navigator.of(context, rootNavigator: true).push<Color>(
      PageRouteBuilder<Color>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _EyedropperPage(image: img, bytes: bytes),
      ),
    );
    if (picked != null && mounted) {
      _setColor(picked.withValues(alpha: _hsv.alpha));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final fg = dark ? Colors.white : const Color(0xFF171717);
    final field = dark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F4);
    final color = _hsv.toColor();
    final hueColor = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();
    final opaque = _hsv.withAlpha(1).toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onBack != null) ...[
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onBack,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.title ?? 'COLOR',
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _SvPanel(
          hsv: _hsv,
          hueColor: hueColor,
          onChanged: (s, v) =>
              _set(HSVColor.fromAHSV(_hsv.alpha, _hsv.hue, s, v)),
        ),
        const SizedBox(height: 14),
        _GradientSlider(
          value: _hsv.hue / 360,
          colors: const <Color>[
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
          thumbColor: hueColor,
          onChanged: (v) => _set(
            HSVColor.fromAHSV(
              _hsv.alpha,
              (v * 360).clamp(0.0, 360.0),
              _hsv.saturation,
              _hsv.value,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _GradientSlider(
          value: _hsv.alpha,
          checker: true,
          colors: <Color>[opaque.withValues(alpha: 0), opaque],
          thumbColor: color,
          onChanged: (v) => _set(_hsv.withAlpha(v.clamp(0.0, 1.0))),
        ),
        const SizedBox(height: 14),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: field,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '#',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _hex,
                  focusNode: _hexFocus,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                  ],
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: _onHexChanged,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CustomPaint(
                    painter: _CheckerPainter(cell: 4.5),
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
              if (widget.captureCanvas != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _eyedrop,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.colorize_rounded, size: 18, color: fg),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Color Presets',
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            const gap = 8.0;
            final size = (box.maxWidth - gap * 5) / 6;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final p in kCanvaColorPresets)
                  GestureDetector(
                    onTap: () => _setColor(p),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: p,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _hexOf(p) == _hexOf(opaque)
                              ? const Color(0xFF8B3DFF)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.onReset != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onReset,
            child: const Text('Remove color'),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Saturation / value square
// ---------------------------------------------------------------------------
class _SvPanel extends StatelessWidget {
  const _SvPanel({
    required this.hsv,
    required this.hueColor,
    required this.onChanged,
  });

  final HSVColor hsv;
  final Color hueColor;
  final void Function(double s, double v) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        const h = 190.0;

        void handle(Offset p) {
          final s = (p.dx / w).clamp(0.0, 1.0);
          final v = (1 - p.dy / h).clamp(0.0, 1.0);
          onChanged(s, v);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          onTapDown: (d) => handle(d.localPosition),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, hueColor],
                        ),
                      ),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: hsv.saturation * w - 10,
                  top: (1 - hsv.value) * h - 10,
                  child: IgnorePointer(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Rainbow / opacity slider
// ---------------------------------------------------------------------------
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.value,
    required this.colors,
    required this.thumbColor,
    required this.onChanged,
    this.checker = false,
  });

  final double value; // 0..1
  final List<Color> colors;
  final Color thumbColor;
  final ValueChanged<double> onChanged;
  final bool checker;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        const thumb = 20.0;
        const trackH = 12.0;
        final usable = math.max(1.0, w - thumb);

        void handle(Offset p) =>
            onChanged(((p.dx - thumb / 2) / usable).clamp(0.0, 1.0));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          onTapDown: (d) => handle(d.localPosition),
          child: SizedBox(
            width: w,
            height: 26,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: thumb / 2,
                  right: thumb / 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(trackH / 2),
                    child: SizedBox(
                      height: trackH,
                      child: CustomPaint(
                        painter: checker ? _CheckerPainter(cell: 4) : null,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: value.clamp(0.0, 1.0) * usable,
                  child: IgnorePointer(
                    child: Container(
                      width: thumb,
                      height: thumb,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckerPainter extends CustomPainter {
  _CheckerPainter({this.cell = 5});
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final a = Paint()..color = const Color(0xFFFFFFFF);
    final b = Paint()..color = const Color(0xFFCFCFCF);
    canvas.drawRect(Offset.zero & size, a);
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if ((x + y).isOdd) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), b);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter old) => old.cell != cell;
}

// ---------------------------------------------------------------------------
// Eyedropper: the design page, a magnifier loupe follows the finger and the
// colour under it is picked when the finger is lifted.
// ---------------------------------------------------------------------------
class _EyedropperPage extends StatefulWidget {
  const _EyedropperPage({required this.image, required this.bytes});

  final ui.Image image;
  final ByteData bytes;

  @override
  State<_EyedropperPage> createState() => _EyedropperPageState();
}

class _EyedropperPageState extends State<_EyedropperPage> {
  Offset? _pos;
  Rect _rect = Rect.zero;

  Color _colorAt(Offset p) {
    final iw = widget.image.width;
    final ih = widget.image.height;
    final x = (((p.dx - _rect.left) / _rect.width) * iw).floor().clamp(0, iw - 1);
    final y = (((p.dy - _rect.top) / _rect.height) * ih).floor().clamp(0, ih - 1);
    final i = (y * iw + x) * 4;
    return Color.fromARGB(
      255,
      widget.bytes.getUint8(i),
      widget.bytes.getUint8(i + 1),
      widget.bytes.getUint8(i + 2),
    );
  }

  Offset _clamp(Offset p) => Offset(
    p.dx.clamp(_rect.left, _rect.right - 0.01).toDouble(),
    p.dy.clamp(_rect.top, _rect.bottom - 0.01).toDouble(),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, box) {
          final iw = widget.image.width.toDouble();
          final ih = widget.image.height.toDouble();
          final k = math.min(box.maxWidth / iw, box.maxHeight / ih);
          final w = iw * k;
          final h = ih * k;
          _rect = Rect.fromLTWH(
            (box.maxWidth - w) / 2,
            (box.maxHeight - h) / 2,
            w,
            h,
          );
          final pos = _pos;
          const loupe = 120.0;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => setState(() => _pos = _clamp(d.localPosition)),
            onPanUpdate: (d) => setState(() => _pos = _clamp(d.localPosition)),
            onPanEnd: (_) {
              final p = _pos;
              if (p != null) Navigator.of(context).pop(_colorAt(p));
            },
            onTapUp: (d) =>
                Navigator.of(context).pop(_colorAt(_clamp(d.localPosition))),
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: _rect,
                  child: RawImage(image: widget.image, fit: BoxFit.fill),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: const IgnorePointer(
                    child: Center(
                      child: Text(
                        'Drag to pick a colour',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                if (pos != null)
                  Positioned(
                    left: (pos.dx - loupe / 2)
                        .clamp(4.0, box.maxWidth - loupe - 4)
                        .toDouble(),
                    top: (pos.dy - loupe - 36)
                        .clamp(4.0, box.maxHeight - loupe - 4)
                        .toDouble(),
                    child: IgnorePointer(
                      child: CustomPaint(
                        size: const Size(loupe, loupe),
                        painter: _LoupePainter(
                          image: widget.image,
                          pixel: Offset(
                            ((pos.dx - _rect.left) / _rect.width) * iw,
                            ((pos.dy - _rect.top) / _rect.height) * ih,
                          ),
                          centerColor: _colorAt(pos),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoupePainter extends CustomPainter {
  _LoupePainter({
    required this.image,
    required this.pixel,
    required this.centerColor,
  });

  final ui.Image image;
  final Offset pixel;
  final Color centerColor;

  static const int _cells = 15;

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawRect(circle, Paint()..color = Colors.white);
    final cx = pixel.dx.floorToDouble();
    final cy = pixel.dy.floorToDouble();
    final half = _cells / 2;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(cx - half + 0.5, cy - half + 0.5, _cells.toDouble(),
          _cells.toDouble()),
      circle,
      Paint()..filterQuality = FilterQuality.none,
    );
    final cell = size.width / _cells;
    final grid = Paint()
      ..color = Colors.black26
      ..strokeWidth = 0.7;
    for (var i = 0; i <= _cells; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), grid);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), grid);
    }
    final mid = Rect.fromLTWH(
      (_cells ~/ 2) * cell,
      (_cells ~/ 2) * cell,
      cell,
      cell,
    );
    canvas.drawRect(
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawRect(
      mid.inflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black,
    );
    canvas.restore();
    canvas.drawCircle(
      circle.center,
      size.width / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = centerColor,
    );
    canvas.drawCircle(
      circle.center,
      size.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _LoupePainter old) =>
      old.pixel != pixel || old.centerColor != centerColor;
}