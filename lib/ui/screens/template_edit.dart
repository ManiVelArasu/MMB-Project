import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:project_mmb/ui/screens/video_widget/editor_video.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../Api Model/editor_model.dart';
import '../../Repository/freePic.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';
import '../../network/provider/custom_theme_provider.dart';

class TemplateEditScreen extends StatelessWidget {
  final String? resizeSize;
  final String? templateUid;

  const TemplateEditScreen({
    super.key,
    this.resizeSize,
    this.templateUid,
  });

  bool _isSelectedCanvasBackground(EditorProvider provider) {
    final id = provider.selectedItemId;
    if (id == null) return false;

    final item = provider.items.where((e) => e.id == id).toList();
    if (item.isEmpty) return false;

    final value = item.first;
    return value.id?.startsWith('bg_') == true ||
        (value.position.dx == 0 &&
            value.position.dy == 0 &&
            value.width >= 1000 &&
            value.height >= 1000);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String resolvedResizeSize = resizeSize??'';

    if (args is String && args.trim().isNotEmpty) {
      resolvedResizeSize = args.trim();
    } else if (args is Map) {
      final value = args['resizeSize'] ?? args['resize_size'];
      if (value is String && value.trim().isNotEmpty) {
        resolvedResizeSize = value.trim();
      }
    }

    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: Scaffold(
        body: SafeArea(
          child: EditorView(
            resizeSize: resolvedResizeSize,
            templateUid: templateUid ??
                (args is Map ? args['templateUid']?.toString() : null),
          ),
        ),
      ),
    );
  }
}

class EditorView extends StatefulWidget {
  final String resizeSize;
  final String? templateUid;

  const EditorView({
    super.key,
    required this.resizeSize,
    this.templateUid,
  });

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  Size _getCanvasSize() {
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
    return const Size(1080, 1080);
  }

  bool _isCanvasBackground(EditorItem item) {
    // Background layers have a stable bg_ id, so they remain a background
    // even after the user drags / scales / rotates them.
    return item.id?.startsWith('bg_') == true &&
        (item.type == 'image' || item.type == 'video' || item.type == 'shape');
  }

