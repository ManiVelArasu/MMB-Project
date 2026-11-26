import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmb_app/component/custom_widget.dart';

import '../../../utils/theme/app.colors.dart';

/// Result of [CanvaCropScreen]. Geometry is expressed in SOURCE image pixels
/// so the caller can resize / move the canvas item so the picture does not
/// jump or stretch.
class CanvaCropResult {
  const CanvaCropResult({
    required this.png,
    required this.srcWidth,
    required this.srcHeight,
    required this.cropWidth,
    required this.cropHeight,
    required this.centerShift,
  });

  /// Encoded PNG of the cropped / rotated picture (transparent where the
  /// frame was expanded beyond the picture).
  final Uint8List png;

  /// Size of the picture that was opened (source image px).
  final double srcWidth;
  final double srcHeight;

  /// Size of the crop frame in source image px (before any output down-scale).
  final double cropWidth;
  final double cropHeight;

  /// Crop frame centre minus the old picture centre, in source image px.
  final Offset centerShift;
}

enum _CropTab { auto, ratio, rotate, expand }

enum _Drag { none, pan, corner, edge }

class _RatioOption {
  const _RatioOption(this.key, this.label, [this.ratio]);
  final String key;
  final String label;
  final double? ratio; // w / h
}

/// Canva-style crop screen: Cancel | Crop | tick, and the tabs
/// Auto (Smart Crop) / Aspect ratio / Rotate / Expand.
class CanvaCropScreen extends StatefulWidget {
  const CanvaCropScreen({super.key, required this.source});

  /// http(s) URL, file:// URL or a local path.
  final String source;

  @override
  State<CanvaCropScreen> createState() => _CanvaCropScreenState();
}

class _CanvaCropScreenState extends State<CanvaCropScreen> {
  static const Color _purple = Color(0xFF7D2AE8);
  static const Color _purpleSoft = Color(0xFFE9DDFB);
  static const Color _stageBg = Color(0xFFDDE2EA);
  static const double _pad = 28;
  static const double _minFrame = 48;
  static const double _handleHit = 30;
  static const double _maxRotate = 45;

  static const double _headerH = 52;
  static const double _contentH = 118;
  static const double _tabsH = 56;
  static const double _grabH = 18;
  static const double _panelH = _grabH + _headerH + _contentH + _tabsH;

  static const List<_RatioOption> _ratios = [
    _RatioOption('free', 'Freeform'),
    _RatioOption('original', 'Original'),
    _RatioOption('1:1', '1:1', 1),
    _RatioOption('16:9', '16:9', 16 / 9),
    _RatioOption('9:16', '9:16', 9 / 16),
    _RatioOption('4:5', '4:5', 4 / 5),
    _RatioOption('5:4', '5:4', 5 / 4),
    _RatioOption('3:2', '3:2', 3 / 2),
    _RatioOption('2:3', '2:3', 2 / 3),
    _RatioOption('4:3', '4:3', 4 / 3),
    _RatioOption('3:4', '3:4', 3 / 4),
  ];

  // ---- source picture ----
  ui.Image? _img;
  bool _failed = false;
  bool _busy = false;
  double get _iw => _img!.width.toDouble();
  double get _ih => _img!.height.toDouble();

  // ---- view state (stage coordinates) ----
  Size _stage = Size.zero;
  bool _inited = false;
  double _sUser = 1; // wanted scale (screen px per image px)
  Offset _c = Offset.zero; // picture centre
  double _theta = 0; // radians
  Rect _f = Rect.zero; // crop frame
  String _ratioKey = 'original';
  double? _ratio; // null = freeform

  _CropTab _tab = _CropTab.ratio;
  bool _interacting = false;

  // ---- gesture state ----
  _Drag _drag = _Drag.none;
  int _handleIndex = 0; // corner 0..3 (tl,tr,br,bl) / edge 0..3 (l,t,r,b)
  Offset _anchor = Offset.zero;
  double _gBaseS = 1;
  Offset _gBaseC = Offset.zero;
  Offset _gStartFocal = Offset.zero;

