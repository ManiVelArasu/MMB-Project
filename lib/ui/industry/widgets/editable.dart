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

        final bodyWidth = math.max(1.0, currentItem.width).toDouble();
        final bodyHeight = math.max(1.0, currentItem.height).toDouble();


        return KeyedSubtree(
          key: ValueKey(currentItem.id),
          child: GestureDetector(
            behavior: isTextItem
                ? HitTestBehavior.deferToChild
                : HitTestBehavior.opaque,
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
                _showTextEditorDialog(
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
        );
      },
    );
  }

  static Widget buildStandaloneMediaContent(
      BuildContext context,
      EditorItem item,
      ) {
    final widget = EditableItemWidget(item: item, onItemSelected: (_, __) {});
    return widget._buildItemContent(item, context, isBackground: true);
  }

  Future<void> _showTextEditorDialog(
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

  Widget _buildFabricShape(EditorItem item, Map<String, dynamic> raw) {
    final type = (raw['type']?.toString() ?? item.text ?? '').toLowerCase();
    final fill = _parseShapeColor(raw['fill']) ?? item.color;
    final stroke = _parseShapeColor(raw['stroke']) ?? item.outlineColor;
    final strokeWidth = _number(raw['strokeWidth']) ?? item.outlineWidth;

    if (type == 'circle' || type == 'ellipse') {
      return CustomPaint(
        size: Size(item.width, item.height),
        painter: _FabricShapePainter(
          type: type,
          fill: fill,
          stroke: stroke,
          strokeWidth: strokeWidth,
          radiusX: _number(raw['radius']) ?? item.width / 2,
          radiusY: _number(raw['ry']) ?? item.height / 2,
          pathData: raw['path'],
        ),
      );
    }

    if (type == 'rect' || type == 'rectangle') {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fill ?? Colors.transparent,
          border: strokeWidth > 0
              ? Border.all(color: stroke, width: strokeWidth)
              : null,
          borderRadius: BorderRadius.circular(
            (_number(raw['rx']) ?? _number(raw['ry']) ?? item.borderRadius)
                .clamp(0.0, math.min(item.width, item.height) / 2),
          ),
        ),
        child: const SizedBox.expand(),
      );
    }

    // Fabric Path objects are used for the small white room icons. Draw their
    // M/L/C/Q/Z commands instead of dropping them as empty shapes.
    return CustomPaint(
      size: Size(item.width, item.height),
      painter: _FabricShapePainter(
        type: type,
        fill: fill,
        stroke: stroke,
        strokeWidth: strokeWidth,
        radiusX: item.width / 2,
        radiusY: item.height / 2,
        pathData: raw['path'],
      ),
    );
  }

  Color? _parseShapeColor(dynamic value) {
    if (value == null || value == '' || value == 'none') return null;
    if (value is Color) return value;
    final text = value.toString().trim();
    final rgba = RegExp(r'rgba?\(([^)]+)\)').firstMatch(text);
    if (rgba != null) {
      final parts = rgba.group(1)!.split(',').map((v) => v.trim()).toList();
      if (parts.length >= 3) {
        final r = double.tryParse(parts[0])?.round() ?? 0;
        final g = double.tryParse(parts[1])?.round() ?? 0;
        final b = double.tryParse(parts[2])?.round() ?? 0;
        final a = parts.length > 3 ? (double.tryParse(parts[3]) ?? 1.0) : 1.0;
        return Color.fromRGBO(r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255), a.clamp(0.0, 1.0));
      }
    }
    var hex = text.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(value);
    }
    return null;
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
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
      final raw = provider.templateRawObject(item.id ?? '') ?? const <String, dynamic>{};
      return _buildFabricShape(item, raw);
    }

    if (item.type == 'image') {
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

      return SizedBox.expand(child: image);
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

      return SvgPicture.string(
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

    final textWidget = Text(
      textValue,
      maxLines: isMultiline ? null : 1,
      softWrap: isMultiline,
      textAlign: editorProvider.textAlignment(id),
      overflow: TextOverflow.visible,
      style: textStyle,
    );

    // For single-line text, do not force a narrow width that causes wrapping.
    // For multiline text, respect the item width.
    final renderWidth = isMultiline
        ? math.max(12.0, item.width)
        : double.infinity;

    return SizedBox(
      width: isMultiline ? renderWidth : null,
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

class _FabricShapePainter extends CustomPainter {
  final String type;
  final Color? fill;
  final Color? stroke;
  final double strokeWidth;
  final double radiusX;
  final double radiusY;
  final dynamic pathData;

  const _FabricShapePainter({
    required this.type,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.radiusX,
    required this.radiusY,
    required this.pathData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (type == 'circle' || type == 'ellipse') {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = math.min(size.width, size.height) / 2;
      if (fill != null) {
        canvas.drawCircle(center, radius, Paint()..color = fill!);
      }
      if (stroke != null && strokeWidth > 0) {
        final outlinePaint = Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        canvas.drawCircle(center, radius - strokeWidth / 2, outlinePaint);
      }
      return;
    }

    if (pathData is! List) return;
    final path = Path();
    for (final rawCommand in pathData as List) {
      if (rawCommand is! List || rawCommand.isEmpty) continue;
      final command = rawCommand.first.toString().toUpperCase();
      double n(int i) => i < rawCommand.length ? (rawCommand[i] as num).toDouble() : 0.0;
      switch (command) {
        case 'M': path.moveTo(n(1), n(2)); break;
        case 'L': path.lineTo(n(1), n(2)); break;
        case 'C': path.cubicTo(n(1), n(2), n(3), n(4), n(5), n(6)); break;
        case 'Q': path.quadraticBezierTo(n(1), n(2), n(3), n(4)); break;
        case 'Z': path.close(); break;
      }
    }
    if (fill != null) {
      final fillPaint = Paint()
        ..color = fill!
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }
    if (stroke != null && strokeWidth > 0) {
      final outlinePaint = Paint()
        ..color = stroke!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawPath(path, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FabricShapePainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.fill != fill ||
          oldDelegate.stroke != stroke || oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.pathData != pathData;
}

class _ItemViewState {
  final EditorItem currentItem;
  final bool isSelected;
  final bool flipX;
  final bool flipY;

  _ItemViewState({
    required this.currentItem,
    required this.isSelected,
    required this.flipX,
    required this.flipY,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _ItemViewState &&
              runtimeType == other.runtimeType &&
              currentItem == other.currentItem &&
              isSelected == other.isSelected &&
              flipX == other.flipX &&
              flipY == other.flipY;

  @override
  int get hashCode => Object.hash(currentItem, isSelected, flipX, flipY);
}
