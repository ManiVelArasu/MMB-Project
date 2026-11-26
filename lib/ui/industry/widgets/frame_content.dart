import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mmb_app/core/api/api_endpoints.dart';

// ========================================================================
// Renders the frame `content` (Fabric.js JSON from frames/{uid}) as native
// Flutter widgets. Objects whose data.name starts with "slot:" are
// replaceable:
//   slot:logo*   -> logo widget (logoBuilder)
//   slot:phone   -> slotTexts['phone']
//   slot:web     -> slotTexts['web']
//   slot:email   -> slotTexts['email']
//
// Also supported:
//   - Fabric "group" objects (slot name on the group is inherited by its
//     children, children are positioned relative to the group centre)
//   - If the designer forgot the slot name, text that looks like a phone /
//     website / email is detected automatically.
// Page background is NOT painted, so the user's photo shows through.
// ========================================================================

class FrameContent {
  final double width;
  final double height;
  final List<Map<String, dynamic>> objects;
  final bool hasSlots;

  const FrameContent({
    required this.width,
    required this.height,
    required this.objects,
    required this.hasSlots,
  });

  /// `version.asset_prefix` of the frames/{id} response (e.g.
  /// "frames/<versionUid>/"). The frame json points to a temp bucket that the
  /// app cannot read (403); published assets live under this prefix on the CDN.
  static String assetPrefix = '';

  /// `uid` of the frame (frames/{uid}). Template assets live under
  /// templates/<uid>/<file>, so frame assets are tried under frames/<uid>/.
  static String frameUid = '';

  static String? _lastRaw;
  static FrameContent? _lastParsed;

