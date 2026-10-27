import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, mapEquals;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

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
          filterIntensity: provider.imageFilterIntensity(currentItem.id ?? ''),
          tint: provider.imageTint(currentItem.id ?? ''),
          blur: provider.imageBlur(currentItem.id ?? ''),
          maskUrl: provider.imageMaskUrl(currentItem.id ?? ''),
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
        child: CustomPaint(painter: _FabricShapePainter(raw)),
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
            tintColor.withOpacity(tint.abs() / 100.0 * 0.45),
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

class _ItemViewState {
  final EditorItem currentItem;
  final bool isSelected;
  final bool flipX;
  final bool flipY;
  final double filterIntensity;
  final double tint;
  final double blur;
  final String? maskUrl;

  _ItemViewState({
    required this.currentItem,
    required this.isSelected,
    required this.flipX,
    required this.flipY,
    required this.filterIntensity,
    required this.tint,
    required this.blur,
    required this.maskUrl,
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
              maskUrl == other.maskUrl;

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
  _FabricShapePainter(this.raw);
  final Map<String, dynamic> raw;

  double _n(dynamic v, [double fallback = 0]) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;

  Color? _c(dynamic value) {
    if (value == null || value == '' || value == 'transparent') return null;
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
    var h = s.replaceFirst('#', '');
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
    final fill = _c(raw['fill']), stroke = _c(raw['stroke']);
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
      !mapEquals(oldDelegate.raw, raw);
}
