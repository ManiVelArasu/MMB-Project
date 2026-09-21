import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../../Api Model/editor_model.dart';
import '../../Repository/freePic.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/home_screen_provider.dart';

class TemplateEditScreen extends StatelessWidget {
  final String? resizeSize;
  final String? templateUid;
  final double? canvasWidth;
  final double? canvasHeight;

  const TemplateEditScreen({
    super.key,
    this.resizeSize,
    this.templateUid,
    this.canvasWidth,
    this.canvasHeight,
  });

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String resolvedResizeSize = resizeSize ?? '';
    double? resolvedCanvasWidth = canvasWidth;
    double? resolvedCanvasHeight = canvasHeight;

    if (args is String && args.trim().isNotEmpty) {
      resolvedResizeSize = args.trim();
    } else if (args is Map) {
      final value = args['resizeSize'] ?? args['resize_size'];
      if (value is String && value.trim().isNotEmpty) {
        resolvedResizeSize = value.trim();
      }

      final widthValue =
          args['width'] ?? args['canvasWidth'] ?? args['canvas_width'];
      final heightValue =
          args['height'] ?? args['canvasHeight'] ?? args['canvas_height'];

      resolvedCanvasWidth =
          double.tryParse(widthValue?.toString() ?? '') ?? resolvedCanvasWidth;
      resolvedCanvasHeight =
          double.tryParse(heightValue?.toString() ?? '') ??
              resolvedCanvasHeight;
    }

    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: Scaffold(
        body: SafeArea(
          child: EditorView(
            resizeSize: resolvedResizeSize,
            canvasWidth: resolvedCanvasWidth,
            canvasHeight: resolvedCanvasHeight,
            templateUid:
            templateUid ??
                (args is Map
                    ? (args['templateUid'] ??
                    args['template_uid'] ??
                    args['uid'])
                    ?.toString()
                    : null),
          ),
        ),
      ),
    );
  }
}

class EditorView extends StatefulWidget {
  final String resizeSize;
  final String? templateUid;
  final double? canvasWidth;
  final double? canvasHeight;

  const EditorView({
    super.key,
    required this.resizeSize,
    this.templateUid,
    this.canvasWidth,
    this.canvasHeight,
  });

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  bool _showFlipOptions = false;
  final AudioPlayer _musicPlayer = AudioPlayer();
  StreamSubscription<Duration>? _musicPositionSubscription;
  StreamSubscription<Duration>? _musicDurationSubscription;
  StreamSubscription<void>? _musicCompleteSubscription;

  Size _getCanvasSize() {
    if (widget.canvasWidth != null &&
        widget.canvasHeight != null &&
        widget.canvasWidth! > 0 &&
        widget.canvasHeight! > 0) {
      return Size(widget.canvasWidth!, widget.canvasHeight!);
    }

    final size = widget.resizeSize.toLowerCase();

    if (size.contains('4:5')) {
      return const Size(1080, 1350);
    }
    if (size.contains('9:16')) {
      return const Size(1080, 1920);
    }
    if (size.contains('horizontal')) {
      return const Size(1200, 628);
    }
    if (size.contains('portrait')) {
      return const Size(1080, 1350);
    }
    return const Size(1080, 1350);
  }

  bool _isCanvasBackground(EditorItem item) {
    if (item.id?.startsWith('bg_') == true &&
        (item.type == 'image' ||
            item.type == 'video' ||
            item.type == 'shape')) {
      return true;
    }
    return item.type == 'image' &&
        item.position.dx.abs() < 1.0 &&
        item.position.dy.abs() < 1.0 &&
        (item.width - 1080.0).abs() < 2.0 &&
        (item.height - 1080.0).abs() < 2.0;
  }