  /// Parses the `content` string (cached, so typing in the edit fields
  /// does not re-parse the JSON on every keystroke).
  static FrameContent? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw == _lastRaw) return _lastParsed;
    _lastRaw = raw;
    _lastParsed = _parse(raw);
    return _lastParsed;
  }

  static FrameContent? _parse(String raw) {
    try {
      final root = jsonDecode(raw);
      if (root is! Map) return null;

      final pages = root['pages'];
      if (pages is! List || pages.isEmpty || pages.first is! Map) return null;

      final page = pages.first as Map;
      final fabric = page['fabric'];
      final objs = (fabric is Map && fabric['objects'] is List)
          ? (fabric['objects'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      final w = _num(page['width'], 1080);
      final h = _num(page['height'], 1080);
      if (w <= 0 || h <= 0) return null;

      // DEBUG (debug builds only): what the frame JSON contains and which
      // objects were detected as slots. Remove when everything works.
      if (kDebugMode) {
        for (final o in _flatten(objs)) {
          debugPrint(
            'FRAME obj type=${o['type']} data=${o['data']} '
            'text=${o['text']} src=${o['src']} -> slot=${slotKeyOf(o)}',
          );
        }
      }

      return FrameContent(
        width: w,
        height: h,
        objects: objs,
        hasSlots: _flatten(objs).any((o) => slotKeyOf(o) != null),
      );
    } catch (_) {
      return null;
    }
  }

  /// All objects including the children of groups.
  static List<Map<String, dynamic>> _flatten(List<Map<String, dynamic>> list) {
    final out = <Map<String, dynamic>>[];
    for (final o in list) {
      out.add(o);
      final c = o['objects'];
      if (c is List) {
        out.addAll(
          _flatten(
            c
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
          ),
        );
      }
    }
    return out;
  }

  /// "slot:phone" -> "phone", "slot:logo.svg" -> "logo", else null.
  /// Falls back to guessing from the text when the name is missing.
  static String? slotKeyOf(Map<String, dynamic> o) {
    final d = o['data'];
    final name =
        (d is Map ? d['name'] : null)?.toString() ?? o['name']?.toString();

    if (name != null && name.toLowerCase().trim().startsWith('slot:')) {
      var key = name.trim().substring(5).toLowerCase().trim();
      final dot = key.indexOf('.');
      if (dot > 0) key = key.substring(0, dot);

      // tolerate names like "logo1", "phone-2", "website_text" ...
      if (key.startsWith('logo')) return 'logo';
      if (key.startsWith('phone') ||
          key.startsWith('mobile') ||
          key.startsWith('contact') ||
          key.startsWith('number') ||
          key.startsWith('whatsapp')) {
        return 'phone';
      }
      if (key.startsWith('web') ||
          key.startsWith('site') ||
          key.startsWith('url')) {
        return 'web';
      }
      if (key.startsWith('mail') || key.startsWith('email')) return 'email';
      return key;
    }

    return _guessFromText(o) ?? _guessLogo(o);
  }

  /// Unnamed image whose name / file name contains "logo".
  static String? _guessLogo(Map<String, dynamic> o) {
    if ((o['type'] ?? '').toString().toLowerCase() != 'image') return null;
    final d = o['data'];
    final hay = [
      d is Map ? d['name'] : null,
      o['name'],
      o['src']?.toString().split('?').first.split('/').last,
    ].join(' ').toLowerCase();
    return hay.contains('logo') ? 'logo' : null;
  }

  /// Unnamed text that looks like a phone / website / email.
  static String? _guessFromText(Map<String, dynamic> o) {
    final t = (o['type'] ?? '').toString().toLowerCase();
    if (t != 'textbox' && t != 'text' && t != 'itext') return null;

    final s = (o['text'] ?? '').toString().trim().toLowerCase();
    if (s.isEmpty) return null;

    if (s.contains('@')) return 'email';
    if (s.startsWith('www.') || s.startsWith('http')) return 'web';
    if (RegExp(r'^\+?[\d\s\-()]{8,}$').hasMatch(s)) return 'phone';
    return null;
  }
}

double _num(dynamic v, [double d = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? d;
}

class FrameContentView extends StatelessWidget {
  final FrameContent content;

  /// Values for text slots: {'phone': ..., 'web': ..., 'email': ...}.
  /// An empty value keeps the frame's original placeholder text; a key
  /// that is not passed keeps the original text too.
  final Map<String, String> slotTexts;

  /// false -> all slot objects (logo / phone / web ...) are hidden.
  final bool showSlots;

  /// Builds the logo for `slot:logo*` (w / h are canvas units).
  /// Return null to keep the frame's own logo image.
  final Widget? Function(double w, double h)? logoBuilder;

  const FrameContentView({
    super.key,
    required this.content,
    this.slotTexts = const {},
    this.showSlots = true,
    this.logoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: content.width,
        height: content.height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [for (final o in content.objects) _object(o)],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // OBJECTS
  // dx / dy = offset of the parent group's centre (0 for top level)
  // ------------------------------------------------------------------

  Widget _object(
    Map<String, dynamic> o, {
    double dx = 0,
    double dy = 0,
    String? inheritSlot,
  }) {
    if (o['visible'] == false) return const SizedBox.shrink();

    final ownSlot = FrameContent.slotKeyOf(o);
    final slot = ownSlot ?? inheritSlot;
    // slot taken only from the parent group (e.g. "LET'S TALK" label inside
    // a slot:phone group) - such children are not replaced blindly
    final inherited = ownSlot == null && inheritSlot != null;
    if (slot != null && !showSlots) return const SizedBox.shrink();

    final type = (o['type'] ?? '').toString().toLowerCase();
    final sx = _num(o['scaleX'], 1);
    final sy = _num(o['scaleY'], 1);
    final w = _num(o['width']) * sx;
    final h = _num(o['height']) * sy;

    switch (type) {
      case 'group':
        return _group(o, slot, w, h, sx, sy, dx, dy);
      case 'image':
        return _image(o, slot, w, h, dx, dy);
      case 'textbox':
      case 'text':
      case 'itext':
        return _text(o, slot, inherited, w, h, sy, dx, dy);
      case 'path':
        return _path(o, w, h, sx, sy, dx, dy);
      case 'rect':
        return _rect(o, w, h, dx, dy);
      case 'circle':
        final d = _num(o['radius']) * 2;
        return _circle(o, d * sx, d * sy, dx, dy);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _group(
    Map<String, dynamic> o,
    String? slot,
    double w,
    double h,
    double sx,
    double sy,
    double dx,
    double dy,
  ) {
    final gw = _num(o['width']);
    final gh = _num(o['height']);
    final kids = (o['objects'] is List ? o['objects'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e));

    // Fabric: children coordinates are relative to the group's centre.
    final inner = SizedBox(
      width: gw,
      height: gh,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final k in kids)
            _object(k, dx: gw / 2, dy: gh / 2, inheritSlot: slot),
        ],
      ),
    );

    return _place(
      o,
      w,
      h,
      SizedBox(
        width: w,
        height: h,
        child: Align(
          alignment: Alignment.topLeft,
          child: Transform.scale(
            scaleX: sx,
            scaleY: sy,
            alignment: Alignment.topLeft,
            child: inner,
          ),
        ),
      ),
      dx: dx,
      dy: dy,
    );
  }

  Widget _image(
    Map<String, dynamic> o,
    String? slot,
    double w,
    double h,
    double dx,
    double dy,
  ) {
    Widget child;

    final custom = (slot == 'logo' && logoBuilder != null)
        ? logoBuilder!(w, h)
        : null;

    if (custom != null) {
      child = custom;
    } else {
      final src = _resolveSrc((o['src'] ?? '').toString());
      if (src.isEmpty) return const SizedBox.shrink();

      if (src.startsWith('data:')) {
        // inline image (whatsapp / website icons are often embedded svg)
        child = _dataImage(src, w, h);
      } else {
        final isSvg = src.split('?').first.toLowerCase().endsWith('.svg');
        child = isSvg
            ? _RemoteSvg(url: src, width: w, height: h)
            : CachedNetworkImage(
                imageUrl: src,
                width: w,
                height: h,
                fit: BoxFit.fill,
                placeholder: (_, __) => const SizedBox.shrink(),
                // not a bitmap (svg without .svg in the url) -> try as svg
                errorWidget: (_, __, ___) =>
                    _RemoteSvg(url: src, width: w, height: h),
              );
      }
    }

    return _place(
      o,
      w,
      h,
      SizedBox(width: w, height: h, child: child),
      dx: dx,
      dy: dy,
    );
  }

  /// Relative s3 key -> cdn url, "//host/x" -> https, full urls unchanged.
  String _resolveSrc(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http') || s.startsWith('data:')) return s;
    if (s.startsWith('//')) return 'https:$s';
    final key = s.startsWith('/') ? s.substring(1) : s;
    return '${ApiEndpoints.cdnImageUrl}/$key';
  }

  Widget _dataImage(String src, double w, double h) {
    try {
      final data = Uri.parse(src).data;
      if (data == null) return const SizedBox.shrink();
      final bytes = data.contentAsBytes();
      if (data.mimeType.contains('svg')) {
        return SvgPicture.memory(bytes, width: w, height: h, fit: BoxFit.fill);
      }
      return Image.memory(bytes, width: w, height: h, fit: BoxFit.fill);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _text(
    Map<String, dynamic> o,
    String? slot,
    bool inherited,
    double w,
    double h,
    double sy,
    double dx,
    double dy,
  ) {
    var text = (o['text'] ?? '').toString();
    var isSlotText = false;

    // Inside a named group only the text that looks like the slot value
    // (phone / website / email) is replaced, labels are kept.
    final replaceable =
        slot != null && (!inherited || FrameContent._guessFromText(o) == slot);

    if (replaceable && slotTexts.containsKey(slot)) {
      final v = slotTexts[slot]!.trim();
      // empty field -> keep the frame's own placeholder text
      // (e.g. "www.mywebsite.com"), exactly like the web version
      if (v.isNotEmpty) {
        text = v;
        isSlotText = true;
      }
    }

    final fs = _num(o['fontSize'], 16) * sy;

    var weight = 400.0;
    final rawWeight = o['fontWeight'];
    if (rawWeight is num) {
      weight = rawWeight.toDouble();
    } else if (rawWeight is String) {
      weight = rawWeight == 'bold' ? 700 : (double.tryParse(rawWeight) ?? 400);
    }
    final fw =
        FontWeight.values[(weight / 100).round().clamp(1, 9).toInt() - 1];

    final align = switch (o['textAlign']) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      _ => TextAlign.left,
    };

    final deco = <TextDecoration>[
      if (o['underline'] == true) TextDecoration.underline,
      if (o['linethrough'] == true) TextDecoration.lineThrough,
    ];

    final style = TextStyle(
      fontSize: fs,
      fontWeight: fw,
      fontStyle: o['fontStyle'] == 'italic'
          ? FontStyle.italic
          : FontStyle.normal,
      color: _color(o['fill']) ?? Colors.black,
      height: _num(o['lineHeight'], 1.16),
      fontFamily: _family(o['fontFamily']),
      letterSpacing: _num(o['charSpacing']) / 1000 * fs,
      decoration: deco.isEmpty ? null : TextDecoration.combine(deco),
    );

    Widget t = Text(
      text,
      textAlign: align,
      style: style,
      softWrap: !isSlotText,
      maxLines: isSlotText ? 1 : null,
    );

    // slot values (phone / website) shrink to fit instead of wrapping
    if (isSlotText) {
      t = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align == TextAlign.center
            ? Alignment.center
            : align == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: t,
      );
    }

    return _place(
      o,
      w,
      h,
      SizedBox(width: w, child: t),
      dx: dx,
      dy: dy,
    );
  }

  Widget _path(
    Map<String, dynamic> o,
    double w,
    double h,
    double sx,
    double sy,
    double dx,
    double dy,
  ) {
    final path = _buildPath(o['path']);
    if (path == null) return const SizedBox.shrink();

    path.fillType = o['fillRule'] == 'evenodd'
        ? PathFillType.evenOdd
        : PathFillType.nonZero;

    final painter = _PathPainter(
      path: path,
      bounds: path.getBounds(),
      fill: _color(o['fill']),
      stroke: _color(o['stroke']),
      strokeWidth: _num(o['strokeWidth']),
      sx: sx,
      sy: sy,
    );

    return _place(
      o,
      w,
      h,
      SizedBox(
        width: w,
        height: h,
        child: CustomPaint(painter: painter),
      ),
      dx: dx,
      dy: dy,
    );
  }

  Widget _rect(
    Map<String, dynamic> o,
    double w,
    double h,
    double dx,
    double dy,
  ) {
    final stroke = _color(o['stroke']);
    final sw = _num(o['strokeWidth']);

    return _place(
      o,
      w,
      h,
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _color(o['fill']),
          borderRadius: BorderRadius.circular(_num(o['rx'])),
          border: stroke != null && sw > 0
              ? Border.all(color: stroke, width: sw)
              : null,
        ),
      ),
      dx: dx,
      dy: dy,
    );
  }

  Widget _circle(
    Map<String, dynamic> o,
    double w,
    double h,
    double dx,
    double dy,
  ) {
    final stroke = _color(o['stroke']);
    final sw = _num(o['strokeWidth']);

    return _place(
      o,
      w,
      h,
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _color(o['fill']),
          shape: BoxShape.circle,
          border: stroke != null && sw > 0
              ? Border.all(color: stroke, width: sw)
              : null,
        ),
      ),
      dx: dx,
      dy: dy,
    );
  }

  // ------------------------------------------------------------------
  // POSITION / ROTATION / OPACITY  (Fabric: left/top = origin point)
  // ------------------------------------------------------------------

  Widget _place(
    Map<String, dynamic> o,
    double w,
    double h,
    Widget child, {
    double dx = 0,
    double dy = 0,
  }) {
    final ox = (o['originX'] ?? 'left').toString();
    final oy = (o['originY'] ?? 'top').toString();
    final ax = ox == 'center' ? 0.0 : (ox == 'right' ? 1.0 : -1.0);
    final ay = oy == 'center' ? 0.0 : (oy == 'bottom' ? 1.0 : -1.0);

    final left = _num(o['left']) - (ax + 1) / 2 * w + dx;
    final top = _num(o['top']) - (ay + 1) / 2 * h + dy;

    Widget c = child;

    if (o['flipX'] == true || o['flipY'] == true) {
      c = Transform.scale(
        scaleX: o['flipX'] == true ? -1 : 1,
        scaleY: o['flipY'] == true ? -1 : 1,
        child: c,
      );
    }

    final angle = _num(o['angle']);
    if (angle != 0) {
      c = Transform.rotate(
        angle: angle * math.pi / 180,
        alignment: Alignment(ax, ay),
        child: c,
      );
    }

    final opacity = _num(o['opacity'], 1);
    if (opacity < 1) {
      c = Opacity(opacity: opacity.clamp(0.0, 1.0).toDouble(), child: c);
    }

    return Positioned(left: left, top: top, child: c);
  }

  // ------------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------------

  String? _family(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return null;
    final first = s
        .split(',')
        .first
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    return first.isEmpty ? null : first;
  }

  /// "rgba(73,153,31,1)" / "#fff" / "#ffffff" / "#rrggbbaa"
  Color? _color(dynamic v) {
    if (v is! String) return null;
    final s = v.trim().toLowerCase();
    if (s.isEmpty || s == 'none') return null;
    if (s == 'transparent') return Colors.transparent;

    if (s.startsWith('#')) {
      var h = s.substring(1);
      if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
      if (h.length == 6) h = 'ff$h';
      if (h.length == 8) h = h.substring(6) + h.substring(0, 6); // rrggbbaa
      final n = int.tryParse(h, radix: 16);
      return n == null ? null : Color(n);
    }

    final m = RegExp(r'rgba?\(([^)]+)\)').firstMatch(s);
    if (m != null) {
      final p = m.group(1)!.split(',').map((e) => e.trim()).toList();
      if (p.length < 3) return null;
      final r = (double.tryParse(p[0]) ?? 0).round().clamp(0, 255).toInt();
      final g = (double.tryParse(p[1]) ?? 0).round().clamp(0, 255).toInt();
      final b = (double.tryParse(p[2]) ?? 0).round().clamp(0, 255).toInt();
      final a = p.length > 3 ? (double.tryParse(p[3]) ?? 1.0) : 1.0;
      return Color.fromRGBO(r, g, b, a.clamp(0.0, 1.0).toDouble());
    }
    return null;
  }

  /// Fabric path array: [["M",x,y], ["C",x1,y1,x2,y2,x,y], ["L",x,y], ["Z"]]
  Path? _buildPath(dynamic raw) {
    if (raw is! List) return null;
    try {
      final p = Path();
      var cx = 0.0, cy = 0.0, startX = 0.0, startY = 0.0;

      for (final seg in raw) {
        if (seg is! List || seg.isEmpty) continue;
        final cmd = seg.first.toString();
        final v = seg.skip(1).map((e) => _num(e)).toList();

        switch (cmd) {
          case 'M':
            p.moveTo(v[0], v[1]);
            cx = startX = v[0];
            cy = startY = v[1];
          case 'L':
            p.lineTo(v[0], v[1]);
            cx = v[0];
            cy = v[1];
          case 'H':
            p.lineTo(v[0], cy);
            cx = v[0];
          case 'V':
            p.lineTo(cx, v[0]);
            cy = v[0];
          case 'C':
            p.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
            cx = v[4];
            cy = v[5];
          case 'Q':
            p.quadraticBezierTo(v[0], v[1], v[2], v[3]);
            cx = v[2];
            cy = v[3];
          case 'Z':
          case 'z':
            p.close();
            cx = startX;
            cy = startY;
        }
      }
      return p;
    } catch (_) {
      return null;
    }
  }
}

