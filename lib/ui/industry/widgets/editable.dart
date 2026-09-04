import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
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

    return KeyedSubtree(
      key: ValueKey(
        "${currentItem.id}_${currentItem.filterType}_${currentItem.rotation}_${currentItem.scale}_${currentItem.opacity}_${currentItem.position}_${currentItem.fontFamily}_${currentItem.fontSize}",
      ),
      child: GestureDetector(
        // IMPORTANT: only the actual item body moves. Resize/rotate handles
        // below have their own gesture detectors, so touching a handle never
        // bubbles into this pan handler.
        onPanUpdate: (details) {
          provider.updatePosition(
            currentItem.id!,
            currentItem.position + details.delta,
          );
        },
        onTapDown: (_) {
          onItemSelected(currentItem.type ?? '', currentItem.id!);
        },
        onTap: () {
          onItemSelected(currentItem.type ?? '', currentItem.id!);
        },
        child: Transform.rotate(
          angle: currentItem.rotation,
          child: Transform.scale(
            scale: currentItem.scale.clamp(0.01, 10.0),
            alignment: Alignment.center,
            child: SizedBox(
              width: currentItem.width ?? 220,
              height: currentItem.height ?? 220,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: currentItem.width ?? 220,
                    height: currentItem.height ?? 220,
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: const Color(0xFF2196F3), width: 2)
                          : Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: Opacity(
                      opacity: currentItem.opacity.clamp(0.0, 1.0),
                      child: _buildItemContent(currentItem, context),
                    ),
                  ),

                  // 8 resize handles + one bottom-center rotate handle.
                  // The handles are only shown for a selected, non-background
                  // item. Their visible dot is small, but the GestureDetector
                  // hit area is deliberately larger for reliable touch.
                  if (isSelected && !isBackground)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: false,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.topLeft,
                              isHorizontal: true,
                              isVertical: true,
                            ),
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.topCenter,
                              isHorizontal: false,
                              isVertical: true,
                            ),
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.topRight,
                              isHorizontal: true,
                              isVertical: true,
                            ),
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.centerLeft,
                              isHorizontal: true,
                              isVertical: false,
                            ),
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.centerRight,
                              isHorizontal: true,
                              isVertical: false,
                            ),
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.bottomLeft,
                              isHorizontal: true,
                              isVertical: true,
                            ),
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.bottomCenter,
                              isHorizontal: false,
                              isVertical: true,
                            ),
                            _buildResizeHandle(
                              context,
                              provider,
                              currentItem,
                              Alignment.bottomRight,
                              isHorizontal: true,
                              isVertical: true,
                            ),

                            // Rotate handle. Image, video, sticker and
                            // text all use the same bottom-center 3-dot
                            // control. The gesture keeps the initial angle so
                            // the first touch never causes a jump.
                            Positioned(
                              left: (currentItem.width ?? 220) / 2 - 22,
                              bottom: -48,
                              width: 44,
                              height: 44,
                              child: _RotateThreeDotHandle(
                                parentContext: context,
                                provider: provider,
                                item: currentItem,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    return widget._buildItemContent(item, context);
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

    Widget filtered = imageWidget;

    if (filter != null) {
      filtered = ColorFiltered(colorFilter: filter, child: filtered);
    }

    if (adjusted != null) {
      filtered = ColorFiltered(colorFilter: adjusted, child: filtered);
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

  Widget _buildItemContent(EditorItem item, BuildContext context) {
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

    if (item.type == 'image' || item.type == 'shape') {
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
                fit: BoxFit.contain,
                placeholderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              )
            : Image.file(
                File(localPath),
                width: item.width,
                height: item.height,
                fit: BoxFit.contain,
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
          fit: BoxFit.contain,
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
          fit: BoxFit.contain,
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

      // A remote shape already contains its own shape. Do not apply the
      // normal image rounded-mask to it.
      if (item.type == 'shape') {
        return _buildFilteredImage(item, imageWidget, context);
      }

      final editorProvider = context.read<EditorProvider>();
      final apiMaskUrl = editorProvider.imageMaskUrl(item.id ?? '');
      final hasApiMask = apiMaskUrl != null && apiMaskUrl.trim().isNotEmpty;

      // API masks belong to the image that opened the Image > MASK toolbar.
      // When a mask is selected, use the mask asset's alpha channel to clip
      // only this image. Do not use the mask name as a ShapeClipper name:
      // API mask names are arbitrary and are not built-in shapes.
      final Widget maskedImage = hasApiMask
          ? _ApiMaskImage(
              image: imageWidget,
              maskUrl: apiMaskUrl!,
              width: item.width ?? 220,
              height: item.height ?? 220,
            )
          : ClipPath(
              clipper: ShapeClipper(
                (item.text ?? 'rounded').toLowerCase(),
                radius: item.borderRadius,
              ),
              child: imageWidget,
            );

      final filteredImage = _buildFilteredImage(item, maskedImage, context);

      // API masks already define the final shape, so the normal shape border
      // painter is only used when no API mask is selected.
      if (hasApiMask) return filteredImage;

      final shape = (item.text ?? 'rounded').toLowerCase();
      return CustomPaint(
        foregroundPainter: ShapeBorderPainter(
          shape: shape,
          radius: item.borderRadius,
          color: item.outlineColor,
          width: item.outlineWidth,
        ),
        child: filteredImage,
      );
    }

    final editorProvider = context.read<EditorProvider>();
    final id = item.id ?? '';

    // TextAlign only has a visible effect when the Text widget has a
    // meaningful width. Previously text items had no width, so CENTER/RIGHT
    // appeared not to work. Give every text item a stable editable box.
    final textWidth = (item.width ?? 600.0).clamp(80.0, 1080.0).toDouble();
    final textHeight = (item.height ?? 180.0).clamp(40.0, 1080.0).toDouble();

    return SizedBox(
      width: textWidth,
      height: textHeight,
      child: Text(
        item.text ?? "",
        maxLines: null,
        softWrap: true,
        textAlign: editorProvider.textAlignment(id),
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontSize: item.fontSize,
          color: item.color ?? Colors.white,
          fontWeight: editorProvider.textWeight(id),
          fontStyle: editorProvider.textStyle(id),
          decoration: editorProvider.textUnderline(id)
              ? TextDecoration.underline
              : TextDecoration.none,
          letterSpacing: editorProvider.textLetterSpacing(id),
          height: editorProvider.textLineSpacing(id),
          fontFamily: (item.fontFamily ?? '').trim().isEmpty
              ? null
              : item.fontFamily!.trim(),
        ),
      ),
    );
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
                        _imageEditSlider('Brightness', brightness, -1, 1, (v) {
                          setModalState(() => brightness = v.clamp(-1.0, 1.0));
                          apply();
                        }, '${((brightness + 1) * 50).round()}'),
                        _imageEditSlider('Contrast', contrast, .5, 2, (v) {
                          setModalState(() => contrast = v.clamp(.5, 2.0));
                          apply();
                        }, '${(contrast * 50).round()}'),
                        _imageEditSlider('Saturation', saturation, 0, 2, (v) {
                          setModalState(() => saturation = v.clamp(0.0, 2.0));
                          apply();
                        }, '${(saturation * 50).round()}'),
                        const SizedBox(height: 14),
                        Center(
                          child: OutlinedButton(
                            onPressed: () {
                              filter = 'none';
                              filterIntensity = 1;
                              brightness = 0;
                              contrast = 1;
                              saturation = 1;
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
    String valueText,
  ) {
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
        Slider(min: min, max: max, value: safeValue, onChanged: onChanged),
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

  const _ApiMaskImage({
    required this.image,
    required this.maskUrl,
    required this.width,
    required this.height,
  });

  @override
  State<_ApiMaskImage> createState() => _ApiMaskImageState();
}

class _ApiMaskImageState extends State<_ApiMaskImage> {
  ui.Image? _maskImage;
  bool _maskImageOwned = false;

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  @override
  void didUpdateWidget(covariant _ApiMaskImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maskUrl != widget.maskUrl) {
      if (_maskImageOwned) {
        _maskImage?.dispose();
      }
      _maskImage = null;
      _maskImageOwned = false;
      _loadMask();
    }
  }

  bool _looksLikeSvg(String url) {
    final value = url.toLowerCase().split('?').first.split('#').first;
    return value.endsWith('.svg') || value.endsWith('.svgz');
  }

  Future<void> _loadMask() async {
    final url = widget.maskUrl.trim();
    if (url.isEmpty) return;

    try {
      if (_looksLikeSvg(url)) {
        final pictureInfo = await vg.loadPicture(SvgNetworkLoader(url), null);

        final targetWidth = math.max(1, widget.width.round());
        final targetHeight = math.max(1, widget.height.round());

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        );

        final sourceWidth = pictureInfo.size.width <= 0
            ? targetWidth.toDouble()
            : pictureInfo.size.width;
        final sourceHeight = pictureInfo.size.height <= 0
            ? targetHeight.toDouble()
            : pictureInfo.size.height;

        canvas.scale(targetWidth / sourceWidth, targetHeight / sourceHeight);
        canvas.drawPicture(pictureInfo.picture);

        final image = await recorder.endRecording().toImage(
          targetWidth,
          targetHeight,
        );

        pictureInfo.picture.dispose();

        if (!mounted) {
          image.dispose();
          return;
        }

        setState(() {
          _maskImage = image;
          _maskImageOwned = true;
        });
        return;
      }
      final stream = NetworkImage(url).resolve(const ImageConfiguration());
      final completer = Completer<ui.Image>();
      late final ImageStreamListener listener;

      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!completer.isCompleted) completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (Object error, StackTrace? stack) {
          if (!completer.isCompleted) completer.completeError(error, stack);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final image = await completer.future;
      if (!mounted) return;
      setState(() {
        _maskImage = image;
        _maskImageOwned = false;
      });
    } catch (e, st) {
      debugPrint('API mask load failed: ${widget.maskUrl} - $e');
      debugPrint('$st');
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    if (_maskImageOwned) {
      _maskImage?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mask = _maskImage;

    if (mask == null) {
      // Keep the selected image visible while the mask loads/fails.
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.image,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        foregroundPainter: _ApiMaskPainter(mask),
        child: widget.image,
      ),
    );
  }
}

class _ApiMaskPainter extends CustomPainter {
  final ui.Image maskImage;

  const _ApiMaskPainter(this.maskImage);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image first (CustomPaint child), then use the mask as dstIn.
    // This leaves the image visible only where the mask has alpha.
    final src = Rect.fromLTWH(
      0,
      0,
      maskImage.width.toDouble(),
      maskImage.height.toDouble(),
    );
    final dst = Offset.zero & size;

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..blendMode = BlendMode.dstIn;

    canvas.drawImageRect(maskImage, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _ApiMaskPainter oldDelegate) =>
      oldDelegate.maskImage != maskImage;
}

class ShapeBorderPainter extends CustomPainter {
  final String shape;
  final double radius;
  final Color color;
  final double width;
  ShapeBorderPainter({
    required this.shape,
    required this.radius,
    required this.color,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;
    final path = ShapeClipper(shape, radius: radius).getClip(size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ShapeBorderPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.width != width;
}