  Future<String?> _prepareCropSource(String source) async {
    if (!source.startsWith('http://') && !source.startsWith('https://')) {
      return source;
    }

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(source));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final bytes = await response.fold<List<int>>(
        <int>[],
            (buffer, data) => buffer..addAll(data),
      );
      client.close();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/editor_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cropSelectedImage(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      ) async {
    final item = provider.items.where((e) => e.id == itemId).isEmpty
        ? null
        : provider.items.firstWhere((e) => e.id == itemId);
    if (item == null ||
        item.type != 'image' ||
        (item.contentUrl ?? '').isEmpty) {
      return;
    }

    final sourcePath = await _prepareCropSource(item.contentUrl!);
    if (sourcePath == null) {
      Fluttertoast.showToast(msg: 'Unable to open image for crop');
      return;
    }

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: false),
      ],
    );

    if (cropped != null) {
      provider.updateCroppedImage(itemId, cropped.path);
    }
  }

  Future<Size?> _resolveNetworkVideoSize(String url) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize().timeout(const Duration(seconds: 15));
      final size = controller.value.size;
      if (size.width > 0 && size.height > 0) {
        return size;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  Future<bool> _confirmReplaceBackground(
      BuildContext context,
      EditorProvider provider,
      String imageUrl, {
        String? selectedItemId,
      }) async {
    final replace = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText('Replace Background?'),
        content: const AppText(
          'The current background will be removed and this image will become the full-size background.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AppText('REPLACE BACKGROUND'),
          ),
        ],
      ),
    );

    if (replace == true) {
      if (selectedItemId != null) {
        // Media image -> full-size background.
        // This also removes the selected media item so it is not rendered twice.
        final canvasSize = Size(provider.canvasWidth, provider.canvasHeight);
        // Replace immediately. Do NOT wait for the remote image dimensions.
        // The provider already sizes the background to the current canvas and
        // the renderer uses cover behavior.
        provider.replaceBackgroundImage(
          imageUrl,
          selectedItemId,
          canvasWidth: canvasSize.width,
          canvasHeight: canvasSize.height,
        );
      } else {
        // Background/stock image -> full-size background.
        // setBackgroundImage creates/selects the new bg_ layer.
        final canvasSize = Size(provider.canvasWidth, provider.canvasHeight);
        // Replace immediately. Do NOT wait for the remote image dimensions.
        provider.setBackgroundImage(
          imageUrl,
          canvasWidth: canvasSize.width,
          canvasHeight: canvasSize.height,
        );
      }

      // Repaint immediately so the newly selected/replaced background is
      // visible at once, without waiting for the bottom sheet to close.
      if (mounted) setState(() {});

      // Close the selection sheet, then keep the new background selected.
      // The image editor bottom toolbar is driven by selectedItemType.
      final bgItems = provider.items.where(_isCanvasBackground).toList();

      if (bgItems.isNotEmpty) {
        final bg = bgItems.last;
        provider.setSelectedItem(bg.type, bg.id);
      }

      if (mounted) {
        setState(() {
          _bottomNavIndex = 3;
        });
      }

      return true;
    }
    return false;
  }

  int _bottomNavIndex = 0;
  bool _isInitialized = false;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTemplateJsonAndInitEditor();
      });
      _isInitialized = true;
    }
  }

  Future<void> _loadTemplateJsonAndInitEditor() async {
    final provider = Provider.of<EditorProvider>(context, listen: false);
    final hasExplicitResize = widget.resizeSize.trim().isNotEmpty;
    final resizeCanvas = hasExplicitResize ? _getCanvasSize() : null;

    final uid = widget.templateUid?.trim() ?? '';
    if (uid.isNotEmpty) {
      await provider.loadTemplateByUid(uid);

      final selectedSize = resizeCanvas ?? _getCanvasSize();
      provider.setCanvasSize(selectedSize.width, selectedSize.height);
    } else {
      final canvasSize = resizeCanvas ?? _getCanvasSize();
      provider.setCanvasSize(canvasSize.width, canvasSize.height);
      debugPrint('ℹ️ No template UID supplied; opening blank editor');
    }
    provider.fetchFreePikAssets("furniture");
    provider.fetchFreePikStickers("stickers");
  }

  Future<void> _addRemoteShape(
      BuildContext context,
      EditorProvider provider,
      String url,
      ) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw Exception('Invalid shape URL');
      }

      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, '*/*');
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Shape request failed: ${response.statusCode}');
        }

        final bytes = await response.fold<List<int>>(
          <int>[],
              (buffer, data) => buffer..addAll(data),
        );

        final contentType =
            response.headers.contentType?.mimeType.toLowerCase() ?? '';
        final pathPart = uri.path.toLowerCase();
        final isSvg = contentType.contains('svg') || pathPart.endsWith('.svg');

        if (!isSvg) {
          final dir = await getTemporaryDirectory();
          final ext = contentType.contains('webp')
              ? 'webp'
              : contentType.contains('jpeg') || contentType.contains('jpg')
              ? 'jpg'
              : 'png';
          final file = File(
            '${dir.path}/shape_${DateTime.now().microsecondsSinceEpoch}.$ext',
          );
          await file.writeAsBytes(bytes, flush: true);
          provider.addImage(file.path, isLocal: true);
          if (context.mounted) Navigator.pop(context);
          return;
        }

        final svgText = utf8.decode(bytes, allowMalformed: true);
        final pictureInfo = await vg.loadPicture(
          svg.SvgStringLoader(svgText),
          null,
        );

        const outputSize = 512.0;
        final sourceWidth = pictureInfo.size.width > 0
            ? pictureInfo.size.width
            : outputSize;
        final sourceHeight = pictureInfo.size.height > 0
            ? pictureInfo.size.height
            : outputSize;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final scale = math.min(
          outputSize / sourceWidth,
          outputSize / sourceHeight,
        );

        canvas.translate(
          (outputSize - sourceWidth * scale) / 2,
          (outputSize - sourceHeight * scale) / 2,
        );
        canvas.scale(scale);
        canvas.drawPicture(pictureInfo.picture);

        final picture = recorder.endRecording();
        final image = await picture.toImage(
          outputSize.toInt(),
          outputSize.toInt(),
        );
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        pictureInfo.picture.dispose();
        picture.dispose();
        image.dispose();

        if (byteData == null) {
          throw Exception('Unable to render SVG shape');
        }

        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/shape_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

        // Render remote SVG as a real local PNG image layer. The existing
        // canvas renderer supports image layers, so the selected shape is
        // immediately visible on the canvas.
        provider.addImage(file.path, isLocal: true);

        if (context.mounted) Navigator.pop(context);
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      debugPrint('Unable to add remote shape: $e');
      if (context.mounted) {
        Fluttertoast.showToast(msg: 'Unable to add shape');
      }
    }
  }

  Future<void> _addLocalShape(
      BuildContext context,
      EditorProvider provider,
      String assetPath,
      ) async {
    try {
      final pictureInfo = await vg.loadPicture(
        svg.SvgAssetLoader(assetPath),
        null,
      );

      const outputSize = 512.0;

      final sourceSize = pictureInfo.size;

      final sourceWidth = sourceSize.width > 0 ? sourceSize.width : outputSize;

      final sourceHeight = sourceSize.height > 0
          ? sourceSize.height
          : outputSize;

      final recorder = ui.PictureRecorder();

      final canvas = Canvas(recorder);

      final scale = math.min(
        outputSize / sourceWidth,
        outputSize / sourceHeight,
      );

      canvas.translate(
        (outputSize - sourceWidth * scale) / 2,
        (outputSize - sourceHeight * scale) / 2,
      );

      canvas.scale(scale);

      canvas.drawPicture(pictureInfo.picture);

      final picture = recorder.endRecording();

      final image = await picture.toImage(
        outputSize.toInt(),
        outputSize.toInt(),
      );

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      pictureInfo.picture.dispose();
      picture.dispose();
      image.dispose();

      if (byteData == null) {
        throw Exception('Unable to render SVG');
      }

      final dir = await getTemporaryDirectory();

      final file = File(
        "${dir.path}/shape_${DateTime.now().microsecondsSinceEpoch}.png",
      );

      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      provider.addImage(file.path, isLocal: true);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (context.mounted) {
        Fluttertoast.showToast(msg: "Unable to add shape");
      }
    }
  }

  void _showFramesBottomSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "My Frames",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1A1C)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        provider.setSelectedFrame(
                          "assets/images/thumbnail1.png",
                        );
                        Navigator.pop(modalContext);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.grey.shade50,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_rounded,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
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
    );
  }

  void _showTemplatesBottomSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider(
          create: (_) => HomeScreenProvider(),
          child: Container(
            height: MediaQuery.of(modalContext).size.height * 0.72,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF17191E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(modalContext),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A1C)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppText(
                  'Templates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  'Choose a template to replace the current design',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Consumer<HomeScreenProvider>(
                    builder: (sheetContext, homeProvider, _) {
                      final categories = homeProvider.templateCategories;

                      if (categories.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE53935),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 18),
                        itemCount: categories.length,
                        itemBuilder: (context, categoryIndex) {
                          final category = categories[categoryIndex];
                          final categoryName = category.name?.trim() ?? '';
                          final slug = category.slug?.trim() ?? '';

                          if (slug.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final templates = homeProvider.templatesForCategory(
                            slug,
                          );
                          final loading = homeProvider.isTemplateLoading(slug);

                          if (!loading && templates.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        categoryName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (loading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                if (loading && templates.isEmpty)
                                  SizedBox(
                                    height: 150,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 3,
                                      separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                      itemBuilder: (_, __) => Container(
                                        width: 108,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF25272D)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 150,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: templates.length,
                                      separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                      itemBuilder: (_, templateIndex) {
                                        final template =
                                        templates[templateIndex];
                                        final uid = _templateStringValue(
                                          template,
                                          const [
                                            'uid',
                                            'templateUid',
                                            'template_uid',
                                          ],
                                        );
                                        final imageKey = _templateStringValue(
                                          template,
                                          const [
                                            'thumbnailS3Key',
                                            'thumbnail_s3_key',
                                            'previewS3Key',
                                            'preview_s3_key',
                                            's3Key',
                                            's3_key',
                                            'thumbnail',
                                            'image',
                                            'preview',
                                          ],
                                        );

                                        final imageUrl = _templateImageUrl(
                                          imageKey,
                                        );

                                        return GestureDetector(
                                          onTap: uid.isEmpty
                                              ? null
                                              : () async {
                                            Navigator.pop(modalContext);
                                            await provider
                                                .loadTemplateByUid(uid);

                                            if (mounted) {
                                              setState(() {});
                                            }
                                          },
                                          child: Container(
                                            width: 108,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF25272D)
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                              BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.grey.shade800
                                                    : Colors.grey.shade200,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                              BorderRadius.circular(14),
                                              child: imageUrl.isEmpty
                                                  ? const Center(
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  color: Colors.grey,
                                                  size: 30,
                                                ),
                                              )
                                                  : Image.network(
                                                imageUrl,
                                                cacheWidth: 800,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                    _,
                                                    __,
                                                    ___,
                                                    ) => const Center(
                                                  child: Icon(
                                                    Icons
                                                        .broken_image_outlined,
                                                    color:
                                                    Colors.grey,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
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
  }

  String _templateStringValue(dynamic item, List<String> keys) {
    if (item is Map) {
      for (final key in keys) {
        final value = item[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }

    for (final key in keys) {
      try {
        dynamic value;
        switch (key) {
          case 'uid':
            value = item.uid;
            break;
          case 'templateUid':
            value = item.templateUid;
            break;
          case 'template_uid':
            value = item.template_uid;
            break;
          case 'thumbnailS3Key':
            value = item.thumbnailS3Key;
            break;
          case 'thumbnail_s3_key':
            value = item.thumbnail_s3_key;
            break;
          case 'previewS3Key':
            value = item.previewS3Key;
            break;
          case 'preview_s3_key':
            value = item.preview_s3_key;
            break;
          case 's3Key':
            value = item.s3Key;
            break;
          case 's3_key':
            value = item.s3_key;
            break;
          case 'thumbnail':
            value = item.thumbnail;
            break;
          case 'image':
            value = item.image;
            break;
          case 'preview':
            value = item.preview;
            break;
        }
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      } catch (_) {}
    }

    return '';
  }

  String _templateImageUrl(String value) {
    final url = value.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '${ApiEndpoints.cdnImageUrl}$url';
    }
    return '${ApiEndpoints.cdnImageUrl}/$url';
  }

  void _showTextStylesBottomSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      "Add Text",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(modalContext),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A1C)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Center(
                    child: AppText(
                      "My Heading",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  onTap: () {
                    _addTextCentered(provider, "My Heading");
                    Navigator.pop(modalContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Center(
                    child: AppText(
                      "My Sub Title",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  onTap: () {
                    _addTextCentered(provider, "My Sub Title");
                    Navigator.pop(modalContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Center(
                    child: AppText(
                      "My Text",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  onTap: () {
                    _addTextCentered(provider, "My Text");
                    Navigator.pop(modalContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addTextCentered(EditorProvider provider, String text) {
    provider.addText(initialText: text);

    // Newly added text should start at the visual center of the canvas
    // instead of the provider's default/top-left position.
    final textItems = provider.items
        .where((item) => item.type == 'text' || item.type == 'textbox')
        .toList();

    if (textItems.isEmpty) return;

    final item = textItems.last;
    final canvasSize = Size(
      provider.canvasWidth > 0 ? provider.canvasWidth : 1080.0,
      provider.canvasHeight > 0 ? provider.canvasHeight : 1080.0,
    );

    // `EditorItem.position` is the item's TOP-LEFT position on the canvas.
    // Put the whole text box at the visual center instead of placing its
    // top-left corner at the center (which pushes half of the text off-screen).
    final itemWidth = item.width * item.scale;
    final itemHeight = item.height * item.scale;

    final centeredX = ((canvasSize.width - itemWidth) / 2)
        .clamp(0.0, math.max(0.0, canvasSize.width - itemWidth))
        .toDouble();
    final centeredY = ((canvasSize.height - itemHeight) / 2)
        .clamp(0.0, math.max(0.0, canvasSize.height - itemHeight))
        .toDouble();

    provider.updateItemTransform(
      item.id ?? '',
      position: Offset(centeredX, centeredY),
    );

    if (mounted) {
      setState(() {});
    }
  }

  bool isStickerProxyCategory(String category) {
    final normalized = category.trim().toLowerCase();
    return normalized == 'stickers' ||
        normalized == 'social media' ||
        normalized == 'e-commerce';
  }

  void _showMediaBottomSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    int selectedTab = 1; // 0 uploads, 1 elements, 2 images
    String? expandedCategory;
    bool sheetOpen = true;
    bool elementsInitialLoadScheduled = false;
    bool imagesInitialLoadScheduled = false;
    final searchController = TextEditingController();

    const categories = <Map<String, String>>[
      {'title': 'Shapes', 'query': 'shapes'},
      {'title': 'Stickers', 'query': 'stickers'},
      {'title': 'Social Media', 'query': 'social media'},
      {'title': 'E-commerce', 'query': 'e-commerce'},
    ];

    const imageCategories = <Map<String, String>>[
      {'title': 'Nature', 'query': 'nature landscape'},
      {'title': 'People', 'query': 'people lifestyle'},
      {'title': 'Business', 'query': 'business'},
      {'title': 'Animals', 'query': 'animals'},
      {'title': 'Travel', 'query': 'travel'},
      {'title': 'Food', 'query': 'food'},
      {'title': 'Technology', 'query': 'technology'},
      {'title': 'Fashion', 'query': 'fashion'},
      {'title': 'Architecture', 'query': 'architecture'},
      {'title': 'Background', 'query': 'background'},
    ];

    void loadCategory(
        String query,
        void Function(void Function()) setState, {
          int limit = 4,
          bool force = false,
        }) {
      if (query == 'shapes') {
        if (!force && provider.elementCategoryAssets(query).isNotEmpty) return;
        if (provider.isElementCategoryLoading(query)) return;
        provider.fetchElementCategory(query, limit: limit).then((_) {
          if (!sheetOpen) return;
          setState(() {});
        });
        setState(() {});
        return;
      }
      if (isStickerProxyCategory(query)) {
        if (!force && provider.elementCategoryAssets(query).isNotEmpty) return;
        if (provider.isElementCategoryLoading(query)) return;
        provider.fetchElementCategory(query, limit: limit).then((_) {
          if (!sheetOpen) return;
          setState(() {});
        });
        setState(() {});
        return;
      }
      if (!force && provider.elementCategoryAssets(query).isNotEmpty) {
        return;
      }
      if (provider.isElementCategoryLoading(query)) return;

      provider.fetchElementCategory(query, limit: limit).then((_) {
        if (!sheetOpen) return;
        setState(() {});
      });
      setState(() {});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            // Never start provider requests or call setSheetState directly
            // from the StatefulBuilder build method. fetchElementCategory()
            // calls notifyListeners(), which otherwise causes
            // "setState()/markNeedsBuild() called during build".
            if (selectedTab == 1 &&
                expandedCategory == null &&
                !elementsInitialLoadScheduled) {
              elementsInitialLoadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!sheetOpen || !sheetContext.mounted) return;

                for (final category in categories) {
                  loadCategory(category['query']!, setSheetState);
                }
              });
            }

            // Initial Images request must also happen after the current
            // StatefulBuilder frame, not while it is building.
            if (selectedTab == 2 && !imagesInitialLoadScheduled) {
              imagesInitialLoadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!sheetOpen || !sheetContext.mounted) return;
                if (provider.mediaImageAssets.isEmpty &&
                    !provider.isMediaImagesLoading) {
                  provider.fetchMediaImages('');
                }
              });
            }

            Widget elementCard(
                String url, {
                  bool locked = false,
                  VoidCallback? onTap,
                }) {
              final isLocalShape = url.startsWith('assets/shapes/');
              final bool isSvg = url
                  .toLowerCase()
                  .split('?')
                  .first
                  .endsWith('.svg');

              final Widget preview = url.isEmpty
                  ? const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
              )
                  : isLocalShape
                  ? SvgPicture.asset(
                url,
                fit: BoxFit.contain,
                width: 58,
                height: 58,
                placeholderBuilder: (_) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey,
                ),
              )
                  : isSvg
                  ? SvgPicture.network(
                url,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_outlined, color: Colors.grey),
              )
                  : Image.network(
                url,
                cacheWidth: 800,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_outlined, color: Colors.grey),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  );
                },
              );

              return GestureDetector(
                onTap: locked
                    ? null
                    : onTap ??
                        () {
                      if (isLocalShape) {
                        _addLocalShape(modalContext, provider, url);
                      } else {
                        provider.addFreePikElement(url);
                        Navigator.pop(modalContext);
                      }
                    },
                child: Stack(
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF24262B)
                            : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: locked
                              ? (isDark
                              ? Colors.orange.withValues(alpha: .55)
                              : Colors.orange.shade200)
                              : (isDark
                              ? Colors.white12
                              : const Color(0xFFE8E8E8)),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Opacity(opacity: locked ? .38 : 1, child: preview),
                    ),
                    if (locked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.lock_rounded,
                                size: 24,
                                color: Colors.orange,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'LOCKED',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            Widget assetCategoryCard(
                AssetCategoryItem item, {
                  bool isShape = false,
                }) {
              final url = item.previewKey;
              final isLocalShape = url.startsWith('assets/shapes/');

              return elementCard(
                url,
                locked: item.isLocked,
                onTap: item.isLocked
                    ? null
                    : () async {
                  if (isLocalShape) {
                    await _addLocalShape(modalContext, provider, url);
                  } else if (isShape) {
                    // Remote shapes can be SVGs. Rasterize them to a
                    // local PNG image so the existing canvas renderer
                    // displays them immediately after selection.
                    await _addRemoteShape(modalContext, provider, url);
                  } else {
                    // Other API assets are normal image layers.
                    provider.addImage(url, isLocal: false);

                    if (modalContext.mounted) {
                      Navigator.pop(modalContext);
                    }
                  }
                },
              );
            }

            Widget categoryTitle(String title, String query) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF151515),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.resetElementCategoryRequest(query);
                        provider.fetchElementCategoryAll(query).then((_) {
                          if (sheetOpen) setSheetState(() {});
                        });
                        setSheetState(() => expandedCategory = query);
                      },
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget categorySection(Map<String, String> category) {
              final title = category['title']!;
              final query = category['query']!;

              final bool stickerProxy = isStickerProxyCategory(query);

              final List<AssetCategoryItem> assetItems = stickerProxy
                  ? const <AssetCategoryItem>[]
                  : provider.assetCategoryItems(query);

              final List<String> stickerItems = stickerProxy
                  ? provider.elementCategoryAssets(query)
                  : const <String>[];

              final previewAssets = assetItems.take(4).toList();
              final previewStickers = stickerItems.take(4).toList();

              final bool hasItems = stickerProxy
                  ? previewStickers.isNotEmpty
                  : previewAssets.isNotEmpty;

              final bool isLoading = stickerProxy
                  ? (provider.isFreePikStickerCategoryLoading[query] ?? false)
                  : provider.isElementCategoryLoading(query);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  categoryTitle(title, query),

                  SizedBox(
                    height: 58,
                    child: isLoading
                        ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                        ),
                      ),
                    )
                        : !hasItems
                        ? const Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    )
                        : Row(
                      children: stickerProxy
                          ? previewStickers.map((url) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 8,
                            ),
                            child: elementCard(url),
                          ),
                        );
                      }).toList()
                          : previewAssets.map((item) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 8,
                            ),
                            child: assetCategoryCard(
                              item,
                              isShape: query == 'shapes',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              );
            }

            Widget elementsView() {
              if (expandedCategory != null) {
                final query = expandedCategory!;
                final title = categories.firstWhere(
                      (e) => e['query'] == query,
                )['title']!;
                final bool stickerProxy = isStickerProxyCategory(query);
                final List<AssetCategoryItem> assetItems = stickerProxy
                    ? const <AssetCategoryItem>[]
                    : provider.assetCategoryItems(query);
                final List<String> stickerItems = stickerProxy
                    ? provider.elementCategoryAssets(query)
                    : const <String>[];
                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              setSheetState(() => expandedCategory = null),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child:
                      (isStickerProxyCategory(query)
                          ? (provider
                          .isFreePikStickerCategoryLoading[query] ??
                          false)
                          : provider.isElementCategoryLoading(query))
                          ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: isStickerProxyCategory(query)
                            ? stickerItems.length
                            : assetItems.length,
                        itemBuilder: (_, index) =>
                        isStickerProxyCategory(query)
                            ? elementCard(stickerItems[index])
                            : assetCategoryCard(
                          assetItems[index],
                          isShape: query == 'shapes',
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
                children: categories.map(categorySection).toList(),
              );
            }

            Widget uploadsView() {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(modalContext);
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null)
                        provider.addImage(image.path, isLocal: true);
                    },
                    child: _mediaPickerTile(isDark, Icons.camera_alt, 'CAMERA'),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(modalContext);
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null)
                        provider.addImage(image.path, isLocal: true);
                    },
                    child: _mediaPickerTile(
                      isDark,
                      Icons.photo_library,
                      'GALLERY',
                    ),
                  ),
                ],
              );
            }

            Widget imagesView() {
              const defaultQuery = '';
              final images = provider.mediaImageAssets;

              // Initial loading is scheduled from the bottom-sheet builder
              // with addPostFrameCallback. Do not notify the provider from
              // this build method.

              Widget imageChip(String title, String query) {
                final selected = provider.mediaImagesQuery == query;
                return GestureDetector(
                  onTap: () {
                    searchController.text = query;
                    provider.fetchMediaImages(query).then((_) {
                      if (sheetOpen) setSheetState(() {});
                    });
                    setSheetState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFFE9E9)
                          : (isDark ? const Color(0xFF24262B) : Colors.white),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected
                            ? Colors.redAccent
                            : (isDark
                            ? Colors.white24
                            : const Color(0xFFE0E0E0)),
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.redAccent
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF24262B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFD9D9D9),
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (value) {
                        provider.fetchMediaImages(
                          value.trim().isEmpty ? defaultQuery : value.trim(),
                        );
                      },
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          provider.fetchMediaImages(defaultQuery);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search images...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search_rounded, size: 20),
                          onPressed: () {
                            final value = searchController.text.trim();
                            provider.fetchMediaImages(
                              value.isEmpty ? defaultQuery : value,
                            );
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final category = imageCategories[index];
                        return imageChip(
                          category['title']!,
                          category['query']!,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: provider.isMediaImagesLoading
                        ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : images.isEmpty
                        ? const Center(
                      child: Text(
                        'No images found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: images.length,
                      itemBuilder: (_, index) {
                        return GestureDetector(
                          onTap: () {
                            provider.addImage(
                              images[index],
                              isLocal: false,
                            );
                            Navigator.pop(modalContext);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF24262B)
                                  : const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE6E6E6),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              images[index],
                              cacheWidth: 800,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.6,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return Container(
              height: MediaQuery.of(sheetContext).size.height * .72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF17191E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white38 : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
                      child: Row(
                        children: [
                          if (expandedCategory != null)
                            IconButton(
                              onPressed: () =>
                                  setSheetState(() => expandedCategory = null),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          Expanded(
                            child: Text(
                              'Media',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              sheetOpen = false;
                              Navigator.pop(modalContext);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (expandedCategory == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _backgroundTab(
                              title: 'UPLOADS',
                              selected: selectedTab == 0,
                              onTap: () => setSheetState(() => selectedTab = 0),
                            ),
                            const SizedBox(width: 24),
                            _backgroundTab(
                              title: 'ELEMENTS',
                              selected: selectedTab == 1,
                              onTap: () {
                                setSheetState(() => selectedTab = 1);
                                if (!elementsInitialLoadScheduled) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                      _,
                                      ) {
                                    if (!sheetOpen || !sheetContext.mounted)
                                      return;
                                    elementsInitialLoadScheduled = true;
                                    for (final category in categories) {
                                      loadCategory(
                                        category['query']!,
                                        setSheetState,
                                      );
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 24),
                            _backgroundTab(
                              title: 'IMAGES',
                              selected: selectedTab == 2,
                              onTap: () {
                                setSheetState(() => selectedTab = 2);
                                WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                    ) {
                                  if (!sheetOpen || !sheetContext.mounted)
                                    return;
                                  if (provider.mediaImageAssets.isEmpty &&
                                      !provider.isMediaImagesLoading) {
                                    provider.fetchMediaImages('');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    Divider(
                      height: 18,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: selectedTab == 0
                            ? uploadsView()
                            : selectedTab == 1
                            ? elementsView()
                            : imagesView(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      sheetOpen = false;
      searchController.dispose();
    });
  }

  Widget _mediaPickerTile(bool isDark, IconData icon, String title) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A1C) : const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.red, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showBackgroundBottomSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    int selectedTab = 0; // 0 images, 1 videos, 2 colors
    String searchQuery = 'background';
    String videoSearchQuery = 'background';
    bool sheetOpen = true;
    bool backgroundRequestStarted = false;
    final searchController = TextEditingController(text: searchQuery);
    final videoSearchController = TextEditingController(text: videoSearchQuery);

    const chips = <String>[
      'Abstract background',
      'Gradient',
      'Soft background',
      'Minimal',
      'Nature',
      'Texture',
    ];

    void fetchImages(String query, void Function(void Function()) setState) {
      final value = query.trim().isEmpty ? 'background' : query.trim();
      searchQuery = value;
      setState(() {});

      provider.fetchBackgroundAssets(value).then((_) {
        if (!sheetOpen) return;
        setState(() {});
      });
    }

    void fetchVideos(String query, void Function(void Function()) setState) {
      final value = query.trim().isEmpty ? 'background' : query.trim();
      videoSearchQuery = value;
      setState(() {});

      provider.fetchFreePikVideos(value).then((_) {
        if (!sheetOpen) return;
        setState(() {});
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            if (selectedTab == 0 && !backgroundRequestStarted) {
              backgroundRequestStarted = true;
              Future.microtask(() async {
                await provider.fetchBackgroundAssets(searchQuery);
                if (sheetOpen) {
                  setSheetState(() {});
                }
              });
            }

            Widget searchBox({required bool forVideos}) {
              final controller = forVideos
                  ? videoSearchController
                  : searchController;
              return Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF24262B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white24 : const Color(0xFFD9D9D9),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  onSubmitted: (value) => forVideos
                      ? fetchVideos(value, setSheetState)
                      : fetchImages(value, setSheetState),
                  onChanged: (value) {
                    if (forVideos) {
                      videoSearchQuery = value;
                    } else {
                      searchQuery = value;
                    }
                    setSheetState(() {});
                  },
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF222222),
                  ),
                  decoration: InputDecoration(
                    hintText: forVideos
                        ? 'Search background videos...'
                        : 'Search background...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF8A8A8A),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.search_rounded,
                        size: 21,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF444444),
                      ),
                      onPressed: () => forVideos
                          ? fetchVideos(controller.text, setSheetState)
                          : fetchImages(controller.text, setSheetState),
                    ),
                  ),
                ),
              );
            }

            Widget chip(String title) {
              final selected = searchQuery.toLowerCase() == title.toLowerCase();
              return GestureDetector(
                onTap: () {
                  searchController.text = title;
                  fetchImages(title, setSheetState);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                        ? const Color(0xFF4A2024)
                        : const Color(0xFFFFE7E7))
                        : (isDark ? const Color(0xFF24262B) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? Colors.red.shade300
                          : (isDark ? Colors.white24 : const Color(0xFFE2E2E2)),
                    ),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.red
                          : (isDark ? Colors.white70 : const Color(0xFF444444)),
                    ),
                  ),
                ),
              );
            }

            Widget videoChip(String title) {
              final selected =
                  videoSearchQuery.toLowerCase() == title.toLowerCase();
              return GestureDetector(
                onTap: () {
                  videoSearchController.text = title;
                  fetchVideos(title, setSheetState);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                        ? const Color(0xFF4A2024)
                        : const Color(0xFFFFE7E7))
                        : (isDark ? const Color(0xFF24262B) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? Colors.red.shade300
                          : (isDark ? Colors.white24 : const Color(0xFFE2E2E2)),
                    ),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.red
                          : (isDark ? Colors.white70 : const Color(0xFF444444)),
                    ),
                  ),
                ),
              );
            }

            Widget imageCard(String url, double height) {
              return GestureDetector(
                onTap: () async {
                  final replaced = await _confirmReplaceBackground(
                    context,
                    provider,
                    url,
                  );
                  if (replaced && Navigator.canPop(modalContext)) {
                    Navigator.pop(modalContext);
                  }
                },
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF24262B)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    url,
                    cacheWidth: 800,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            }

            Widget imageResults() {
              if (provider.isBackgroundLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final items = provider.backgroundAssets
                  .where((u) {
                final uri = Uri.tryParse(u);
                return uri != null &&
                    (uri.scheme == 'http' || uri.scheme == 'https');
              })
                  .take(24)
                  .toList();
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No backgrounds found',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 20),
                itemCount: (items.length / 2).ceil(),
                itemBuilder: (_, rowIndex) {
                  final leftIndex = rowIndex * 2;
                  final rightIndex = leftIndex + 1;
                  final rowHeight = rowIndex % 3 == 0
                      ? 170.0
                      : rowIndex % 3 == 1
                      ? 118.0
                      : 145.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: imageCard(items[leftIndex], rowHeight)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: rightIndex < items.length
                              ? imageCard(
                            items[rightIndex],
                            rowHeight * (rowIndex.isEven ? .78 : 1.18),
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            Widget colorsView() {
              const colors = [
                Colors.white,
                Colors.black,
                Color(0xFFF44336),
                Color(0xFFE91E63),
                Color(0xFF9C27B0),
                Color(0xFF673AB7),
                Color(0xFF3F51B5),
                Color(0xFF2196F3),
                Color(0xFF03A9F4),
                Color(0xFF00BCD4),
                Color(0xFF009688),
                Color(0xFF4CAF50),
                Color(0xFF8BC34A),
                Color(0xFFFFEB3B),
                Color(0xFFFFC107),
                Color(0xFFFF9800),
                Color(0xFFFF5722),
                Color(0xFF795548),
              ];
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: colors.length,
                itemBuilder: (_, index) => InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    provider.setBackgroundColor(colors[index]);
                    Navigator.pop(modalContext);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              );
            }

            Widget videosView() {
              if (!provider.isVideosLoading &&
                  provider.pexelsVideoAssets.isEmpty) {
                Future.microtask(
                      () => provider.fetchFreePikVideos(videoSearchQuery),
                );
              }
              if (provider.isVideosLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final assets = provider.pexelsVideoAssets;
              if (assets.isEmpty) {
                return const Center(
                  child: Text(
                    'No videos found',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                itemCount: assets.length,
                itemBuilder: (_, index) {
                  final asset = assets[index];
                  return GestureDetector(
                    onTap: () async {
                      final replace = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Replace Background?'),
                          content: const Text(
                            'The current background will be replaced with this video.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('CANCEL'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('REPLACE'),
                            ),
                          ],
                        ),
                      );
                      if (replace == true) {
                        final canvasSize = Size(
                          provider.canvasWidth > 0
                              ? provider.canvasWidth
                              : 1080.0,
                          provider.canvasHeight > 0
                              ? provider.canvasHeight
                              : 1080.0,
                        );
                        final sourceSize = await _resolveNetworkVideoSize(
                          asset.videoUrl,
                        );
                        provider.setBackgroundVideo(
                          asset.videoUrl,
                          canvasWidth: canvasSize.width,
                          canvasHeight: canvasSize.height,
                          sourceWidth: sourceSize?.width,
                          sourceHeight: sourceSize?.height,
                        );
                        provider.clearSelection();
                        if (mounted) setState(() {});
                        if (Navigator.canPop(modalContext))
                          Navigator.pop(modalContext);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF24262B)
                            : const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (asset.thumbnailUrl != null)
                            Image.network(
                              asset.thumbnailUrl!,
                              cacheWidth: 800,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                            ),
                          Container(color: Colors.black26),
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return Container(
              height: MediaQuery.of(sheetContext).size.height * .86,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF17191E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white38 : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
                      child: Row(
                        children: [
                          const Expanded(
                            child: AppText(
                              'Background',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              sheetOpen = false;
                              Navigator.pop(modalContext);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedTab == 0) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                        child: searchBox(forVideos: false),
                      ),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          scrollDirection: Axis.horizontal,
                          children: chips.map(chip).toList(),
                        ),
                      ),
                    ] else if (selectedTab == 1) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                        child: searchBox(forVideos: true),
                      ),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          scrollDirection: Axis.horizontal,
                          children: [
                            'Abstract',
                            'Loop',
                            'Animation',
                            'Nature',
                            'Technology',
                            'Texture',
                          ].map(videoChip).toList(),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                      child: Row(
                        children: [
                          _backgroundTab(
                            title: 'IMAGES',
                            selected: selectedTab == 0,
                            onTap: () => setSheetState(() => selectedTab = 0),
                          ),
                          const SizedBox(width: 24),
                          _backgroundTab(
                            title: 'VIDEOS',
                            selected: selectedTab == 1,
                            onTap: () => setSheetState(() => selectedTab = 1),
                          ),
                          const SizedBox(width: 24),
                          _backgroundTab(
                            title: 'COLORS',
                            selected: selectedTab == 2,
                            onTap: () => setSheetState(() => selectedTab = 2),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    Expanded(
                      child: selectedTab == 0
                          ? imageResults()
                          : selectedTab == 1
                          ? videosView()
                          : colorsView(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      sheetOpen = false;
      searchController.dispose();
      videoSearchController.dispose();
    });
  }

  Widget _backgroundTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            width: selected ? 46 : 0,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _musicPositionSubscription = _musicPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      context.read<EditorProvider>().setMusicPosition(position);
    });

    _musicDurationSubscription = _musicPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      context.read<EditorProvider>().setMusicDuration(duration);
    });

    _musicCompleteSubscription = _musicPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      final provider = context.read<EditorProvider>();
      provider.setMusicPlaying(false);
      provider.setMusicPosition(Duration.zero);
    });
  }

  @override
  void dispose() {
    _musicPositionSubscription?.cancel();
    _musicDurationSubscription?.cancel();
    _musicCompleteSubscription?.cancel();
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final hasTemplateUid = (widget.templateUid?.trim() ?? '').isNotEmpty;
    if (hasTemplateUid && provider.isTemplateDetailLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              AppText(
                'Loading template...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // IMPORTANT:
    // For an API template, canvas size MUST come from the template JSON/API.
    // Never use widget.resizeSize to resize an already-loaded template.
    // resizeSize is only used for a blank/new editor.
    final Size canvasSize = hasTemplateUid
        ? Size(
      provider.canvasWidth > 0 ? provider.canvasWidth : 1080.0,
      provider.canvasHeight > 0 ? provider.canvasHeight : 1080.0,
    )
        : _getCanvasSize();

    final double aspectRatio = canvasSize.width / canvasSize.height;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          widget.resizeSize,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.grey),
            onPressed: () => provider.undo(),
          ),
          IconButton(
            tooltip: 'Pages',
            icon: const Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.grey,
            ),
            onPressed: () => _showPagesSheet(context, provider, isDark),
          ),
          IconButton(
            tooltip: 'Copy Page',
            icon: const Icon(Icons.copy_all_rounded, color: Colors.grey),
            onPressed: () {
              provider.copyCurrentPage();
              Fluttertoast.showToast(
                msg: 'Page copied. Go to another page and paste.',
              );
            },
          ),
          IconButton(
            tooltip: 'Paste Page',
            icon: Icon(
              Icons.content_paste_rounded,
              color: provider.canPasteCopiedPage
                  ? Colors.grey
                  : Colors.grey.shade400,
            ),
            onPressed: !provider.canPasteCopiedPage
                ? null
                : () {
              final pasted = provider.pasteCopiedPage();
              if (pasted) {
                Fluttertoast.showToast(
                  msg:
                  'Copied page pasted to Page ${provider.currentPageIndex + 1}',
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Download',

            icon: const Icon(Icons.download_rounded, color: Colors.red),
            onPressed: () => _showExportSheet(context,provider),
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, color: Colors.grey),
            onPressed: () => provider.redo(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RepaintBoundary(
            key: _canvasKey,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(color: provider.backgroundColor),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double scaleX =
                        constraints.maxWidth / canvasSize.width;
                    final double scaleY =
                        constraints.maxHeight / canvasSize.height;

                    final backgroundItems = provider.items
                        .where(_isCanvasBackground)
                        .toList();

                    return ClipRect(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: provider.backgroundColor,
                                gradient: provider.importedBackgroundGradient,
                              ),
                            ),
                          ),

                          if (backgroundItems.isNotEmpty)
                            _InteractiveBackgroundLayer(
                              key: ValueKey(backgroundItems.last.id),
                              item: backgroundItems.last,
                              scaleX: scaleX,
                              scaleY: scaleY,
                              canvasWidth: canvasSize.width,
                              canvasHeight: canvasSize.height,
                              onSelected: () {
                                final bg = backgroundItems.last;

                                // Select the background exactly like a normal
                                // image layer so the image editor toolbar opens.
                                provider.setSelectedItem(bg.type, bg.id);

                                if (mounted) {
                                  setState(() {
                                    _bottomNavIndex = 3;
                                  });
                                }
                              },
                            ),

                          // IMPORTANT: selecting an item must NOT change its
                          // layer/z-order. Keep the provider's original order.
                          // A click only selects the item; Bring To Front /
                          // Send To Back are the only actions that should change
                          // the actual layer order.
                          ...(() {
                            final orderedItems = provider.items
                                .where((item) => !_isCanvasBackground(item))
                                .toList();

                            return orderedItems.map((item) {
                              return Positioned(
                                left: item.position.dx * scaleX,
                                top: item.position.dy * scaleY,
                                child: Transform.scale(
                                  scale: scaleX,
                                  alignment: Alignment.topLeft,
                                  child: EditableItemWidget(
                                    item: item,
                                    onItemSelected: (type, id) {
                                      provider.setSelectedItem(type, id);
                                    },
                                  ),
                                ),
                              );
                            });
                          })(),

                          // -----------------------------------------
                          // FRAME ATTACHED TO SELECTED IMAGE
                          // -----------------------------------------
                          if (provider.selectedFrameUrl != null &&
                              provider.selectedItemId != null)
                            Builder(
                              builder: (_) {
                                final selected = provider.items
                                    .where(
                                      (e) => e.id == provider.selectedItemId,
                                )
                                    .toList();

                                if (selected.isEmpty ||
                                    selected.first.type != 'image') {
                                  return const SizedBox.shrink();
                                }

                                final item = selected.first;
                                return Positioned(
                                  left: item.position.dx * scaleX,
                                  top: item.position.dy * scaleY,
                                  width: item.width * item.scale * scaleX,
                                  height: item.height * item.scale * scaleY,
                                  child: IgnorePointer(
                                    child: Transform.rotate(
                                      angle: item.rotation.isFinite
                                          ? item.rotation
                                          : 0.0,
                                      child: Image.asset(
                                        provider.selectedFrameUrl!,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildEditorBottomBar(context, provider, isDark),
    );
  }

  Widget _buildEditorBottomBar(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final type = (provider.selectedItemType ?? '').toLowerCase();
    if (type == 'text' || type == 'textbox') {
      return _buildTextEditorToolbar(context, provider, isDark);
    }

    // IMPORTANT: There is already one persistent editor bottom sheet in this
    // screen. Do not create/open another modal bottom sheet when an object is
    // tapped. Every selectable visual object must switch that SAME existing
    // sheet to the appropriate controls.
    //
    // Image-like/template objects (including background images, raster groups,
    // and generic image/shape objects coming from Fabric) use the existing
    // Image editor toolbar. This keeps CROP/PHOTO/FLIP/FILTER/MASK and the
    // existing Front/Back/Duplicate/Delete controls visible.
    // Shapes have their own controls (Fill, Outline color, style,
    // thickness and join). Do not route them through the image toolbar,
    // otherwise the colour controls are never shown.
    if (type == 'shape' ||
        type == 'rect' ||
        type == 'ellipse' ||
        type == 'circle' ||
        type == 'line' ||
        type == 'path' ||
        type == 'polygon') {
      return _buildShapeEditorToolbar(context, provider, isDark);
    }

    if (type == 'image' ||
        type == 'background' ||
        type == 'video' ||
        type == 'raster_group' ||
        type == 'svg_group' ||
        type == 'svg_element' ||
        type == 'group') {
      return _buildImageEditorToolbar(context, provider, isDark);
    }

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _bottomTool(
              Image.asset("assets/images/templates.png"),
              'TEMPLATES',
                  () => _showTemplatesBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/brush.png"),
              'FRAMES',
                  () => _showFramesBottomSheet(context, provider, isDark),
            ),
            /*_bottomTool(
             Image.asset("assets/images/text.png"),
              'MY BRAND',
                  () => _showMyBrandBottomSheet(context, provider, isDark),
            ),*/
            _bottomTool(
              Image.asset("assets/images/text.png"),
              'TEXT',
                  () => _showTextStylesBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/gallery.png"),
              'MEDIA',
                  () => _showMediaBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/gallery.png"),
              'BACKGROUND',
                  () => _showBackgroundBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/elements.png"),
              'ELEMENTS',
                  () => _showBackgroundBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/magic_star.png"),
              'AI TOOLS',
                  () => _showBackgroundBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/music.png"),
              provider.isEditorMusicPlaying ? 'PLAYING' : 'MUSIC',
                  () => _showMusicBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/brand_kit.png"),
              'BRAND KIT',
                  () => _showBackgroundBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/heart.png"),
              'FAVORITES',
                  () => _showBackgroundBottomSheet(context, provider, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTextColorPicker(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) async {
    var hsv = HSVColor.fromColor(provider.textColor(id));

    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final current = hsv.toColor();

            return AlertDialog(
              title: const Text('Text Color'),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: current,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hue
                    Row(
                      children: [
                        const SizedBox(width: 42, child: Text('Hue')),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 360,
                            value: hsv.hue,
                            onChanged: (v) {
                              setState(() {
                                hsv = hsv.withHue(v);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Saturation
                    Row(
                      children: [
                        const SizedBox(width: 42, child: Text('Sat')),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 1,
                            value: hsv.saturation,
                            onChanged: (v) {
                              setState(() {
                                hsv = hsv.withSaturation(v);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Brightness
                    Row(
                      children: [
                        const SizedBox(width: 42, child: Text('Val')),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 1,
                            value: hsv.value,
                            onChanged: (v) {
                              setState(() {
                                hsv = hsv.withValue(v);
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      '#${current.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
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

    if (picked != null) {
      provider.updateTextColor(id, picked);
    }
  }

  Widget _buildTextEditorToolbar(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final id = provider.selectedItemId;
    if (id == null) return const SizedBox.shrink();

    // Use the complete Google Fonts catalog instead of a hard-coded
    // seven-font list. The existing horizontal toolbar can scroll through
    // the complete catalog.
    final fonts = GoogleFonts.asMap().keys.toList()..sort();

    final alignments = <Map<String, dynamic>>[
      {
        'label': 'LEFT',
        'icon': Icons.format_align_left_rounded,
        'value': TextAlign.left,
      },
      {
        'label': 'CENTER',
        'icon': Icons.format_align_center_rounded,
        'value': TextAlign.center,
      },
      {
        'label': 'RIGHT',
        'icon': Icons.format_align_right_rounded,
        'value': TextAlign.right,
      },
      {
        'label': 'JUSTIFY',
        'icon': Icons.format_align_justify_rounded,
        'value': TextAlign.justify,
      },
    ];

    final palette = <Color>[
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 62,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _bottomTool(
                  Icons.edit_rounded,
                  'EDIT',
                      () => _showTextEditDialog(context, provider, id),
                ),
                _bottomTool(
                  Icons.format_size_rounded,
                  'SIZE',
                      () => _showTextSizeBottomSheet(context, provider, id, isDark),
                ),
                ...fonts.map(
                      (font) => _bottomTool(
                    Icons.font_download_rounded,
                    font,
                        () => provider.updateFontFamily(id, font),
                    selected:
                    (provider.items
                        .firstWhere(
                          (e) => e.id == id,
                      orElse: () => provider.items.first,
                    )
                        .fontFamily)
                        .trim()
                        .toLowerCase() ==
                        font.toLowerCase(),
                  ),
                ),
                _bottomTool(
                  Icons.format_bold_rounded,
                  'BOLD',
                      () => provider.toggleTextBold(id),
                  selected: provider.textWeight(id) == FontWeight.bold,
                ),
                _bottomTool(
                  Icons.format_italic_rounded,
                  'ITALIC',
                      () => provider.toggleTextItalic(id),
                  selected: provider.textStyle(id) == FontStyle.italic,
                ),
                _bottomTool(
                  Icons.format_underlined_rounded,
                  'UNDERLINE',
                      () => provider.toggleTextUnderline(id),
                  selected: provider.textUnderline(id),
                ),
                ...alignments.map(
                      (item) => _bottomTool(
                    item['icon'] as IconData,
                    item['label'] as String,
                        () => provider.updateTextAlignment(
                      id,
                      item['value'] as TextAlign,
                    ),
                    selected: provider.textAlignment(id) == item['value'],
                  ),
                ),
                _bottomTool(
                  Icons.colorize_rounded,
                  'COLOR',
                      () => _showTextColorPicker(context, provider, id, isDark),
                ),
                ...palette.map(
                      (color) => _colorTool(
                    color,
                        () => provider.updateTextColor(id, color),
                  ),
                ),
                _bottomTool(
                  Icons.flip_to_front_rounded,
                  'FRONT',
                      () => provider.bringToFront(id),
                ),
                _bottomTool(
                  Icons.flip_to_back_rounded,
                  'BACK',
                      () => provider.sendToBack(id),
                ),
                _bottomTool(
                  Icons.copy_rounded,
                  'DUPLICATE',
                      () => provider.duplicateItem(id),
                ),
                _bottomTool(
                  Icons.delete_outline_rounded,
                  'DELETE',
                      () => provider.removeItem(id),
                  danger: true,
                ),
                _bottomTool(
                  Icons.close_rounded,
                  'CLOSE',
                  provider.clearSelection,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _bottomSliderTool(
                  'FONT SIZE',
                  provider.items
                      .firstWhere(
                        (e) => e.id == id,
                    orElse: () => provider.items.first,
                  )
                      .fontSize,
                  8,
                  300,
                      (v) => provider.updateFontSize(id, v),
                ),
                _bottomSliderTool(
                  'LETTER SPACING',
                  provider.textLetterSpacing(id),
                  -2,
                  20,
                      (v) => provider.updateTextLetterSpacing(id, v),
                ),
                _bottomSliderTool(
                  'LINE SPACING',
                  provider.textLineSpacing(id),
                  .7,
                  3,
                      (v) => provider.updateTextLineSpacing(id, v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTextSizeBottomSheet(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    final item = provider.items.firstWhere(
          (e) => e.id == id,
      orElse: () => provider.items.first,
    );

    double size = item.fontSize.isFinite
        ? item.fontSize.clamp(8.0, 300.0).toDouble()
        : 32.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final current = provider.items.firstWhere(
                  (e) => e.id == id,
              orElse: () => item,
            );
            final currentSize = current.fontSize.isFinite
                ? current.fontSize.clamp(8.0, 300.0).toDouble()
                : size;

            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF17191F) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.format_size_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Text Size',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          currentSize.round().toString(),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(sheetContext).copyWith(
                        activeTrackColor: Colors.amber,
                        thumbColor: Colors.amber,
                        overlayColor: Colors.amber.withValues(alpha: .15),
                      ),
                      child: Slider(
                        value: currentSize,
                        min: 8,
                        max: 300,
                        onChanged: (v) {
                          size = v;
                          setSheetState(() {});
                          provider.updateFontSize(id, v);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '8',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '300',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildMaskPreview(String url) {
    final clean = url.toLowerCase().split('?').first.split('#').first;
    final isSvg = clean.endsWith('.svg') || clean.endsWith('.svgz');

    if (isSvg) {
      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
    }

    return Image.network(
      url,
      cacheWidth: 800,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.broken_image_outlined, color: Colors.grey),
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
    );
  }

  void _showApiMaskSheet(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      ) {
    String query = '';
    bool requested = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            if (!requested) {
              requested = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await provider.fetchElementCategory(
                  'masks',
                  page: 1,
                  limit: 30,
                );
                if (sheetContext.mounted) setState(() {});
              });
            }

            final masks = provider.assetCategoryItems('masks');
            final q = query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? masks
                : masks.where((m) => m.name.toLowerCase().contains(q)).toList();
            final loading = provider.isElementCategoryLoading('masks');

            return SizedBox(
              height: MediaQuery.of(sheetContext).size.height * .70,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Image Masks',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Search image masks',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: loading && filtered.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                        ? const Center(child: Text('No mask found'))
                        : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final mask = filtered[index];
                        final url = provider.assetCdnUrl(mask.previewKey);
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: url.isEmpty
                              ? null
                              : () {
                            // Apply the selected mask only to the image
                            // whose Image > MASK toolbar opened this sheet.
                            provider.setImageMask(
                              itemId,
                              name: mask.name,
                              url: url,
                            );
                            Navigator.pop(sheetContext);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: url.isEmpty
                                ? const Icon(
                              Icons.image_not_supported_outlined,
                            )
                                : _buildMaskPreview(url),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShapeEditorToolbar(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final id = provider.selectedItemId;
    if (id == null) return const SizedBox.shrink();

    final item = provider.items.firstWhere(
          (e) => e.id == id,
      orElse: () => provider.items.first,
    );

    final fillColor = item.color ?? Colors.white;
    final outlineColor = item.outlineColor ?? const Color(0xFFD9D9D9);
    final outlineStyle = provider.outlineStyle(id);
    final outlineJoin = provider.outlineJoin(id);

    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _shapeColorTool(
                  'FILL',
                  fillColor,
                      () => _showShapeColorPicker(
                    context,
                    provider,
                    id,
                    isOutline: false,
                  ),
                ),
                _shapeColorTool(
                  'OUTLINE',
                  outlineColor,
                      () => _showShapeColorPicker(
                    context,
                    provider,
                    id,
                    isOutline: true,
                  ),
                ),
                _bottomTool(
                  Icons.flip_to_front_rounded,
                  'FRONT',
                      () => provider.bringToFront(id),
                ),
                _bottomTool(
                  Icons.flip_to_back_rounded,
                  'BACK',
                      () => provider.sendToBack(id),
                ),
                _bottomTool(
                  Icons.copy_rounded,
                  'DUPLICATE',
                      () => provider.duplicateItem(id),
                ),
                _bottomTool(
                  Icons.delete_outline_rounded,
                  'DELETE',
                      () => provider.removeItem(id),
                  danger: true,
                ),
                _bottomTool(
                  Icons.close_rounded,
                  'CLOSE',
                  provider.clearSelection,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _shapeOutlineStyleTools(
                  outlineStyle,
                      (style) => provider.updateOutlineStyle(id, style),
                ),
                _bottomSliderTool(
                  'THICKNESS',
                  item.outlineWidth.clamp(0.0, 20.0),
                  0,
                  20,
                      (v) => provider.updateOutline(id, v, outlineColor),
                ),
                _shapeJoinTools(
                  outlineJoin,
                      (join) => provider.updateOutlineJoin(id, join),
                ),
                _bottomSliderTool(
                  'ROTATION',
                  item.rotation.clamp(0.0, math.pi * 2),
                  0,
                  math.pi * 2,
                      (v) => provider.updateRotation(id, v),
                ),
                _bottomSliderTool(
                  'OPACITY',
                  item.opacity.clamp(0.0, 1.0),
                  0,
                  1,
                      (v) => provider.updateOpacity(id, v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shapeColorTool(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1F232C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shapeOutlineStyleTools(
      String selected,
      ValueChanged<String> onChanged,
      ) {
    const styles = <String>['none', 'solid', 'dashed', 'dotted', 'fine_dotted'];
    const labels = <String>['NONE', 'SOLID', 'DASHED', 'DOTTED', 'FINE'];

    return Container(
      width: 330,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OUTLINE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 46,
            child: Row(
              children: List.generate(styles.length, (index) {
                final style = styles[index];
                final selectedStyle = selected == style;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => onChanged(style),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedStyle
                              ? const Color(0xFFFFC107)
                              : const Color(0xFF252A34),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: selectedStyle
                                ? const Color(0xFFFFC107)
                                : Colors.white10,
                          ),
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(38, 16),
                            painter: _OutlineStylePreviewPainter(style),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: labels
                .map(
                  (label) => Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _shapeJoinTools(String selected, ValueChanged<String> onChanged) {
    const joins = <String>['miter', 'bevel', 'round'];
    const labels = <String>['MITER', 'BEVEL', 'ROUND'];
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JOIN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 46,
            child: Row(
              children: List.generate(joins.length, (index) {
                final value = joins[index];
                final active = selected == value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => onChanged(value),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFFFC107)
                              : const Color(0xFF252A34),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: active
                                ? const Color(0xFFFFC107)
                                : Colors.white10,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            value == 'round'
                                ? Icons.rounded_corner
                                : value == 'bevel'
                                ? Icons.change_history_rounded
                                : Icons.crop_square_rounded,
                            size: 20,
                            color: active ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
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

    Color current = isOutline
        ? (item.outlineColor ?? const Color(0xFFD9D9D9))
        : (item.color ?? Colors.white);

    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        HSVColor hsv = HSVColor.fromColor(current);
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  const SizedBox(height: 12),
                  _shapeColorSlider(
                    'HUE',
                    hsv.hue,
                    360,
                        (v) => setDialogState(() => hsv = hsv.withHue(v)),
                  ),
                  _shapeColorSlider(
                    'SAT',
                    hsv.saturation,
                    1,
                        (v) => setDialogState(() => hsv = hsv.withSaturation(v)),
                  ),
                  _shapeColorSlider(
                    'VALUE',
                    hsv.value,
                    1,
                        (v) => setDialogState(() => hsv = hsv.withValue(v)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${current.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
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

  Widget _shapeColorSlider(
      String label,
      double value,
      double max,
      ValueChanged<double> onChanged,
      ) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: max,
            value: value.clamp(0, max),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildImageEditorToolbar(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final id = provider.selectedItemId;
    if (id == null) return const SizedBox.shrink();

    final item = provider.items.firstWhere(
          (e) => e.id == id,
      orElse: () => provider.items.first,
    );

    const filters = <String>[
      'normal',
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

    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              key: PageStorageKey<String>('image-tools-$id'),
              scrollDirection: Axis.horizontal,
              controller: ScrollController(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _bottomTool(Icons.wallpaper_rounded, 'REPLACE BG', () async {
                  final url = item.contentUrl;
                  if (url != null && url.isNotEmpty) {
                    await _confirmReplaceBackground(
                      context,
                      provider,
                      url,
                      selectedItemId: id,
                    );
                  }
                }),
                _bottomTool(
                  Icons.crop_rounded,
                  'CROP',
                      () => _cropSelectedImage(context, provider, id),
                ),
                _bottomTool(Icons.photo_library_rounded, 'PHOTO', () async {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null)
                    provider.addImage(image.path, isLocal: true);
                }),
                _bottomTool(
                  Icons.flip_rounded,
                  'FLIP',
                      () => setState(() => _showFlipOptions = !_showFlipOptions),
                  selected: _showFlipOptions,
                ),
                _bottomTool(
                  Icons.flip_to_front_rounded,
                  'FRONT',
                      () => provider.bringToFront(id),
                ),
                _bottomTool(
                  Icons.flip_to_back_rounded,
                  'BACK',
                      () => provider.sendToBack(id),
                ),
                _bottomTool(
                  Icons.copy_rounded,
                  'DUPLICATE',
                      () => provider.duplicateItem(id),
                ),
                _bottomTool(
                  Icons.delete_outline_rounded,
                  'DELETE',
                      () => provider.removeItem(id),
                  danger: true,
                ),
                _bottomTool(
                  Icons.close_rounded,
                  'CLOSE',
                  provider.clearSelection,
                ),
              ],
            ),
          ),
          if (_showFlipOptions)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Flip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _flipOption(
                          Icons.flip_rounded,
                          'Flip Horizontal',
                              () => provider.flipImageHorizontal(id),
                        ),
                      ),
                      Expanded(
                        child: _flipOption(
                          Icons.flip_rounded,
                          'Flip Vertical',
                              () => provider.flipImageVertical(id),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 64,
            child: ListView(
              key: PageStorageKey<String>('image-filter-tools-$id'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _labelledHorizontalList(
                  'FILTER',
                  filters,
                      (value) => provider.setImageFilter(id, value),
                  selected: item.filterType,
                ),
                _bottomTool(
                  Icons.category_rounded,
                  'MASK',
                      () => _showApiMaskSheet(context, provider, id),
                  selected:
                  provider.imageMaskUrl(id) != null ||
                      (item.text != null &&
                          item.text!.trim().isNotEmpty &&
                          item.text != 'image'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _bottomSliderTool(
                  'FILTER INTENSITY',
                  provider.imageFilterIntensity(id),
                  0,
                  1,
                      (v) => provider.updateImageFilterIntensity(id, v),
                ),
                _bottomSliderTool(
                  'BRIGHTNESS',
                  item.brightness,
                  -1,
                  1,
                      (v) =>
                      provider.updateImageColorAdjustments(id, brightness: v),
                ),
                _bottomSliderTool(
                  'CONTRAST',
                  item.contrast,
                  .5,
                  2,
                      (v) => provider.updateImageColorAdjustments(id, contrast: v),
                ),
                _bottomSliderTool(
                  'TINT',
                  provider.imageTint(id),
                  -100,
                  100,
                      (v) => provider.updateImageTint(id, v),
                ),
                _bottomSliderTool(
                  'SATURATION',
                  item.saturation,
                  0,
                  2,
                      (v) =>
                      provider.updateImageColorAdjustments(id, saturation: v),
                ),
                _bottomSliderTool(
                  'BLUR',
                  provider.imageBlur(id),
                  0,
                  20,
                      (v) => provider.updateImageBlur(id, v),
                ),
                _bottomSliderTool(
                  'SCALE',
                  item.scale.clamp(.5, 3.0),
                  .5,
                  3,
                      (v) => provider.updateScale(id, v),
                ),
                _bottomSliderTool(
                  'ROTATION',
                  item.rotation.clamp(0.0, math.pi * 2),
                  0,
                  math.pi * 2,
                      (v) => provider.updateRotation(id, v),
                ),
                _bottomSliderTool(
                  'OPACITY',
                  item.opacity.clamp(0.0, 1.0),
                  0,
                  1,
                      (v) => provider.updateOpacity(id, v),
                ),
                _outlineStyleTools(
                  provider.outlineStyle(id),
                      (style) => provider.updateOutlineStyle(id, style),
                ),
                _bottomSliderTool(
                  'OUTLINE WIDTH',
                  item.outlineWidth.clamp(0.0, 20.0),
                  0,
                  20,
                      (v) => provider.updateOutline(
                    id,
                    v,
                    item.outlineColor ?? const Color(0xFFD9D9D9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineStyleTools(String selected, ValueChanged<String> onChanged) {
    const styles = <String>['none', 'solid', 'dashed', 'dotted', 'fine_dotted'];
    const labels = <String>['None', 'Solid', 'Dashed', 'Dotted', 'Fine Dotted'];

    return SizedBox(
      width: 310,
      height: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 5),
            child: Text(
              'OUTLINE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: styles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final style = styles[index];
                final isSelected = selected == style;
                return GestureDetector(
                  onTap: () => onChanged(style),
                  child: SizedBox(
                    width: 54,
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFECEE)
                                : const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFE53935)
                                  : Colors.transparent,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _OutlineStylePreviewPainter(style),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFE53935)
                                : Colors.white70,
                            fontSize: 8,
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
  }

  Widget _flipOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: Colors.white70),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomTool(
      dynamic icon,
      String label,
      VoidCallback onTap, {
        bool selected = false,
        bool danger = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: danger
                ? Colors.red.withValues(alpha: .16)
                : selected
                ? Colors.amber.withValues(alpha: .18)
                : const Color(0xFF1F232C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Colors.amber : Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon OR Image.asset
              if (icon is IconData)
                Icon(icon, color: danger ? Colors.red : Colors.white, size: 19)
              else if (icon is Widget)
                SizedBox(width: 19, height: 19, child: icon),

              const SizedBox(height: 3),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorTool(Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1F232C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'COLOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelledHorizontalList(
      String title,
      List<String> values,
      ValueChanged<String> onSelected, {
        String? selected,
      }) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF151820),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...values.map(
                (value) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: InkWell(
                onTap: () => onSelected(value),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected == value
                        ? Colors.amber.withValues(alpha: .18)
                        : const Color(0xFF252A34),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected == value ? Colors.amber : Colors.white10,
                    ),
                  ),
                  child: Text(
                    value.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSliderTool(
      String title,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      ) {
    final safeValue = value.isFinite ? value.clamp(min, max).toDouble() : min;
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F232C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title == 'OPACITY'
                    ? '${(safeValue * 100).round()}%'
                    : safeValue.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Expanded(
            child: Slider(
              value: safeValue,
              min: min,
              max: max,
              activeColor: Colors.amber,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTextEditDialog(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      ) async {
    final item = provider.items.firstWhere(
          (e) => e.id == itemId,
      orElse: () => provider.items.first,
    );
    final controller = TextEditingController(text: item.text ?? '');

    // Let the dialog return the edited text first. Updating the provider
    // while the dialog route is still being deactivated can trigger
    // InheritedElement.debugDeactivated (_dependents.isEmpty) in Flutter.
    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter text',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    // The showDialog Future completes when the route is popped, but Flutter
    // may still be deactivating the dialog subtree in the same frame.
    // Updating the ChangeNotifier immediately here can therefore rebuild the
    // editor while the dialog's inherited elements still have dependents,
    // causing: InheritedElement.debugDeactivated (_dependents.isEmpty).
    // Wait until the current frame has completely finished before notifying
    // the editor provider.
    await WidgetsBinding.instance.endOfFrame;

    controller.dispose();

    if (!mounted) return;
    if (newText != null && newText != item.text) {
      provider.updateTextContent(itemId, newText);
    }
  }

  Future<void> _toggleEditorMusic(EditorProvider provider) async {
    try {
      if (provider.selectedMusicPath == null) return;

      if (provider.isEditorMusicPlaying) {
        await _musicPlayer.pause();
        provider.setMusicPlaying(false);
      } else {
        await _musicPlayer.resume();
        provider.setMusicPlaying(true);
      }
    } catch (e) {
      debugPrint('Music toggle error: $e');
    }
  }

  Future<void> _pickMusicFile(EditorProvider provider) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final path = file.path;
      if (path == null || path.isEmpty) return;

      provider.setSelectedMusic(
        path: path,
        title: file.name,
      );

      await _musicPlayer.stop();
      await _musicPlayer.play(DeviceFileSource(path));
      provider.setMusicPlaying(true);
    } catch (e, stackTrace) {
      debugPrint('Music upload error: $e');
      debugPrintStack(stackTrace: stackTrace);
      provider.setMusicPlaying(false);
      Fluttertoast.showToast(msg: 'Unable to upload music');
    }
  }

  Future<void> _playMusicPath(
      EditorProvider provider,
      String path,
      String title,
      ) async {
    try {
      provider.setSelectedMusic(path: path, title: title);
      await _musicPlayer.stop();
      await _musicPlayer.play(DeviceFileSource(path));
      provider.setMusicPlaying(true);
    } catch (e) {
      debugPrint('Music play error: $e');
      provider.setMusicPlaying(false);
    }
  }

  void _showMusicBottomSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final searchController = TextEditingController();
    final tracks = <Map<String, String>>[
      {'title': 'Corporate 12', 'duration': '00.30'},
      {'title': 'Corporate 12', 'duration': '00.30'},
      {'title': 'Corporate 12', 'duration': '00.30'},
      {'title': 'Corporate 12', 'duration': '00.30'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = tracks.where((track) {
              final q = searchController.text.trim().toLowerCase();
              return q.isEmpty || track['title']!.toLowerCase().contains(q);
            }).toList();

            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * .82,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171717) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                          const Expanded(
                            child: Text(
                              'Music',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by tags, keywords',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: const Icon(Icons.mic, size: 18),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF242424)
                              : const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _musicChip('Super', true),
                          _musicChip('Greetings', false),
                          _musicChip('Thank You', false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final track = filtered[index];
                          final selected = provider.selectedMusicTitle ==
                              track['title'];
                          return GestureDetector(
                            onTap: () async {
                              // Demo list entries are placeholders. Real API
                              // tracks should pass their local/downloaded path.
                              if (provider.selectedMusicPath != null &&
                                  selected) {
                                await _toggleEditorMusic(provider);
                              }
                            },
                            child: Container(
                              height: 64,
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF211A1B)
                                    : const Color(0xFFFFF9F9),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFFFFCACA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE7E7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      provider.isEditorMusicPlaying && selected
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track['title']!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Duration: ${track['duration']}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: selected
                                        ? const Color(0xFFFF8F8F)
                                        : Colors.grey.shade300,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (provider.selectedMusicPath != null)
                      _buildNowPlayingBar(context, provider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickMusicFile(provider),
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('UPLOAD MUSIC'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                Fluttertoast.showToast(
                                  msg: 'Text to Audio coming soon',
                                );
                              },
                              icon: const Icon(Icons.graphic_eq, size: 16),
                              label: const Text('TEXT TO AUDIO'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
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
        );
      },
    ).whenComplete(searchController.dispose);
  }

  Widget _musicChip(String title, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNowPlayingBar(
      BuildContext context,
      EditorProvider provider,
      ) {
    final duration = provider.musicDuration.inMilliseconds;
    final position = provider.musicPosition.inMilliseconds;
    final progress = duration > 0
        ? (position / duration).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFFF2028),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _toggleEditorMusic(provider),
            icon: Icon(
              provider.isEditorMusicPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.selectedMusicTitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.white54,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await _musicPlayer.stop();
              provider.clearMusic();
            },
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Future<File?> _renderCurrentPagePng(EditorProvider provider) async {
    final boundary = _canvasKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/MMB_Page_${provider.currentPageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _downloadCurrentPage(BuildContext context) async {
    final provider = context.read<EditorProvider>();
    try {
      final file = await _renderCurrentPagePng(provider);
      if (file == null) {
        Fluttertoast.showToast(msg: 'Canvas is not ready');
        return;
      }

      // Open the native Android/iOS save/share sheet for the rendered PNG.
      // The rendered file contains only the canvas, not selection dots/handles.
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'MMB Design PNG',
        text: 'Save this MMB design image.',
      );
    } catch (e) {
      debugPrint('Download error: $e');
      Fluttertoast.showToast(msg: 'Unable to download design');
    }
  }

  Future<void> _exportCurrentPageJson(BuildContext context) async {
    final provider = context.read<EditorProvider>();
    try {
      final json = provider.exportCurrentPageJson();
      final prettyJson = const JsonEncoder.withIndent('  ').convert(json);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/MMB_Page_${provider.currentPageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(prettyJson, flush: true);

      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'MMB Editor JSON',
        text: 'Exported MMB editor page JSON.',
      );
      Fluttertoast.showToast(msg: 'JSON ready to save/share');
    } catch (e) {
      debugPrint('JSON export error: $e');
      Fluttertoast.showToast(msg: 'Unable to export JSON');
    }
  }

  Future<void> _exportCurrentPageZip(BuildContext context) async {
    final provider = context.read<EditorProvider>();
    try {
      final pngFile = await _renderCurrentPagePng(provider);
      if (pngFile == null) {
        Fluttertoast.showToast(msg: 'Canvas is not ready');
        return;
      }

      final json = provider.exportCurrentPageJson();
      final jsonBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(json),
      );

      final archive = Archive();
      archive.addFile(
        ArchiveFile(
          'MMB_Page_${provider.currentPageIndex + 1}.json',
          jsonBytes.length,
          jsonBytes,
        ),
      );

      final pngBytes = await pngFile.readAsBytes();
      archive.addFile(
        ArchiveFile(
          'MMB_Page_${provider.currentPageIndex + 1}.png',
          pngBytes.length,
          pngBytes,
        ),
      );

      // Bundle the selected music file into the project ZIP. PNG itself cannot
      // contain audio, so the audio is preserved as a separate project asset.
      final musicPath = provider.selectedMusicPath;
      if (musicPath != null && musicPath.isNotEmpty) {
        final musicFile = File(musicPath);
        if (await musicFile.exists()) {
          final musicBytes = await musicFile.readAsBytes();
          final musicName = provider.selectedMusicTitle?.trim().isNotEmpty == true
              ? provider.selectedMusicTitle!.trim()
              : 'selected_music.mp3';
          archive.addFile(
            ArchiveFile(
              'music/$musicName',
              musicBytes.length,
              musicBytes,
            ),
          );
        }
      }

      final zipBytes = ZipEncoder().encode(archive);

      final dir = await getTemporaryDirectory();
      final zipFile = File(
        '${dir.path}/MMB_Page_${provider.currentPageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      await zipFile.writeAsBytes(zipBytes, flush: true);

      if (!context.mounted) return;
      /*await SharePl.shareXFiles(
        [XFile(zipFile.path, mimeType: 'application/zip')],
        subject: 'MMB Editor Project ZIP',
        text: 'Exported MMB page JSON and PNG.',
      );*/
    } catch (e) {
      debugPrint('ZIP export error: $e');
      Fluttertoast.showToast(msg: 'Unable to create ZIP');
    }
  }

  void _showExportSheet(BuildContext context,EditorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF111318),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DOWNLOAD / EXPORT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _exportTile(
                        icon: Icons.image_rounded,
                        title: 'Image',
                        subtitle: 'PNG',
                        onTap: () {
                          Navigator.pop(modalContext);
                          _downloadCurrentPage(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _exportTile(
                        icon: Icons.data_object_rounded,
                        title: 'JSON',
                        subtitle: 'Page data',
                        onTap: () {
                          Navigator.pop(modalContext);
                          _exportCurrentPageJson(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _exportTile(
                        icon: Icons.folder_zip_rounded,
                        title: 'ZIP',
                        subtitle: provider.selectedMusicPath != null ? 'JSON + PNG + Music' : 'JSON + PNG',
                        onTap: () {
                          Navigator.pop(modalContext);
                          _exportCurrentPageZip(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _exportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFFC107), size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _showPagesSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * .58,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF17191E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add page',
                        onPressed: () {
                          provider.addPage();
                          setModalState(() {});
                        },
                        icon: const Icon(
                          Icons.add_circle_rounded,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Duplicate page',
                        onPressed: () {
                          provider.duplicateCurrentPage();
                          setModalState(() {});
                        },
                        icon: const Icon(
                          Icons.library_add_rounded,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete page',
                        onPressed: () {
                          provider.deleteCurrentPage();
                          setModalState(() {});
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: .82,
                      ),
                      itemCount: provider.pageCount,
                      itemBuilder: (_, index) {
                        final selected = index == provider.currentPageIndex;
                        return GestureDetector(
                          onTap: () {
                            provider.switchPage(index);
                            Navigator.pop(modalContext);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252932)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? Colors.red
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_rounded,
                                  size: 42,
                                  color: selected ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Page ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                if (selected)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
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
        );
      },
    );
  }
}

class _TransformSelectionOverlay extends StatefulWidget {
  final EditorItem item;
  final double scaleX;
  final double scaleY;
  final bool isBackground;
  final double canvasWidth;
  final double canvasHeight;

  const _TransformSelectionOverlay({
    super.key,
    required this.item,
    required this.scaleX,
    required this.scaleY,
    required this.canvasWidth,
    required this.canvasHeight,
    this.isBackground = false,
  });

  @override
  State<_TransformSelectionOverlay> createState() =>
      _TransformSelectionOverlayState();
}

class _TransformSelectionOverlayState
    extends State<_TransformSelectionOverlay> {
  final GlobalKey _overlayKey = GlobalKey();
  double _startRotation = 0.0;
  Offset _startPosition = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _rotationCenterGlobal = Offset.zero;
  double _rotationStartAngle = 0.0;

  // Actual source-image aspect ratio. The editor renders normal images with
  // BoxFit.contain, so the visible pixels can be smaller than item.width/height.
  double _imageAspectRatio = 1.0;
  bool _imageAspectReady = false;

  double _resizeStartScale = 1.0;
  Offset _resizeStartLocal = Offset.zero;
  Offset _resizeStartGlobal = Offset.zero;
  Offset _resizeStartPosition = Offset.zero;

  EditorProvider get _provider => context.read<EditorProvider>();

  // Normal media items are rendered inside a Transform.scale(scaleX), so
  // both axes use the canvas width scale. Background media is rendered by
  // _InteractiveBackgroundLayer with independent X/Y canvas scales.
  bool get _isText =>
      widget.item.type == 'text' || widget.item.type == 'textbox';

  Size get _naturalTextSize {
    final id = widget.item.id ?? '';
    final painter = TextPainter(
      text: TextSpan(
        text: widget.item.text ?? '',
        style: TextStyle(
          fontSize: widget.item.fontSize,
          color: widget.item.color ?? Colors.black,
          fontWeight: _provider.textWeight(id),
          fontStyle: _provider.textStyle(id),
          decoration: _provider.textUnderline(id)
              ? TextDecoration.underline
              : TextDecoration.none,
          letterSpacing: _provider.textLetterSpacing(id),
          height: _provider.textLineSpacing(id),
          fontFamily: (widget.item.fontFamily).trim().isEmpty
              ? null
              : widget.item.fontFamily.trim(),
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return Size(math.max(1.0, painter.width), math.max(1.0, painter.height));
  }

  double get _baseVisualWidth =>
      _isText ? _naturalTextSize.width : widget.item.width;
  double get _baseVisualHeight =>
      _isText ? _naturalTextSize.height : widget.item.height;

  double get _width => _baseVisualWidth * widget.item.scale * widget.scaleX;

  double get _height =>
      _baseVisualHeight *
          widget.item.scale *
          (widget.isBackground ? widget.scaleY : widget.scaleX);

  // Text now has a natural-size layout box, so its selection rectangle starts
  // exactly at item.position and only compensates for center scaling using the
  // measured text dimensions. Media keeps the same behavior.
  // Fabric `left` / `top` are the object's top-left origin. The rendered
  // EditableItemWidget also scales from top-left, so the selection overlay
  // must use the exact same origin with no center compensation.
  double get _left => widget.item.position.dx * widget.scaleX;

  double get _top => widget.item.position.dy * widget.scaleY;

  @override
  void initState() {
    super.initState();
    _loadImageAspectRatio();
  }

  Future<void> _loadImageAspectRatio() async {
    if (widget.item.type != 'image') {
      return;
    }

    final url = (widget.item.contentUrl ?? '').trim();
    if (url.isEmpty) return;

    try {
      final ImageProvider provider;
      if (url.startsWith('file://') || url.startsWith('/data/')) {
        provider = FileImage(File(url.replaceFirst('file://', '')));
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        provider = NetworkImage(url);
      } else {
        provider = FileImage(File(url));
      }

      final stream = provider.resolve(const ImageConfiguration());
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
            (info, _) {
          final w = info.image.width.toDouble();
          final h = info.image.height.toDouble();
          if (w > 0 && h > 0 && mounted) {
            setState(() {
              _imageAspectRatio = w / h;
              _imageAspectReady = true;
            });
          }
          stream.removeListener(listener);
        },
        onError: (_, __) {
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
    } catch (_) {
      // Keep the editor box as the fallback for unsupported image sources.
    }
  }

  double get _baseBoxWidth =>
      _baseVisualWidth * widget.item.scale * widget.scaleX;

  double get _baseBoxHeight =>
      _baseVisualHeight *
          widget.item.scale *
          (widget.isBackground ? widget.scaleY : widget.scaleX);

  // Exact visible rectangle produced by BoxFit.contain inside the item's
  // layout box. The API/template item width/height is the layout box, not
  // necessarily the visible image rectangle. For example, a landscape image
  // inside a tall box leaves empty space above/below. The selection border
  // and handles must surround only the rendered image area.
  Rect get _visualRect {
    final boxW = _baseBoxWidth;
    final boxH = _baseBoxHeight;

    if (!_imageAspectReady ||
        !_imageAspectRatio.isFinite ||
        _imageAspectRatio <= 0 ||
        boxW <= 0 ||
        boxH <= 0) {
      return Rect.fromLTWH(0, 0, boxW, boxH);
    }

    final boxAspect = boxW / boxH;
    double visibleW;
    double visibleH;

    if (_imageAspectRatio > boxAspect) {
      // Image is wider than the layout box. BoxFit.contain uses full width
      // and centers the remaining vertical space.
      visibleW = boxW;
      visibleH = boxW / _imageAspectRatio;
    } else {
      // Image is taller/narrower than the layout box. BoxFit.contain uses
      // full height and centers the remaining horizontal space.
      visibleH = boxH;
      visibleW = boxH * _imageAspectRatio;
    }

    visibleW = visibleW.clamp(0.0, boxW).toDouble();
    visibleH = visibleH.clamp(0.0, boxH).toDouble();

    return Rect.fromLTWH(
      (boxW - visibleW) / 2,
      (boxH - visibleH) / 2,
      visibleW,
      visibleH,
    );
  }

  // Match the rounded/pill shape used by template buttons.  The dotted
  // outline follows the visible object's rounded corners instead of drawing
  // a plain square rectangle.
  double _selectionBorderRadius(Size size) {
    if (size.width <= 0 || size.height <= 0) return 0;

    // Short button-like objects become pill shaped, while larger objects keep
    // a smaller rounded corner. This matches the rounded white category
    // buttons in the template (LIVING ROOM / BEDROOM / DINING / OFFICE).
    final maxRadius = size.height / 2.0;
    final proportionalRadius = size.height * 0.28;
    return math.min(10.0, math.min(maxRadius, proportionalRadius));
  }

  @override
  Widget build(BuildContext context) {
    final width = _baseBoxWidth;
    final height = _baseBoxHeight;
    final visual = _visualRect;

    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _left,
      top: _top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: widget.item.rotation.isFinite ? widget.item.rotation : 0.0,
        alignment: Alignment.center,
        child: Stack(
          key: _overlayKey,
          clipBehavior: Clip.none,
          children: [
            // Drag the selected image from anywhere inside the box.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  _startPosition = widget.item.position;
                  _startFocalPoint = details.globalPosition;
                },
                onPanUpdate: (details) {
                  final dx =
                      (details.globalPosition.dx - _startFocalPoint.dx) /
                          widget.scaleX;
                  final dy =
                      (details.globalPosition.dy - _startFocalPoint.dy) /
                          widget.scaleY;

                  // Drag in CANVAS coordinates. The item itself is rendered
                  // inside an outer Transform.scale, so global finger delta
                  // must first be converted by the canvas scale.
                  //
                  // The stored position is the top-left of the layout box,
                  // matching Fabric's originX/originY. The item widget now
                  // scales from that top-left point, so no half-scale offset
                  // must be added to the drag position.
                  // FREE MOVE: match the reference video. Do not clamp the
                  // object to the canvas edges. The canvas clips the part that
                  // is outside, and the object can be dragged back in from any
                  // direction.
                  final nextX = _startPosition.dx + dx;
                  final nextY = _startPosition.dy + dy;

                  _provider.updateItemTransform(
                    widget.item.id ?? '',
                    position: Offset(nextX, nextY),
                    clampToFrame: false,
                  );
                },
              ),
            ),

            // Selection UI follows the ACTUAL visible image rectangle.
            // Normal images use BoxFit.contain, so a landscape image inside a
            // square item must not get a square selection box around the empty
            // top/bottom space.
            Positioned(
              left: visual.left,
              top: visual.top,
              width: visual.width,
              height: visual.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ImageSelectionPainter(
                          style: _provider.outlineStyle(widget.item.id ?? ''),
                          outlineWidth: widget.item.outlineWidth,
                          outlineColor:
                          widget.item.outlineColor ??
                              const Color(0xFFD9D9D9),
                          borderRadius: _selectionBorderRadius(visual.size),
                        ),
                      ),
                    ),
                  ),
                  ...[
                    _buildHandle(
                      alignment: Alignment.topLeft,
                      cursor: SystemMouseCursors.resizeUpLeft,
                    ),
                    _buildHandle(
                      alignment: Alignment.topCenter,
                      cursor: SystemMouseCursors.resizeUp,
                    ),
                    _buildHandle(
                      alignment: Alignment.topRight,
                      cursor: SystemMouseCursors.resizeUpRight,
                    ),
                    _buildHandle(
                      alignment: Alignment.centerLeft,
                      cursor: SystemMouseCursors.resizeLeft,
                    ),
                    _buildHandle(
                      alignment: Alignment.centerRight,
                      cursor: SystemMouseCursors.resizeRight,
                    ),
                    _buildHandle(
                      alignment: Alignment.bottomLeft,
                      cursor: SystemMouseCursors.resizeDownLeft,
                    ),
                    _buildHandle(
                      alignment: Alignment.bottomCenter,
                      cursor: SystemMouseCursors.resizeDown,
                    ),
                    _buildHandle(
                      alignment: Alignment.bottomRight,
                      cursor: SystemMouseCursors.resizeDownRight,
                    ),
                  ],

                  // 3-dot control is outside the image selection rectangle.
                  Positioned(
                    left: visual.width + 10,
                    top: (visual.height / 2.0) - 26.0,
                    width: 52,
                    height: 52,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          final id = widget.item.id;
                          if (id != null && id.isNotEmpty) {
                            _provider.setSelectedItem(widget.item.type, id);
                          }
                        },
                        customBorder: const CircleBorder(),
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
                                blurRadius: 6,
                                offset: Offset(0, 2),
                                color: Color(0x33000000),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 25,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rotation handle follows the visible image rectangle.
            Positioned(
              left: visual.left + visual.width / 2 - 14,
              top: visual.top - 39,
              width: 28,
              height: 28,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _startRotation = widget.item.rotation;
                  _rotationCenterGlobal = _globalCenter();
                  _rotationStartAngle = math.atan2(
                    details.globalPosition.dy - _rotationCenterGlobal.dy,
                    details.globalPosition.dx - _rotationCenterGlobal.dx,
                  );
                },
                onPanUpdate: (details) {
                  final currentAngle = math.atan2(
                    details.globalPosition.dy - _rotationCenterGlobal.dy,
                    details.globalPosition.dx - _rotationCenterGlobal.dx,
                  );
                  final delta = _normalizeAngle(
                    currentAngle - _rotationStartAngle,
                  );

                  _provider.updateItemTransform(
                    widget.item.id ?? '',
                    rotation: _startRotation + delta,
                  );
                },
                child: const Center(child: _RotationHandleVisual()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Offset _globalCenter() {
    final box = _overlayKey.currentContext?.findRenderObject();
    final visual = _visualRect;
    if (box is RenderBox) {
      return box.localToGlobal(
        Offset(visual.left + visual.width / 2, visual.top + visual.height / 2),
      );
    }
    return Offset.zero;
  }

  double _normalizeAngle(double angle) {
    while (angle > math.pi) {
      angle -= math.pi * 2;
    }
    while (angle < -math.pi) {
      angle += math.pi * 2;
    }
    return angle;
  }

  Widget _buildHandle({
    required Alignment alignment,
    required MouseCursor cursor,
  }) {
    const handleSize = 34.0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: handleSize,
        height: handleSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _resizeStartScale = widget.item.scale.isFinite
                ? widget.item.scale
                : 1.0;
            _resizeStartPosition = widget.item.position;
            _resizeStartGlobal = details.globalPosition;
          },
          onPanUpdate: (details) {
            final baseWidth = math.max(1.0, widget.item.width);
            final baseHeight = math.max(1.0, widget.item.height);
            final globalDelta = details.globalPosition - _resizeStartGlobal;

            // Convert the finger movement into the item's local, unrotated
            // coordinate system. This keeps handles correct even after the
            // item has been rotated.
            final canvasDx = globalDelta.dx / widget.scaleX;
            final canvasDy =
                globalDelta.dy /
                    (widget.isBackground ? widget.scaleY : widget.scaleX);
            final angle = widget.item.rotation.isFinite
                ? widget.item.rotation
                : 0.0;
            final cosA = math.cos(angle);
            final sinA = math.sin(angle);
            final dx = canvasDx * cosA + canvasDy * sinA;
            final dy = -canvasDx * sinA + canvasDy * cosA;

            double deltaScale;
            if (alignment.x == 0) {
              // Top/bottom center handles: vertical resize only.
              deltaScale = alignment.y == 1
                  ? dy / baseHeight
                  : -dy / baseHeight;
            } else if (alignment.y == 0) {
              // Left/right center handles: horizontal resize only.
              deltaScale = alignment.x == 1 ? dx / baseWidth : -dx / baseWidth;
            } else {
              // Corner handles: use the larger proportional movement while
              // preserving the item's aspect ratio.
              final sx = alignment.x == 1 ? dx / baseWidth : -dx / baseWidth;
              final sy = alignment.y == 1 ? dy / baseHeight : -dy / baseHeight;
              deltaScale = sx.abs() >= sy.abs() ? sx : sy;
            }

            final newScale = (_resizeStartScale + deltaScale)
                .clamp(0.02, 10.0)
                .toDouble();
            final scaleDelta = newScale - _resizeStartScale;

            // The item is rendered with a top-left scale origin, matching
            // Fabric's originX/originY. Keep the opposite edge/corner fixed:
            // right/bottom handles leave position unchanged; left/top
            // handles move the top-left by the amount the size changed.
            final anchorX = alignment.x == -1 ? -baseWidth * scaleDelta : 0.0;
            final anchorY = alignment.y == -1 ? -baseHeight * scaleDelta : 0.0;

            // Rotate the position correction back into canvas coordinates.
            final correctedX = anchorX * cosA - anchorY * sinA;
            final correctedY = anchorX * sinA + anchorY * cosA;
            final nextPosition = Offset(
              _resizeStartPosition.dx + correctedX,
              _resizeStartPosition.dy + correctedY,
            );

            _provider.updateItemTransform(
              widget.item.id ?? '',
              scale: newScale,
              position: nextPosition,
              // Do not clamp during resize. Clamping here changes the anchor
              // edge when the object is resized at the canvas boundary and
              // causes the exact jump visible in the previous implementation.
              clampToFrame: false,
            );
          },
          child: MouseRegion(
            cursor: cursor,
            child: const Center(child: _ResizeHandleVisual()),
          ),
        ),
      ),
    );
  }

  Offset _globalToOverlay(Offset globalPosition) {
    final box = _overlayKey.currentContext?.findRenderObject();
    if (box is RenderBox) {
      return box.globalToLocal(globalPosition);
    }
    return Offset(_width / 2, _height / 2);
  }
}

class _ResizeHandleVisual extends StatelessWidget {
  const _ResizeHandleVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2196F3), width: 2),
      ),
    );
  }
}

class _RotationHandleVisual extends StatelessWidget {
  const _RotationHandleVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2196F3), width: 2),
      ),
    );
  }
}

class _OutlineStylePreviewPainter extends CustomPainter {
  final String style;

  const _OutlineStylePreviewPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final left = 7.0;
    final right = size.width - 7.0;

    if (style == 'none') {
      final paint = Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawCircle(Offset(size.width / 2, centerY), 8, paint);
      canvas.drawLine(
        Offset(size.width / 2 - 6, centerY - 6),
        Offset(size.width / 2 + 6, centerY + 6),
        paint,
      );
      return;
    }

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = style == 'dotted' || style == 'fine_dotted'
          ? StrokeCap.round
          : StrokeCap.butt
      ..strokeWidth = style == 'fine_dotted' ? 2.0 : 3.0;

    if (style == 'solid') {
      canvas.drawLine(Offset(left, centerY), Offset(right, centerY), paint);
      return;
    }

    final dash = style == 'dashed'
        ? 9.0
        : style == 'dotted'
        ? 2.5
        : 1.2;
    final gap = style == 'dashed'
        ? 6.0
        : style == 'dotted'
        ? 5.0
        : 3.5;

    double x = left;
    while (x < right) {
      final end = math.min(x + dash, right);
      if (style == 'dotted' || style == 'fine_dotted') {
        canvas.drawCircle(
          Offset(x + (end - x) / 2, centerY),
          paint.strokeWidth / 2,
          paint,
        );
      } else {
        canvas.drawLine(Offset(x, centerY), Offset(end, centerY), paint);
      }
      x = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _OutlineStylePreviewPainter oldDelegate) =>
      oldDelegate.style != style;
}

class _ImageSelectionPainter extends CustomPainter {
  final String style;
  final double outlineWidth;
  final Color outlineColor;
  final double borderRadius;

  const _ImageSelectionPainter({
    this.style = 'none',
    this.outlineWidth = 1.8,
    this.outlineColor = const Color(0xFFD9D9D9),
    this.borderRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // The outline is an editor selection aid. It must follow the visible
    // object's rounded shape, not a hard rectangular box. This is especially
    // important for the template's category buttons where the selected
    // LIVING ROOM / BEDROOM / DINING / OFFICE element has rounded corners.
    if (style != 'none' && outlineWidth > 0) {
      final width = outlineWidth.clamp(1.0, 20.0).toDouble();
      final paint = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final inset = width / 2.0;
      final rect = Rect.fromLTWH(
        inset,
        inset,
        math.max(0.0, size.width - width),
        math.max(0.0, size.height - width),
      );

      final radius = borderRadius
          .clamp(0.0, math.min(rect.width, rect.height) / 2.0)
          .toDouble();
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

      if (style == 'solid') {
        canvas.drawRRect(rrect, paint);
      } else {
        _drawDashedRRect(
          canvas,
          rrect,
          paint,
          dash: style == 'dashed' ? 8.0 : 1.5,
          gap: style == 'dashed' ? 5.0 : 4.0,
          dotted: style == 'dotted' || style == 'fine_dotted',
        );
      }

      return;
    }

    // Default editor selection border.
    const selectionColor = Color(0xFF2196F3);
    const strokeWidth = 1.8;

    final borderPaint = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      math.max(0.0, size.width - strokeWidth),
      math.max(0.0, size.height - strokeWidth),
    );

    final radius = borderRadius
        .clamp(0.0, math.min(rect.width, rect.height) / 2.0)
        .toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      borderPaint,
    );
  }

  void _drawDashedRRect(
      Canvas canvas,
      RRect rrect,
      Paint paint, {
        required double dash,
        required double gap,
        required bool dotted,
      }) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final segmentLength = math.min(dash, metric.length - distance);
        final p1 = metric.getTangentForOffset(distance);
        final p2 = metric.getTangentForOffset(distance + segmentLength);
        if (p1 == null || p2 == null) break;

        if (dotted) {
          // Draw a round dot at the centre of each dash segment. Because the
          // path itself contains the rounded corners, the dots follow those
          // corners naturally instead of cutting across them.
          canvas.drawCircle(
            p1.position + (p2.position - p1.position) / 2.0,
            paint.strokeWidth / 2.0,
            Paint()
              ..color = paint.color
              ..style = PaintingStyle.fill,
          );
        } else {
          final segmentPath = metric.extractPath(
            distance,
            distance + segmentLength,
          );
          canvas.drawPath(segmentPath, paint);
        }

        distance += segmentLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ImageSelectionPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.outlineWidth != outlineWidth ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _InteractiveBackgroundLayer extends StatefulWidget {
  final EditorItem item;
  final double scaleX;
  final double scaleY;
  final double canvasWidth;
  final double canvasHeight;
  final VoidCallback onSelected;

  const _InteractiveBackgroundLayer({
    super.key,
    required this.item,
    required this.scaleX,
    required this.scaleY,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onSelected,
  });

  @override
  State<_InteractiveBackgroundLayer> createState() =>
      _InteractiveBackgroundLayerState();
}

class _InteractiveBackgroundLayerState
    extends State<_InteractiveBackgroundLayer> {
  Offset _startPosition = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  double _startScale = 1.0;
  double _startRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // Backgrounds are canvas layers, not normal media layers. Their source
    // image dimensions/aspect ratio must never determine the displayed size.
    // Always use the editor canvas dimensions as the base size; scale/rotation
    // are then applied on top of that by the editor controls.
    final baseWidth = widget.canvasWidth;
    final baseHeight = widget.canvasHeight;

    // A newly applied/replaced background is anchored to the canvas origin.
    // If the user later transforms it, preserve the stored position.
    final isDefaultTransform =
        item.position.dx.abs() < 0.5 && item.position.dy.abs() < 0.5;

    return Positioned(
      left: (isDefaultTransform ? 0.0 : item.position.dx) * widget.scaleX,
      top: (isDefaultTransform ? 0.0 : item.position.dy) * widget.scaleY,
      width: baseWidth * item.scale * widget.scaleX,
      height: baseHeight * item.scale * widget.scaleY,
      child: GestureDetector(
        onTap: widget.onSelected,

        onScaleStart: (details) {
          widget.onSelected();

          _startPosition = item.position;
          _startFocalPoint = details.focalPoint;

          _startScale = item.scale;
          _startRotation = item.rotation;
        },

        onScaleUpdate: (details) {
          final provider = context.read<EditorProvider>();

          // Move
          final dx =
              (details.focalPoint.dx - _startFocalPoint.dx) / widget.scaleX;

          final dy =
              (details.focalPoint.dy - _startFocalPoint.dy) / widget.scaleY;

          final newPosition = Offset(
            _startPosition.dx + dx,
            _startPosition.dy + dy,
          );

          // Scale
          final newScale = (_startScale * details.scale).clamp(0.1, 10.0);

          // Rotation
          final newRotation = _startRotation + details.rotation;

          provider.updateItemTransform(
            item.id ?? '',
            position: newPosition,
            scale: newScale,
            rotation: newRotation,
          );
        },

        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.rotate(
              angle: item.rotation,
              child: Opacity(
                opacity: item.opacity.clamp(0.0, 1.0),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: baseWidth,
                    height: baseHeight,
                    child: EditableItemWidget.buildStandaloneMediaContent(
                      context,
                      item,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onSelected,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2196F3),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 6,
                          offset: Offset(0, 2),
                          color: Color(0x22000000),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundQuickMenu(BuildContext context) {
    final id = widget.item.id;
    if (id == null || id.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final provider = context.read<EditorProvider>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _backgroundAction(
                  sheetContext,
                  Icons.flip_to_front_rounded,
                  'Front',
                      () => provider.bringToFront(id),
                ),
                _backgroundAction(
                  sheetContext,
                  Icons.copy_rounded,
                  'Duplicate',
                      () => provider.duplicateItem(id),
                ),
                _backgroundAction(
                  sheetContext,
                  Icons.delete_outline_rounded,
                  'Delete',
                      () => provider.removeItem(id),
                  destructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _backgroundAction(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap, {
        bool destructive = false,
      }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: destructive ? Colors.red : null),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: destructive ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