/// Downloads an svg itself (so the http status / content-type / first bytes
/// are printed in debug builds when it does not show) and draws it.
class _RemoteSvg extends StatefulWidget {
  const _RemoteSvg({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final double width;
  final double height;

  @override
  State<_RemoteSvg> createState() => _RemoteSvgState();
}

class _RemoteSvgState extends State<_RemoteSvg> {
  static final Map<String, Uint8List> _cache = {};
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bytes = _cache[widget.url];
    if (_bytes == null) _load();
  }

  /// The frame json points to a temp S3 bucket (403 from the app). Tried in
  /// order: CDN + frame asset prefix, CDN + same path, the original url.
  List<(String, String)> _candidates() {
    final urls = <(String, String)>[];
    try {
      final u = Uri.parse(widget.url);
      final cdn = ApiEndpoints.cdnImageUrl.replaceFirst(RegExp(r'/$'), '');
      final name = u.pathSegments.isEmpty ? '' : u.pathSegments.last;

      var prefix = FrameContent.assetPrefix.trim();
      if (prefix.isNotEmpty && !prefix.endsWith('/')) prefix = '$prefix/';

      if (prefix.isNotEmpty && name.isNotEmpty) {
        urls.add(('cdn+prefix', '$cdn/$prefix$name'));
      }
      final fUid = FrameContent.frameUid.trim();
      if (fUid.isNotEmpty && name.isNotEmpty && !prefix.contains(fUid)) {
        urls.add(('cdn+frame', '$cdn/frames/$fUid/$name'));
      }
      if (u.path.isNotEmpty && !widget.url.startsWith(cdn)) {
        urls.add(('cdn', '$cdn${u.path}'));
      }
    } catch (_) {}
    urls.add(('s3', widget.url));
    return urls;
  }

  Future<void> _load() async {
    final errors = <String>[];

    for (final (label, url) in _candidates()) {
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(url));
        final res = await req.close().timeout(const Duration(seconds: 20));
        final bytes = await consolidateHttpClientResponseBytes(res);
        debugPrint(
          'FRAME SVG status=${res.statusCode} '
          'type=${res.headers.contentType} len=${bytes.length} url=$url',
        );
        if (res.statusCode != 200 || bytes.isEmpty) {
          errors.add('$label ${res.statusCode}');
          continue;
        }
        if (kDebugMode) {
          debugPrint(
            'FRAME SVG head: '
            '${utf8.decode(bytes.take(300).toList(), allowMalformed: true)}',
          );
        }
        _cache[widget.url] = bytes;
        if (mounted) setState(() => _bytes = bytes);
        return;
      } catch (e) {
        errors.add('$label error');
        debugPrint('FRAME SVG load error: $e | url=$url');
      } finally {
        client.close();
      }
    }

    if (mounted) setState(() => _error = errors.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      // debug builds: show WHY the image is missing, right on the frame
      if (kDebugMode && _error != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SVG ERR\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      return SizedBox(width: widget.width, height: widget.height);
    }
    return SvgPicture.memory(
      bytes,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.fill,
    );
  }
}

class _PathPainter extends CustomPainter {
  final Path path;
  final Rect bounds;
  final Color? fill;
  final Color? stroke;
  final double strokeWidth;
  final double sx;
  final double sy;

  _PathPainter({
    required this.path,
    required this.bounds,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.sx,
    required this.sy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(sx, sy);
    canvas.translate(-bounds.left, -bounds.top);

    if (fill != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = fill!
          ..style = PaintingStyle.fill,
      );
    }
    if (stroke != null && strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) =>
      old.path != path ||
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.sx != sx ||
      old.sy != sy;
}
