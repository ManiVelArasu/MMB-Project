import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, mapEquals;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmb_app/ui/industry/widgets/text_effect.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

import '../../../Api Model/editor_model.dart';
import '../../../network/provider/editor_provider.dart';
import 'package:image/image.dart' as img;

import '../../screens/video_widget/editor_video.dart';
import '../../screens/video_widget/video_widget.dart';
import 'animation.dart';

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
    // FIX: Using Selector or Consumer instead of full build listen: true
    // prevents unnecessary tree deactivation conflicts during Dialog pop.
    return Selector<EditorProvider, _ItemViewState>(
      selector: (_, provider) {
        final currentItem = provider.items.firstWhere(
              (e) => e.id == item.id,
          orElse: () => item,
        );
        return _ItemViewState(
          currentItem: currentItem,
          isSelected: provider.selectedItemId == currentItem.id,
          flipX: provider.templateFlipX(currentItem.id ?? ''),
          flipY: provider.templateFlipY(currentItem.id ?? ''),
          filterIntensity: provider.imageFilterIntensity(currentItem.id ?? ''),
          tint: provider.imageTint(currentItem.id ?? ''),
          blur: provider.imageBlur(currentItem.id ?? ''),
          maskUrl: provider.imageMaskUrl(currentItem.id ?? ''),
          animation: provider.itemAnimation(currentItem.id ?? ''),
          animationTick: provider.animationPreviewTick(currentItem.id ?? ''),
          textEffect: provider.textEffect(currentItem.id ?? ''),
        );
      },
      builder: (context, state, child) {
        final currentItem = state.currentItem;
        final isSelected = state.isSelected;
        final provider = context.read<EditorProvider>();

        final isBackground = _isCanvasBackground(currentItem);
        final normalizedItemType = (currentItem.type ?? '')
            .trim()
            .toLowerCase();
        final isTextItem =
            normalizedItemType == 'text' ||
                normalizedItemType == 'textbox' ||
                normalizedItemType == 'i-text' ||
                normalizedItemType == 'itext';

        // Text is sized from its real measured layout (same helper the
        // selection overlay uses) so the rotation pivot, the blue box and the
        // handles always agree with what is drawn.
        final Size textBox = isTextItem
            ? measureTextBox(currentItem, provider)
            : Size.zero;
        final bodyWidth = isTextItem
            ? textBox.width
            : math.max(1.0, currentItem.width).toDouble();
        final bodyHeight = isTextItem
            ? textBox.height
            : math.max(1.0, currentItem.height).toDouble();

        // Fabric `clipPath` with absolutePositioned: the clip window is fixed
        // on the canvas while the image can be dragged/resized behind it.
        Map? absoluteClip;
        if (currentItem.type == 'image' && !isBackground) {
          final rawObject = provider.templateRawObject(currentItem.id ?? '');
          final clip = rawObject?['clipPath'];
          if (clip is Map &&
              clip['absolutePositioned'] == true &&
              clip['inverted'] != true) {
            absoluteClip = clip;
          }
        }

        final itemWidget = KeyedSubtree(
          key: ValueKey(currentItem.id),
          child: _MinTouchTarget(
            visualSize: Size(
              bodyWidth * currentItem.scale.clamp(0.01, 10.0),
              bodyHeight * currentItem.scale.clamp(0.01, 10.0),
            ),
            enabled: !isBackground,
            child: GestureDetector(
              // Whole text box is tappable (not only the glyph pixels).
              behavior: HitTestBehavior.opaque,
              // Press-and-drag moves the item directly (selects it first), so
              // small text needs no separate tap-then-drag.
              onPanStart: isBackground
                  ? null
                  : (_) {
                if (!isSelected) {
                  onItemSelected(currentItem.type ?? '', currentItem.id!);
                }
              },
              onPanUpdate: isBackground
                  ? null
                  : (d) {
                final id = currentItem.id ?? '';
                final idx = provider.items.indexWhere((e) => e.id == id);
                if (idx < 0) return;
                final box = context.findRenderObject();
                double k = 1.0;
                if (box is RenderBox && box.attached) {
                  k = box.getTransformTo(null).getMaxScaleOnAxis();
                }
                if (!k.isFinite || k <= 0) k = 1.0;
                provider.updateItemTransform(
                  id,
                  position: provider.items[idx].position + d.delta / k,
                  clampToFrame: false,
                );
              },
              onPanEnd: isBackground ? null : (_) => provider.commitTransform(),
              onPanCancel: isBackground ? null : () => provider.commitTransform(),
              // Single tap selects an element; double tap edits text.
              // Move/resize/rotate are handled by the selection overlay to avoid
              // competing gestures on the same canvas element.
              onTap: () {
                if (!isSelected) {
                  onItemSelected(currentItem.type ?? '', currentItem.id!);
                }
              },
              onDoubleTap: () {
                if (isTextItem && !isBackground) {
                  showTextEditor(
                    context,
                    provider,
                    currentItem.id!,
                    currentItem.text ?? '',
                  );
                }
              },
              child: Transform.scale(
                scale: currentItem.scale.clamp(0.01, 10.0),
                alignment: Alignment.topLeft,
                child: Transform.rotate(
                  angle: currentItem.rotation,
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scaleX: state.flipX ? -1 : 1,
                    scaleY: state.flipY ? -1 : 1,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: bodyWidth,
                      height: bodyHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: bodyWidth,
                            height: bodyHeight,
                            child: Opacity(
                              opacity: currentItem.opacity.clamp(0.0, 1.0),
                              child: _buildItemContent(
                                currentItem,
                                context,
                                isBackground: isBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Entrance / exit animation preview. Pivot = visual centre of item.
        final itemScale = currentItem.scale.clamp(0.01, 10.0).toDouble();
        Widget animated(Widget child) => AnimatedItemShell(
          animation: state.animation,
          previewTick: state.animationTick,
          pivot: Offset(
            bodyWidth * itemScale / 2,
            bodyHeight * itemScale / 2,
          ),
          child: child,
        );

        if (absoluteClip == null) return animated(itemWidget);
        return animated(
          ClipPath(
            clipper: _FabricAbsoluteClipper(absoluteClip, currentItem.position),
            child: itemWidget,
          ),
        );
      },
    );
  }

  static bool isTextType(String? type) {
    final t = (type ?? '').trim().toLowerCase();
    return t == 'text' || t == 'textbox' || t == 'i-text' || t == 'itext';
  }

  static bool isMultilineText(EditorItem item) {
    final v = item.text ?? '';
    return v.contains('\n') || v.contains('\r');
  }

  /// Exact TextStyle used to render a text item (also used for measuring).
  static TextStyle buildTextStyle(EditorItem item, EditorProvider provider) {
    final id = item.id ?? '';
    return _buildGoogleFontTextStyle(
      fontFamily: item.fontFamily,
      fontSize: item.fontSize,
      color: item.color ?? Colors.black,
      fontWeight: provider.textWeight(id),
      fontStyle: provider.textStyle(id),
      decoration: provider.textUnderline(id)
          ? TextDecoration.underline
          : TextDecoration.none,
      letterSpacing: provider.textLetterSpacing(id),
      height: provider.textLineSpacing(id),
    );
  }

  /// Un-scaled layout size of a text item, in canvas units. Single source of
  /// truth for both the rendered text box and the selection overlay.
  /// [widthOverride] lets a resize gesture ask "how tall would it be at this
  /// wrap width?" before committing it.
  static Size measureTextBox(
      EditorItem item,
      EditorProvider provider, {
        double? widthOverride,
      }) {
    // Curved text: the box must wrap the whole arc, not the flat text.
    final fx = provider.textEffect(item.id ?? '');
    if (fx.type == TextEffectType.curve) {
      final cs = curvedTextSize(
        item.text ?? '',
        buildTextStyle(item, provider),
        fx.curve,
      );
      return Size(math.max(1.0, cs.width), math.max(1.0, cs.height));
    }

    final multiline = isMultilineText(item);
    final boxWidth = widthOverride ?? item.width;
    final wrapWidth = multiline && boxWidth > 12.0 ? boxWidth : double.infinity;
    final painter = TextPainter(
      text: TextSpan(
        text: item.text ?? '',
        style: buildTextStyle(item, provider),
      ),
      maxLines: multiline ? null : 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: wrapWidth);
    final w = multiline && boxWidth > 12.0
        ? math.max(boxWidth, painter.width)
        : painter.width;
    return Size(math.max(1.0, w), math.max(1.0, painter.height));
  }

  static Widget buildStandaloneMediaContent(
      BuildContext context,
      EditorItem item,
      ) {
    final widget = EditableItemWidget(item: item, onItemSelected: (_, __) {});
    return widget._buildItemContent(item, context, isBackground: true);
  }

  static Future<void> showTextEditor(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      String initialText,
      ) async {
    final matchingItems = provider.items.where((e) => e.id == itemId);

    if (itemId.isEmpty || matchingItems.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Please select a text item first.')),
        );
      }
      return;
    }

    final selectedItem = matchingItems.first;

    // Controller creation
    final controller = TextEditingController(
      text: selectedItem.text ?? initialText,
    );

    String? savedText;

    // FIX: Remove manual controller.dispose() entirely inside try/finally.
    // Let the Dialog and Flutter widgets clean up naturally without triggering
    // the "used after being disposed" assertion error during exit animations.
    savedText = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text(
            'Edit Text',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Type text here...',
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
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text(
                'Save',
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

    if (!context.mounted || savedText == null) return;

    final stillExists = provider.items.any((e) => e.id == itemId);

    if (!stillExists) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('This text item no longer exists.')),
        );
      }
      return;
    }

    provider.updateTextContent(itemId, savedText);
  }

  bool _isCanvasBackground(EditorItem item) {
    return item.position.dx == 0 &&
        item.position.dy == 0 &&
        (item.width ?? 0) >= 1000 &&
        (item.height ?? 0) >= 1000 &&
        (item.type == 'image' || item.type == 'video' || item.type == 'shape');
  }

  static TextStyle _buildGoogleFontTextStyle({
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

    final rawFamily = (fontFamily ?? '').trim();
    if (rawFamily.isEmpty) return base;

    final family = rawFamily
        .split(',')
        .first
        .trim()
        .replaceAll(RegExp(r'''^["']|["']$'''), '')
        .trim();
    if (family.isEmpty) return base;

    try {
      return GoogleFonts.getFont(family, textStyle: base);
    } catch (_) {
      return base.copyWith(fontFamily: family);
    }
  }

  List<double> _identityMatrix() => const <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  List<double> _mixMatrices(List<double> a, List<double> b, double amount) {
    return List<double>.generate(
      20,
          (i) => a[i] + (b[i] - a[i]) * amount,
      growable: false,
    );
  }

  List<double> _adjustmentMatrix({
    required double brightness,
    required double contrast,
    required double saturation,
  }) {
    final b = brightness.clamp(-1.0, 1.0) * 255.0;
    final c = contrast.clamp(0.0, 3.0);
    final s = saturation.clamp(0.0, 3.0);
    final sr = 0.2126 * (1.0 - s);
    final sg = 0.7152 * (1.0 - s);
    final sb = 0.0722 * (1.0 - s);
    // Saturation/luminance matrix with contrast and brightness applied.
    return <double>[
      (sr + s) * c,
      sg * c,
      sb * c,
      0,
      b + 128 * (1 - c),
      sr * c,
      (sg + s) * c,
      sb * c,
      0,
      b + 128 * (1 - c),
      sr * c,
      sg * c,
      (sb + s) * c,
      0,
      b + 128 * (1 - c),
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double>? _matrixForFilter(String filter) {
    switch (filter.toLowerCase()) {
      case 'festive':
      case 'summer':
        return const <double>[
          // Strong warm/golden treatment so Festive is visibly different
          // from Normal, including on mostly grey product photos.
          1.22,
          0,
          0,
          0,
          24,
          0,
          1.08,
          0,
          0,
          8,
          0,
          0,
          0.58,
          0,
          -6,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'drama':
        return const <double>[
          1.18,
          0,
          0,
          0,
          0,
          0,
          0.86,
          0,
          0,
          0,
          0,
          0,
          1.18,
          0,
          8,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'cali':
        return const <double>[
          0.88,
          0,
          0,
          0,
          12,
          0,
          0.94,
          0,
          0,
          8,
          0,
          0,
          0.82,
          0,
          4,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'epic':
        return const <double>[
          1.12,
          0,
          0,
          0,
          0,
          0,
          1.08,
          0,
          0,
          0,
          0,
          0,
          1.02,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'street':
      case 'retro':
        return const <double>[
          0.92,
          0,
          0,
          0,
          10,
          0,
          0.86,
          0,
          0,
          5,
          0,
          0,
          0.72,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'grayscale':
        return const <double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'rosie':
      case 'whimsical':
        return const <double>[
          1.02,
          0,
          0,
          0,
          8,
          0,
          0.90,
          0,
          0,
          0,
          0,
          0,
          1.08,
          0,
          10,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'edge':
        return const <double>[
          1.25,
          0,
          0,
          0,
          0,
          0,
          1.25,
          0,
          0,
          0,
          0,
          0,
          1.25,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'nordic':
      case 'blues':
        return const <double>[
          0.88,
          0,
          0,
          0,
          0,
          0,
          0.96,
          0,
          0,
          3,
          0,
          0,
          1.18,
          0,
          12,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'selfie':
        return const <double>[
          1.08,
          0,
          0,
          0,
          8,
          0,
          1.02,
          0,
          0,
          4,
          0,
          0,
          0.92,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'normal':
      case '':
      default:
        return null;
    }
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

    if (item.type == 'shape') {
      final provider = context.read<EditorProvider>();
      final raw = provider.templateRawObject(item.id ?? '');
      if (raw == null) return const SizedBox.shrink();
      return SizedBox.expand(
        child: CustomPaint(
          painter: _FabricShapePainter(raw, fillColor: item.color),
        ),
      );
    }

    if (item.type == 'image' || item.type == 'shape') {
      final source = (item.contentUrl ?? '').trim();

      if (source.isEmpty) {
        return const SizedBox.shrink();
      }

      final isHttp =
          source.startsWith('http://') || source.startsWith('https://');

      final image = isHttp
          ? Image.network(
        source,
        fit: isBackground ? BoxFit.cover : BoxFit.fill,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, error, stackTrace) {
          debugPrint('Background image error: $error');
          return const SizedBox.shrink();
        },
      )
          : Image.file(
        File(
          source.startsWith('file://')
              ? source.replaceFirst('file://', '')
              : source,
        ),
        fit: isBackground ? BoxFit.cover : BoxFit.fill,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, error, stackTrace) {
          debugPrint('Local image error: $error');
          return const SizedBox.shrink();
        },
      );

      final provider = context.read<EditorProvider>();
      final id = item.id ?? '';
      final intensity = provider.imageFilterIntensity(id).clamp(0.0, 1.0);
      final tint = provider.imageTint(id).clamp(-100.0, 100.0);
      final blur = provider.imageBlur(id).clamp(0.0, 20.0);

      Widget rendered = image;

      final preset = _matrixForFilter(item.filterType);
      if (preset != null && intensity > 0.001) {
        final matrix = _mixMatrices(_identityMatrix(), preset, intensity);
        rendered = ColorFiltered(
          colorFilter: ColorFilter.matrix(matrix),
          child: rendered,
        );
      }

      // Brightness, contrast and saturation are independent adjustments.
      final brightness = item.brightness;
      final contrast = item.contrast;
      final saturation = item.saturation;
      final adjustmentMatrix = _adjustmentMatrix(
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
      );
      rendered = ColorFiltered(
        colorFilter: ColorFilter.matrix(adjustmentMatrix),
        child: rendered,
      );

      if (tint.abs() > 0.01) {
        final tintColor = tint >= 0
            ? Color.fromARGB(255, 255, 90, 35)
            : Color.fromARGB(255, 35, 110, 255);
        rendered = ColorFiltered(
          colorFilter: ColorFilter.mode(
            tintColor.withValues(alpha: tint.abs() / 100.0 * 0.45),
            BlendMode.color,
          ),
          child: rendered,
        );
      }

      if (blur > 0.01) {
        rendered = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: rendered,
        );
      }

      final maskUrl = provider.imageMaskUrl(id);
      if (maskUrl != null && maskUrl.trim().isNotEmpty) {
        rendered = _NetworkAlphaMask(maskUrl: maskUrl, child: rendered);
      }

      // Fabric.js `clipPath` that moves WITH the image (not absolutePositioned).
      // Canvas-fixed clips are applied in build() instead, so dragging the
      // image slides it behind a fixed window like the web editor does.
      if (!isBackground) {
        final rawObject = provider.templateRawObject(id);
        final clip = rawObject?['clipPath'];
        if (rawObject != null &&
            clip is Map &&
            clip['inverted'] != true &&
            clip['absolutePositioned'] != true) {
          rendered = ClipPath(
            clipper: _FabricClipPathClipper(rawObject, clip),
            child: rendered,
          );
        }
      }

      return SizedBox.expand(child: rendered);
    }

    if (item.type == 'svg_group' || item.type == 'svg_element') {
      final source = (item.contentUrl ?? '').trim();

      if (source.isEmpty) {
        return const SizedBox.shrink();
      }

      final isImageUrl = RegExp(
        r'\.(png|jpe?g|webp|gif)(\?.*)?$',
        caseSensitive: false,
      ).hasMatch(source);

      if (isImageUrl) {
        return Image.network(
          source,
          width: item.width,
          height: item.height,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const Center(
              child: CircularProgressIndicator(strokeWidth: 1.5),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Sticker load failed: $source | $error');
            return const Icon(Icons.broken_image);
          },
        );
      }

      return svg.SvgPicture.string(
        source,
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
      );
    }

    final editorProvider = context.read<EditorProvider>();
    final id = item.id ?? '';

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

    // Text effects (outline / text box / shadow / curve / reflection /
    // echo / glitch). With no effect this is the plain Text widget.
    final textWidget = buildTextWithEffect(
      effect: editorProvider.textEffect(id),
      text: textValue,
      style: textStyle,
      multiline: isMultiline,
      textAlign: editorProvider.textAlignment(id),
    );

    // For single-line text, do not force a narrow width that causes wrapping.
    // For multiline text, respect the item width.
    final isCurved = editorProvider.textEffect(id).type == TextEffectType.curve;
    final renderWidth = isMultiline && !isCurved
        ? math.max(12.0, item.width)
        : double.infinity;

    return SizedBox(
      width: isMultiline && !isCurved ? renderWidth : null,
      child: Align(
        alignment: switch (editorProvider.textAlignment(id)) {
          TextAlign.center => Alignment.topCenter,
          TextAlign.right => Alignment.topRight,
          TextAlign.justify => Alignment.topLeft,
          _ => Alignment.topLeft,
        },
        child: textWidget,
      ),
    );
  }
}

/// Keeps the hit area of an item at least ~48 logical px (on screen) so tiny
/// text/stickers are easy to touch. Hits inside the enlarged zone are clamped
/// into the child so its gesture detector still receives them.
class _MinTouchTarget extends SingleChildRenderObjectWidget {
  const _MinTouchTarget({
    required this.visualSize,
    required this.enabled,
    required super.child,
  });

  final Size visualSize;
  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinTouchTarget(visualSize, enabled);

  @override
  void updateRenderObject(
      BuildContext context,
      covariant _RenderMinTouchTarget renderObject,
      ) {
    renderObject
      ..visualSize = visualSize
      ..enabled = enabled;
  }
}

class _RenderMinTouchTarget extends RenderProxyBox {
  _RenderMinTouchTarget(this.visualSize, this.enabled);

  Size visualSize;
  bool enabled;
  static const double _minScreen = 48.0;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!enabled || child == null) {
      return super.hitTest(result, position: position);
    }
    double k = 1.0;
    try {
      k = getTransformTo(null).getMaxScaleOnAxis();
    } catch (_) {}
    if (!k.isFinite || k <= 0) k = 1.0;
    final w = math.max(size.width, visualSize.width);
    final h = math.max(size.height, visualSize.height);
    final extraX = math.max(0.0, (_minScreen / k - w) / 2);
    final extraY = math.max(0.0, (_minScreen / k - h) / 2);
    final zone = Rect.fromLTRB(-extraX, -extraY, w + extraX, h + extraY);
    if (!zone.contains(position)) return false;
    final clamped = Offset(
      position.dx.clamp(0.0, size.width).toDouble(),
      position.dy.clamp(0.0, size.height).toDouble(),
    );
    return child!.hitTest(result, position: clamped);
  }
}

class _ItemViewState {
  final EditorItem currentItem;
  final bool isSelected;
  final bool flipX;
  final bool flipY;
  final double filterIntensity;
  final double tint;
  final double blur;
  final String? maskUrl;
  final ItemAnimation animation;
  final int animationTick;
  final TextEffect textEffect;

  _ItemViewState({
    required this.currentItem,
    required this.isSelected,
    required this.flipX,
    required this.flipY,
    required this.filterIntensity,
    required this.tint,
    required this.blur,
    required this.maskUrl,
    required this.animation,
    required this.animationTick,
    required this.textEffect,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _ItemViewState &&
              runtimeType == other.runtimeType &&
              currentItem == other.currentItem &&
              isSelected == other.isSelected &&
              flipX == other.flipX &&
              flipY == other.flipY &&
              filterIntensity == other.filterIntensity &&
              tint == other.tint &&
              blur == other.blur &&
              maskUrl == other.maskUrl &&
              animation == other.animation &&
              animationTick == other.animationTick &&
              textEffect == other.textEffect;

  @override
  int get hashCode => Object.hash(
    currentItem,
    isSelected,
    flipX,
    flipY,
    filterIntensity,
    tint,
    blur,
    maskUrl,
    animation,
    animationTick,
    textEffect,
  );
}

/// Applies a transparent PNG mask to the image content without changing the
/// canvas item geometry or selection overlay.
class _NetworkAlphaMask extends StatefulWidget {
  final String maskUrl;
  final Widget child;

  const _NetworkAlphaMask({required this.maskUrl, required this.child});

  @override
  State<_NetworkAlphaMask> createState() => _NetworkAlphaMaskState();
}

class _NetworkAlphaMaskState extends State<_NetworkAlphaMask> {
  ui.Image? _maskImage;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolveMask();
  }

  @override
  void didUpdateWidget(covariant _NetworkAlphaMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maskUrl != widget.maskUrl) {
      _removeListener();
      _maskImage?.dispose();
      _maskImage = null;
      _failed = false;
      _resolveMask();
    }
  }

  Future<void> _resolveMask() async {
    try {
      final uri = Uri.tryParse(widget.maskUrl);
      if (uri == null ||
          !uri.hasScheme ||
          !(uri.scheme == 'http' || uri.scheme == 'https')) {
        throw const FormatException('Mask URL is not a valid HTTP(S) URL');
      }

      // Fetch the bytes directly instead of using NetworkImage's platform
      // decoder. Some CDN mask assets are served in formats the Android image
      // decoder cannot decode. Re-encode supported raster formats as PNG.
      final client = HttpClient();
      Uint8List bytes;
      try {
        final request = await client.getUrl(uri);
        request.headers.set(
          HttpHeaders.acceptHeader,
          'image/png,image/jpeg,image/webp,image/*,*/*;q=0.8',
        );
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Mask request failed with HTTP ${response.statusCode}',
            uri: uri,
          );
        }
        bytes = await consolidateHttpClientResponseBytes(response);
      } finally {
        client.close(force: true);
      }

      // CDN mask assets may be SVG or raster images. Convert either format
      // into a ui.Image so the same alpha-mask shader can render it.
      final trimmedText = utf8.decode(bytes, allowMalformed: true).trimLeft();
      final isSvg =
          trimmedText.startsWith('<svg') ||
              (trimmedText.startsWith('<?xml') && trimmedText.contains('<svg')) ||
              trimmedText.startsWith('<!DOCTYPE svg');

      ui.Image decodedImage;
      if (isSvg) {
        final svgText = utf8.decode(bytes, allowMalformed: false);
        final pictureInfo = await svg.vg.loadPicture(
          svg.SvgStringLoader(svgText),
          null,
        );
        try {
          final width = pictureInfo.size.width.ceil().clamp(1, 4096).toInt();
          final height = pictureInfo.size.height.ceil().clamp(1, 4096).toInt();
          decodedImage = await pictureInfo.picture.toImage(width, height);
        } finally {
          pictureInfo.picture.dispose();
        }
      } else {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          final preview = utf8
              .decode(bytes.take(180).toList(), allowMalformed: true)
              .replaceAll(RegExp(r'\\s+'), ' ');
          throw FormatException(
            'Mask response is not SVG or a supported raster image. '
                'Response begins with: $preview',
          );
        }
        final pngBytes = Uint8List.fromList(img.encodePng(decoded));
        final codec = await ui.instantiateImageCodec(pngBytes);
        try {
          final frame = await codec.getNextFrame();
          decodedImage = frame.image;
        } finally {
          codec.dispose();
        }
      }

      if (!mounted) {
        decodedImage.dispose();
        return;
      }
      setState(() {
        _maskImage?.dispose();
        _maskImage = decodedImage;
        _failed = false;
      });
    } catch (error, stackTrace) {
      if (mounted) setState(() => _failed = true);
      debugPrint('Image mask load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _removeListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _removeListener();
    _maskImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mask = _maskImage;
    // On failure keep the original image visible rather than hiding the canvas.
    if (mask == null || _failed) return widget.child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        final sx = bounds.width / mask.width;
        final sy = bounds.height / mask.height;
        return ImageShader(
          mask,
          TileMode.clamp,
          TileMode.clamp,
          Float64List.fromList(<double>[
            sx,
            0,
            0,
            0,
            0,
            sy,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
          ]),
          filterQuality: FilterQuality.medium,
        );
      },
      child: widget.child,
    );
  }
}

/// Renders Fabric.js Rect, Circle and Path objects imported from a template.
class _FabricShapePainter extends CustomPainter {
  _FabricShapePainter(this.raw, {this.fillColor});
  final Map<String, dynamic> raw;
  final Color? fillColor;

  double _n(dynamic v, [double fallback = 0]) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;

  Color? _c(dynamic value) {
    if (value is Color) return value;
    if (value == null ||
        value == '' ||
        value.toString().toLowerCase() == 'transparent' ||
        value.toString().toLowerCase() == 'none')
      return null;
    final s = value.toString().trim();
    final m = RegExp(
      r'rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)',
    ).firstMatch(s);
    if (m != null) {
      final a = (_n(m.group(4), 1).clamp(0.0, 1.0) * 255).round();
      return Color.fromARGB(
        a,
        _n(m.group(1)).round().clamp(0, 255),
        _n(m.group(2)).round().clamp(0, 255),
        _n(m.group(3)).round().clamp(0, 255),
      );
    }
    const named = <String, Color>{
      'white': Colors.white,
      'black': Colors.black,
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'grey': Colors.grey,
      'gray': Colors.grey,
    };
    final namedColor = named[s.toLowerCase()];
    if (namedColor != null) return namedColor;
    var h = s.replaceFirst('#', '');
    if (h.startsWith('0x')) h = h.substring(2);
    if (h.length == 6) h = 'FF$h';
    final valueInt = h.length == 8 ? int.tryParse(h, radix: 16) : null;
    return valueInt == null ? null : Color(valueInt);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = _n(raw['width'], size.width).abs();
    final h = _n(raw['height'], size.height).abs();
    if (w <= 0 || h <= 0 || size.isEmpty) return;
    final sx = size.width / w, sy = size.height / h;
    canvas.save();
    canvas.scale(sx, sy);
    // Prefer the live model colour so picker changes repaint immediately,
    // even when the template's original fill format is not a hex string.
    final fill = fillColor ?? _c(raw['fill']);
    final stroke = _c(raw['stroke']);
    final sw = _n(raw['strokeWidth']) / math.max(0.01, (sx + sy) / 2);
    final fp = Paint()..style = PaintingStyle.fill;
    final sp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;
    final type = (raw['type'] ?? '').toString().toLowerCase();

    if (type == 'circle' || type == 'ellipse') {
      final r = Rect.fromLTWH(0, 0, w, h);
      if (fill != null) canvas.drawOval(r, fp..color = fill);
      if (stroke != null && sw > 0)
        canvas.drawOval(r.deflate(sw / 2), sp..color = stroke);
    } else if (type == 'rect' || type == 'rectangle') {
      final rx = _n(raw['rx']).clamp(0.0, w / 2);
      final ry = _n(raw['ry'], rx).clamp(0.0, h / 2);
      final path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            Radius.elliptical(rx, ry),
          ),
        );
      if (fill != null) canvas.drawPath(path, fp..color = fill);
      if (stroke != null && sw > 0) canvas.drawPath(path, sp..color = stroke);
    } else if (type == 'path' && raw['path'] is List) {
      final path = Path();
      Offset? start;
      for (final entry in raw['path'] as List) {
        if (entry is! List || entry.isEmpty) continue;
        final cmd = entry.first.toString().toUpperCase();
        double v(int i) => i < entry.length ? _n(entry[i]) : 0;
        switch (cmd) {
          case 'M':
            path.moveTo(v(1), v(2));
            start = Offset(v(1), v(2));
            break;
          case 'L':
            path.lineTo(v(1), v(2));
            break;
          case 'C':
            path.cubicTo(v(1), v(2), v(3), v(4), v(5), v(6));
            break;
          case 'Q':
            path.quadraticBezierTo(v(1), v(2), v(3), v(4));
            break;
          case 'Z':
            path.close();
            break;
        }
      }
      if (fill != null) canvas.drawPath(path, fp..color = fill);
      if (stroke != null && sw > 0) canvas.drawPath(path, sp..color = stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FabricShapePainter oldDelegate) =>
      !mapEquals(oldDelegate.raw, raw) || oldDelegate.fillColor != fillColor;
}

/// Applies a Fabric.js `clipPath` (rect / circle / ellipse / path) to an image
/// so the app crops it exactly like the web editor does.
///
/// Fabric positions a clipPath in the object's own un-scaled, centre-origin
/// coordinate space (or in canvas space when `absolutePositioned` is true).
/// We build the clip shape there and map that space onto the widget box.
class _FabricClipPathClipper extends CustomClipper<Path> {
  _FabricClipPathClipper(this.object, this.clip);

  final Map object;
  final Map clip;

  static double _n(dynamic v, [double fallback = 0]) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;

  /// 0 = left/top, 0.5 = centre, 1 = right/bottom.
  static double _origin(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    switch ('$v') {
      case 'center':
        return 0.5;
      case 'right':
      case 'bottom':
        return 1;
      case 'left':
      case 'top':
        return 0;
    }
    return fallback;
  }

  /// Matrix placing a Fabric object (centre-origin local space) into its parent.
  static Matrix4 _placement(Map o, double w, double h) {
    final sx = _n(o['scaleX'], 1);
    final sy = _n(o['scaleY'], 1);
    final angle = _n(o['angle']) * math.pi / 180;
    final ox = _origin(o['originX'], 0);
    final oy = _origin(o['originY'], 0);
    // Offset from the origin point to the object's centre, then rotated.
    final dx = (0.5 - ox) * w * sx;
    final dy = (0.5 - oy) * h * sy;
    final cosA = math.cos(angle), sinA = math.sin(angle);
    final cx = _n(o['left']) + dx * cosA - dy * sinA;
    final cy = _n(o['top']) + dx * sinA + dy * cosA;
    return Matrix4.translationValues(cx, cy, 0)
      ..rotateZ(angle)
      ..scale(sx, sy, 1);
  }

  static Path _buildPath(Map c, void Function(double w, double h) setSize) {
    final type = (c['type'] ?? '').toString().toLowerCase();
    if (type == 'circle') {
      final r = _n(c['radius']);
      setSize(r * 2, r * 2);
      return Path()..addOval(
        Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2),
      );
    }
    if (type == 'ellipse') {
      final rx = _n(c['rx']), ry = _n(c['ry']);
      setSize(rx * 2, ry * 2);
      return Path()..addOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      );
    }
    if (type == 'path' && c['path'] is List) {
      final p = Path();
      double x = 0, y = 0, sx0 = 0, sy0 = 0;
      for (final e in c['path'] as List) {
        if (e is! List || e.isEmpty) continue;
        final cmd = e.first.toString();
        final rel = cmd == cmd.toLowerCase();
        double v(int i) => i < e.length ? _n(e[i]) : 0;
        switch (cmd.toUpperCase()) {
          case 'M':
            x = rel ? x + v(1) : v(1);
            y = rel ? y + v(2) : v(2);
            sx0 = x;
            sy0 = y;
            p.moveTo(x, y);
            break;
          case 'L':
            x = rel ? x + v(1) : v(1);
            y = rel ? y + v(2) : v(2);
            p.lineTo(x, y);
            break;
          case 'H':
            x = rel ? x + v(1) : v(1);
            p.lineTo(x, y);
            break;
          case 'V':
            y = rel ? y + v(1) : v(1);
            p.lineTo(x, y);
            break;
          case 'C':
            final ax = rel ? x : 0.0, ay = rel ? y : 0.0;
            p.cubicTo(
              ax + v(1),
              ay + v(2),
              ax + v(3),
              ay + v(4),
              ax + v(5),
              ay + v(6),
            );
            x = ax + v(5);
            y = ay + v(6);
            break;
          case 'Q':
            final qx = rel ? x : 0.0, qy = rel ? y : 0.0;
            p.quadraticBezierTo(qx + v(1), qy + v(2), qx + v(3), qy + v(4));
            x = qx + v(3);
            y = qy + v(4);
            break;
          case 'Z':
            p.close();
            x = sx0;
            y = sy0;
            break;
        }
      }
      final bounds = p.getBounds();
      final w = _n(c['width'], bounds.width);
      final h = _n(c['height'], bounds.height);
      setSize(w, h);
      // Fabric draws a path shifted by -pathOffset (its bbox centre).
      final po = c['pathOffset'];
      final pox = po is Map ? _n(po['x'], bounds.center.dx) : bounds.center.dx;
      final poy = po is Map ? _n(po['y'], bounds.center.dy) : bounds.center.dy;
      return p.shift(Offset(-pox, -poy));
    }
    // rect (default)
    final w = _n(c['width']), h = _n(c['height']);
    setSize(w, h);
    final rx = _n(c['rx']).clamp(0.0, w / 2);
    final ry = _n(c['ry'], rx).clamp(0.0, h / 2);
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Radius.elliptical(rx, ry),
      ),
    );
  }

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Offset.zero & size);
    try {
      final ow = _n(object['width'], size.width).abs();
      final oh = _n(object['height'], size.height).abs();
      if (ow <= 0 || oh <= 0 || size.isEmpty) return full;

      double cw = 0, ch = 0;
      final shape = _buildPath(clip, (w, h) {
        cw = w;
        ch = h;
      });

      // clip -> image-local space (clip moves with the image)
      final m = _placement(clip, cw, ch);

      // local (centre-origin, ow x oh) -> widget box
      final toWidget = Matrix4.diagonal3Values(
        size.width / ow,
        size.height / oh,
        1,
      )..translate(ow / 2, oh / 2);

      final result = shape.transform((toWidget * m).storage);
      final b = result.getBounds();
      // Fail open: a degenerate clip must never hide the whole image.
      if (b.isEmpty || !b.overlaps(Offset.zero & size)) return full;
      return result;
    } catch (_) {
      return full;
    }
  }

  @override
  bool shouldReclip(covariant _FabricClipPathClipper oldClipper) =>
      !identical(oldClipper.clip, clip) ||
          !identical(oldClipper.object, object);
}

