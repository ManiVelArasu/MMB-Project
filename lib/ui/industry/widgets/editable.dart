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
        final normalizedItemType = (currentItem.type ?? '').trim().toLowerCase();
        final isTextItem = normalizedItemType == 'text' ||
            normalizedItemType == 'textbox' ||
            normalizedItemType == 'i-text' ||
            normalizedItemType == 'itext';

        final bodyWidth = math.max(1.0, currentItem.width).toDouble();
        final bodyHeight = math.max(1.0, currentItem.height).toDouble();

        double gestureStartScale = currentItem.scale.isFinite
            ? currentItem.scale
            : 1.0;

        return KeyedSubtree(
          key: ValueKey(currentItem.id),
          child: GestureDetector(
            behavior: isTextItem
                ? HitTestBehavior.deferToChild
                : HitTestBehavior.opaque,
            onTap: () {
              if (isTextItem && !isBackground) {
                onItemSelected(
                  currentItem.type ?? '',
                  currentItem.id!,
                );

                _showTextEditorDialog(
                  context,
                  provider,
                  currentItem.id!,
                  currentItem.text ?? '',
                );
              } else if (!isSelected) {
                onItemSelected(
                  currentItem.type ?? '',
                  currentItem.id!,
                );
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
                scale: currentItem.scale.clamp(0.01, 10.0),
                alignment: Alignment.topLeft,
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
                            child: _buildItemContent(currentItem, context, isBackground: isBackground),
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
          const SnackBar(
            content: Text('Please select a text item first.'),
          ),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              hintText: 'Type text here...',
              hintStyle: TextStyle(
                color: Colors.white54,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.amberAccent,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.amberAccent,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
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
          const SnackBar(
            content: Text('This text item no longer exists.'),
          ),
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

    // Explicitly render image/shape layers. Previously they fell through
    // to the text renderer, leaving only selection handles visible.
    if (item.type == 'image' || item.type == 'shape') {
      final source = (item.contentUrl ?? '').trim();
      if (source.isEmpty) return const SizedBox.shrink();

      final isHttp =
          source.startsWith('http://') || source.startsWith('https://');
      final isFileUri = source.startsWith('file://');
      final localPath = isFileUri ? source.replaceFirst('file://', '') : source;

      if (isHttp) {
        return Image.network(
          source,
          width: item.width,
          height: item.height,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) {
            debugPrint('Editor image failed to load: $source | $error');
            return const SizedBox.shrink();
          },
        );
      }

      return Image.file(
        File(localPath),
        width: item.width,
        height: item.height,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) {
          debugPrint('Editor local image failed to load: $localPath | $error');
          return const SizedBox.shrink();
        },
      );
    }

    if (item.type == 'svg_group' || item.type == 'svg_element') {
      return SizedBox(
        width: item.width,
        height: item.height,
        child: SvgPicture.string(
          item.contentUrl ?? '',
          width: item.width,
          height: item.height,
          fit: BoxFit.fill,
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
      maxLines: null,
      softWrap: isMultiline,
      textAlign: editorProvider.textAlignment(id),
      overflow: TextOverflow.visible,
      style: textStyle,
    );

    return SizedBox(
      width: math.max(1.0, item.width).toDouble(),
      height: math.max(1.0, item.height).toDouble(),
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