  Widget _buildCanvasBackground(EditorProvider provider) {
    final bgItems = provider.items.where(_isCanvasBackground).toList();

    if (bgItems.isEmpty) {
      return Container(color: provider.backgroundColor);
    }

    final bg = bgItems.last;
    if (bg.type == 'image' &&
        bg.contentUrl != null &&
        bg.contentUrl!.isNotEmpty) {
      return Center(
        child: Transform.rotate(
          angle: bg.rotation.isFinite ? bg.rotation : 0.0,
          child: Transform.scale(
            scale: bg.scale.isFinite ? bg.scale.clamp(0.01, 10.0) : 1.0,
            child: Opacity(
              opacity: bg.opacity.isFinite ? bg.opacity.clamp(0.0, 1.0) : 1.0,
              child: SizedBox(
                width: bg.width,
                height: bg.height,
                child: EditableItemWidget.buildStandaloneMediaContent(
                  context,
                  bg,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (bg.type == 'video' &&
        bg.contentUrl != null &&
        bg.contentUrl!.isNotEmpty) {
      return Opacity(
        opacity: bg.opacity.isFinite ? bg.opacity.clamp(0.0, 1.0) : 1.0,
        child: Transform.rotate(
          angle: bg.rotation.isFinite ? bg.rotation : 0.0,
          child: Transform.scale(
            scale: bg.scale.isFinite ? bg.scale.clamp(0.01, 10.0) : 1.0,
            child: SizedBox(
              width: bg.width,
              height: bg.height,
              child: EditorVideoWidget(videoUrl: bg.contentUrl!),
            ),
          ),
        ),
      );
    }

    return Container(color: provider.backgroundColor);
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

  Future<Size?> _resolveNetworkImageSize(String url) async {
    try {
      final completer = Completer<Size>();
      final provider = NetworkImage(url);
      final stream = provider.resolve(const ImageConfiguration());
      late final ImageStreamListener listener;
      listener = ImageStreamListener((info, _) {
        final image = info.image;
        completer.complete(
          Size(image.width.toDouble(), image.height.toDouble()),
        );
        stream.removeListener(listener);
      }, onError: (error, stack) {
        if (!completer.isCompleted) completer.complete(null);
        stream.removeListener(listener);
      });
      stream.addListener(listener);
      return await completer.future.timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
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
            child: const Text('CANCEL'),
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
        final canvasSize = _getCanvasSize();
        final sourceSize = await _resolveNetworkImageSize(imageUrl);
        provider.replaceBackgroundImage(
          imageUrl,
          selectedItemId,
          canvasWidth: canvasSize.width,
          canvasHeight: canvasSize.height,
          sourceWidth: sourceSize?.width,
          sourceHeight: sourceSize?.height,
        );
      } else {
        // Background/stock image -> full-size background.
        // setBackgroundImage creates/selects the new bg_ layer.
        final canvasSize = _getCanvasSize();
        final sourceSize = await _resolveNetworkImageSize(imageUrl);
        provider.setBackgroundImage(
          imageUrl,
          canvasWidth: canvasSize.width,
          canvasHeight: canvasSize.height,
          sourceWidth: sourceSize?.width,
          sourceHeight: sourceSize?.height,
        );
      }

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
    final canvasSize = _getCanvasSize();
    provider.setCanvasSize(canvasSize.width, canvasSize.height);

    final uid = widget.templateUid?.trim() ?? '';
    if (uid.isNotEmpty) {
      await provider.loadTemplateByUid(
        uid,
        canvasWidth: canvasSize.width,
        canvasHeight: canvasSize.height,
      );
    } else {
      debugPrint('ℹ️ No template UID supplied; opening blank editor');
    }

    // Keep the editor asset panels working exactly as before.
    provider.fetchFreePikAssets("furniture");
    provider.fetchFreePikStickers("stickers");
  }

  static const List<String> _localShapeAssets = [
    'assets/shapes/4-point-star.svg',
    'assets/shapes/5-point-star.svg',
    'assets/shapes/8-point-badge.svg',
    'assets/shapes/badge-shield.svg',
    'assets/shapes/beveled-octagon.svg',
    'assets/shapes/bookmark.svg',
    'assets/shapes/capsule.svg',
    'assets/shapes/check-mark.svg',
    'assets/shapes/chevron-up.svg',
    'assets/shapes/circle.svg',
    'assets/shapes/cloud-badge.svg',
    'assets/shapes/corner-line.svg',
    'assets/shapes/crescent-moon.svg',
    'assets/shapes/curved-badge.svg',
    'assets/shapes/d-shape.svg',
    'assets/shapes/decorative-shield.svg',
    'assets/shapes/diamond.svg',
    'assets/shapes/diamond-gem.svg',
    'assets/shapes/diamond2.svg',
    'assets/shapes/egg-oval.svg',
    'assets/shapes/half-circle.svg',
    'assets/shapes/heart.svg',
    'assets/shapes/hexagon.svg',
    'assets/shapes/hexagon2.svg',
    'assets/shapes/hexagonal-capsule.svg',
    'assets/shapes/leaf.svg',
    'assets/shapes/line.svg',
    'assets/shapes/notched-square.svg',
    'assets/shapes/octagon.svg',
    'assets/shapes/oval-burst.svg',
    'assets/shapes/pennant-shield.svg',
    'assets/shapes/pentagon.svg',
    'assets/shapes/pentagon-shield.svg',
    'assets/shapes/pill.svg',
    'assets/shapes/plus.svg',
    'assets/shapes/pointed-shield.svg',
    'assets/shapes/quarter-ring.svg',
    'assets/shapes/rectangle.svg',
    'assets/shapes/ribbon-banner.svg',
    'assets/shapes/ribbon2.svg',
    'assets/shapes/round-shield.svg',
    'assets/shapes/rounded-rectangle-2.svg',
    'assets/shapes/rounded-shield.svg',
    'assets/shapes/rounded-speech-bubble.svg',
    'assets/shapes/rounded-square.svg',
    'assets/shapes/rounded-star.svg',
    'assets/shapes/scalloped-circle.svg',
    'assets/shapes/scalloped-oval.svg',
    'assets/shapes/seal.svg',
    'assets/shapes/sharp-star.svg',
    'assets/shapes/shield.svg',
    'assets/shapes/small-diamond.svg',
    'assets/shapes/speech-bubble.svg',
    'assets/shapes/spiky-burst.svg',
    'assets/shapes/square.svg',
    'assets/shapes/sunburst-circle.svg',
    'assets/shapes/swallowtail-ribbon.svg',
    'assets/shapes/tall-oval.svg',
    'assets/shapes/teardrop.svg',
    'assets/shapes/ticket.svg',
    'assets/shapes/trapezoid.svg',
    'assets/shapes/triangle.svg',
    'assets/shapes/u-shape.svg',
    'assets/shapes/up-arrow.svg',
    'assets/shapes/vertical-oval.svg',
    'assets/shapes/zigzag-ribbon.svg',
  ];

  Future<void> _addLocalShape(
      BuildContext context,
      EditorProvider provider,
      String assetPath,
      ) async {
    try {
      final pictureInfo = await vg.loadPicture(SvgAssetLoader(assetPath), null);

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

  Widget _buildTab(bool isSelected, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AppText(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.red : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(
              height: 2,
              width: 30,
              color: Colors.red,
              margin: const EdgeInsets.only(top: 4),
            ),
        ],
      ),
    );
  }

  Widget _textSheetContainer({
    required bool isDark,
    required Widget child,
    double height = 0.42,
  }) {
    return Container(
      height: WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
          ? WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .physicalSize
          .height /
          WidgetsBinding
              .instance
              .platformDispatcher
              .views
              .first
              .devicePixelRatio *
          height
          : 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }

  Widget _formatToggle({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.red.withValues(alpha: .10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.red : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.red : Colors.grey.shade700,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAdjustSlider(
      String title,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      ) {
    return Row(
      children: [
        SizedBox(width: 88, child: Text(title)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(value.toStringAsFixed(1), textAlign: TextAlign.right),
        ),
      ],
    );
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

  void _showMyBrandBottomSheet(
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
                      "Upload Brand Assets",
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
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(modalContext);
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      provider.addImage(image.path, isLocal: true);
                    }
                  },
                  child: const AppText(
                    "UPLOAD LOGO / IMAGE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                  title: AppText(
                    "My Heading",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    provider.addText(initialText: "My Heading");
                    Navigator.pop(modalContext);
                  },
                ),
                ListTile(
                  title: AppText(
                    "My Sub Title",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    provider.addText(initialText: "My Sub Title");
                    Navigator.pop(modalContext);
                  },
                ),
                ListTile(
                  title: AppText(
                    "My Text",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    provider.addText(initialText: "My Text");
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
    final searchController = TextEditingController();

    const categories = <Map<String, String>>[
      {'title': 'Shapes', 'query': 'shapes'},
      {'title': 'Masks', 'query': 'masks'},
      {'title': 'Stickers', 'query': 'stickers'},
      {'title': 'Social Media', 'query': 'social media'},
      {'title': 'E-commerce', 'query': 'e-commerce'},
    ];

    const imageCategories = <Map<String, String>>[
      {'title': 'Nature', 'query': 'nature'},
      {'title': 'People', 'query': 'people'},
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
      if (query == 'shapes' || query == 'masks') {
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
            if (selectedTab == 1 && expandedCategory == null) {
              for (final category in categories) {
                loadCategory(category['query']!, setSheetState);
              }
            }

            Widget elementCard(
                String url, {
                  bool locked = false,
                  VoidCallback? onTap,
                }) {
              final isLocalShape = url.startsWith('assets/shapes/');
              final bool isSvg =
              url.toLowerCase().split('?').first.endsWith('.svg');

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
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                    ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: Colors.grey,
                ),
              )
                  : Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: Colors.grey,
                ),
                loadingBuilder:
                    (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                      ),
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
                              ? Colors.orange.withOpacity(.55)
                              : Colors.orange.shade200)
                              : (isDark
                              ? Colors.white12
                              : const Color(0xFFE8E8E8)),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Opacity(
                        opacity: locked ? .38 : 1,
                        child: preview,
                      ),
                    ),
                    if (locked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.18),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.lock_rounded,
                                size: 20,
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
                    await _addLocalShape(
                      modalContext,
                      provider,
                      url,
                    );
                  } else if (isShape) {
                    // Shapes and masks must become real shape layers.
                    provider.addShape(
                      url,
                      isLocal: false,
                    );

                    if (modalContext.mounted) {
                      Navigator.pop(modalContext);
                    }
                  } else {
                    // Other API assets are normal image layers.
                    provider.addImage(
                      url,
                      isLocal: false,
                    );

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
                          ? previewStickers.map(
                            (url) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: elementCard(url),
                            ),
                          );
                        },
                      ).toList()
                          : previewAssets.map(
                            (item) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: assetCategoryCard(item, isShape: query == 'shapes' || query == 'masks'),
                            ),
                          );
                        },
                      ).toList(),
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
                final List<AssetCategoryItem> assetItems =
                stickerProxy ? const <AssetCategoryItem>[] : provider.assetCategoryItems(query);
                final List<String> stickerItems =
                stickerProxy ? provider.elementCategoryAssets(query) : const <String>[];
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
                          ? (provider.isFreePikStickerCategoryLoading[query] ?? false)
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
                        itemBuilder: (_, index) => isStickerProxyCategory(query)
                            ? elementCard(stickerItems[index])
                            : assetCategoryCard(assetItems[index], isShape: query == 'shapes' || query == 'masks'),
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
              const defaultQuery = 'background';
              final images = provider.mediaImageAssets;

              if (!provider.isMediaImagesLoading &&
                  images.isEmpty &&
                  provider.mediaImageAssets.isEmpty) {
                Future.microtask(() => provider.fetchMediaImages(defaultQuery));
              }

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
                      borderRadius: BorderRadius.circular(18),
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
                              onTap: () => setSheetState(() => selectedTab = 1),
                            ),
                            const SizedBox(width: 24),
                            _backgroundTab(
                              title: 'IMAGES',
                              selected: selectedTab == 2,
                              onTap: () {
                                setSheetState(() => selectedTab = 2);
                                if (provider.mediaImageAssets.isEmpty &&
                                    !provider.isMediaImagesLoading) {
                                  provider.fetchMediaImages('background');
                                }
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
              final currentQuery = forVideos ? videoSearchQuery : searchQuery;
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
                        final canvasSize = _getCanvasSize();
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
                            child: Text(
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
          Text(
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
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final canvasSize = _getCanvasSize();
    provider.setCanvasSize(canvasSize.width, canvasSize.height);
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
            onPressed: () => _showExportSheet(context),
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
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(
                            child: ColoredBox(color: provider.backgroundColor),
                          ),

                          if (backgroundItems.isNotEmpty)
                            _InteractiveBackgroundLayer(
                              key: ValueKey(backgroundItems.last.id),
                              item: backgroundItems.last,
                              scaleX: scaleX,
                              scaleY: scaleY,
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

                          ...provider.items
                              .where((item) => !_isCanvasBackground(item))
                              .map((item) {
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
                          }),

                          // -----------------------------------------
                          // FRAME
                          // -----------------------------------------
                          if (provider.selectedFrameUrl != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Image.asset(
                                  provider.selectedFrameUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                          // -----------------------------------------
                          // TRANSFORM SELECTION OVERLAY
                          // Keeps the existing editor behavior intact
                          // and only adds the Canva-style selection box when
                          // an image is selected.
                          // -----------------------------------------
                          if (provider.selectedItemId != null &&
                              (provider.selectedItemType == 'image' ||
                                  provider.selectedItemType == 'video' ||
                                  provider.selectedItemType == 'shape' ||
                                  provider.selectedItemType == 'svg_group' ||
                                  provider.selectedItemType == 'svg_element' ||
                                  provider.selectedItemType == 'raster_group' ||
                                  provider.selectedItemType == 'text' ||
                                  provider.selectedItemType == 'textbox') &&
                              !provider.items.any(
                                    (e) =>
                                e.id == provider.selectedItemId &&
                                    _isCanvasBackground(e),
                              ))
                            Builder(
                              builder: (context) {
                                final selected = provider.items
                                    .where(
                                      (item) =>
                                  item.id == provider.selectedItemId,
                                )
                                    .toList();

                                if (selected.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final item = selected.first;

                                return _TransformSelectionOverlay(
                                  item: item,
                                  scaleX: scaleX,
                                  scaleY: scaleY,
                                  isBackground: _isCanvasBackground(item),
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
    final type = provider.selectedItemType;
    if (type == 'text' || type == 'textbox') {
      return _buildTextEditorToolbar(context, provider, isDark);
    }
    if (type == 'image') {
      return _buildImageEditorToolbar(context, provider, isDark);
    }
    if (type == 'svg_group') {
      return _buildSvgGroupToolbar(context, provider, isDark);
    }
    if (type == 'svg_element') {
      return _buildSvgElementToolbar(context, provider, isDark);
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
              Icons.layers_rounded,
              'FRAMES',
                  () => _showFramesBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Icons.branding_watermark_rounded,
              'MY BRAND',
                  () => _showMyBrandBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Icons.text_fields_rounded,
              'TEXT',
                  () => _showTextStylesBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Icons.photo_library_rounded,
              'MEDIA',
                  () => _showMediaBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Icons.wallpaper_rounded,
              'BACKGROUND',
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
                      '#${current.value.toRadixString(16).substring(2).toUpperCase()}',
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

    const fonts = <String>[
      'Inter',
      'Roboto',
      'Poppins',
      'Anton',
      'Montserrat',
      'Pacifico',
      'Playfair Display',
    ];

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
                    selected: (provider.items.firstWhere(
                          (e) => e.id == id,
                      orElse: () => provider.items.first,
                    ).fontFamily ?? '').trim().toLowerCase() ==
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
                  provider.items.firstWhere(
                        (e) => e.id == id,
                    orElse: () => provider.items.first,
                  ).fontSize,
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

  Widget _buildSvgGroupToolbar(
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
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _bottomTool(
                  Icons.unfold_more_rounded,
                  'UNGROUP ELEMENTS',
                      () => provider.ungroupSvgElement(id),
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
                  'SCALE',
                  item.scale.clamp(.1, 10.0),
                  .1,
                  10,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSvgElementToolbar(
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
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
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
                  'SCALE',
                  item.scale.clamp(.1, 10.0),
                  .1,
                  10,
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
              ],
            ),
          ),
        ],
      ),
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
      'grayscale',
      'sepia',
      'vintage',
      'drama',
      'cali',
      'epic',
      'street',
      'rosie',
      'edge',
      'nordic',
      'selfie',
      'blues',
      'whimsical',
      'summer',
      'retro',
    ];
    const masks = <String>[
      'square',
      'rounded',
      'rectangle',
      'circle',
      'oval',
      'triangle',
      'diamond',
      'pentagon',
      'hexagon',
      'octagon',
    ];

    return Container(
      height: 205,
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
                      () => provider.flipImageHorizontal(id),
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
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _labelledHorizontalList(
                  'FILTER',
                  filters,
                      (value) => provider.setImageFilter(id, value),
                  selected: item.filterType,
                ),
                _labelledHorizontalList(
                  'MASK',
                  masks,
                      (value) => provider.updateImageShape(id, value),
                  selected: item.text,
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
                  0,
                  2,
                      (v) => provider.updateImageColorAdjustments(id, contrast: v),
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
                  'OUTLINE',
                  item.outlineWidth.clamp(0.0, 20.0),
                  0,
                  20,
                      (v) => provider.updateOutline(id, v, Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTool(
      IconData icon,
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
              Icon(icon, color: danger ? Colors.red : Colors.white, size: 19),
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

  Widget _buildTextActionItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 5),
        AppText(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade500,
          size: 22,
        ),
        const SizedBox(height: 5),
        AppText(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

  void _showExportSheet(BuildContext context) {
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
                        subtitle: 'JSON + PNG',
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

  const _TransformSelectionOverlay({
    super.key,
    required this.item,
    required this.scaleX,
    required this.scaleY,
    this.isBackground = false,
  });

  @override
  State<_TransformSelectionOverlay> createState() =>
      _TransformSelectionOverlayState();
}

class _TransformSelectionOverlayState
    extends State<_TransformSelectionOverlay> {
  final GlobalKey _overlayKey = GlobalKey();

  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _startPosition = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _rotationCenterGlobal = Offset.zero;
  double _rotationStartAngle = 0.0;

  double _resizeStartScale = 1.0;
  Offset _resizeStartLocal = Offset.zero;
  Offset _resizeStartPosition = Offset.zero;

  EditorProvider get _provider => context.read<EditorProvider>();

  // Normal media items are rendered inside a Transform.scale(scaleX), so
  // both axes use the canvas width scale. Background media is rendered by
  // _InteractiveBackgroundLayer with independent X/Y canvas scales.
  double get _width => widget.item.width * widget.item.scale * widget.scaleX;

  double get _height =>
      widget.item.height *
          widget.item.scale *
          (widget.isBackground ? widget.scaleY : widget.scaleX);

  // Normal media is rendered inside an outer canvas item and then scaled
  // around its CENTER by EditableItemWidget. The selection box must use the
  // same visual origin, otherwise it stays at the old top-left when the
  // image is resized. Background items do not have this extra centered
  // scale, so their origin remains the item's position.
  double get _left =>
      widget.item.position.dx * widget.scaleX +
          (widget.isBackground
              ? 0.0
              : (widget.item.width * widget.scaleX - _width) / 2);

  double get _top =>
      widget.item.position.dy * widget.scaleY +
          (widget.isBackground
              ? 0.0
              : (widget.item.height * widget.scaleX - _height) / 2);

  @override
  Widget build(BuildContext context) {
    final width = _width;
    final height = _height;

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

                  _provider.updateItemTransform(
                    widget.item.id ?? '',
                    position: Offset(
                      _startPosition.dx + dx,
                      _startPosition.dy + dy,
                    ),
                  );
                },
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ImageSelectionPainter()),
              ),
            ),

            // Three-dot menu is also available on the selected background.
            Positioned(
              right: -18,
              top: -18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showItemQuickMenu(context),
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

            // 8 resize handles for image/text.
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

            // Canva-style three-dot action button for every selected item.
            Positioned(
              right: -18,
              top: -18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showItemQuickMenu(context),
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

            // Rotation handle above the top-center.
            Positioned(
              left: width / 2 - 14,
              top: -39,
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

  void _showItemQuickMenu(BuildContext context) {
    final id = widget.item.id;
    if (id == null || id.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final provider = _provider;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAction(sheetContext, Icons.flip_to_front_rounded, 'Front', () => provider.bringToFront(id)),
                _quickAction(sheetContext, Icons.copy_rounded, 'Duplicate', () => provider.duplicateItem(id)),
                _quickAction(sheetContext, Icons.delete_outline_rounded, 'Delete', () => provider.removeItem(id), destructive: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool destructive = false}) {
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
            Text(label, style: TextStyle(fontSize: 11, color: destructive ? Colors.red : null)),
          ],
        ),
      ),
    );
  }

  Offset _globalCenter() {
    final box = _overlayKey.currentContext?.findRenderObject();
    if (box is RenderBox) {
      return box.localToGlobal(Offset(_width / 2, _height / 2));
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
    const handleSize = 32.0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: handleSize,
        height: handleSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _resizeStartScale = widget.item.scale;
            _resizeStartPosition = widget.item.position;

            final box = _overlayKey.currentContext?.findRenderObject();
            if (box is RenderBox) {
              _resizeStartLocal = box.globalToLocal(details.globalPosition);
            } else {
              _resizeStartLocal = Offset(_width / 2, _height / 2);
            }
          },
          onPanUpdate: (details) {
            final box = _overlayKey.currentContext?.findRenderObject();
            if (box is! RenderBox) return;

            final local = box.globalToLocal(details.globalPosition);
            final delta = local - _resizeStartLocal;

            final baseWidth = math.max(1.0, widget.item.width);
            final baseHeight = math.max(1.0, widget.item.height);

            // Convert screen movement to the design/canvas coordinate
            // system. scaleX/scaleY are the editor's actual canvas scales.
            final dx = delta.dx / widget.scaleX;
            final dy =
                delta.dy /
                    (widget.isBackground ? widget.scaleY : widget.scaleX);

            double deltaScale;

            if (alignment.x == 0) {
              // Top/bottom-center: only vertical movement controls size.
              deltaScale = alignment.y == 1
                  ? dy / baseHeight
                  : -dy / baseHeight;
            } else if (alignment.y == 0) {
              // Left/right-center: only horizontal movement controls size.
              deltaScale = alignment.x == 1 ? dx / baseWidth : -dx / baseWidth;
            } else {
              // Corners: use the dominant proportional axis. This preserves
              // the element's aspect ratio and makes the touched corner track
              // the finger instead of using a center-radius calculation.
              final sx = alignment.x == 1 ? dx / baseWidth : -dx / baseWidth;
              final sy = alignment.y == 1 ? dy / baseHeight : -dy / baseHeight;

              deltaScale = (sx.abs() >= sy.abs() ? sx : sy);
            }

            final newScale = (_resizeStartScale + deltaScale).clamp(0.05, 10.0);

            // Because EditableItemWidget scales around its CENTER, keep the
            // opposite edge fixed. Without this correction the item appears
            // to jump away from the finger while resizing.
            final scaleDelta = newScale - _resizeStartScale;
            final anchorX = alignment.x == 1
                ? baseWidth * scaleDelta / 2
                : alignment.x == -1
                ? -baseWidth * scaleDelta / 2
                : 0.0;
            final anchorY = alignment.y == 1
                ? baseHeight * scaleDelta / 2
                : alignment.y == -1
                ? -baseHeight * scaleDelta / 2
                : 0.0;

            final nextPosition = Offset(
              _resizeStartPosition.dx + anchorX,
              _resizeStartPosition.dy + anchorY,
            );

            _provider.updateItemTransform(
              widget.item.id ?? '',
              scale: newScale,
              position: nextPosition,
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

class _ImageSelectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const selectionColor = Color(0xFF2196F3);
    const strokeWidth = 1.8;

    final borderPaint = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRect(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      borderPaint,
    );

    // Connector for rotation handle.
    final connectorPaint = Paint()
      ..color = selectionColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, -25),
      connectorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ImageSelectionPainter oldDelegate) => false;
}

class _InteractiveBackgroundLayer extends StatefulWidget {
  final EditorItem item;
  final double scaleX;
  final double scaleY;
  final VoidCallback onSelected;

  const _InteractiveBackgroundLayer({
    super.key,
    required this.item,
    required this.scaleX,
    required this.scaleY,
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

    return Positioned(
      left: item.position.dx * widget.scaleX,
      top: item.position.dy * widget.scaleY,
      width: item.width * item.scale * widget.scaleX,
      height: item.height * item.scale * widget.scaleY,
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
                child: EditableItemWidget.buildStandaloneMediaContent(
                  context,
                  item,
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showBackgroundQuickMenu(context),
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
                _backgroundAction(sheetContext, Icons.flip_to_front_rounded, 'Front', () => provider.bringToFront(id)),
                _backgroundAction(sheetContext, Icons.copy_rounded, 'Duplicate', () => provider.duplicateItem(id)),
                _backgroundAction(sheetContext, Icons.delete_outline_rounded, 'Delete', () => provider.removeItem(id), destructive: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _backgroundAction(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool destructive = false}) {
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
            Text(label, style: TextStyle(fontSize: 11, color: destructive ? Colors.red : null)),
          ],
        ),
      ),
    );
  }

  List<double> _imageColorMatrix(
      double brightness,
      double contrast,
      double saturation,
      ) {
    final b = brightness * 255.0;
    final c = contrast;
    final t = (1 - c) * 128.0;

    // Saturation matrix.
    final sr = 0.2126 * (1 - saturation);
    final sg = 0.7152 * (1 - saturation);
    final sb = 0.0722 * (1 - saturation);

    return <double>[
      (c * (sr + 1)),
      c * sg,
      c * sb,
      0,
      t + b,
      c * sr,
      (c * (sg + 1)),
      c * sb,
      0,
      t + b,
      c * sr,
      c * sg,
      (c * (sb + 1)),
      0,
      t + b,
      0,
      0,
      0,
      1,
      0,
    ];
  }


}