  final TextEditingController _degCtl = TextEditingController(text: '0.0');
  final FocusNode _degFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _degCtl.dispose();
    _degFocus.dispose();
    _img?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ load
  Future<void> _load() async {
    try {
      final src = widget.source.trim();
      Uint8List bytes;
      if (src.startsWith('http://') || src.startsWith('https://')) {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 20);
        try {
          final req = await client.getUrl(Uri.parse(src));
          final res = await req.close().timeout(const Duration(seconds: 40));
          if (res.statusCode < 200 || res.statusCode >= 300) {
            throw HttpException('HTTP ${res.statusCode}');
          }
          bytes = await consolidateHttpClientResponseBytes(res);
        } finally {
          client.close(force: true);
        }
      } else {
        final path = src.startsWith('file://')
            ? src.replaceFirst('file://', '')
            : src;
        bytes = await File(path).readAsBytes();
      }
      // Huge photos are decoded at a sane size (still > any canvas need).
      final probe = await ui.instantiateImageCodec(bytes);
      final first = await probe.getNextFrame();
      final w = first.image.width, h = first.image.height;
      ui.Image decoded = first.image;
      probe.dispose();
      const maxSide = 4096;
      if (w > maxSide || h > maxSide) {
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: w >= h ? maxSide : null,
          targetHeight: h > w ? maxSide : null,
        );
        decoded.dispose();
        decoded = (await codec.getNextFrame()).image;
        codec.dispose();
      }
      if (!mounted) {
        decoded.dispose();
        return;
      }
      setState(() => _img = decoded);
    } catch (e) {
      debugPrint('Crop load failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  // ------------------------------------------------------------ geometry
  bool get _allowOutside => _tab == _CropTab.expand;

  /// Smallest scale at which the picture still covers [f] at angle [th].
  double _coverMin(Rect f, double th) {
    final c = math.cos(th).abs(), s = math.sin(th).abs();
    final ex = f.width / 2 * c + f.height / 2 * s;
    final ey = f.width / 2 * s + f.height / 2 * c;
    return math.max(2 * ex / _iw, 2 * ey / _ih);
  }

  /// Effective scale on screen.
  double get _s =>
      _allowOutside ? _sUser : math.max(_sUser, _coverMin(_f, _theta));

  Offset _clampCenter(Offset c, double s, double th, Rect f) {
    if (_allowOutside) return c;
    final cs = math.cos(th), sn = math.sin(th);
    final ex = f.width / 2 * cs.abs() + f.height / 2 * sn.abs();
    final ey = f.width / 2 * sn.abs() + f.height / 2 * cs.abs();
    final d = f.center - c;
    var lx = d.dx * cs + d.dy * sn;
    var ly = -d.dx * sn + d.dy * cs;
    final mx = math.max(0.0, s * _iw / 2 - ex);
    final my = math.max(0.0, s * _ih / 2 - ey);
    lx = lx.clamp(-mx, mx).toDouble();
    ly = ly.clamp(-my, my).toDouble();
    final dx = lx * cs - ly * sn;
    final dy = lx * sn + ly * cs;
    return f.center - Offset(dx, dy);
  }

  void _normalise() {
    _c = _clampCenter(_c, _s, _theta, _f);
  }

  void _initLayout(Size stage) {
    _stage = stage;
    final s0 = math.min(
      (stage.width - 2 * _pad) / _iw,
      (stage.height - 2 * _pad) / _ih,
    );
    _sUser = s0 > 0 ? s0 : 1;
    _c = Offset(stage.width / 2, stage.height / 2);
    _theta = 0;
    _f = Rect.fromCenter(center: _c, width: _iw * _sUser, height: _ih * _sUser);
    _ratioKey = 'original';
    _ratio = _iw / _ih;
    _inited = true;
  }

  Rect _frameForRatio(double r) {
    final maxW = _stage.width - 2 * _pad;
    final maxH = _stage.height - 2 * _pad;
    var w = maxW;
    var h = w / r;
    if (h > maxH) {
      h = maxH;
      w = h * r;
    }
    return Rect.fromCenter(
      center: Offset(_stage.width / 2, _stage.height / 2),
      width: w,
      height: h,
    );
  }

  void _selectRatio(_RatioOption o) {
    setState(() {
      _ratioKey = o.key;
      if (o.key == 'free') {
        _ratio = null;
      } else {
        final r = o.key == 'original' ? _iw / _ih : o.ratio!;
        _ratio = r;
        // Re-centre picture + frame; the picture keeps the user's zoom.
        final f = _frameForRatio(r);
        _f = f;
        _c = Offset(_stage.width / 2, _stage.height / 2);
        _normalise();
      }
    });
  }

  void _setRotation(double degrees, {bool fromField = false}) {
    final d = degrees.clamp(-_maxRotate, _maxRotate).toDouble();
    setState(() {
      _theta = d * math.pi / 180;
      _normalise();
      if (!fromField) _degCtl.text = d.toStringAsFixed(1);
    });
  }

  double get _deg => _theta * 180 / math.pi;

  void _selectTab(_CropTab t) {
    if (t == _tab) return;
    setState(() {
      final leavingExpand = _tab == _CropTab.expand;
      _tab = t;
      if (leavingExpand) {
        // Back to "must cover": zoom the picture so the frame is filled.
        _sUser = math.max(_sUser, _coverMin(_f, _theta));
        _normalise();
      }
    });
  }

  // ------------------------------------------------------------- gestures
  List<Offset> get _corners => [
    _f.topLeft,
    _f.topRight,
    _f.bottomRight,
    _f.bottomLeft,
  ];

  List<Offset> get _edges => [
    _f.centerLeft,
    _f.topCenter,
    _f.centerRight,
    _f.bottomCenter,
  ];

  void _onScaleStart(ScaleStartDetails d) {
    if (!_inited || _busy) return;
    final p = d.localFocalPoint;
    _drag = _Drag.pan;
    if (d.pointerCount == 1) {
      final cs = _corners;
      for (var i = 0; i < 4; i++) {
        if ((cs[i] - p).distance <= _handleHit) {
          _drag = _Drag.corner;
          _handleIndex = i;
          _anchor = cs[(i + 2) % 4];
          break;
        }
      }
      if (_drag == _Drag.pan && _ratio == null) {
        final es = _edges;
        for (var i = 0; i < 4; i++) {
          if ((es[i] - p).distance <= _handleHit * 0.8) {
            _drag = _Drag.edge;
            _handleIndex = i;
            break;
          }
        }
      }
    }
    _gBaseS = _s;
    _gBaseC = _c;
    _gStartFocal = p;
    setState(() => _interacting = true);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (!_inited || _busy) return;
    switch (_drag) {
      case _Drag.corner:
        _dragCorner(d.localFocalPoint);
        break;
      case _Drag.edge:
        _dragEdge(d.localFocalPoint);
        break;
      case _Drag.pan:
        final minS = _allowOutside ? 0.02 : _coverMin(_f, _theta);
        final newS = (_gBaseS * d.scale).clamp(minS, minS * 12 + 0.0001);
        final k = newS / _gBaseS;
        setState(() {
          _sUser = newS.toDouble();
          _c = d.localFocalPoint + (_gBaseC - _gStartFocal) * k;
          _normalise();
        });
        break;
      case _Drag.none:
        break;
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    setState(() {
      _interacting = false;
      _drag = _Drag.none;
    });
  }

  Offset _clampToStage(Offset p) => Offset(
    p.dx.clamp(8.0, _stage.width - 8).toDouble(),
    p.dy.clamp(8.0, _stage.height - 8).toDouble(),
  );

  bool _frameOk(Rect f) {
    if (f.width < _minFrame || f.height < _minFrame) return false;
    if (_allowOutside) return true;
    return _coverMin(f, _theta) <= _s + 1e-6;
  }

  void _dragCorner(Offset pointer) {
    final p = _clampToStage(pointer);
    final dx = p.dx - _anchor.dx;
    final dy = p.dy - _anchor.dy;
    final sx = dx >= 0 ? 1.0 : -1.0;
    final sy = dy >= 0 ? 1.0 : -1.0;
    var w = dx.abs();
    var h = dy.abs();
    final r = _ratio;
    if (r != null) {
      if (w / math.max(h, 0.001) > r) {
        w = h * r;
      } else {
        h = w / r;
      }
      if (w < _minFrame) {
        w = _minFrame;
        h = w / r;
      }
      if (h < _minFrame) {
        h = _minFrame;
        w = h * r;
      }
    } else {
      w = math.max(w, _minFrame);
      h = math.max(h, _minFrame);
    }
    final next = Rect.fromPoints(_anchor, _anchor + Offset(sx * w, sy * h));
    if (!_stageRect.contains(next.topLeft) ||
        !_stageRect.contains(next.bottomRight)) {
      return;
    }
    if (!_frameOk(next)) return;
    setState(() {
      _f = next;
      _ratioKey = r == null ? 'free' : _ratioKey;
      _normalise();
    });
  }

  Rect get _stageRect => Offset.zero & _stage;

  void _dragEdge(Offset pointer) {
    final p = _clampToStage(pointer);
    var l = _f.left, t = _f.top, r = _f.right, b = _f.bottom;
    switch (_handleIndex) {
      case 0:
        l = math.min(p.dx, r - _minFrame);
        break;
      case 1:
        t = math.min(p.dy, b - _minFrame);
        break;
      case 2:
        r = math.max(p.dx, l + _minFrame);
        break;
      default:
        b = math.max(p.dy, t + _minFrame);
    }
    final next = Rect.fromLTRB(l, t, r, b);
    if (!_frameOk(next)) return;
    setState(() {
      _f = next;
      _normalise();
    });
  }

  // ------------------------------------------------------------ smart crop
  /// Trims transparent / flat-colour borders (local "smart" crop).
  Future<void> _smartCrop() async {
    final img = _img;
    if (img == null || !_inited) return;
    setState(() => _busy = true);
    try {
      const probe = 256;
      final k = probe / math.max(img.width, img.height);
      final pw = math.max(1, (img.width * k).round());
      final ph = math.max(1, (img.height * k).round());
      final rec = ui.PictureRecorder();
      final cv = Canvas(rec);
      cv.scale(pw / img.width, ph / img.height);
      cv.drawImage(
        img,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.low,
      );
      final small = await rec.endRecording().toImage(pw, ph);
      final data = await small.toByteData(format: ui.ImageByteFormat.rawRgba);
      small.dispose();
      if (data == null) return;
      final px = data.buffer.asUint8List();

      int idx(int x, int y) => (y * pw + x) * 4;
      // Reference colour = top-left pixel (used when nothing is transparent).
      final rr = px[0], rg = px[1], rb = px[2];
      bool isContent(int x, int y) {
        final i = idx(x, y);
        final a = px[i + 3];
        if (a < 12) return false;
        final dr = (px[i] - rr).abs(),
            dg = (px[i + 1] - rg).abs(),
            db = (px[i + 2] - rb).abs();
        final transparentRef = px[3] < 12;
        if (transparentRef) return true;
        return dr + dg + db > 36;
      }

      var minX = pw, minY = ph, maxX = -1, maxY = -1;
      for (var y = 0; y < ph; y++) {
        for (var x = 0; x < pw; x++) {
          if (isContent(x, y)) {
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
        }
      }
      if (maxX < 0) return;
      final fx0 = minX / pw, fy0 = minY / ph;
      final fx1 = (maxX + 1) / pw, fy1 = (maxY + 1) / ph;
      if (fx1 - fx0 > 0.985 && fy1 - fy0 > 0.985) {
        _toast('Nothing to trim');
        return;
      }
      // Box in image px, then show it fitted in the stage with rotation 0.
      final bw = (fx1 - fx0) * _iw, bh = (fy1 - fy0) * _ih;
      final s = math.min(
        (_stage.width - 2 * _pad) / bw,
        (_stage.height - 2 * _pad) / bh,
      );
      setState(() {
        _theta = 0;
        _degCtl.text = '0.0';
        _sUser = s;
        _f = Rect.fromCenter(
          center: Offset(_stage.width / 2, _stage.height / 2),
          width: bw * s,
          height: bh * s,
        );
        _ratio = null;
        _ratioKey = 'free';
        // Picture centre so the trimmed box sits in the frame centre.
        final boxCentre = Offset(
          ((fx0 + fx1) / 2 - 0.5) * _iw,
          ((fy0 + fy1) / 2 - 0.5) * _ih,
        );
        _c = _f.center - boxCentre * s;
        _normalise();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 1)),
      );
  }

  // ----------------------------------------------------------------- apply
  Future<void> _apply() async {
    final img = _img;
    if (img == null || !_inited || _busy) return;
    final s = _s;

    // Nothing changed -> no need to re-encode.
    final original = Rect.fromCenter(
      center: _c,
      width: _iw * s,
      height: _ih * s,
    );
    final untouched =
        _theta.abs() < 1e-6 &&
        (_f.left - original.left).abs() < 0.5 &&
        (_f.top - original.top).abs() < 0.5 &&
        (_f.right - original.right).abs() < 0.5 &&
        (_f.bottom - original.bottom).abs() < 0.5;
    if (untouched) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    try {
      final outW = _f.width / s;
      final outH = _f.height / s;
      var k = 1.0;
      final longest = math.max(outW, outH);
      if (longest > 4096) k = 4096 / longest;
      final w = math.max(1, (outW * k).round());
      final h = math.max(1, (outH * k).round());

      final rec = ui.PictureRecorder();
      final cv = Canvas(rec, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
      cv.scale(w / outW, h / outH);
      cv.translate((_c.dx - _f.left) / s, (_c.dy - _f.top) / s);
      cv.rotate(_theta);
      cv.drawImage(
        img,
        Offset(-_iw / 2, -_ih / 2),
        Paint()..filterQuality = FilterQuality.high,
      );
      final out = await rec.endRecording().toImage(w, h);
      final bd = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      if (bd == null) throw StateError('encode failed');
      if (!mounted) return;
      Navigator.of(context).pop(
        CanvaCropResult(
          png: bd.buffer.asUint8List(),
          srcWidth: _iw,
          srcHeight: _ih,
          cropWidth: outW,
          cropHeight: outH,
          centerShift: (_f.center - _c) / s,
        ),
      );
    } catch (e) {
      debugPrint('Crop apply failed: $e');
      _toast('Could not crop this image');
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomSafe = mq.padding.bottom;
    final panelTotal = _panelH + bottomSafe;

    return Scaffold(
      backgroundColor: _stageBg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ---------------- stage ----------------
          Positioned(
            left: 0,
            right: 0,
            top: mq.padding.top,
            bottom: panelTotal,
            child: LayoutBuilder(
              builder: (context, box) {
                if (_failed) {
                  return const Center(
                    child: Text(
                      'Unable to open this image',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }
                if (_img == null) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.appRed),
                  );
                }
                final size = Size(box.maxWidth, box.maxHeight);
                if (!_inited) _initLayout(size);
                _stage = size;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  child: CustomPaint(
                    size: size,
                    painter: _CropPainter(
                      image: _img!,
                      scale: _s,
                      centre: _c,
                      theta: _theta,
                      frame: _f,
                      showGrid: _interacting,
                      freeform: _ratio == null,
                    ),
                  ),
                );
              },
            ),
          ),
          // ---------------- panel ----------------
          Positioned(
            left: 0,
            right: 0,
            bottom: mq.viewInsets.bottom,
            child: _buildPanel(bottomSafe),
          ),
          if (_busy)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator(color:AppColors.appRed)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPanel(double bottomSafe) {
    return Container(
      height: _panelH + bottomSafe,
      padding: EdgeInsets.only(bottom: bottomSafe),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
      ),
      child: Column(
        children: [
          SizedBox(
            height: _grabH,
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D3D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(
            height: _headerH,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: AppText(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.appRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: AppText(
                        'Crop',
                        style: TextStyle(
                          color: Color(0xFF0E1116),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : _apply,
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF0E1116),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: _contentH, child: _buildTabContent()),
          SizedBox(height: _tabsH, child: _buildTabs()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    Widget tab(String label, _CropTab t) {
      final sel = _tab == t;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _selectTab(t),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppColors.appRed : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: AppText(
              label,
              style: TextStyle(
                color: sel ? AppColors.appWhite :  AppColors.appRed,
                fontSize: 15,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            tab('Auto', _CropTab.auto),
            tab('Aspect ratio', _CropTab.ratio),
            tab('Rotate', _CropTab.rotate),
            tab('Expand', _CropTab.expand),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case _CropTab.auto:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Center(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _smartCrop,
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const AppText(
                  'Smart Crop',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        );
      case _CropTab.ratio:
        return _buildRatioRow();
      case _CropTab.rotate:
        return _buildRotate();
      case _CropTab.expand:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: AppText(
              'Drag the corners or edges outside the picture to add empty '
              'space around it. Tap the tick to apply.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4B5160), fontSize: 14),
            ),
          ),
        );
    }
  }

  Widget _buildRatioRow() {
    Widget icon(_RatioOption o, bool sel) {
      final color = sel ? _purple : const Color(0xFF1F2430);
      if (o.key == 'free') {
        return Icon(Icons.crop_free_rounded, color: color, size: 28);
      }
      if (o.key == 'original') {
        return Icon(Icons.image_outlined, color: color, size: 28);
      }
      final r = o.ratio!;
      const m = 24.0;
      final w = r >= 1 ? m : m * r;
      final h = r >= 1 ? m / r : m;
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _ratios.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final o = _ratios[i];
        final sel = _ratioKey == o.key;
        return GestureDetector(
          onTap: () => _selectRatio(o),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? AppColors.appRed : const Color(0xFFD7DAE0),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: icon(o, sel),
              ),
              const SizedBox(height: 4),
              AppText(
                o.label,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF1F2430),
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRotate() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Rotate',
            style: TextStyle(
              color: Color(0xFF1F2430),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _purple,
                    inactiveTrackColor: const Color(0xFFD7DAE0),
                    thumbColor: _purple,
                    overlayColor: _purple.withValues(alpha: 0.12),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    min: -_maxRotate,
                    max: _maxRotate,
                    value: _deg.clamp(-_maxRotate, _maxRotate).toDouble(),
                    onChangeStart: (_) => setState(() => _interacting = true),
                    onChanged: (v) =>
                        _setRotation(double.parse(v.toStringAsFixed(1))),
                    onChangeEnd: (_) => setState(() => _interacting = false),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  _degFocus.unfocus();
                  _setRotation(0);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F2430),
                  side: const BorderSide(color: Color(0xFFC9CDD5)),
                  minimumSize: const Size(60, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const AppText('Auto'),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 62,
                height: 38,
                child: TextField(
                  controller: _degCtl,
                  focusNode: _degFocus,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                  ],
                  onChanged: (t) {
                    final v = double.tryParse(t);
                    if (v != null) _setRotation(v, fromField: true);
                  },
                  onSubmitted: (_) {
                    _degCtl.text = _deg.toStringAsFixed(1);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFC9CDD5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.appRed,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.image,
    required this.scale,
    required this.centre,
    required this.theta,
    required this.frame,
    required this.showGrid,
    required this.freeform,
  });

  final ui.Image image;
  final double scale;
  final Offset centre;
  final double theta;
  final Rect frame;
  final bool showGrid;
  final bool freeform;

  void _drawPicture(Canvas canvas, Paint paint) {
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(theta);
    canvas.scale(scale);
    canvas.drawImage(image, Offset(-image.width / 2, -image.height / 2), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Whole picture, faded: shows what lies outside the crop frame.
    canvas.save();
    _drawPicture(
      canvas,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = const Color(0x59FFFFFF),
    );
    canvas.restore();

    // Part inside the frame, at full strength.
    canvas.save();
    canvas.clipRect(frame);
    _drawPicture(canvas, Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();

    // Border.
    canvas.drawRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.appRed,
    );

    // Rule-of-thirds grid while moving.
    if (showGrid) {
      final g = Paint()
        ..strokeWidth = 1
        ..color = const Color(0xCCFFFFFF);
      for (var i = 1; i < 3; i++) {
        final x = frame.left + frame.width * i / 3;
        final y = frame.top + frame.height * i / 3;
        canvas.drawLine(Offset(x, frame.top), Offset(x, frame.bottom), g);
        canvas.drawLine(Offset(frame.left, y), Offset(frame.right, y), g);
      }
    }

    // Edge handles (freeform only).
    if (freeform) {
      final bar = Paint()..color = Colors.white;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.appRed;
      void edge(Offset c, bool horizontal) {
        final r = Rect.fromCenter(
          center: c,
          width: horizontal ? 22 : 6,
          height: horizontal ? 6 : 22,
        );
        final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
        canvas.drawRRect(rr, bar);
        canvas.drawRRect(rr, ring);
      }

      edge(frame.centerLeft, false);
      edge(frame.centerRight, false);
      edge(frame.topCenter, true);
      edge(frame.bottomCenter, true);
    }

    // Corner handles.
    final fill = Paint()..color = Colors.white;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.appRed;
    for (final p in [
      frame.topLeft,
      frame.topRight,
      frame.bottomRight,
      frame.bottomLeft,
    ]) {
      canvas.drawCircle(p, 8, fill);
      canvas.drawCircle(p, 8, ring);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropPainter o) =>
      o.image != image ||
      o.scale != scale ||
      o.centre != centre ||
      o.theta != theta ||
      o.frame != frame ||
      o.showGrid != showGrid ||
      o.freeform != freeform;
}