/// Fabric `clipPath` with `absolutePositioned: true`: the clip window lives in
/// canvas coordinates and stays put while the image is moved, scaled or rotated
/// behind it (exactly like the web editor).
///
/// This clipper is applied around the item, whose local origin is the item's
/// canvas position, so the canvas-space shape is simply shifted by -position.
class _FabricAbsoluteClipper extends CustomClipper<Path> {
  _FabricAbsoluteClipper(this.clip, this.origin);

  final Map clip;
  final Offset origin;

  @override
  Path getClip(Size size) {
    // Fail open: an unreadable clip must never hide the image.
    final full = Path()
      ..addRect(Rect.fromLTWH(-100000, -100000, 200000, 200000));
    try {
      double cw = 0, ch = 0;
      final shape = _FabricClipPathClipper._buildPath(clip, (w, h) {
        cw = w;
        ch = h;
      });
      final m = _FabricClipPathClipper._placement(clip, cw, ch);
      final result = shape.transform(m.storage).shift(-origin);
      if (result.getBounds().isEmpty) return full;
      return result;
    } catch (_) {
      return full;
    }
  }

  @override
  bool shouldReclip(covariant _FabricAbsoluteClipper oldClipper) =>
      !identical(oldClipper.clip, clip) || oldClipper.origin != origin;
}