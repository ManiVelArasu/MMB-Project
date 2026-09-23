import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../Api Model/editor_model.dart';
import '../../../network/provider/editor_provider.dart';
import 'package:image/image.dart' as img;

import '../../screens/video_widget/editor_video.dart';
import '../../screens/video_widget/video_widget.dart';


class EditableItemWidget extends StatelessWidget {
  final EditorItem item;
  final Function(String type, String id) onItemSelected;

  const EditableItemWidget({
    super.key,
    required this.item,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    final currentItem = provider.items.firstWhere(
          (e) => e.id == item.id,
      orElse: () => item,
    );
    bool isSelected = provider.selectedItemId == currentItem.id;

    final isBackground = _isCanvasBackground(currentItem);
    final isTextItem = currentItem.type == 'text' || currentItem.type == 'textbox';

    // Text must occupy only its real painted size. Do not reuse the API's
    // large width/height rectangle for selection/hit testing.
    Size? naturalTextSize;
    if (isTextItem) {
      final id = currentItem.id ?? '';
      final painter = TextPainter(
        text: TextSpan(
          text: currentItem.text ?? '',
          style: _buildGoogleFontTextStyle(
            fontFamily: currentItem.fontFamily,
            fontSize: currentItem.fontSize,
            color: currentItem.color ?? Colors.black,
            fontWeight: provider.textWeight(id),
            fontStyle: provider.textStyle(id),
            decoration: provider.textUnderline(id)
                ? TextDecoration.underline
                : TextDecoration.none,
            letterSpacing: provider.textLetterSpacing(id),
            height: provider.textLineSpacing(id),
          ),
        ),
        maxLines: null,
        textDirection: TextDirection.ltr,
      )..layout();
      naturalTextSize = Size(
        math.max(1.0, painter.width),
        math.max(1.0, painter.height),
      );
    }
    final textValueForBounds = currentItem.text ?? '';
    final isMultilineForBounds = textValueForBounds.contains('\n') || textValueForBounds.contains('\r');
    final bodyWidth = isMultilineForBounds
        ? (currentItem.width ?? naturalTextSize?.width ?? 220)
        : (naturalTextSize?.width ?? (currentItem.width ?? 220));
    final bodyHeight = isMultilineForBounds
        ? (currentItem.height ?? naturalTextSize?.height ?? 220)
        : (naturalTextSize?.height ?? (currentItem.height ?? 220));

    // One finger = move, two fingers = pinch zoom + pan. Keep the starting
    // scale outside the GestureDetector callbacks so a rebuild during the
    // gesture does not reset the pinch baseline.
    double gestureStartScale = currentItem.scale.isFinite
        ? currentItem.scale
        : 1.0;

    return KeyedSubtree(
      // Keep the element stable while position/scale changes. Re-keying on
      // every drag/resize recreates the GestureDetector and makes editing
      // feel sticky or causes the wrong item to receive the gesture.
        key: ValueKey(currentItem.id),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Tapping an unselected item selects it instantly without moving it.
          // Dragging/moving is only active when the item is already selected.
          onTap: () {
            if (!isSelected) {
              onItemSelected(currentItem.type ?? '', currentItem.id!);
            }
          },
          onScaleStart: isSelected ? (details) {
            final latest = provider.items.where((e) => e.id == currentItem.id);
            gestureStartScale = latest.isNotEmpty && latest.first.scale.isFinite
                ? latest.first.scale
                : 1.0;
          } : null,
          onScaleUpdate: isSelected ? (details) {
            final latest = provider.items.where((e) => e.id == currentItem.id);
            if (latest.isEmpty) return;

            final latestItem = latest.first;
            final nextScale = (gestureStartScale * details.scale)
                .clamp(0.05, 10.0)
                .toDouble();

            // focalPointDelta works for both one-finger dragging and two-finger
            // panning. Applying it to the latest provider position keeps the
            // gesture smooth even while the provider is rebuilding.
            final nextPosition =
                latestItem.position + details.focalPointDelta;

            provider.updateItemTransform(
              latestItem.id!,
              scale: nextScale,
              position: nextPosition,
              clampToFrame: false,
            );
          } : null,
          onDoubleTap: () {
            if (isTextItem && !isBackground) {
              _showTextEditorDialog(
                context,
                provider,
                currentItem.id!,
                currentItem.text ?? '',
              );
            }
          },
          child: Transform.rotate(
            angle: currentItem.rotation,
            child: Transform.scale(
              // Keep the object's real scale anchored to its top-left origin.
              // Flip is intentionally handled by a SECOND transform below.
              // Combining a negative scale with top-left alignment moves the
              // visual image to the opposite side of its box. The reference
              // editor flips the pixels in-place, so the image must stay at the
              // exact same x/y, width and height.
              scale: currentItem.scale.clamp(0.01, 10.0),
              alignment: Alignment.topLeft,
              child: Transform.scale(
                scaleX: provider.templateFlipX(currentItem.id ?? '') ? -1 : 1,
                scaleY: provider.templateFlipY(currentItem.id ?? '') ? -1 : 1,
                // Flip around the CENTER of the object's own box. This keeps
                // the same image bounds and therefore the same position.
                alignment: Alignment.center,
                child: SizedBox(
                  // Extra hit area on the right is intentional: the 3-dot
                  // control is visually outside the image. A RenderBox cannot
                  // hit-test a child that is outside its own size, so the
                  // selection layer gets a small right-side hit area.
                  width: bodyWidth,
                  height: bodyHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: bodyWidth,
                        height: bodyHeight,
                        // Selection visuals are rendered by the single
                        // _TransformSelectionOverlay in template_edit.dart.
                        // Do not draw another border here; that creates a second
                        // selection rectangle offset from the real touch target.
                        decoration: const BoxDecoration(),
                        child: Opacity(
                          opacity: currentItem.opacity.clamp(0.0, 1.0),
                          child: _buildItemContent(currentItem, context, isBackground: isBackground),
                        ),
                      ),

                      // Selection visuals are rendered at canvas level by
                      // _TransformSelectionOverlay in template_edit.dart so
                      // selection handles and borders maintain a fixed, clear
                      // screen size regardless of item scale or zoom.
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildResizeHandle(
      BuildContext context,
      EditorProvider provider,
      EditorItem item,
      Alignment alignment, {
        required bool isHorizontal,
        required bool isVertical,
      }) {
    final w = item.width ?? 220;
    final h = item.height ?? 220;

    double left = 0;
    double top = 0;

    if (alignment.x == -1) {
      left = -16;
    } else if (alignment.x == 0) {
      left = w / 2 - 16;
    } else {
      left = w - 16;
    }

    if (alignment.y == -1) {
      top = -16;
    } else if (alignment.y == 0) {
      top = h / 2 - 16;
    } else {
      top = h - 16;
    }

    return Positioned(
      left: left,
      top: top,
      width: 32,
      height: 32,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          provider.setSelectedItem(item.type, item.id);
        },
        onPanUpdate: (details) {
          final oldScale = item.scale.isFinite ? item.scale : 1.0;

          // Use the handle's outward movement. This keeps resizing stable
          // even when the visible dot is tiny and prevents a handle drag from
          // becoming a move gesture.
          double delta = 0;

          if (isHorizontal) {
            delta += alignment.x == 1
                ? details.delta.dx
                : alignment.x == -1
                ? -details.delta.dx
                : 0;
          }

          if (isVertical) {
            delta += alignment.y == 1
                ? details.delta.dy
                : alignment.y == -1
                ? -details.delta.dy
                : 0;
          }

          if (isHorizontal && isVertical) {
            delta /= 2;
          }

          // Scale is intentionally incremental, so the image does not jump
          // when the first touch lands on a small handle.
          final base = math.max(40.0, math.min(w, h));
          final nextScale = (oldScale + delta / base).clamp(0.05, 10.0);

          provider.updateScale(item.id!, nextScale);
        },
        child: Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isCanvasBackground(EditorItem item) {
    return item.position.dx == 0 &&
        item.position.dy == 0 &&
        (item.width ?? 0) >= 1000 &&
        (item.height ?? 0) >= 1000 &&
        (item.type == 'image' || item.type == 'video' || item.type == 'shape');
  }

  // ---------------------------------------------------------------------------
  // PUBLIC ENTRY POINT FOR PAGE/BACKGROUND CLICK
  // ---------------------------------------------------------------------------
  //
  // Use this from the page/background GestureDetector instead of opening
  // another background-specific bottom sheet.
  static void showUnifiedImageActions(
      BuildContext context,
      EditorProvider provider,
      EditorItem backgroundItem,
      ) {
    final widget = EditableItemWidget(
      item: backgroundItem,
      onItemSelected: (_, __) {},
    );

    widget._showProActionSheet(
      context,
      provider,
      backgroundItem,
      isBackground: true,
    );
  }

  // Reusable media renderer for canvas backgrounds. It applies the same
  // filters, color adjustments and mask shape used by normal image items.
  static Widget buildStandaloneMediaContent(
      BuildContext context,
      EditorItem item,
      ) {
    final widget = EditableItemWidget(item: item, onItemSelected: (_, __) {});
    return widget._buildItemContent(item, context, isBackground: true);
  }

  Widget _buildFilteredImage(
      EditorItem item,
      Widget imageWidget,
      BuildContext context,
      ) {
    final filter = _baseFilter(item.filterType);
    final adjusted = _adjustmentFilter(
      brightness: item.brightness,
      contrast: item.contrast,
      saturation: item.saturation,
    );

    final editorProvider = context.read<EditorProvider>();
    final id = item.id ?? '';
    final tint = editorProvider.imageTint(id);
    final blur = editorProvider.imageBlur(id);

    Widget filtered = imageWidget;

    if (filter != null) {
      filtered = ColorFiltered(colorFilter: filter, child: filtered);
    }

    if (adjusted != null) {
      filtered = ColorFiltered(colorFilter: adjusted, child: filtered);
    }

    if (tint.abs() > 0.001) {
      filtered = ColorFiltered(
        colorFilter: _tintFilter(tint),
        child: filtered,
      );
    }

    if (blur > 0.001) {
      filtered = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: filtered,
      );
    }

    final intensity = _readFilterIntensity(item, context);

    if (intensity < 0.999 && filter != null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          imageWidget,
          Opacity(opacity: intensity, child: filtered),
        ],
      );
    }

    return filtered;
  }

  ColorFilter _tintFilter(double value) {
    // Tint is implemented as a hue rotation so the full -100..100 range
    // remains visible while preserving image luminance.
    final angle = value.clamp(-100.0, 100.0) * math.pi / 100.0;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    const lumR = 0.213;
    const lumG = 0.715;
    const lumB = 0.072;

    return ColorFilter.matrix([
      lumR + cosA * (1 - lumR) + sinA * (-lumR),
      lumG + cosA * (-lumG) + sinA * (-lumG),
      lumB + cosA * (-lumB) + sinA * (1 - lumB),
      0,
      0,
      lumR + cosA * (-lumR) + sinA * 0.143,
      lumG + cosA * (1 - lumG) + sinA * 0.140,
      lumB + cosA * (-lumB) + sinA * (-0.283),
      0,
      0,
      lumR + cosA * (-lumR) + sinA * (-(1 - lumR)),
      lumG + cosA * (-lumG) + sinA * lumG,
      lumB + cosA * (1 - lumB) + sinA * lumB,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  double _readFilterIntensity(EditorItem item, BuildContext context) {
    try {
      final provider = context.read<EditorProvider>();
      return provider.imageFilterIntensity(item.id ?? '').clamp(0.0, 1.0);
    } catch (_) {
      return 1.0;
    }
  }

  ColorFilter? _baseFilter(String type) {
    switch (type) {
      case 'grayscale':
        return const ColorFilter.matrix([
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'sepia':
        return const ColorFilter.matrix([
          .393,
          .769,
          .189,
          0,
          0,
          .349,
          .686,
          .168,
          0,
          0,
          .272,
          .534,
          .131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'vintage':
        return const ColorFilter.matrix([
          .9,
          .5,
          .1,
          0,
          0,
          .3,
          .8,
          .2,
          0,
          0,
          .2,
          .3,
          .6,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'festive':
        return const ColorFilter.matrix([
          1.12,
          .05,
          0,
          0,
          4,
          .05,
          1.05,
          .02,
          0,
          2,
          .02,
          .04,
          1.12,
          0,
          4,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'drama':
        return const ColorFilter.matrix([
          1.25,
          -.08,
          -.08,
          0,
          -10,
          -.08,
          1.18,
          -.08,
          0,
          -8,
          -.08,
          -.08,
          1.25,
          0,
          -6,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'cali':
        return const ColorFilter.matrix([
          1.08,
          .02,
          -.03,
          0,
          5,
          .02,
          1.02,
          .02,
          0,
          2,
          -.03,
          .02,
          1.08,
          0,
          5,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'epic':
        return const ColorFilter.matrix([
          1.18,
          -.05,
          -.05,
          0,
          0,
          -.03,
          1.12,
          -.03,
          0,
          0,
          -.05,
          -.02,
          1.18,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'street':
        return const ColorFilter.matrix([
          .95,
          .05,
          0,
          0,
          0,
          .05,
          .95,
          0,
          0,
          0,
          0,
          .05,
          .95,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'rosie':
        return const ColorFilter.matrix([
          1.05,
          0,
          .05,
          0,
          4,
          0,
          .92,
          .05,
          0,
          0,
          .02,
          0,
          1.08,
          0,
          5,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'edge':
        return const ColorFilter.matrix([
          1.35,
          -.17,
          -.17,
          0,
          0,
          -.17,
          1.35,
          -.17,
          0,
          0,
          -.17,
          -.17,
          1.35,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'nordic':
        return const ColorFilter.matrix([
          .92,
          .02,
          .02,
          0,
          5,
          .02,
          1.02,
          .04,
          0,
          8,
          .02,
          .06,
          1.12,
          0,
          12,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'selfie':
        return const ColorFilter.matrix([
          1.05,
          .04,
          .02,
          0,
          4,
          .04,
          1.02,
          .02,
          0,
          3,
          .02,
          .02,
          .98,
          0,
          2,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'blues':
        return const ColorFilter.matrix([
          .85,
          .02,
          .04,
          0,
          0,
          .02,
          .95,
          .06,
          0,
          0,
          .02,
          .08,
          1.22,
          0,
          4,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'whimsical':
        return const ColorFilter.matrix([
          1.08,
          .02,
          .02,
          0,
          6,
          .02,
          1.04,
          .03,
          0,
          4,
          .03,
          .02,
          1.08,
          0,
          8,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'summer':
        return const ColorFilter.matrix([
          1.12,
          .04,
          -.02,
          0,
          8,
          .04,
          1.02,
          0,
          0,
          4,
          -.02,
          .02,
          .9,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      case 'retro':
        return const ColorFilter.matrix([
          1.05,
          .08,
          -.02,
          0,
          0,
          .02,
          .92,
          .04,
          0,
          0,
          -.02,
          .04,
          .75,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);

      default:
        return null;
    }
  }

  ColorFilter? _adjustmentFilter({
    required double brightness,
    required double contrast,
    required double saturation,
  }) {
    final b = brightness.clamp(-1.0, 1.0);
    final c = contrast.clamp(.5, 2.0);
    final s = saturation.clamp(0.0, 2.0);

    if (b.abs() < .001 && (c - 1).abs() < .001 && (s - 1).abs() < .001) {
      return null;
    }

    const lumR = .2126;
    const lumG = .7152;
    const lumB = .0722;

    final sr = (1 - s) * lumR;
    final sg = (1 - s) * lumG;
    final sb = (1 - s) * lumB;
    final t = b * 255;

    return ColorFilter.matrix([
      (sr + s) * c,
      sg * c,
      sb * c,
      0,
      t + 128 * (1 - c),
      sr * c,
      (sg + s) * c,
      sb * c,
      0,
      t + 128 * (1 - c),
      sr * c,
      sg * c,
      (sb + s) * c,
      0,
      t + 128 * (1 - c),
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  Widget _buildItemContent(
      EditorItem item,
      BuildContext context, {
        bool isBackground = false,
      }) {
    if (item.type == 'video') {
      return SizedBox(
        width: item.width,
        height: item.height,
        child: EditorVideoWidget(videoUrl: item.contentUrl ?? ''),
      );
    }

    if (item.type == 'svg_group') {
      final isRasterGroup = (item.text ?? '') == 'raster_group';
      if (isRasterGroup) {
        return SizedBox(
          width: item.width,
          height: item.height,
          child: Image.network(
            item.contentUrl ?? '',
            width: item.width,
            height: item.height,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              );
            },
          ),
        );
      }

      return SizedBox(
        width: item.width,
        height: item.height,
        child: SvgPicture.string(
          item.contentUrl ?? '',
          width: item.width,
          height: item.height,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
      );
    }

    if (item.type == 'svg_element') {
      return SizedBox(
        width: item.width,
        height: item.height,
        child: SvgPicture.string(
          item.contentUrl ?? '',
          width: item.width,
          height: item.height,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
      );
    }

    if (item.type == 'shape') {
      final editorProvider = context.read<EditorProvider>();
      final raw = editorProvider.templateRawObject(item.id ?? '') ?? const <String, dynamic>{};
      final shapeType = (raw['type']?.toString() ?? item.text ?? 'rect').toLowerCase();
      final fillValue = raw['fill'];
      final fillColor = _templateColor(fillValue) ?? item.color ?? Colors.transparent;
      final gradient = _templateGradient(fillValue);
      final stroke = _templateColor(raw['stroke']) ?? item.outlineColor;
      final strokeWidth = _toFiniteDouble(raw['strokeWidth']) ?? item.outlineWidth;
      final rx = _toFiniteDouble(raw['rx']) ?? item.borderRadius;
      final ry = _toFiniteDouble(raw['ry']) ?? rx;

      // Keep the original Fabric object type and geometry. This avoids
      // turning every unknown shape/path into a plain rectangle.
      if (shapeType == 'path' || shapeType == 'line' ||
          shapeType == 'polygon' || shapeType == 'polyline') {
        return CustomPaint(
          size: Size(item.width, item.height),
          painter: FabricGeometryPainter(
            type: shapeType,
            raw: raw,
            fill: fillColor,
            gradient: gradient,
            stroke: stroke,
            strokeWidth: strokeWidth,
          ),
        );
      }

      final outlineStyle = editorProvider.outlineStyle(item.id ?? '');
      final outlineColor = stroke ?? item.outlineColor ?? Colors.transparent;
      final effectiveOutlineWidth = strokeWidth.isFinite
          ? strokeWidth.clamp(0.0, 100.0).toDouble()
          : 0.0;

      final decoration = BoxDecoration(
        color: gradient == null ? fillColor : null,
        gradient: gradient,
        shape: shapeType == 'circle' ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: shapeType == 'circle'
            ? null
            : BorderRadius.only(
          topLeft: Radius.circular(rx),
          topRight: Radius.circular(rx),
          bottomLeft: Radius.circular(ry),
          bottomRight: Radius.circular(ry),
        ),
      );

      // Fabric's ellipse is not a rounded rectangle; use an oval path.
      if (shapeType == 'ellipse' || shapeType == 'oval') {
        return CustomPaint(
          size: Size(item.width, item.height),
          painter: FabricEllipsePainter(
            fill: fillColor,
            gradient: gradient,
            stroke: stroke,
            strokeWidth: strokeWidth,
          ),
        );
      }

      // Built-in/custom polygon shapes use the same shape clipper used by
      // image masks, so triangle/star/heart/etc. remain editable.
      if (const {
        'triangle', 'diamond', 'pentagon', 'hexagon', 'octagon', 'star',
        'heart', 'arch', 'shield', 'crescent'
      }.contains(shapeType)) {
        return ClipPath(
          clipper: ShapeClipper(shapeType, radius: rx),
          child: Container(
            width: item.width,
            height: item.height,
            decoration: decoration,
          ),
        );
      }

      final shapeWidget = Container(
        width: item.width,
        height: item.height,
        decoration: decoration,
      );

      // Render the outline independently from the fill. This is important:
      // BoxDecoration can only draw a solid border, while the API/editor
      // supports solid, dashed and dotted outlines.
      return CustomPaint(
        foregroundPainter: ShapeBorderPainter(
          shape: shapeType,
          radius: rx,
          color: outlineColor,
          width: outlineStyle == 'none' ? 0 : effectiveOutlineWidth,
          style: outlineStyle,
          join: editorProvider.outlineJoin(item.id ?? ''),
        ),
        child: shapeWidget,
      );
    }

    if (item.type == 'image') {
      final url = item.contentUrl ?? '';
      final isLocalFile =
          item.isLocal || url.startsWith('file://') || url.startsWith('/data/');

      final isSvg = url.toLowerCase().split('?').first.endsWith('.svg');

      Widget imageWidget;

      if (url.trim().isEmpty) {
        imageWidget = const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        );
      } else if (isLocalFile) {
        final localPath = url.replaceFirst('file://', '');
        imageWidget = isSvg
            ? SvgPicture.file(
          File(localPath),
          fit: isBackground ? BoxFit.cover : BoxFit.contain,
          placeholderBuilder: (_) => const Center(
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        )
            : Image.file(
          File(localPath),
          width: item.width,
          height: item.height,
          fit: isBackground ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        );
      } else if (isSvg) {
        // Image.network cannot decode SVG. Freepik/category APIs can return
        // SVG URLs, so SVG assets must use flutter_svg.
        imageWidget = SvgPicture.network(
          url,
          width: item.width,
          height: item.height,
          fit: isBackground ? BoxFit.cover : BoxFit.contain,
          placeholderBuilder: (_) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        );
      } else {
        imageWidget = Image.network(
          url,
          width: item.width,
          height: item.height,
          fit: isBackground ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            );
          },
        );
      }

      final editorProvider = context.read<EditorProvider>();
      final apiMaskUrl = editorProvider.imageMaskUrl(item.id ?? '');
      final hasApiMask = apiMaskUrl != null && apiMaskUrl.trim().isNotEmpty;

      // API masks belong to the image that opened the Image > MASK toolbar.
      // When a mask is selected, use the mask asset's alpha channel to clip
      // only this image. Do not use the mask name as a ShapeClipper name:
      // API mask names are arbitrary and are not built-in shapes.
      final outlineStyle = editorProvider.outlineStyle(item.id ?? '');
      final outlineWidth = item.outlineWidth.isFinite
          ? item.outlineWidth.clamp(0.0, 20.0).toDouble()
          : 0.0;

      Widget maskedImage = hasApiMask
          ? _ApiMaskImage(
        image: imageWidget,
        maskUrl: apiMaskUrl!,
        width: item.width ?? 220,
        height: item.height ?? 220,
        outlineStyle: outlineStyle,
        outlineColor: item.outlineColor,
        outlineWidth: outlineWidth,
      )
          : ClipPath(
        clipper: ShapeClipper(
          (item.text ?? 'rounded').toLowerCase(),
          radius: item.borderRadius,
        ),
        child: imageWidget,
      );

      final rawTemplate = editorProvider.templateRawObject(item.id ?? '');
      final clipPath = rawTemplate?['clipPath'];
      if (!hasApiMask && clipPath is Map) {
        final clipType = clipPath['type']?.toString().toLowerCase() ?? 'rect';
        final clipRadius = _toFiniteDouble(clipPath['rx']) ??
            _toFiniteDouble(clipPath['ry']) ?? item.borderRadius;
        maskedImage = ClipPath(
          clipper: ShapeClipper(clipType, radius: clipRadius),
          child: imageWidget,
        );
      }

      final filteredImage = _buildFilteredImage(item, maskedImage, context);

      final shape = (item.text ?? 'rounded').toLowerCase();

      return CustomPaint(
        foregroundPainter: ShapeBorderPainter(
          shape: shape,
          radius: item.borderRadius,
          color: item.outlineColor,
          width: outlineStyle == 'none' ? 0 : outlineWidth,
          style: outlineStyle,
          join: editorProvider.outlineJoin(item.id ?? ''),
        ),
        child: filteredImage,
      );
    }

    final editorProvider = context.read<EditorProvider>();
    final id = item.id ?? '';

    // Preserve Fabric multiline text exactly. Newlines from JSON (\n) are
    // real line breaks after json.decode(), so never force maxLines: 1.
    // For multiline text use the Fabric object dimensions; for one-line text
    // keep the natural painted width.
    final textValue = item.text ?? "";
    final isMultiline = textValue.contains("\n") || textValue.contains("\r");
    final textStyle = _buildGoogleFontTextStyle(
      fontFamily: item.fontFamily,
      fontSize: item.fontSize,
      color: item.color ?? Colors.black,
      fontWeight: editorProvider.textWeight(id),
      fontStyle: editorProvider.textStyle(id),
      decoration: editorProvider.textUnderline(id)
          ? TextDecoration.underline
          : TextDecoration.none,
      letterSpacing: editorProvider.textLetterSpacing(id),
      height: editorProvider.textLineSpacing(id),
    );

    final textWidget = Text(
      textValue,
      maxLines: null,
      softWrap: isMultiline,
      textAlign: editorProvider.textAlignment(id),
      overflow: TextOverflow.visible,
      style: textStyle,
    );

    if (isMultiline) {
      return SizedBox(
        width: item.width,
        height: item.height,
        child: textWidget,
      );
    }
    return textWidget;
  }

  void _showProActionSheet(
      BuildContext context,
      EditorProvider provider,
      EditorItem item, {
        bool isBackground = false,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (modalContext) {
        return SafeArea(
          child: ChangeNotifierProvider.value(
            value: provider,
            child: StatefulBuilder(
              builder: (sheetContext, setModalState) {
                final currentItem = provider.items.firstWhere(
                      (e) => e.id == item.id,
                  orElse: () => item,
                );

                final safeScale = currentItem.scale.isFinite
                    ? currentItem.scale.clamp(.5, 3.0)
                    : 1.0;
                final safeFontSize = currentItem.fontSize.isFinite
                    ? currentItem.fontSize.clamp(8.0, 300.0).toDouble()
                    : 36.0;
                final rawRotation = currentItem.rotation.isFinite
                    ? currentItem.rotation
                    : 0.0;
                final normalizedRotation =
                    ((rawRotation % (2 * math.pi)) + (2 * math.pi)) %
                        (2 * math.pi);
                final safeOpacity = currentItem.opacity.isFinite
                    ? currentItem.opacity.clamp(0.0, 1.0)
                    : 1.0;
                final safeOutline = currentItem.outlineWidth.isFinite
                    ? currentItem.outlineWidth.clamp(0.0, 20.0)
                    : 0.0;

                return Container(
                  height: MediaQuery.of(sheetContext).size.height * .78,
                  decoration: const BoxDecoration(
                    color: Color(0xFF111318),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFC107),
                                    Color(0xFFFF8A00),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                isBackground
                                    ? Icons.wallpaper_rounded
                                    : Icons.auto_awesome_rounded,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBackground
                                        ? 'Background Editor'
                                        : 'Image Editor',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    currentItem.type == 'text' ||
                                        currentItem.type == 'textbox'
                                        ? 'Edit your text'
                                        : (isBackground
                                        ? 'Edit your canvas background'
                                        : 'Professional image controls'),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(modalContext),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: [
                            _premiumSectionTitle(
                              'QUICK ACTIONS',
                              Icons.bolt_rounded,
                            ),
                            const SizedBox(height: 10),
                            GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: .98,
                              children: [
                                if (currentItem.type == 'text' ||
                                    currentItem.type == 'textbox')
                                  _premiumActionTile(
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    accent: const Color(0xFFFFC107),
                                    onTap: () {
                                      // Close the bottom sheet first. The sheet's
                                      // builder context becomes invalid after pop,
                                      // so open the dialog with the parent context
                                      // on the next frame.
                                      Navigator.pop(modalContext);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!context.mounted) return;
                                        _showTextEditorDialog(
                                          context,
                                          provider,
                                          currentItem.id ?? '',
                                          currentItem.text ?? '',
                                        );
                                      });
                                    },
                                  ),
                                if (currentItem.type != 'text' &&
                                    currentItem.type != 'textbox') ...[
                                  _premiumActionTile(
                                    icon: Icons.wallpaper_rounded,
                                    label: 'Replace BG',
                                    accent: const Color(0xFFFFC107),
                                    onTap: () async {
                                      if (isBackground) {
                                        await _pickAndReplaceBackground(
                                          sheetContext,
                                          provider,
                                          currentItem,
                                          modalContext,
                                        );
                                      } else {
                                        final url = currentItem.contentUrl;
                                        if (url != null && url.isNotEmpty) {
                                          provider.replaceBackgroundImage(
                                            url,
                                            currentItem.id ?? '',
                                          );
                                          Navigator.pop(modalContext);
                                        }
                                      }
                                    },
                                  ),
                                  _premiumActionTile(
                                    icon: Icons.crop_rounded,
                                    label: 'Crop',
                                    accent: const Color(0xFF64B5F6),
                                    onTap: () {
                                      Navigator.pop(modalContext);
                                      _openCropScreen(
                                        context,
                                        provider,
                                        currentItem,
                                      );
                                    },
                                  ),
                                  _premiumActionTile(
                                    icon: Icons.category_rounded,
                                    label: 'Mask',
                                    accent: const Color(0xFFFF6F61),
                                    onTap: () {
                                      Navigator.pop(modalContext);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!context.mounted) return;
                                        _showMaskSheet(
                                          context,
                                          provider,
                                          currentItem.id ?? '',
                                        );
                                      });
                                    },
                                  ),
                                  _premiumActionTile(
                                    icon: Icons.auto_fix_high_rounded,
                                    label: 'Edit',
                                    accent: const Color(0xFFCE93D8),
                                    onTap: () {
                                      Navigator.pop(modalContext);
                                      _showImageEditSheet(
                                        context,
                                        provider,
                                        currentItem.id ?? '',
                                      );
                                    },
                                  ),
                                  _premiumActionTile(
                                    icon: Icons.photo_library_rounded,
                                    label: 'Photo',
                                    accent: const Color(0xFF81C784),
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      final image = await picker.pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (image == null) return;
                                      provider.addImage(
                                        image.path,
                                        isLocal: true,
                                      );
                                      Navigator.pop(modalContext);
                                    },
                                  ),
                                ],
                              ],
                            ),

                            if (currentItem.type != 'text' &&
                                currentItem.type != 'textbox') ...[
                              const SizedBox(height: 20),
                              _premiumSectionTitle(
                                'FILTERS',
                                Icons.tune_rounded,
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _miniFilter(
                                      provider,
                                      currentItem,
                                      'Normal',
                                      'normal',
                                      setModalState,
                                    ),
                                    _miniFilter(
                                      provider,
                                      currentItem,
                                      'Gray',
                                      'grayscale',
                                      setModalState,
                                    ),
                                    _miniFilter(
                                      provider,
                                      currentItem,
                                      'Sepia',
                                      'sepia',
                                      setModalState,
                                    ),
                                    _miniFilter(
                                      provider,
                                      currentItem,
                                      'Vintage',
                                      'vintage',
                                      setModalState,
                                    ),
                                    _miniFilter(
                                      provider,
                                      currentItem,
                                      'Drama',
                                      'drama',
                                      setModalState,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (currentItem.type == 'text' ||
                                currentItem.type == 'textbox') ...[
                              const SizedBox(height: 20),
                              _premiumSectionTitle(
                                'FONT FAMILY',
                                Icons.font_download_rounded,
                              ),
                              const SizedBox(height: 10),
                              _fontFamilyControl(
                                  currentItem,
                                  provider,
                                  setModalState,
                                  context
                              ),
                            ],

                            const SizedBox(height: 20),
                            _premiumSectionTitle(
                              'TRANSFORM',
                              Icons.open_with_rounded,
                            ),
                            const SizedBox(height: 10),

                            if (currentItem.type == 'text' ||
                                currentItem.type == 'textbox')
                              _textSizeControl(
                                currentItem,
                                provider,
                                setModalState,
                              ),

                            _premiumSliderCard(
                              icon: Icons.zoom_in_rounded,
                              title: 'Scale',
                              valueText: '${(safeScale * 100).round()}%',
                              value: safeScale,
                              min: .5,
                              max: 3,
                              onChanged: (v) => setModalState(
                                    () => provider.updateScale(
                                  currentItem.id ?? '',
                                  v.clamp(.5, 3.0),
                                ),
                              ),
                            ),
                            _premiumSliderCard(
                              icon: Icons.rotate_right_rounded,
                              title: 'Rotation',
                              valueText:
                              '${((normalizedRotation * 180) / math.pi).round()}°',
                              value: normalizedRotation.clamp(0.0, 2 * math.pi),
                              min: 0,
                              max: 2 * math.pi,
                              onChanged: (v) => setModalState(
                                    () => provider.updateRotation(
                                  currentItem.id ?? '',
                                  v.clamp(0.0, 2 * math.pi),
                                ),
                              ),
                            ),
                            _premiumSliderCard(
                              icon: Icons.opacity_rounded,
                              title: 'Opacity',
                              valueText: '${(safeOpacity * 100).round()}%',
                              value: safeOpacity,
                              min: 0,
                              max: 1,
                              onChanged: (v) => setModalState(
                                    () => provider.updateOpacity(
                                  currentItem.id ?? '',
                                  v.clamp(0.0, 1.0),
                                ),
                              ),
                            ),

                            if (currentItem.type == 'image' &&
                                currentItem.type != 'text' &&
                                currentItem.type != 'textbox') ...[
                              const SizedBox(height: 20),
                              _premiumSectionTitle(
                                'SHAPE & BORDER',
                                Icons.crop_square_rounded,
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: _premiumChoiceButton(
                                  icon: Icons.category_rounded,
                                  label: 'Open Mask Shapes',
                                  selected:
                                  currentItem.text != 'square' &&
                                      currentItem.text != 'rounded',
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!context.mounted) return;
                                      _showMaskSheet(
                                        context,
                                        provider,
                                        currentItem.id ?? '',
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              _premiumSliderCard(
                                icon: Icons.border_style_rounded,
                                title: 'Outline',
                                valueText: '${safeOutline.round()}',
                                value: safeOutline,
                                min: 0,
                                max: 20,
                                onChanged: (v) => setModalState(
                                      () => provider.updateOutline(
                                    currentItem.id ?? '',
                                    v.clamp(0.0, 20.0),
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ],

                            if (currentItem.type == 'shape') ...[
                              const SizedBox(height: 20),
                              _premiumSectionTitle('SHAPE', Icons.category_rounded),
                              const SizedBox(height: 10),
                              _shapeColorSetting(
                                label: 'FILL',
                                color: _templateColor(
                                  provider.templateRawObject(currentItem.id ?? '')?['fill'],
                                ) ??
                                    currentItem.color ??
                                    Colors.transparent,
                                onTap: () => _showShapeColorPicker(
                                  context,
                                  provider,
                                  currentItem.id ?? '',
                                  isOutline: false,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _premiumSectionTitle(
                                'OUTLINE',
                                Icons.border_style_rounded,
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _outlineStyleButton(
                                      'None', 'none', provider.outlineStyle(currentItem.id ?? ''),
                                          () => setModalState(() => provider.updateOutlineStyle(currentItem.id ?? '', 'none')),
                                    ),
                                    _outlineStyleButton(
                                      'Solid', 'solid', provider.outlineStyle(currentItem.id ?? ''),
                                          () => setModalState(() => provider.updateOutlineStyle(currentItem.id ?? '', 'solid')),
                                    ),
                                    _outlineStyleButton(
                                      'Dashed', 'dashed', provider.outlineStyle(currentItem.id ?? ''),
                                          () => setModalState(() => provider.updateOutlineStyle(currentItem.id ?? '', 'dashed')),
                                    ),
                                    _outlineStyleButton(
                                      'Dotted', 'dotted', provider.outlineStyle(currentItem.id ?? ''),
                                          () => setModalState(() => provider.updateOutlineStyle(currentItem.id ?? '', 'dotted')),
                                    ),
                                    _outlineStyleButton(
                                      'Fine', 'fine_dotted', provider.outlineStyle(currentItem.id ?? ''),
                                          () => setModalState(() => provider.updateOutlineStyle(currentItem.id ?? '', 'fine_dotted')),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _shapeColorSetting(
                                label: 'OUTLINE COLOR',
                                color: currentItem.outlineColor ?? const Color(0xFFD9D9D9),
                                onTap: () => _showShapeColorPicker(
                                  context,
                                  provider,
                                  currentItem.id ?? '',
                                  isOutline: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _premiumSliderCard(
                                icon: Icons.line_weight_rounded,
                                title: 'Thickness',
                                valueText: '${safeOutline.round()}',
                                value: safeOutline,
                                min: 0,
                                max: 20,
                                onChanged: (v) => setModalState(() => provider.updateOutline(
                                  currentItem.id ?? '',
                                  v.clamp(0.0, 20.0),
                                  currentItem.outlineColor ?? const Color(0xFFD9D9D9),
                                )),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Join',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _outlineJoinButton('miter', Icons.crop_square_rounded, provider.outlineJoin(currentItem.id ?? ''), () => setModalState(() => provider.updateOutlineJoin(currentItem.id ?? '', 'miter'))),
                                  const SizedBox(width: 8),
                                  _outlineJoinButton('bevel', Icons.rounded_corner_rounded, provider.outlineJoin(currentItem.id ?? ''), () => setModalState(() => provider.updateOutlineJoin(currentItem.id ?? '', 'bevel'))),
                                  const SizedBox(width: 8),
                                  _outlineJoinButton('round', Icons.rounded_corner, provider.outlineJoin(currentItem.id ?? ''), () => setModalState(() => provider.updateOutlineJoin(currentItem.id ?? '', 'round'))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _premiumChoiceButton(
                                      icon: Icons.flip_rounded,
                                      label: 'Flip Horizontal',
                                      onTap: () => provider.flipImageHorizontal(currentItem.id ?? ''),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _premiumChoiceButton(
                                      icon: Icons.flip_rounded,
                                      label: 'Flip Vertical',
                                      onTap: () => provider.flipImageVertical(currentItem.id ?? ''),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 20),
                            _premiumSectionTitle('LAYER', Icons.layers_rounded),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _premiumChoiceButton(
                                    icon: Icons.flip_to_front_rounded,
                                    label: 'Front',
                                    onTap: () => provider.bringToFront(
                                      currentItem.id ?? '',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _premiumChoiceButton(
                                    icon: Icons.flip_to_back_rounded,
                                    label: 'Back',
                                    onTap: () => provider.sendToBack(
                                      currentItem.id ?? '',
                                    ),
                                  ),
                                ),
                                if (!isBackground) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _premiumChoiceButton(
                                      icon: Icons.copy_rounded,
                                      label: 'Duplicate',
                                      onTap: () => provider.duplicateItem(
                                        currentItem.id ?? '',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 12),
                            _premiumDangerButton(
                              icon: Icons.delete_outline_rounded,
                              label:
                              currentItem.type == 'text' ||
                                  currentItem.type == 'textbox'
                                  ? 'Delete Text'
                                  : (isBackground
                                  ? 'Delete Background'
                                  : 'Delete Image'),
                              onTap: () {
                                final id = currentItem.id ?? '';
                                provider.removeItem(id);
                                Navigator.pop(modalContext);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndReplaceBackground(
      BuildContext context,
      EditorProvider provider,
      EditorItem currentItem,
      BuildContext modalContext,
      ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    provider.replaceBackgroundImage(image.path, currentItem.id ?? '');
    if (Navigator.canPop(modalContext)) {
      Navigator.pop(modalContext);
    }
  }

  Widget _premiumSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFFC107)),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _premiumActionTile({
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1B1F27),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumChoiceButton({
    required IconData icon,
    required String label,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? const Color(0xFFFFC107).withOpacity(.16)
          : const Color(0xFF1B1F27),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFFFC107) : Colors.white10,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? const Color(0xFFFFC107) : Colors.white70,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFFFFC107) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumDangerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF2A171A),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withOpacity(.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.redAccent, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _buildGoogleFontTextStyle({
    required String? fontFamily,
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
    required FontStyle fontStyle,
    required TextDecoration decoration,
    required double letterSpacing,
    required double height,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
    );

    final family = (fontFamily ?? '').trim();
    if (family.isEmpty) return base;

    try {
      return GoogleFonts.getFont(family, textStyle: base);
    } catch (_) {
      return base.copyWith(fontFamily: family);
    }
  }

  Widget _fontFamilyControl(
      EditorItem currentItem,
      EditorProvider provider,
      StateSetter setModalState,
      BuildContext context
      ) {
    final currentFont = (currentItem.fontFamily ?? '').trim().isEmpty
        ? 'Roboto'
        : currentItem.fontFamily.trim();

    return Material(
      color: const Color(0xFF1B1F27),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          _showFontPicker(
            context,
            provider,
            currentItem.id ?? '',
            currentFont,
            setModalState,
          );
        },
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.font_download_rounded, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Font',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentFont,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _buildGoogleFontTextStyle(
                        fontFamily: currentFont,
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        decoration: TextDecoration.none,
                        letterSpacing: 0,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  void _showFontPicker(
      BuildContext parentContext,
      EditorProvider provider,
      String itemId,
      String selectedFont,
      StateSetter setParentModalState,
      ) {
    final fonts = GoogleFonts.asMap().keys.toList()..sort();
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111318),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (fontContext) {
        return StatefulBuilder(
          builder: (fontContext, setFontState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? fonts
                : fonts.where((font) => font.toLowerCase().contains(query)).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(fontContext).size.height * .86,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Choose Font',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${filtered.length} fonts',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(fontContext),
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setFontState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search all Google Fonts...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                          suffixIcon: searchController.text.isEmpty
                              ? null
                              : IconButton(
                            onPressed: () {
                              searchController.clear();
                              setFontState(() {});
                            },
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1B1F27),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 7),
                        itemBuilder: (_, index) {
                          final font = filtered[index];
                          final selected = font == selectedFont;
                          return Material(
                            color: selected
                                ? const Color(0x33FFC107)
                                : const Color(0xFF1B1F27),
                            borderRadius: BorderRadius.circular(13),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(13),
                              onTap: () {
                                provider.updateFontFamily(itemId, font);
                                setParentModalState(() {});
                                Navigator.pop(fontContext);
                              },
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 58),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFFFC107)
                                        : Colors.white10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        font,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _buildGoogleFontTextStyle(
                                          fontFamily: font,
                                          fontSize: 21,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.normal,
                                          decoration: TextDecoration.none,
                                          letterSpacing: 0,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      selected ? 'SELECTED' : 'Aa',
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFFFFC107)
                                            : Colors.white38,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _textSizeControl(
      EditorItem currentItem,
      EditorProvider provider,
      StateSetter setModalState,
      ) {
    final size = currentItem.fontSize.isFinite
        ? currentItem.fontSize.clamp(8.0, 300.0).toDouble()
        : 36.0;

    void changeSize(double value) {
      provider.updateFontSize(
        currentItem.id ?? '',
        value.clamp(8.0, 300.0).toDouble(),
      );
      setModalState(() {});
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F27),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_size_rounded,
                size: 18,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Text Size',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${size.toStringAsFixed(0)} px',
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => changeSize(size - 2),
                child: const SizedBox(
                  width: 34,
                  height: 38,
                  child: Icon(Icons.remove_rounded, color: Colors.white70),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFFFFC107),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: const Color(0xFFFFC107),
                    overlayColor: const Color(0x1FFFC107),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: size,
                    min: 8,
                    max: 300,
                    onChanged: changeSize,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => changeSize(size + 2),
                child: const SizedBox(
                  width: 34,
                  height: 38,
                  child: Icon(Icons.add_rounded, color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _premiumSliderCard({
    required IconData icon,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final safeValue = value.isFinite ? value.clamp(min, max).toDouble() : min;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F27),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFFC107),
              inactiveTrackColor: Colors.white12,
              thumbColor: const Color(0xFFFFC107),
              overlayColor: const Color(0x1FFFC107),
              trackHeight: 3,
            ),
            child: Slider(
              value: safeValue,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniFilter(
      EditorProvider provider,
      EditorItem item,
      String label,
      String type,
      StateSetter setModalState,
      ) {
    final selected = item.filterType == type;
    return GestureDetector(
      onTap: () =>
          setModalState(() => provider.setImageFilter(item.id ?? '', type)),
      child: Container(
        width: 74,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFC107).withOpacity(.13)
              : const Color(0xFF1B1F27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFC107) : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 42,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(colors: _filterPreviewColors(type)),
              ),
              child: Icon(_filterIcon(type), color: Colors.white, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? const Color(0xFFFFC107) : Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaskSheet(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      ) {
    final shapes = <Map<String, dynamic>>[
      {'name': 'Square', 'id': 'square', 'icon': Icons.crop_square_rounded},
      {'name': 'Rounded', 'id': 'rounded', 'icon': Icons.rounded_corner},
      {'name': 'Rectangle', 'id': 'rectangle', 'icon': Icons.rectangle_rounded},
      {'name': 'Circle', 'id': 'circle', 'icon': Icons.circle},
      {'name': 'Oval', 'id': 'oval', 'icon': Icons.circle_outlined},
      {
        'name': 'Triangle',
        'id': 'triangle',
        'icon': Icons.change_history_rounded,
      },
      {'name': 'Diamond', 'id': 'diamond', 'icon': Icons.diamond_rounded},
      {'name': 'Pentagon', 'id': 'pentagon', 'icon': Icons.pentagon_rounded},
      {'name': 'Hexagon', 'id': 'hexagon', 'icon': Icons.stop_circle_outlined},
      {'name': 'Octagon', 'id': 'octagon', 'icon': Icons.stop_rounded},
      {'name': 'Star', 'id': 'star', 'icon': Icons.star_rounded},
      {'name': 'Heart', 'id': 'heart', 'icon': Icons.favorite_rounded},
      {'name': 'Arch', 'id': 'arch', 'icon': Icons.architecture_rounded},
      {'name': 'Shield', 'id': 'shield', 'icon': Icons.shield_rounded},
      {'name': 'Crescent', 'id': 'crescent', 'icon': Icons.nightlight_round},
    ];
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          final filtered = shapes
              .where(
                (s) => (s['name'] as String).toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
              .toList();
          final current = provider.items.firstWhere(
                (e) => e.id == itemId,
            orElse: () => provider.items.first,
          );
          return SizedBox(
            height: MediaQuery.of(context).size.height * .88,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mask',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search masks...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filtered.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: .94,
                    ),
                    itemBuilder: (_, index) {
                      final shape = filtered[index];
                      final selected = current.text == shape['id'];
                      return GestureDetector(
                        onTap: () {
                          provider.updateImageShape(
                            itemId,
                            shape['id'] as String,
                          );
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? Colors.redAccent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                shape['icon'] as IconData,
                                size: 54,
                                color: Colors.black,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                shape['name'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showImageEditSheet(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      ) {
    final item = provider.items.firstWhere(
          (e) => e.id == itemId,
      orElse: () => provider.items.first,
    );

    String filter = item.filterType == 'normal' ? 'none' : item.filterType;

    double filterIntensity = provider
        .imageFilterIntensity(itemId)
        .clamp(0.0, 1.0);

    double brightness = item.brightness.isFinite
        ? item.brightness.clamp(-1.0, 1.0)
        : 0.0;

    double contrast = item.contrast.isFinite
        ? item.contrast.clamp(.5, 2.0)
        : 1.0;

    double saturation = item.saturation.isFinite
        ? item.saturation.clamp(0.0, 2.0)
        : 1.0;

    double tint = provider.imageTint(itemId).clamp(-100.0, 100.0);
    double blur = provider.imageBlur(itemId).clamp(0.0, 20.0);

    const filters = <String>[
      'none',
      'festive',
      'drama',
      'cali',
      'epic',
      'street',
      'grayscale',
      'rosie',
      'edge',
      'nordic',
      'selfie',
      'blues',
      'whimsical',
      'summer',
      'retro',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void apply() {
            provider.setImageFilter(itemId, filter);
            provider.updateImageFilterIntensity(
              itemId,
              filterIntensity.clamp(0.0, 1.0),
            );
            provider.updateImageColorAdjustments(
              itemId,
              brightness: brightness.clamp(-1.0, 1.0),
              contrast: contrast.clamp(.5, 2.0),
              saturation: saturation.clamp(0.0, 2.0),
            );
            provider.updateImageTint(itemId, tint);
            provider.updateImageBlur(itemId, blur);
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Expanded(
                          child: Text(
                            'EDIT IMAGE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            filter = 'none';
                            filterIntensity = 1;
                            brightness = 0;
                            contrast = 1;
                            saturation = 1;
                            tint = 0;
                            blur = 0;
                            apply();
                            setModalState(() {});
                          },
                          child: const Text('RESET'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filters.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                            childAspectRatio: .82,
                          ),
                          itemBuilder: (_, index) {
                            final f = filters[index];
                            final selected = filter == f;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() => filter = f);
                                apply();
                              },
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? Colors.red
                                              : Colors.grey.shade300,
                                          width: selected ? 2 : 1,
                                        ),
                                        gradient: LinearGradient(
                                          colors: _filterPreviewColors(f),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _filterIcon(f),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _filterTitle(f),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _imageEditSlider(
                          'Filter Intensity',
                          filterIntensity,
                          0,
                          1,
                              (v) {
                            setModalState(
                                  () => filterIntensity = v.clamp(0.0, 1.0),
                            );
                            apply();
                          },
                          '${(filterIntensity * 100).round()}',
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            'Advanced Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _imageEditSlider(
                          'Brightness',
                          brightness,
                          -1,
                          1,
                              (v) {
                            setModalState(() => brightness = v.clamp(-1.0, 1.0));
                            apply();
                          },
                          '${((brightness + 1) * 50).round()}',
                        ),
                        _imageEditSlider(
                          'Contrast',
                          contrast,
                          .5,
                          2,
                              (v) {
                            setModalState(() => contrast = v.clamp(.5, 2.0));
                            apply();
                          },
                          '${(contrast * 50).round()}',
                        ),
                        _imageEditSlider(
                          'Tint',
                          tint,
                          -100,
                          100,
                              (v) {
                            setModalState(() => tint = v.clamp(-100.0, 100.0));
                            apply();
                          },
                          tint >= 0
                              ? '+${tint.round()}'
                              : '${tint.round()}',
                          gradient: true,
                        ),
                        _imageEditSlider(
                          'Saturation',
                          saturation,
                          0,
                          2,
                              (v) {
                            setModalState(() => saturation = v.clamp(0.0, 2.0));
                            apply();
                          },
                          '${(saturation * 50).round()}',
                        ),
                        _imageEditSlider(
                          'Blur',
                          blur,
                          0,
                          20,
                              (v) {
                            setModalState(() => blur = v.clamp(0.0, 20.0));
                            apply();
                          },
                          '${blur.round()}',
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: OutlinedButton(
                            onPressed: () {
                              filter = 'none';
                              filterIntensity = 1;
                              brightness = 0;
                              contrast = 1;
                              saturation = 1;
                              tint = 0;
                              blur = 0;
                              apply();
                              setModalState(() {});
                            },
                            child: const Text('REVERT TO ORIGINAL'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imageEditSlider(
      String title,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      String valueText, {
        bool gradient = false,
      }) {
    final safeValue = value.isFinite ? value.clamp(min, max) : min;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(valueText),
          ],
        ),
        if (gradient)
          SizedBox(
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.pink,
                  ],
                ),
              ),
            ),
          ),
        Slider(
          min: min,
          max: max,
          value: safeValue,
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _filterTitle(String value) {
    const titles = {
      'none': 'Normal',
      'festive': 'Festive',
      'drama': 'Drama',
      'cali': 'Cali',
      'epic': 'Epic',
      'street': 'Street',
      'grayscale': 'Gray Scale',
      'rosie': 'Rosie',
      'edge': 'Edge',
      'nordic': 'Nordic',
      'selfie': 'Selfie',
      'blues': 'The Blues',
      'whimsical': 'Whimsical',
      'summer': 'Summer',
      'retro': 'Retro',
    };

    return titles[value] ?? value;
  }

  List<Color> _filterPreviewColors(String value) {
    switch (value) {
      case 'grayscale':
        return [Colors.grey.shade700, Colors.grey.shade300];
      case 'rosie':
        return [Colors.pink.shade300, Colors.purple.shade700];
      case 'blues':
      case 'nordic':
        return [Colors.blue.shade900, Colors.cyan.shade200];
      case 'summer':
      case 'festive':
        return [Colors.orange, Colors.pinkAccent];
      case 'drama':
      case 'edge':
        return [Colors.black87, Colors.blueGrey];
      case 'retro':
        return [Colors.brown, Colors.amber.shade200];
      default:
        return [Colors.indigo, Colors.purpleAccent];
    }
  }

  IconData _filterIcon(String value) {
    switch (value) {
      case 'grayscale':
        return Icons.contrast;
      case 'festive':
        return Icons.auto_awesome;
      case 'drama':
        return Icons.movie_filter_outlined;
      case 'cali':
        return Icons.wb_sunny_outlined;
      case 'epic':
        return Icons.flash_on_outlined;
      case 'street':
        return Icons.location_city_outlined;
      case 'rosie':
        return Icons.favorite_outline;
      case 'edge':
        return Icons.blur_on_outlined;
      case 'nordic':
        return Icons.ac_unit;
      case 'selfie':
        return Icons.face_retouching_natural;
      case 'blues':
        return Icons.water_drop_outlined;
      case 'whimsical':
        return Icons.auto_fix_high;
      case 'summer':
        return Icons.beach_access_outlined;
      case 'retro':
        return Icons.history;
      default:
        return Icons.image_outlined;
    }
  }

  Widget _filterButton(
      EditorProvider provider,
      EditorItem item,
      String label,
      String type,
      StateSetter setModalState,
      ) {
    return TextButton(
      onPressed: () {
        setModalState(() {
          provider.setImageFilter(item.id ?? "", type);
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: item.filterType == type ? Colors.amber : Colors.white70,
        ),
      ),
    );
  }

  void _showTextEditorDialog(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      String initialText,
      ) {
    final controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text(
            "Edit Text",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: "Type text here...",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.amberAccent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.amberAccent, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  provider.updateTextContent(itemId, controller.text);
                }
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCropScreen(
      BuildContext context,
      EditorProvider provider,
      EditorItem item,
      ) async {
    final GlobalKey<ExtendedImageEditorState> editorKey =
    GlobalKey<ExtendedImageEditorState>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              "Crop Image",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.check,
                  color: Colors.amberAccent,
                  size: 28,
                ),
                onPressed: () async {
                  final state = editorKey.currentState;

                  if (state != null) {
                    final rawImage = state.rawImageData;
                    final rect = state.getCropRect();

                    if (rect != null) {
                      final croppedData = await _cropImageBytes(rawImage, rect);

                      if (croppedData != null) {
                        final tempDir = Directory.systemTemp;
                        final file = File(
                          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );

                        await file.writeAsBytes(croppedData);

                        provider.updateCroppedImage(item.id!, file.path);

                        Navigator.pop(context);
                      }
                    }
                  }
                },
              ),
            ],
          ),
          body: Center(
            child:
            (item.isLocal ||
                (item.contentUrl != null &&
                    item.contentUrl!.startsWith('/')))
                ? ExtendedImage.file(
              File(item.contentUrl!.replaceFirst('file://', '')),
              fit: BoxFit.contain,
              mode: ExtendedImageMode.editor,
              extendedImageEditorKey: editorKey,
              cacheRawData: true,
            )
                : ExtendedImage.network(
              item.contentUrl ?? "",
              fit: BoxFit.contain,
              mode: ExtendedImageMode.editor,
              extendedImageEditorKey: editorKey,
              cacheRawData: true,
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _cropImageBytes(Uint8List rawBytes, Rect rect) async {
    try {
      final src = img.decodeImage(rawBytes);
      if (src == null) return null;

      final x = rect.left.toInt().clamp(0, src.width - 1);

      final y = rect.top.toInt().clamp(0, src.height - 1);

      final w = rect.width.toInt().clamp(1, src.width - x);

      final h = rect.height.toInt().clamp(1, src.height - y);

      final cropped = img.copyCrop(src, x: x, y: y, width: w, height: h);

      return Uint8List.fromList(img.encodeJpg(cropped));
    } catch (e) {
      debugPrint("Crop Error: $e");
      return null;
    }
  }
}


Widget _shapeColorSetting({
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _outlineStyleButton(
    String label,
    String value,
    String selected,
    VoidCallback onTap,
    ) {
  final active = value == selected;
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFC107) : const Color(0xFF1B1F27),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFFFFC107) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

Widget _outlineJoinButton(
    String value,
    IconData icon,
    String selected,
    VoidCallback onTap,
    ) {
  final active = value == selected;
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFC107) : const Color(0xFF1B1F27),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFFFFC107) : Colors.white12),
        ),
        child: Icon(icon, color: active ? Colors.black : Colors.white70),
      ),
    ),
  );
}

Future<void> _showShapeColorPicker(
    BuildContext context,
    EditorProvider provider,
    String id, {
      required bool isOutline,
    }) async {
  final item = provider.items.firstWhere(
        (e) => e.id == id,
    orElse: () => provider.items.first,
  );
  final raw = provider.templateRawObject(id);
  Color current = isOutline
      ? (_templateColor(raw?['stroke']) ?? item.outlineColor ?? const Color(0xFFD9D9D9))
      : (_templateColor(raw?['fill']) ?? item.color ?? Colors.white);

  final picked = await showDialog<Color>(
    context: context,
    builder: (dialogContext) {
      HSVColor hsv = HSVColor.fromColor(current);
      return StatefulBuilder(
        builder: (context, setState) {
          current = hsv.toColor();
          return AlertDialog(
            backgroundColor: const Color(0xFF171A21),
            title: Text(
              isOutline ? 'Outline Color' : 'Fill Color',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    color: current,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 14),
                _colorSlider('Hue', hsv.hue, 360, (v) => setState(() => hsv = hsv.withHue(v))),
                _colorSlider('Sat', hsv.saturation, 1, (v) => setState(() => hsv = hsv.withSaturation(v))),
                _colorSlider('Val', hsv.value, 1, (v) => setState(() => hsv = hsv.withValue(v))),
                const SizedBox(height: 4),
                Text(
                  '#${current.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, current),
                child: const Text('APPLY'),
              ),
            ],
          );
        },
      );
    },
  );

  if (picked == null) return;
  if (isOutline) {
    provider.updateOutline(id, item.outlineWidth, picked);
  } else {
    provider.updateShapeFill(id, picked);
  }
}

Widget _colorSlider(
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged,
    ) {
  return Row(
    children: [
      SizedBox(width: 38, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
      Expanded(child: Slider(min: 0, max: max, value: value.clamp(0, max), onChanged: onChanged)),
    ],
  );
}


class _EditorSelectionControls extends StatefulWidget {
  final EditorItem item;
  final double bodyWidth;
  final double bodyHeight;
  final EditorProvider provider;

  const _EditorSelectionControls({
    required this.item,
    required this.bodyWidth,
    required this.bodyHeight,
    required this.provider,
  });

  @override
  State<_EditorSelectionControls> createState() =>
      _EditorSelectionControlsState();
}

class _EditorSelectionControlsState extends State<_EditorSelectionControls> {
  double _startScale = 1.0;
  double _startWidth = 1.0;
  double _startHeight = 1.0;
  Offset _startPosition = Offset.zero;
  Offset _startGlobal = Offset.zero;
  double _startPixelsPerLocalUnit = 1.0;
  bool _resizing = false;

  double _startRotation = 0.0;
  double _startAngle = 0.0;
  Offset _rotationCenter = Offset.zero;

  static const double _minScale = 0.05;
  static const double _maxScale = 10.0;

  Offset _toObjectDelta(Offset globalDelta) {
    // Convert the finger movement from canvas/global axes into the object's
    // unrotated axes. This is important when an image has been rotated.
    final c = math.cos(-_startRotation);
    final s = math.sin(-_startRotation);
    return Offset(
      globalDelta.dx * c - globalDelta.dy * s,
      globalDelta.dx * s + globalDelta.dy * c,
    );
  }

  Offset _rotateVector(Offset value, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Offset(
      value.dx * c - value.dy * s,
      value.dx * s + value.dy * c,
    );
  }

  double _globalPixelsPerLocalUnit() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return 1.0;

    final localWidth = math.max(1.0, widget.bodyWidth);
    final p0 = renderObject.localToGlobal(Offset.zero);
    final p1 = renderObject.localToGlobal(Offset(localWidth, 0));
    final dx = p1.dx - p0.dx;
    final dy = p1.dy - p0.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (!distance.isFinite || distance <= 0.0001) return 1.0;
    return distance / localWidth;
  }

  void _startResize(Alignment alignment, Offset global) {
    _resizing = true;
    _startScale = widget.item.scale.isFinite ? widget.item.scale : 1.0;
    _startWidth = math.max(20.0, widget.bodyWidth);
    _startHeight = math.max(20.0, widget.bodyHeight);
    _startPosition = widget.item.position;
    _startGlobal = global;
    _startPixelsPerLocalUnit = _globalPixelsPerLocalUnit();
    _startRotation = widget.item.rotation.isFinite ? widget.item.rotation : 0.0;
    widget.provider.setSelectedItem(widget.item.type, widget.item.id);
  }

  void _resize(Alignment alignment, Offset global) {
    if (!_resizing) return;

    final pixelsPerLocalUnit = _startPixelsPerLocalUnit <= 0.0001
        ? 1.0
        : _startPixelsPerLocalUnit;

    // Finger movement -> unrotated editor coordinates. Because the selected
    // item is already inside Transform.scale, _globalPixelsPerLocalUnit()
    // includes both the canvas preview scale and the item's current scale.
    final globalDelta = global - _startGlobal;
    final localDelta = _toObjectDelta(globalDelta);
    final dx = localDelta.dx / pixelsPerLocalUnit;
    final dy = localDelta.dy / pixelsPerLocalUnit;

    // Text is represented by its font size/natural text bounds in this
    // editor, so keep the existing proportional scale behavior for text.
    // Images/shapes/videos use real width/height resizing, matching the
    // reference editor where the aspect ratio can change with each handle.
    final isText = widget.item.type == 'text' || widget.item.type == 'textbox';
    if (isText) {
      final horizontal = alignment.x == 0
          ? 0.0
          : alignment.x == 1
          ? dx / _startWidth
          : -dx / _startWidth;
      final vertical = alignment.y == 0
          ? 0.0
          : alignment.y == 1
          ? dy / _startHeight
          : -dy / _startHeight;
      final deltaScale = alignment.x != 0 && alignment.y != 0
          ? (horizontal.abs() >= vertical.abs() ? horizontal : vertical)
          : (alignment.x != 0 ? horizontal : vertical);

      final nextScale = (_startScale + deltaScale)
          .clamp(0.05, 10.0)
          .toDouble();
      final scaleDelta = nextScale - _startScale;
      final shiftLocal = Offset(
        alignment.x < 0
            ? -_startWidth * scaleDelta
            : alignment.x == 0
            ? -_startWidth * scaleDelta / 2
            : 0.0,
        alignment.y < 0
            ? -_startHeight * scaleDelta
            : alignment.y == 0
            ? -_startHeight * scaleDelta / 2
            : 0.0,
      );
      final shift = _rotateVector(shiftLocal, _startRotation);
      widget.provider.updateItemTransform(
        widget.item.id ?? '',
        scale: nextScale,
        position: _startPosition + shift,
        clampToFrame: false,
      );
      return;
    }

    double newWidth = _startWidth;
    double newHeight = _startHeight;

    if (alignment.x < 0) {
      newWidth = _startWidth - dx;
    } else if (alignment.x > 0) {
      newWidth = _startWidth + dx;
    }

    if (alignment.y < 0) {
      newHeight = _startHeight - dy;
    } else if (alignment.y > 0) {
      newHeight = _startHeight + dy;
    }

    const minSize = 20.0;
    newWidth = math.max(minSize, newWidth);
    newHeight = math.max(minSize, newHeight);

    // Canva-like behavior: When resizing from a corner handle, maintain
    // aspect ratio proportionally to prevent image/shape distortion.
    if (alignment.x != 0 && alignment.y != 0 && _startWidth > 0 && _startHeight > 0) {
      final scaleX = newWidth / _startWidth;
      final scaleY = newHeight / _startHeight;
      final dominantScale = scaleX.abs() >= scaleY.abs() ? scaleX : scaleY;
      newWidth = math.max(minSize, _startWidth * dominantScale);
      newHeight = math.max(minSize, _startHeight * dominantScale);
    }

    // Anchor the opposite edge/corner exactly like the reference editor.
    // The correction is calculated in the item's unrotated coordinate system
    // and then rotated back into canvas coordinates.
    final consumedX = newWidth - _startWidth;
    final consumedY = newHeight - _startHeight;
    final shiftLocal = Offset(
      alignment.x < 0
          ? -consumedX
          : alignment.x == 0
          ? -consumedX / 2
          : 0.0,
      alignment.y < 0
          ? -consumedY
          : alignment.y == 0
          ? -consumedY / 2
          : 0.0,
    );
    final shift = _rotateVector(shiftLocal, _startRotation);

    widget.provider.updateItemSize(
      widget.item.id ?? '',
      width: newWidth,
      height: newHeight,
      position: _startPosition + shift,
    );
  }

  void _endResize() {
    _resizing = false;
  }

  void _beginRotation(Offset global) {
    // Rotation center is derived directly from the current rendered item.
    // No GlobalKey/local transform conversion is needed, so resizing cannot
    // make the rotation center drift.
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      _rotationCenter = renderObject.localToGlobal(
        Offset(widget.bodyWidth / 2, widget.bodyHeight / 2),
      );
    } else {
      return;
    }

    _startRotation = widget.item.rotation.isFinite ? widget.item.rotation : 0.0;
    _startAngle = math.atan2(
      global.dy - _rotationCenter.dy,
      global.dx - _rotationCenter.dx,
    );
  }

  void _rotate(Offset global) {
    final angle = math.atan2(
      global.dy - _rotationCenter.dy,
      global.dx - _rotationCenter.dx,
    );
    var delta = angle - _startAngle;
    if (delta > math.pi) delta -= math.pi * 2;
    if (delta < -math.pi) delta += math.pi * 2;

    widget.provider.updateItemTransform(
      widget.item.id ?? '',
      rotation: _startRotation + delta,
      clampToFrame: false,
    );
  }

  Widget _handle(Alignment alignment) {
    // Large touch target kept strictly inside the bounding box so Flutter's
    // hit-testing accurately registers the tap.
    const double hitSize = 44.0;
    const double visualSize = 14.0;

    final double left = alignment.x < 0
        ? 0.0
        : alignment.x > 0
            ? math.max(0.0, widget.bodyWidth - hitSize)
            : math.max(0.0, (widget.bodyWidth - hitSize) / 2);

    final double top = alignment.y < 0
        ? (alignment.x == 0 ? 24.0 : 0.0)
        : alignment.y > 0
            ? math.max(0.0, widget.bodyHeight - hitSize)
            : math.max(0.0, (widget.bodyHeight - hitSize) / 2);

    return Positioned(
      left: left,
      top: top,
      width: hitSize,
      height: hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _startResize(alignment, d.globalPosition),
        onPanUpdate: (d) => _resize(alignment, d.globalPosition),
        onPanEnd: (_) => _endResize(),
        onPanCancel: _endResize,
        child: Center(
          child: Transform.translate(
            // Shift the visual dot exactly onto the selection line, while the
            // invisible touch target stays safely inside the widget's bounds.
            offset: Offset(
              alignment.x < 0
                  ? -hitSize / 2 + visualSize / 2
                  : alignment.x > 0
                      ? hitSize / 2 - visualSize / 2
                      : 0,
              alignment.y < 0
                  ? (alignment.x == 0
                      ? -hitSize / 2 + visualSize / 2 - 24
                      : -hitSize / 2 + visualSize / 2)
                  : alignment.y > 0
                      ? hitSize / 2 - visualSize / 2
                      : 0,
            ),
            child: Container(
              width: visualSize,
              height: visualSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0066FF),
                  width: 2.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.bodyWidth;
    final h = widget.bodyHeight;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Border is exactly the same size as the image/text body.
        Positioned.fill(
          child: IgnorePointer(
            child: SizedBox(
              width: widget.bodyWidth,
              height: widget.bodyHeight,
              child: CustomPaint(
                painter: _EditorSelectionBorderPainter(
                  width: widget.bodyWidth,
                  height: widget.bodyHeight,
                  // Template pill/category buttons should get a rounded
                  // selection path. For other objects, the painter falls back
                  // to a small rounded rectangle.
                  borderRadius: widget.item.borderRadius.isFinite
                      ? widget.item.borderRadius
                      : 0,
                ),
              ),
            ),
          ),
        ),

        _handle(Alignment.topLeft),
        _handle(Alignment.topCenter),
        _handle(Alignment.topRight),
        _handle(Alignment.centerLeft),
        _handle(Alignment.centerRight),
        _handle(Alignment.bottomLeft),
        _handle(Alignment.bottomCenter),
        _handle(Alignment.bottomRight),

        // Rotation handle. Keep the gesture target INSIDE the selection box.
        // This is important on Flutter: a widget painted outside its parent's
        // bounds can be visible but will not reliably receive pointer events.
        // The 44px target occupies only the upper 22px of the box, so the
        // remaining top-center area is still available for resize.
        Positioned(
          left: w / 2 - 1,
          top: 0,
          width: 2,
          height: 24,
          child: IgnorePointer(
            child: Transform.translate(
              offset: const Offset(0, 20),
              child: const SizedBox(
                width: 2,
                height: 24,
                child: ColoredBox(color: Color(0xFF2196F3)),
              ),
            ),
          ),
        ),
        Positioned(
          left: w / 2 - 22,
          top: 0,
          width: 44,
          height: 22,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _beginRotation(d.globalPosition),
            onPanUpdate: (d) => _rotate(d.globalPosition),
            onPanEnd: (_) {},
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2196F3),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rotate_right_rounded,
                  size: 13,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
          ),
        ),

        // IMPORTANT: the visual 3-dot button may sit just outside the image,
        // but its hit target must remain INSIDE this Stack's bounds. Otherwise
        // Flutter's RenderBox hit testing sends the tap to the item underneath.
        // Keep the 3-dot button INSIDE the selected item's actual box.
        // If it is placed outside, the canvas ClipRect can hide it when a
        // large image reaches the canvas edge. The hit target is also kept
        // inside the same box so an overlapping item cannot steal the tap.
        // Canva-style Edit menu. Keep it inside the selected item so it
        // stays visible/tappable even when the item touches the canvas edge.
        // The top-right resize handle occupies the first 44px, so the menu
        // starts below it and does not steal the resize gesture.
        Positioned(
          right: 4,
          top: math.max(48.0, math.min(h - 56.0, h / 2.0 - 24.0)),
          width: 52,
          height: 52,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.provider.setSelectedItem(
                widget.item.type,
                widget.item.id,
              );
              // Open the complete item editor from the exact selected item.
              // Schedule it after the tap callback so the selection rebuild
              // cannot replace the hit-test tree while the tap is resolving.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                final latest = widget.provider.items.where(
                      (e) => e.id == widget.item.id,
                );
                if (latest.isEmpty) return;

                final host = EditableItemWidget(
                  item: latest.first,
                  onItemSelected: (_, __) {},
                );
                host._showProActionSheet(
                  context,
                  widget.provider,
                  latest.first,
                  isBackground: false,
                );
              });
            },
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2196F3),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF222222),
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorSelectionBorderPainter extends CustomPainter {
  final double width;
  final double height;
  final double borderRadius;

  const _EditorSelectionBorderPainter({
    required this.width,
    required this.height,
    this.borderRadius = 0,
  });

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      if (length <= 0) continue;

      // Larger, darker dots so the selection is clearly visible on white
      // template elements such as LIVING ROOM / BEDROOM / DINING / OFFICE.
      const double dotRadius = 1.8;
      const double step = 7.0;
      double distance = 0;

      while (distance <= length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, dotRadius, paint);
        }
        distance += step;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = math.max(1.0, size.width);
    final h = math.max(1.0, size.height);

    // For wide/short template buttons use a pill/rounded shape. This is what
    // makes the dotted selection follow the visible LIVING ROOM button instead
    // of drawing a sharp rectangular box around it.
    final radius = borderRadius > 0
        ? borderRadius.clamp(0.0, math.min(w, h) / 2).toDouble()
        : (w > h * 1.45 ? math.min(h / 2, 14.0) : 6.0);

    final inset = 2.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(1.0, w - inset * 2),
      math.max(1.0, h - inset * 2),
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = const Color(0xFF0066FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..isAntiAlias = true;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _EditorSelectionBorderPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _RotateThreeDotHandle extends StatefulWidget {
  final BuildContext parentContext;
  final EditorProvider provider;
  final EditorItem item;

  const _RotateThreeDotHandle({
    required this.parentContext,
    required this.provider,
    required this.item,
  });

  @override
  State<_RotateThreeDotHandle> createState() => _RotateThreeDotHandleState();
}

class _RotateThreeDotHandleState extends State<_RotateThreeDotHandle> {
  double? _startPointerAngle;
  double _startRotation = 0.0;

  Offset _parentLocal(Offset globalPosition) {
    final renderObject = widget.parentContext.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.globalToLocal(globalPosition);
    }
    return globalPosition;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.item.width ?? 220.0;
    final h = widget.item.height ?? 220.0;
    final center = Offset(w / 2, h / 2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        final p = _parentLocal(details.globalPosition);
        _startPointerAngle = math.atan2(p.dy - center.dy, p.dx - center.dx);
        _startRotation = widget.item.rotation.isFinite
            ? widget.item.rotation
            : 0.0;
      },
      onPanUpdate: (details) {
        final startAngle = _startPointerAngle;
        if (startAngle == null) return;

        final p = _parentLocal(details.globalPosition);
        final currentAngle = math.atan2(p.dy - center.dy, p.dx - center.dx);

        var delta = currentAngle - startAngle;

        // Keep the shortest angular path across the -pi/pi boundary.
        if (delta > math.pi) delta -= math.pi * 2;
        if (delta < -math.pi) delta += math.pi * 2;

        widget.provider.updateRotation(widget.item.id!, _startRotation + delta);
      },
      onPanEnd: (_) {
        _startPointerAngle = null;
      },
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RotateDot(),
              SizedBox(width: 2),
              _RotateDot(),
              SizedBox(width: 2),
              _RotateDot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RotateDot extends StatelessWidget {
  const _RotateDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 3,
      height: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

// 🚀 Hexagon Clipper
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width, h = size.height;
    path.moveTo(w / 2, h / 5);
    path.cubicTo(w * 5 / 6, 0, w, h / 3, w, h / 2);
    path.cubicTo(w, h * 3 / 4, w / 2, h, w / 2, h);
    path.cubicTo(w / 2, h, 0, h * 3 / 4, 0, h / 2);
    path.cubicTo(0, h / 3, w / 6, 0, w / 2, h / 5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width, h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w * 0.65, h * 0.35);
    path.lineTo(w, h * 0.4);
    path.lineTo(w * 0.75, h * 0.65);
    path.lineTo(w * 0.82, h);
    path.lineTo(w * 0.5, h * 0.8);
    path.lineTo(w * 0.18, h);
    path.lineTo(w * 0.25, h * 0.65);
    path.lineTo(0, h * 0.4);
    path.lineTo(w * 0.35, h * 0.35);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


double? _toFiniteDouble(dynamic value) {
  if (value is num) {
    final d = value.toDouble();
    return d.isFinite ? d : null;
  }
  final d = double.tryParse(value?.toString() ?? '');
  return d != null && d.isFinite ? d : null;
}

Color? _templateColor(dynamic value) {
  if (value == null) return null;
  if (value is Color) return value;
  if (value is num) return Color(value.toInt());
  if (value is Map) {
    return _templateColor(value['color'] ?? value['value'] ?? value['fill']);
  }
  var s = value.toString().trim().toLowerCase();
  if (s.isEmpty || s == 'none' || s == 'transparent') return Colors.transparent;
  if (s.startsWith('0x')) s = s.substring(2);
  if (s.startsWith('#')) s = s.substring(1);
  if (RegExp(r'^[0-9a-f]{3}$').hasMatch(s)) {
    s = s.split('').map((c) => '$c$c').join();
  }
  if (RegExp(r'^[0-9a-f]{6}$').hasMatch(s)) {
    return Color(int.parse('FF$s', radix: 16));
  }
  if (RegExp(r'^[0-9a-f]{8}$').hasMatch(s)) {
    return Color(int.parse(s, radix: 16));
  }
  final rgb = RegExp(r'^rgba?\s*\(([^)]+)\)$').firstMatch(s);
  if (rgb != null) {
    try {
      final parts = rgb.group(1)!.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 3) {
        double ch(String x) => x.endsWith('%')
            ? double.parse(x.substring(0, x.length - 1)) * 2.55
            : double.parse(x);
        final r = ch(parts[0]).round().clamp(0, 255);
        final g = ch(parts[1]).round().clamp(0, 255);
        final b = ch(parts[2]).round().clamp(0, 255);
        var a = 1.0;
        if (parts.length > 3) {
          a = parts[3].endsWith('%')
              ? double.parse(parts[3].substring(0, parts[3].length - 1)) / 100
              : double.parse(parts[3]);
        }
        return Color.fromRGBO(r, g, b, a.clamp(0.0, 1.0));
      }
    } catch (_) {}
  }
  const named = <String, Color>{
    'white': Colors.white, 'black': Colors.black, 'red': Colors.red,
    'green': Colors.green, 'blue': Colors.blue, 'yellow': Colors.yellow,
    'orange': Colors.orange, 'purple': Colors.purple, 'pink': Colors.pink,
    'brown': Colors.brown, 'grey': Colors.grey, 'gray': Colors.grey,
    'cyan': Colors.cyan, 'magenta': Color(0xFFFF00FF),
  };
  return named[s];
}

Gradient? _templateGradient(dynamic value) {
  if (value is! Map) return null;
  final stopsRaw = value['colorStops'];
  if (stopsRaw is! List) return null;
  final colors = <Color>[];
  final stops = <double>[];
  for (final entry in stopsRaw) {
    if (entry is! Map) continue;
    final c = _templateColor(entry['color']);
    final o = _toFiniteDouble(entry['offset']);
    if (c != null && o != null) {
      colors.add(c);
      stops.add(o.clamp(0.0, 1.0));
    }
  }
  if (colors.length < 2) return null;
  final type = value['type']?.toString().toLowerCase();
  if (type == 'radial') {
    return RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: colors,
      stops: stops,
    );
  }
  final coords = value['coords'];
  Alignment begin = Alignment.centerLeft;
  Alignment end = Alignment.centerRight;
  if (coords is Map) {
    final x1 = _toFiniteDouble(coords['x1']);
    final y1 = _toFiniteDouble(coords['y1']);
    final x2 = _toFiniteDouble(coords['x2']);
    final y2 = _toFiniteDouble(coords['y2']);
    if (x1 != null && y1 != null && x2 != null && y2 != null) {
      final normX = (v) => (v as double).clamp(0.0, 1.0) * 2 - 1;
      begin = Alignment(normX(x1), normX(y1));
      end = Alignment(normX(x2), normX(y2));
    }
  }
  return LinearGradient(begin: begin, end: end, colors: colors, stops: stops);
}

class FabricEllipsePainter extends CustomPainter {
  final Color fill;
  final Gradient? gradient;
  final Color? stroke;
  final double strokeWidth;
  FabricEllipsePainter({required this.fill, this.gradient, this.stroke, this.strokeWidth = 0});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    if (gradient != null) paint.shader = gradient!.createShader(rect); else paint.color = fill;
    canvas.drawOval(rect, paint);
    if (stroke != null && strokeWidth > 0) {
      canvas.drawOval(rect, Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..color = stroke!);
    }
  }
  @override bool shouldRepaint(covariant FabricEllipsePainter old) =>
      old.fill != fill || old.gradient != gradient || old.stroke != stroke || old.strokeWidth != strokeWidth;
}

class FabricGeometryPainter extends CustomPainter {
  final String type;
  final Map<String, dynamic> raw;
  final Color fill;
  final Gradient? gradient;
  final Color? stroke;
  final double strokeWidth;
  FabricGeometryPainter({required this.type, required this.raw, required this.fill, this.gradient, this.stroke, this.strokeWidth = 0});

  Path _pathFromFabric(Size size) {
    final path = Path();
    final data = raw['path'];
    if (data is! List) return path..addRect(Offset.zero & size);
    final points = <Offset>[];
    for (final command in data) {
      if (command is! List || command.isEmpty) continue;
      final cmd = command[0].toString().toUpperCase();
      double n(int i) => _toFiniteDouble(command.length > i ? command[i] : null) ?? 0;
      switch (cmd) {
        case 'M': path.moveTo(n(1), n(2)); points.add(Offset(n(1), n(2))); break;
        case 'L': path.lineTo(n(1), n(2)); points.add(Offset(n(1), n(2))); break;
        case 'C': path.cubicTo(n(1),n(2),n(3),n(4),n(5),n(6)); points.add(Offset(n(5),n(6))); break;
        case 'Q': path.quadraticBezierTo(n(1),n(2),n(3),n(4)); points.add(Offset(n(3),n(4))); break;
        case 'H': path.lineTo(n(1), 0); break;
        case 'V': path.lineTo(0, n(1)); break;
        case 'Z': path.close(); break;
      }
    }
    if (points.isEmpty) return path..addRect(Offset.zero & size);
    // Fabric path coordinates may be centered/negative. Normalize the path
    // into the object's width/height so the imported bounds remain intact.
    final minX = points.map((p) => p.dx).reduce(math.min);
    final maxX = points.map((p) => p.dx).reduce(math.max);
    final minY = points.map((p) => p.dy).reduce(math.min);
    final maxY = points.map((p) => p.dy).reduce(math.max);
    final w = math.max(1.0, maxX - minX);
    final h = math.max(1.0, maxY - minY);
    final sx = size.width / w;
    final sy = size.height / h;
    final tx = -minX * sx;
    final ty = -minY * sy;
    // dart:ui Path.transform expects a column-major 4x4 matrix.
    final matrix = Float64List.fromList(<double>[
      sx, 0, 0, 0,
      0, sy, 0, 0,
      0, 0, 1, 0,
      tx, ty, 0, 1,
    ]);
    return path.transform(matrix);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Path path;
    if (type == 'line') {
      final x1 = _toFiniteDouble(raw['x1']) ?? 0;
      final y1 = _toFiniteDouble(raw['y1']) ?? 0;
      final x2 = _toFiniteDouble(raw['x2']) ?? size.width;
      final y2 = _toFiniteDouble(raw['y2']) ?? size.height;
      path = Path()..moveTo(x1, y1)..lineTo(x2, y2);
    } else if (type == 'polygon' || type == 'polyline') {
      path = Path();
      final pts = raw['points'];
      if (pts is List && pts.isNotEmpty) {
        for (var i = 0; i < pts.length; i++) {
          final pt = pts[i];
          if (pt is! Map) continue;
          final x = _toFiniteDouble(pt['x']) ?? 0;
          final y = _toFiniteDouble(pt['y']) ?? 0;
          if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
        }
        if (type == 'polygon') path.close();
      }
    } else {
      path = _pathFromFabric(size);
    }
    final bounds = Offset.zero & size;
    final fillPaint = Paint()..style = PaintingStyle.fill;
    if (gradient != null) fillPaint.shader = gradient!.createShader(bounds); else fillPaint.color = fill;
    if (type != 'line' && type != 'polyline') canvas.drawPath(path, fillPaint);
    if (stroke != null && strokeWidth > 0) {
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..color = stroke!);
    }
  }
  @override bool shouldRepaint(covariant FabricGeometryPainter old) => true;
}

class ShapeClipper extends CustomClipper<Path> {
  final String shape;
  final double radius;
  ShapeClipper(this.shape, {this.radius = 16});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    final cx = w / 2;
    final cy = h / 2;
    final r = math.min(w, h) / 2;

    switch (shape) {
      case 'circle':
        p.addOval(Rect.fromLTWH(0, 0, w, h));
        break;
      case 'oval':
        p.addOval(Rect.fromLTWH(0, h * .12, w, h * .76));
        break;
      case 'rounded':
        p.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            Radius.circular(radius.clamp(0, math.min(w, h) / 2)),
          ),
        );
        break;
      case 'rectangle':
        p.addRect(Rect.fromLTWH(0, 0, w, h));
        break;
      case 'triangle':
        p.moveTo(cx, 0);
        p.lineTo(w, h);
        p.lineTo(0, h);
        p.close();
        break;
      case 'diamond':
        p.moveTo(cx, 0);
        p.lineTo(w, cy);
        p.lineTo(cx, h);
        p.lineTo(0, cy);
        p.close();
        break;
      case 'pentagon':
        _polygon(p, cx, cy, math.min(w, h) * .5, 5, -math.pi / 2);
        break;
      case 'hexagon':
        _polygon(p, cx, cy, math.min(w, h) * .5, 6, -math.pi / 2);
        break;
      case 'octagon':
        _polygon(p, cx, cy, math.min(w, h) * .5, 8, -math.pi / 8);
        break;
      case 'star':
        final outer = r;
        final inner = r * .42;
        for (var i = 0; i < 10; i++) {
          final rr = i.isEven ? outer : inner;
          final a = -math.pi / 2 + i * math.pi / 5;
          final x = cx + math.cos(a) * rr;
          final y = cy + math.sin(a) * rr;
          if (i == 0)
            p.moveTo(x, y);
          else
            p.lineTo(x, y);
        }
        p.close();
        break;
      case 'heart':
        p.moveTo(cx, h * .92);
        p.cubicTo(w * .08, h * .55, w * .05, h * .2, w * .28, h * .14);
        p.cubicTo(w * .42, h * .1, cx, h * .28, cx, h * .34);
        p.cubicTo(cx, h * .28, w * .58, h * .1, w * .72, h * .14);
        p.cubicTo(w * .95, h * .2, w * .92, h * .55, cx, h * .92);
        p.close();
        break;
      case 'arch':
        p.moveTo(0, h);
        p.lineTo(0, h * .48);
        p.arcTo(
          Rect.fromCircle(center: Offset(cx, h * .48), radius: w / 2),
          math.pi,
          -math.pi,
          false,
        );
        p.lineTo(w, h);
        p.close();
        break;
      case 'shield':
        p.moveTo(w * .08, h * .08);
        p.lineTo(w * .92, h * .08);
        p.lineTo(w * .9, h * .58);
        p.cubicTo(w * .82, h * .8, cx, h * .95, cx, h * .95);
        p.cubicTo(cx, h * .95, w * .18, h * .8, w * .1, h * .58);
        p.close();
        break;
      case 'crescent':
        final p = Path()..addOval(Rect.fromLTWH(0, 0, w, h));
        final cut = Path()
          ..addOval(Rect.fromLTWH(w * .35, -h * .05, w * .72, h * .85));
        return Path.combine(PathOperation.difference, p, cut);
      default:
        p.addRect(Rect.fromLTWH(0, 0, w, h));
    }
    return p;
  }

  void _polygon(
      Path p,
      double cx,
      double cy,
      double r,
      int sides,
      double rotation,
      ) {
    for (var i = 0; i < sides; i++) {
      final a = rotation + i * 2 * math.pi / sides;
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      if (i == 0)
        p.moveTo(x, y);
      else
        p.lineTo(x, y);
    }
    p.close();
  }

  @override
  bool shouldReclip(covariant ShapeClipper oldClipper) =>
      oldClipper.shape != shape || oldClipper.radius != radius;
}

class _ApiMaskImage extends StatefulWidget {
  final Widget image;
  final String maskUrl;
  final double width;
  final double height;
  final String outlineStyle;
  final Color outlineColor;
  final double outlineWidth;

  const _ApiMaskImage({
    required this.image,
    required this.maskUrl,
    required this.width,
    required this.height,
    this.outlineStyle = 'none',
    this.outlineColor = Colors.white,
    this.outlineWidth = 0,
  });

  @override
  State<_ApiMaskImage> createState() => _ApiMaskImageState();
}

class _ApiMaskImageState extends State<_ApiMaskImage> {
  ui.Image? _maskImage;
  bool _maskImageOwned = false;
  List<Offset> _outlinePoints = const [];

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  @override
  void didUpdateWidget(covariant _ApiMaskImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maskUrl != widget.maskUrl ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _disposeMask();
      _loadMask();
    }
  }

  void _disposeMask() {
    if (_maskImageOwned) {
      _maskImage?.dispose();
    }
    _maskImage = null;
    _maskImageOwned = false;
    _outlinePoints = const [];
  }

  bool _looksLikeSvg(String url) {
    final value = url.toLowerCase().split('?').first.split('#').first;
    return value.endsWith('.svg') || value.endsWith('.svgz');
  }

  /// Converts a normal black/white mask image into a real alpha mask.
  ///
  /// Many API mask assets are opaque JPG/PNG/SVG previews rather than files
  /// with transparency. A simple BlendMode.dstIn therefore has no visible
  /// effect because their alpha is 1.0 everywhere. We keep the original alpha
  /// and multiply it by luminance, so white becomes visible and black becomes
  /// transparent. If the asset is predominantly white, we invert luminance
  /// so black-on-white mask assets work too.
  Future<ui.Image> _createAlphaMask(
      ui.Image source,
      int targetWidth,
      int targetHeight,
      ) async {
    final src = Rect.fromLTWH(
      0,
      0,
      source.width.toDouble(),
      source.height.toDouble(),
    );
    final dst = Rect.fromLTWH(
      0,
      0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    );

    bool invert = false;
    try {
      final bytes = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes != null && bytes.lengthInBytes >= 4) {
        final data = bytes.buffer.asUint8List();
        double sum = 0;
        int count = 0;
        int opaqueCount = 0;
        for (int i = 0; i + 3 < data.length; i += 4) {
          final a = data[i + 3];
          if (a < 8) continue;
          final r = data[i];
          final g = data[i + 1];
          final b = data[i + 2];
          sum += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
          count++;
          if (a > 245) opaqueCount++;
        }
        if (count > 0) {
          final average = sum / count;
          // White-background/black-shape assets need inversion.
          invert = average > 0.62 && opaqueCount / count > 0.90;
        }
      }
    } catch (_) {
      // Fall back to normal white=visible behavior.
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Rect.fromLTWH(
      0,
      0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    );

    // Everything below is rendered into one off-screen layer so dstIn only
    // affects the mask layer, never the editor canvas/background.
    canvas.saveLayer(bounds, Paint());
    canvas.drawImageRect(
      source,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );

    final luminanceMatrix = invert
        ? const <double>[
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      -0.299, -0.587, -0.114, 0, 255,
    ]
        : const <double>[
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
    ];

    final alphaPaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..colorFilter = ColorFilter.matrix(luminanceMatrix)
      ..blendMode = BlendMode.dstIn;

    canvas.drawImageRect(source, src, dst, alphaPaint);
    canvas.restore();

    return recorder.endRecording().toImage(targetWidth, targetHeight);
  }

  Future<List<Offset>> _buildMaskOutlinePoints(ui.Image mask) async {
    if (widget.outlineStyle == 'none' || widget.outlineWidth <= 0) {
      return const [];
    }

    final data = await mask.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return const [];

    final bytes = data.buffer.asUint8List();
    final w = mask.width;
    final h = mask.height;
    final alpha = Uint8List(w * h);

    for (int i = 0, p = 0; i < alpha.length && p + 3 < bytes.length; i++, p += 4) {
      alpha[i] = bytes[p + 3];
    }

    final edges = <Offset>[];
    bool inside(int x, int y) =>
        x >= 0 && y >= 0 && x < w && y < h && alpha[y * w + x] > 20;

    // Find the outside edge of the actual mask silhouette.
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (!inside(x, y)) continue;
        if (!inside(x - 1, y) ||
            !inside(x + 1, y) ||
            !inside(x, y - 1) ||
            !inside(x, y + 1)) {
          edges.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }

    if (edges.isEmpty) return const [];

    final spacing = widget.outlineStyle == 'fine_dotted'
        ? math.max(2.0, widget.outlineWidth * 2.0)
        : widget.outlineStyle == 'dotted'
        ? math.max(3.0, widget.outlineWidth * 2.8)
        : widget.outlineStyle == 'dashed'
        ? math.max(5.0, widget.outlineWidth * 4.0)
        : math.max(0.8, widget.outlineWidth * 0.45);

    final selected = <Offset>[];
    final minDistanceSquared = spacing * spacing;
    for (final point in edges) {
      if (selected.every((p) => (p - point).distanceSquared >= minDistanceSquared)) {
        selected.add(point);
      }
    }
    return selected;
  }

  Future<void> _loadMask() async {
    final url = widget.maskUrl.trim();
    if (url.isEmpty) return;

    final targetWidth = math.max(1, widget.width.round());
    final targetHeight = math.max(1, widget.height.round());

    try {
      ui.Image sourceImage;

      if (_looksLikeSvg(url)) {
        final pictureInfo = await vg.loadPicture(
          SvgNetworkLoader(url),
          null,
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromLTWH(
            0,
            0,
            targetWidth.toDouble(),
            targetHeight.toDouble(),
          ),
        );
        final sourceWidth = pictureInfo.size.width <= 0
            ? targetWidth.toDouble()
            : pictureInfo.size.width;
        final sourceHeight = pictureInfo.size.height <= 0
            ? targetHeight.toDouble()
            : pictureInfo.size.height;

        canvas.scale(
          targetWidth / sourceWidth,
          targetHeight / sourceHeight,
        );
        canvas.drawPicture(pictureInfo.picture);

        sourceImage = await recorder.endRecording().toImage(
          targetWidth,
          targetHeight,
        );
        pictureInfo.picture.dispose();
      } else {
        final stream = NetworkImage(url).resolve(
          const ImageConfiguration(),
        );
        final completer = Completer<ui.Image>();
        late final ImageStreamListener listener;

        listener = ImageStreamListener(
              (ImageInfo info, bool _) {
            if (!completer.isCompleted) {
              completer.complete(info.image);
            }
            stream.removeListener(listener);
          },
          onError: (Object error, StackTrace? stack) {
            if (!completer.isCompleted) {
              completer.completeError(error, stack);
            }
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
        sourceImage = await completer.future;
      }

      final alphaMask = await _createAlphaMask(
        sourceImage,
        targetWidth,
        targetHeight,
      );

      // SVG source images are owned by us. Network ImageStream images are
      // framework-owned and must not be disposed here.
      if (_looksLikeSvg(url)) {
        sourceImage.dispose();
      }

      if (!mounted) {
        alphaMask.dispose();
        return;
      }

      final outlinePoints = await _buildMaskOutlinePoints(alphaMask);

      setState(() {
        _maskImage = alphaMask;
        _maskImageOwned = true;
        _outlinePoints = outlinePoints;
      });
    } catch (e, st) {
      debugPrint('API mask load failed: ${widget.maskUrl} - $e');
      debugPrint('$st');
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _disposeMask();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mask = _maskImage;

    if (mask == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.image,
      );
    }

    final masked = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return ui.ImageShader(
          mask,
          TileMode.clamp,
          TileMode.clamp,
          Float64List.fromList(const <double>[
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
          ]),
        );
      },
      child: widget.image,
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_outlinePoints.isNotEmpty)
            CustomPaint(
              painter: _MaskOutlinePainter(
                points: _outlinePoints,
                imageWidth: mask.width.toDouble(),
                imageHeight: mask.height.toDouble(),
                color: widget.outlineColor,
                width: widget.outlineWidth,
                style: widget.outlineStyle,
              ),
            ),
          masked,
        ],
      ),
    );
  }
}

class _MaskOutlinePainter extends CustomPainter {
  final List<Offset> points;
  final double imageWidth;
  final double imageHeight;
  final Color color;
  final double width;
  final String style;

  const _MaskOutlinePainter({
    required this.points,
    required this.imageWidth,
    required this.imageHeight,
    required this.color,
    required this.width,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || width <= 0 || style == 'none') return;

    final sx = size.width / imageWidth;
    final sy = size.height / imageHeight;
    final scale = math.min(sx, sy);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final radius = style == 'fine_dotted'
        ? math.max(0.8, width * .42) * scale
        : style == 'dotted'
        ? math.max(1.0, width * .62) * scale
        : math.max(1.0, width * .50) * scale;

    // The points come from the actual alpha-mask silhouette, so the outline
    // follows the cut-out image rather than the rectangular selection box.
    for (int i = 0; i < points.length; i++) {
      if (style == 'dashed') {
        final cycle = (i ~/ 3) % 2;
        if (cycle == 1) continue;
      }
      final p = Offset(points[i].dx * sx, points[i].dy * sy);
      canvas.drawCircle(p, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MaskOutlinePainter oldDelegate) =>
      oldDelegate.points != points ||
          oldDelegate.imageWidth != imageWidth ||
          oldDelegate.imageHeight != imageHeight ||
          oldDelegate.color != color ||
          oldDelegate.width != width ||
          oldDelegate.style != style;
}

class ShapeBorderPainter extends CustomPainter {
  final String shape;
  final double radius;
  final Color color;
  final double width;
  final String style;
  final String join;

  ShapeBorderPainter({
    required this.shape,
    required this.radius,
    required this.color,
    required this.width,
    this.style = 'solid',
    this.join = 'round',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0 || style == 'none') return;
    final path = ShapeClipper(shape, radius: radius).getClip(size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = style == 'dotted' || style == 'fine_dotted'
          ? StrokeCap.round
          : StrokeCap.butt
      ..strokeJoin = join == 'miter'
          ? StrokeJoin.miter
          : (join == 'bevel' ? StrokeJoin.bevel : StrokeJoin.round)
      ..color = color;

    if (style == 'solid') {
      canvas.drawPath(path, paint);
      return;
    }

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      double pos = 0;
      final bool dotted = style == 'dotted' || style == 'fine_dotted';
      final double dash = style == 'dashed'
          ? width * 4.5
          : width * (style == 'fine_dotted' ? 0.9 : 1.4);
      final double gap = style == 'dashed'
          ? width * 2.5
          : width * (style == 'fine_dotted' ? 1.6 : 2.2);

      while (pos < length) {
        final end = math.min(pos + dash, length);
        if (dotted) {
          final mid = (pos + end) / 2;
          final dot = metric.extractPath(
            math.max(0, mid - width * .45),
            math.min(length, mid + width * .45),
          );
          canvas.drawPath(dot, paint);
        } else {
          canvas.drawPath(metric.extractPath(pos, end), paint);
        }
        pos += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShapeBorderPainter oldDelegate) =>
      oldDelegate.shape != shape ||
          oldDelegate.radius != radius ||
          oldDelegate.color != color ||
          oldDelegate.width != width ||
          oldDelegate.style != style;
}

