import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mmb_app/ui/screens/widget/dwonload_widget.dart';
import 'package:mmb_app/ui/screens/widget/empty_state.dart';
import 'package:mmb_app/ui/screens/widget/font_picker.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../../Api Model/editor_model.dart';
import '../../Api Model/template_edit_model.dart';
import '../../Repository/freePic.dart';
import '../../Repository/project.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/home_screen_provider.dart';
import '../../network/provider/prpject_provider.dart';
import 'dart:core';

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

    String? resolvedTemplateUid = templateUid;

    if (args is String && args.trim().isNotEmpty) {
      resolvedResizeSize = args.trim();
    }

    if (args is Map) {
      final resizeValue = args['resizeSize'] ?? args['resize_size'];

      if (resizeValue != null && resizeValue.toString().trim().isNotEmpty) {
        resolvedResizeSize = resizeValue.toString().trim();
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

      final uid = args['templateUid'] ?? args['template_uid'] ?? args['uid'];

      if (uid != null && uid.toString().trim().isNotEmpty) {
        resolvedTemplateUid = uid.toString().trim();
      }
    }

    debugPrint('====================================');
    debugPrint('📂 TEMPLATE EDIT SCREEN');
    debugPrint('Template UID : $resolvedTemplateUid');
    debugPrint('====================================');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EditorProvider()),

        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: Scaffold(
        body: SafeArea(
          child: EditorView(
            resizeSize: resolvedResizeSize,
            canvasWidth: resolvedCanvasWidth,
            canvasHeight: resolvedCanvasHeight,
            templateUid: resolvedTemplateUid,
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
    // Keep the provider as the single source of truth. It knows about both
    // editor-created bg_ layers and API/Fabric template background IDs.
    return context.read<EditorProvider>().isCanvasBackgroundItem(item);
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

  Timer? _projectSaveTimer;
  bool _projectSaveListenerAttached = false;
  bool _projectAutoSaveReady = false;
  bool _projectSaveRunning = false;
  bool _projectSaveQueued = false;
  String _projectSaveStatus = '';
  String? _lastQueuedContent;
  String? _lastSavedProjectContent;

  void _attachProjectAutoSaveListener() {
    if (_projectSaveListenerAttached || !mounted) return;
    final editorProvider = context.read<EditorProvider>();
    editorProvider.addListener(_onEditorChangedForProjectSave);
    _projectSaveListenerAttached = true;
  }

  void _onEditorChangedForProjectSave() {
    if (!_projectAutoSaveReady || !mounted) return;

    // EditorProvider notifies for UI-only changes too (upload progress,
    // media gallery refresh, selection panels, etc.). Only schedule a save
    // when the actual canvas JSON has changed.
    final editorProvider = context.read<EditorProvider>();
    final currentContent = jsonEncode(editorProvider.exportCurrentPageJson());
    if (currentContent == _lastQueuedContent) return;

    _lastQueuedContent = currentContent;
    _projectSaveTimer?.cancel();
    _projectSaveStatus = 'Saving...';
    setState(() {});

    _projectSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveProjectNow();
    });
  }

  Future<String?> _getThumbnailBase64(EditorProvider provider) async {
    try {
      if (!mounted) return null;

      setState(() {
        _isCapturingThumbnail = true;
      });

      // Wait for selection overlay to disappear.
      await WidgetsBinding.instance.endOfFrame;

      final context = _canvasKey.currentContext;
      if (context == null) return null;

      final boundary = context.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 1.0);

      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) return null;

        final bytes = byteData.buffer.asUint8List();

        return 'data:image/png;base64,${base64Encode(bytes)}';
      } finally {
        image.dispose();
      }
    } catch (e, stackTrace) {
      debugPrint('Thumbnail capture failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingThumbnail = false;
        });
      }
    }
  }

  Future<void> _saveProjectNow() async {
    if (!_projectAutoSaveReady || !mounted) return;

    final projectProvider = context.read<ProjectProvider>();
    final editorProvider = context.read<EditorProvider>();
    final uid = projectProvider.projectUid?.trim() ?? '';

    if (uid.isEmpty) return;

    if (_projectSaveRunning) {
      _projectSaveQueued = true;
      return;
    }

    _projectSaveRunning = true;
    _projectSaveQueued = false;

    if (mounted) {
      setState(() => _projectSaveStatus = 'Saving...');
    }

    try {
      do {
        _projectSaveQueued = false;

        // Export the latest canvas content without truncating text.
        final content = jsonEncode(editorProvider.exportCurrentPageJson());

        if (content == _lastSavedProjectContent) {
          continue;
        }
        final thumbnailBase64 = await _getThumbnailBase64(editorProvider);
        final saveResult = await ProjectRepository.instance.updateProject(
          projectUid: uid,
          name: projectProvider.projectName ?? 'Untitled design',
          content: content,
          thumbnailBase64: thumbnailBase64, // ✅ Correct
        );

        final success = saveResult.when(
          success: (_) => true,
          failure: (error) {
            debugPrint('Project save failed: ${error.message}');
            return false;
          },
        );

        if (!mounted) return;

        if (success) {
          _lastSavedProjectContent = content;
          _projectSaveStatus = 'Saved';
        } else {
          _projectSaveStatus = 'Save failed';
        }

        setState(() {});
      } while (_projectSaveQueued && mounted);
    } catch (e, stackTrace) {
      debugPrint('Project autosave error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() => _projectSaveStatus = 'Save failed');
      }
    } finally {
      _projectSaveRunning = false;
    }
  }

  Future<void> _showPlanRequiredDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Plan Limit Reached',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You have reached your Business Posts Templates limit. '
                'Please upgrade your plan or buy a top-up to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // TODO: Navigate to your existing Buy Plan screen.
                // Example:
                // Get.to(() => const SubscriptionScreen());
              },
              child: const Text('Buy Plan'),
            ),
          ],
        );
      },
    );
  }

  void _enableProjectAutoSave() {
    if (!mounted) return;

    // Establish the initial canvas as the baseline. Creating/opening a project
    // should not immediately trigger an extra PATCH because of provider
    // notifications that happen during screen setup.
    final editorProvider = context.read<EditorProvider>();
    final initialContent = jsonEncode(editorProvider.exportCurrentPageJson());
    _lastQueuedContent = initialContent;
    _lastSavedProjectContent = initialContent;

    _projectAutoSaveReady = true;
    _attachProjectAutoSaveListener();
  }

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
    final editorProvider = Provider.of<EditorProvider>(context, listen: false);

    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );

    final hasExplicitResize = widget.resizeSize.trim().isNotEmpty;
    final resizeCanvas = hasExplicitResize ? _getCanvasSize() : null;
    final uid = widget.templateUid?.trim() ?? '';

    // =====================================================
    // TEMPLATE DESIGN
    // =====================================================
    if (uid.isNotEmpty) {
      debugPrint('========================================');
      debugPrint('📡 TEMPLATE API START');
      debugPrint('Template UID: $uid');
      debugPrint('========================================');

      final templateSuccess = await editorProvider.loadTemplateByUid(
        uid,
        canvasWidth: resizeCanvas?.width,
        canvasHeight: resizeCanvas?.height,
      );

      if (!mounted) return;

      if (!templateSuccess) {
        debugPrint('❌ TEMPLATE API FAILED');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              editorProvider.templateDetailError ?? 'Unable to load template',
            ),
          ),
        );
        return;
      }

      final detail = editorProvider.templateDetail;

      if (detail == null || detail.data.items.isEmpty) {
        debugPrint('❌ TEMPLATE DETAIL OR ITEMS EMPTY');
        return;
      }

      // Template API response
      final data = detail.data.items.first;

      // The API's template id is an integer (for example 32). Keep it as a
      // string in ProjectProvider because the update repository accepts a
      // nullable string templateId. Do not use uid/familyUid here.
      final int? templateId = int.tryParse(data.id ?? '');
      final int? templateUId = int.tryParse(data.familyId ?? '');
      final templateUidFromApi = data.uid?.toString();
      final thumbnailS3Key = data.thumbnailS3Key?.toString();
      final templateName = data.name?.toString().trim().isNotEmpty == true
          ? data.name.toString().trim()
          : 'Untitled design';

      // The template API's content is Fabric JSON. loadTemplateByUid() has
      // already imported that Fabric JSON into EditorProvider. Project APIs
      // must receive the app's editor JSON schema instead, so export the
      // loaded canvas and JSON-encode it exactly once.
      final selectedSize =
          resizeCanvas ??
              Size(editorProvider.canvasWidth, editorProvider.canvasHeight);
      if (selectedSize.width > 0 && selectedSize.height > 0) {
        editorProvider.setCanvasSize(selectedSize.width, selectedSize.height);
      }
      final templateContent = jsonEncode(
        editorProvider.exportCurrentPageJson(),
      );

      debugPrint('========================================');
      debugPrint('✅ TEMPLATE API SUCCESS');
      debugPrint('Template ID: $templateId');
      debugPrint('Template UID: $templateUidFromApi');
      debugPrint('Template Name: $templateName');
      debugPrint('Thumbnail S3 Key: $thumbnailS3Key');
      debugPrint('Editor JSON length: ${templateContent.length}');
      debugPrint('========================================');

      final projectSuccess = await projectProvider.createProject(
        name: templateName,
        content: templateContent,
        id: templateUId,
      );

      if (!mounted) return;

      if (!projectSuccess) {
        debugPrint('❌ PROJECT CREATE FAILED');

        if (projectProvider.isQuotaExceeded) {
          await _showPlanRequiredDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                projectProvider.errorMessage ?? 'Unable to create project',
              ),
            ),
          );
        }

        return;
      }

      // Preserve the template's numeric API id for every subsequent project
      // update/autosave. Blank projects explicitly keep this value null.
      projectProvider.setTemplateId(templateId);
      debugPrint('========================================');
      debugPrint('✅ PROJECT CREATED FROM TEMPLATE');
      debugPrint('Project ID: ${projectProvider.projectId}');
      debugPrint('Project UID: ${projectProvider.projectUid}');
      debugPrint('Project Name: ${projectProvider.projectName}');
      debugPrint('Template ID: ${projectProvider.templateId}');
      debugPrint('========================================');
    } else {
      // =====================================================
      // CREATE NEW / BLANK DESIGN
      // =====================================================
      final canvasSize = resizeCanvas ?? _getCanvasSize();

      editorProvider.setCanvasSize(canvasSize.width, canvasSize.height);

      final projectName = _getProjectNameFromSize(widget.resizeSize);

      final now = DateTime.now().toUtc().toIso8601String();
      final blankDesignId = 'blank-${DateTime.now().microsecondsSinceEpoch}';
      final blankContent = jsonEncode({
        'version': 1,
        'metadata': {
          'id': blankDesignId,
          'name': '$projectName / Untitled design',
          'createdAt': now,
          'updatedAt': now,
        },
        'preset': 'blank',
        'pages': [
          {
            'id': 'page-1',
            'name': 'Page 1',
            'width': canvasSize.width.toInt(),
            'height': canvasSize.height.toInt(),
            'fabric': {'objects': <dynamic>[], 'background': '#ffffff'},
          },
        ],
        'assets': <dynamic>[],
        'fonts': <dynamic>[],
      });

      debugPrint('========================================');
      debugPrint('📡 CREATE NEW PROJECT');
      debugPrint('Project Name: $projectName');
      debugPrint('Content length: ${blankContent.length}');
      debugPrint('Template ID: not sent (blank project)');
      debugPrint('========================================');

      final projectSuccess = await projectProvider.createProject(
        name: projectName,
        content: blankContent,
        id: null, // Blank projects must not send template_id: 0.
      );

      if (!mounted) return;

      if (!projectSuccess) {
        debugPrint('❌ PROJECT CREATE FAILED');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              projectProvider.errorMessage ?? 'Unable to create project',
            ),
          ),
        );
        return;
      }

      // Blank project has no template ID.
      projectProvider.setTemplateId(null);

      debugPrint('✅ CREATE NEW PROJECT SUCCESS');
      debugPrint('Project UID: ${projectProvider.projectUid}');
    }

    _enableProjectAutoSave();

    editorProvider.fetchFreePikAssets('furniture');
    editorProvider.fetchFreePikStickers('stickers');
  }

  String _getProjectNameFromSize(String size) {
    switch (size.trim()) {
      case "Post Square (1:1)":
        return "Post Square / Untitled design";
      case "Post Portrait (4:5)":
        return "Post Portrait / Untitled design";
      case "Story / Reel (9:16)":
        return "Story / Untitled design";
      case "Post Horizontal (16:9)":
        return "Post Horizontal / Untitled design";
      default:
        return "Post Square / Untitled design";
    }
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
                    fontSize: AppFontSize.fontSize18,
                    fontWeight: FontWeight.w500,
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
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w500,
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
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w500,
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
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w500,
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
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  onTap: () {
                    _addTextCentered(provider, "My Text");
                    Navigator.pop(modalContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Center(
                    child: AppText(
                      "HELP ME TO WRITE",
                      style: TextStyle(
                        fontSize: AppFontSize.fontSize18,
                        fontWeight: FontWeight.w500,
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
      bool isDark, {
        bool elementsOnly = false,
      }) {
    int selectedTab = elementsOnly ? 1 : 0; // 0 uploads, 1 elements, 2 images
    String? expandedCategory;
    bool sheetOpen = true;
    bool elementsInitialLoadScheduled = false;
    bool uploadsInitialLoadScheduled = false;
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
            // Trigger MyUploads once after the first Media sheet frame.
            // Rebuild the sheet before and after the request so the loader and
            // fetched images are visible on the very first open.
            if (selectedTab == 0 && !elementsOnly &&
                !uploadsInitialLoadScheduled &&
                !provider.hasFetchedMyUploads &&
                !provider.isLoadingMyUploads) {
              uploadsInitialLoadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!sheetOpen || !sheetContext.mounted) return;
                setSheetState(() {});
                await provider.loadMyUploads();
                if (sheetOpen && sheetContext.mounted) {
                  setSheetState(() {});
                }
              });
            }

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
                              AppText(
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
              final previewUrl = item.previewKey;

              final rawAssetKey = item.s3Key.trim();
              final assetUrl =
              rawAssetKey.startsWith('http://') ||
                  rawAssetKey.startsWith('https://')
                  ? rawAssetKey
                  : '${FreePikService.assetCdnBaseUrl}/${rawAssetKey.replaceFirst(RegExp(r'^/+'), '')}';

              return elementCard(
                previewUrl,
                locked: item.isLocked,
                onTap: item.isLocked
                    ? null
                    : () async {
                  if (isShape) {
                    // Canvas-ல் original SVG-ஐ PNG-ஆக மாற்றி சேர்க்கவும்.
                    await _addRemoteShape(
                      modalContext,
                      provider,
                      assetUrl,
                    );
                  } else {
                    provider.addImage(previewUrl, isLocal: false);

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
                      child: AppText(
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
                      child: const AppText(
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
                      child: AppText(
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
                          child: AppText(
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
                          : (isStickerProxyCategory(query)
                          ? stickerItems.isEmpty
                          : assetItems.isEmpty)
                          ? const Center(
                        child: AppText(
                          'No items found. Please try again.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                          );
                          if (image == null || !sheetOpen) return;
                          // Start upload without waiting so the bottom sheet
                          // rebuilds immediately and shows local preview + loader.
                          final uploadFuture = provider.uploadPickedMediaImage(
                            File(image.path),
                          );
                          if (sheetContext.mounted && sheetOpen) {
                            setSheetState(() {});
                          }
                          final ok = await uploadFuture;
                          if (!sheetContext.mounted || !sheetOpen) return;
                          setSheetState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: AppText(
                                ok ? 'Image uploaded' : 'Image upload failed',
                              ),
                            ),
                          );
                        },
                        child: _mediaPickerTile(
                          isDark,
                          Icons.camera_alt,
                          'CAMERA',
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image == null || !sheetOpen) return;
                          // Start upload without waiting so the bottom sheet
                          // rebuilds immediately and shows local preview + loader.
                          final uploadFuture = provider.uploadPickedMediaImage(
                            File(image.path),
                          );
                          if (sheetContext.mounted && sheetOpen) {
                            setSheetState(() {});
                          }
                          final ok = await uploadFuture;
                          if (!sheetContext.mounted || !sheetOpen) return;
                          setSheetState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: AppText(
                                ok ? 'Image uploaded' : 'Image upload failed',
                              ),
                            ),
                          );
                        },
                        child: _mediaPickerTile(
                          isDark,
                          Icons.photo_library,
                          'GALLERY',
                        ),
                      ),
                      if (provider.isUploadingMediaImage) ...[
                        const SizedBox(width: 14),
                        const Padding(
                          padding: EdgeInsets.only(top: 34),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppText(
                    'My uploads',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: provider.isLoadingMyUploads &&
                        provider.uploadedMediaImages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : provider.myUploadsError != null &&
                        provider.uploadedMediaImages.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.myUploadsError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => provider.loadMyUploads(
                              forceRefresh: true,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                        : provider.uploadedMediaImages.isEmpty
                        ? const Center(
                      child: Text(
                        'Uploaded images will appear here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : GridView.builder(
                      itemCount: provider.uploadedMediaImages.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (_, index) {
                        final image = provider.uploadedMediaImages[index];
                        final url = image['url'] ?? '';
                        final localPath = image['localPath'] ?? '';
                        final isUploading = image['uploading'] == 'true';
                        final hasLocalFile =
                            localPath.isNotEmpty &&
                                File(localPath).existsSync();
                        return GestureDetector(
                          onTap: isUploading
                              ? null
                              : () {
                            final key = image['key'] ?? '';
                            if (key.isNotEmpty) {
                              provider.selectedMediaS3Key = key;
                            }
                            final source = url.isNotEmpty
                                ? url
                                : localPath;
                            if (source.isEmpty) return;
                            provider.addImage(
                              source,
                              isLocal: url.isEmpty,
                            );
                            Navigator.pop(modalContext);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (hasLocalFile)
                                  Image.file(
                                    File(localPath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) {
                                      debugPrint(
                                        'Local media thumbnail error: $error',
                                      );
                                      return Container(
                                        color: Colors.black12,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      );
                                    },
                                  )
                                else if (url.isNotEmpty)
                                  Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null)
                                        return child;
                                      return Container(
                                        color: Colors.black12,
                                        alignment: Alignment.center,
                                        child:
                                        const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, error, stackTrace) {
                                      debugPrint(
                                        'Network media thumbnail error: $error',
                                      );
                                      return Container(
                                        color: Colors.black12,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Container(
                                    color: Colors.black12,
                                    child: const Icon(
                                      Icons.image_outlined,
                                    ),
                                  ),
                                if (isUploading)
                                  Container(
                                    color: Colors.black45,
                                    alignment: Alignment.center,
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Uploading...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
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
                    child: AppText(
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
                      child: AppText(
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
                            child: AppText(
                              elementsOnly ? 'Elements' : 'Media',
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize22,
                                fontWeight: FontWeight.w500,
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
                    if (expandedCategory == null && !elementsOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _backgroundTab(
                              title: 'UPLOADS',
                              selected: selectedTab == 0,
                              onTap: () {
                                setSheetState(() => selectedTab = 0);
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
                        child: elementsOnly
                            ? elementsView()
                            : selectedTab == 0
                            ? uploadsView()
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
          AppText(
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

    bool isInitialBackgroundLoading = true;
    bool isInitialVideoLoading = true;

    void fetchImages(String query, void Function(void Function()) setState) {
      final value = query.trim().isEmpty ? 'background' : query.trim();
      searchQuery = value;
      isInitialBackgroundLoading = true;
      setState(() {});

      provider.fetchBackgroundAssets(value).then((_) {
        if (!sheetOpen) return;
        isInitialBackgroundLoading = false;
        setState(() {});
      });
    }

    void fetchVideos(String query, void Function(void Function()) setState) {
      final value = query.trim().isEmpty ? 'background' : query.trim();
      videoSearchQuery = value;
      isInitialVideoLoading = true;
      setState(() {});

      provider.fetchFreePikVideos(value).then((_) {
        if (!sheetOpen) return;
        isInitialVideoLoading = false;
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
                  isInitialBackgroundLoading = false;
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
                  child: AppText(
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
                  child: AppText(
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
              if (provider.isBackgroundLoading || isInitialBackgroundLoading) {
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
                  child: AppText(
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
              if (provider.isVideosLoading || isInitialVideoLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final assets = provider.pexelsVideoAssets;
              if (assets.isEmpty) {
                return const Center(
                  child: AppText(
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
                          title: const AppText('Replace Background?'),
                          content: const AppText(
                            'The current background will be replaced with this video.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const AppText('CANCEL'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const AppText('REPLACE'),
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
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              'Background',
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize22,
                                fontWeight: FontWeight.w500,
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
                    SizedBox(height: 5),
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
                    SizedBox(height: 5),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    SizedBox(height: 5),
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
              fontSize: AppFontSize.fontSize13,
              fontWeight: FontWeight.w600,
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

    _musicPositionSubscription = _musicPlayer.onPositionChanged.listen((
        position,
        ) {
      if (!mounted) return;
      context.read<EditorProvider>().setMusicPosition(position);
    });

    _musicDurationSubscription = _musicPlayer.onDurationChanged.listen((
        duration,
        ) {
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
  Future<void> dispose() async {
    _projectSaveTimer?.cancel();

    // Best-effort final PATCH when the editor is closed. We deliberately call
    // the repository directly here because dispose() cannot await a Future and
    // the screen-scoped ProjectProvider may be disposed immediately afterwards.
    if (_projectAutoSaveReady) {
      try {
        final projectProvider = context.read<ProjectProvider>();
        final editorProvider = context.read<EditorProvider>();
        final uid = projectProvider.projectUid?.trim() ?? '';
        if (uid.isNotEmpty) {
          final thumbnailBase64 = await _getThumbnailBase64(editorProvider);
          final content = jsonEncode(editorProvider.exportCurrentPageJson());
          if (content != _lastSavedProjectContent) {
            // ignore: discarded_futures
            ProjectRepository.instance.updateProject(
              projectUid: uid,
              name: projectProvider.projectName ?? 'Untitled design',
              content: content,
              thumbnailS3Key: thumbnailBase64,
            );
          }
        }
        if (_projectSaveListenerAttached) {
          editorProvider.removeListener(_onEditorChangedForProjectSave);
        }
      } catch (_) {}
    }

    _musicPositionSubscription?.cancel();
    _musicDurationSubscription?.cancel();
    _musicCompleteSubscription?.cancel();
    _musicPlayer.dispose();
    super.dispose();
  }

  bool _isCapturingThumbnail = false;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final saveIndicator = _projectSaveStatus.isEmpty
        ? const SizedBox.shrink()
        : AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey(_projectSaveStatus),
        margin: const EdgeInsets.only(right: 12, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF303030) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(blurRadius: 5, color: Color(0x22000000)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_projectSaveStatus == 'Saving...')
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              )
            else
              Icon(
                _projectSaveStatus == 'Saved'
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 14,
                color: _projectSaveStatus == 'Saved'
                    ? Colors.green
                    : Colors.red,
              ),
            const SizedBox(width: 5),
            AppText(
              _projectSaveStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
    final hasTemplateUid = (widget.templateUid?.trim() ?? '').isNotEmpty;

    if (hasTemplateUid &&
        !provider.isTemplateDetailLoading &&
        provider.templateDetailError != null) {
      return EmptyStateWidget(
        isDark: isDark,
        imagePath: 'assets/images/no_templates.png',
        title: 'No Templates Available',
        message:
        'We’re adding more templates for this category. '
            'Explore other categories to find the right design for your business.',
        primaryButtonText: 'GO BACK',
        secondaryButtonText: 'EXPLORE TEMPLATES',
        onPrimaryPressed: () {
          Navigator.pop(context);
        },
        onSecondaryPressed: () {
          Navigator.pop(context);
          // Replace this with your template listing navigation
          // if that screen is not directly underneath this screen.
        },
      );
    }
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
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            _editorToolbarButton(
              icon: Icons.arrow_back_rounded,
              backgroundColor: const Color(0xFFFFE3E5),
              iconColor: const Color(0xFFFF2938),
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
            _editorToolbarButton(
              icon: Icons.undo_rounded,
              backgroundColor: const Color(0xFFE0E0E0),
              iconColor: const Color(0xFF555555),
              tooltip: 'Undo',
              onPressed: () => provider.undo(),
            ),
            const SizedBox(width: 10),
            _editorToolbarButton(
              icon: Icons.redo_rounded,
              backgroundColor: const Color(0xFFF1F1F1),
              iconColor: const Color(0xFFBDBDBD),
              tooltip: 'Redo',
              onPressed: () => provider.redo(),
            ),
            const SizedBox(width: 10),
            _editorToolbarButton(
              icon: Icons.play_arrow_rounded,
              backgroundColor: const Color(0xFFE0E0E0),
              iconColor: const Color(0xFF555555),
              tooltip: 'Preview',
              onPressed: () =>
                  _showEditorPreview(context, provider, aspectRatio),
            ),
            const SizedBox(width: 10),
            _editorToolbarButton(
              icon: Icons.layers_rounded,
              backgroundColor: const Color(0xFFE0E0E0),
              iconColor: const Color(0xFF555555),
              tooltip: 'Pages',
              onPressed: () => _showPagesSheet(context, provider, isDark),
              onLongPress: () {
                provider.copyCurrentPage();
                Fluttertoast.showToast(
                  msg: 'Page copied. Go to another page and paste.',
                );
              },
            ),
            const SizedBox(width: 10),
            _editorToolbarButton(
              icon: Icons.file_download_outlined,
              backgroundColor: const Color(0xFFE0E0E0),
              iconColor: Colors.black,
              tooltip: 'Download',
              onPressed: () => CommonShareBottomSheet.show(
                context: context,
                isDark: isDark,
                onDownload: () => _showExportSheet(context, provider),
                onInstagram: () => (),
                onFacebook: () => (),
                onX: () => (),
                onLinkedIn: () => (),
                onPinterest: () => (),
                onBoost: () => (),
                onWhatsApp: () => (),
                onMessenger: () => (),
                onDrive: () => (),
                onCopyLink: () => (),
                onCaption: () => (),
                onSchedule: () => (),
              ),
              //_showExportSheet(context, provider),
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          Center(
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

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            provider.clearSelection();
                          },
                          child: ClipRect(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: provider.backgroundColor,
                                      gradient:
                                      provider.importedBackgroundGradient,
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
                                      .where(
                                        (item) => !_isCanvasBackground(item),
                                  )
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
                                            (e) =>
                                        e.id == provider.selectedItemId,
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
                                        height:
                                        item.height * item.scale * scaleY,
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

                                if (!_isCapturingThumbnail &&
                                    provider.selectedItemId != null)
                                  ...(() {
                                    final selectedItems = provider.items
                                        .where(
                                          (e) =>
                                      e.id == provider.selectedItemId,
                                    )
                                        .toList();

                                    if (selectedItems.isEmpty) {
                                      return <Widget>[];
                                    }

                                    final selected = selectedItems.first;

                                    if (_isCanvasBackground(selected)) {
                                      return <Widget>[];
                                    }

                                    return <Widget>[
                                      _TransformSelectionOverlay(
                                        key: ValueKey(
                                          'selection_overlay_${selected.id}',
                                        ),
                                        item: selected,
                                        scaleX: scaleX,
                                        scaleY: scaleY,
                                        canvasWidth: canvasSize.width,
                                        canvasHeight: canvasSize.height,
                                      ),
                                    ];
                                  })(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Small non-blocking save indicator. It lives above the canvas, not
          // inside the bottom toolbar.
          Positioned(
            top: 8,
            right: 12,
            child: IgnorePointer(child: saveIndicator),
          ),
        ],
      ),

      bottomNavigationBar: _buildEditorBottomBar(context, provider, isDark),
    );
  }

  void _showEditorPreview(
      BuildContext context,
      EditorProvider provider,
      double aspectRatio,
      ) {
    final items = provider.templateDetail?.data.items ?? [];

    final thumbnailKey = items.isNotEmpty ? items.first.thumbnailS3Key : null;

    final thumbnailUrl = thumbnailKey != null && thumbnailKey.trim().isNotEmpty
        ? '${ApiEndpoints.cdnImageUrl}/${thumbnailKey.trim()}'
        : null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Template background
                  Container(color: provider.backgroundColor),

                  // Thumbnail image
                  if (thumbnailUrl != null)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, error, stackTrace) {
                        debugPrint('❌ Thumbnail load failed: $error');

                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: Colors.grey,
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

  Widget _editorToolbarButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
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
                  () => _showMediaBottomSheet(
                context,
                provider,
                isDark,
                elementsOnly: true,
              ),
            ),
            _bottomTool(
              Image.asset("assets/images/magic_star.png"),
              'AI TOOLS',
                  () => () {},
            ),
            _bottomTool(
              Image.asset("assets/images/music.png"),
              provider.isEditorMusicPlaying ? 'PLAYING' : 'MUSIC',
                  () => _showMusicBottomSheet(context, provider, isDark),
            ),
            _bottomTool(
              Image.asset("assets/images/brand_kit.png"),
              'BRAND KIT',
                  () => () {},
            ),
            _bottomTool(
              Image.asset("assets/images/heart.png"),
              'FAVORITES',
                  () => () {},
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
    const presets = <Color>[
      Color(0xFFF44336),
      Color(0xFFFF9800),
      Color(0xFFFFEB3B),
      Color(0xFF66BB6A),
      Color(0xFF26A69A),
      Color(0xFF03A9F4),
      Color(0xFF4054B2),
      Color(0xFF673AB7),
      Color(0xFF9C27B0),
      Color(0xFFEC407A),
      Color(0xFF8D6E63),
      Color(0xFFD6D6D6),
    ];

    var hsv = HSVColor.fromColor(provider.textColor(id));
    var selectedTab = 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final current = hsv.toColor();
          final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final fg = isDark ? Colors.white : const Color(0xFF171717);

          void applyColor(Color color) {
            hsv = HSVColor.fromColor(color);
            provider.updateTextColor(id, color);
            setSheetState(() {});
          }

          Widget tab(String label, int index) {
            final active = selectedTab == index;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setSheetState(() => selectedTab = index),
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.black
                          : (isDark
                          ? const Color(0xFF393939)
                          : const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AppText(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
              ),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 70,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            'Font Color',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: fg,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(sheetContext),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE3E3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        tab('PRESETS', 0),
                        tab('CUSTOM', 1),
                        tab('BRAND KIT', 2),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (selectedTab == 0) ...[
                      AppText(
                        'Color Presets',
                        style: TextStyle(fontSize: 19, color: fg),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: presets.map((color) {
                          final active = color.value == current.value;
                          return InkWell(
                            onTap: () => applyColor(color),
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                              width:
                              (MediaQuery.of(sheetContext).size.width -
                                  76) /
                                  7,
                              height: 53,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(7),
                                border: active
                                    ? Border.all(color: fg, width: 3)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else if (selectedTab == 1) ...[
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: current,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppText(
                        '#${current.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _colorSlider('Hue', hsv.hue, 0, 360, (v) {
                        setSheetState(() => hsv = hsv.withHue(v));
                        provider.updateTextColor(id, hsv.toColor());
                      }),
                      _colorSlider('Saturation', hsv.saturation, 0, 1, (v) {
                        setSheetState(() => hsv = hsv.withSaturation(v));
                        provider.updateTextColor(id, hsv.toColor());
                      }),
                      _colorSlider('Brightness', hsv.value, 0, 1, (v) {
                        setSheetState(() => hsv = hsv.withValue(v));
                        provider.updateTextColor(id, hsv.toColor());
                      }),
                    ] else ...[
                      AppText(
                        'Brand Colors',
                        style: TextStyle(fontSize: 19, color: fg),
                      ),
                      const SizedBox(height: 10),
                      AppText(
                        'Your brand colors will appear here.',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _colorSlider(
      String label,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      ) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value.clamp(min, max),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextEditorToolbar(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final id = provider.selectedItemId;
    if (id == null) return const SizedBox.shrink();

    Widget tool(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF626262),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                const SizedBox(height: 7),
                AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.fontSize10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
      decoration: BoxDecoration(
        color: Colors.black,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF252525), width: 3),
        ),
      ),
      child: Row(
        children: [
          tool(Icons.text_fields_rounded, 'FONT', () {
            _showTextFontPicker(context, provider, id, isDark);
          }),
          tool(Icons.text_format_rounded, 'FORMAT', () {
            _showTextFormatBottomSheet(context, provider, id, isDark);
          }),
          tool(Icons.format_line_spacing_rounded, 'SPACING', () {
            _showTextSpacingBottomSheet(context, provider, id, isDark);
          }),
          tool(Icons.palette_rounded, 'COLOR', () {
            _showTextColorPicker(context, provider, id, isDark);
          }),
          tool(Icons.format_align_center_rounded, 'ALIGN', () {
            _showTextAlignmentBottomSheet(context, provider, id, isDark);
          }),
          tool(Icons.layers_rounded, 'ORDER', () {
            _showTextOrderBottomSheet(context, provider, id, isDark);
          }),
        ],
      ),
    );
  }

  void _showTextFormatBottomSheet(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    final item = provider.items.where((e) => e.id == id).firstOrNull;
    if (item == null) return;
    final alignments = <Map<String, dynamic>>[
      {'icon': Icons.format_align_left_rounded, 'value': TextAlign.left},
      {'icon': Icons.format_align_center_rounded, 'value': TextAlign.center},
      {'icon': Icons.format_align_right_rounded, 'value': TextAlign.right},
      {'icon': Icons.format_align_justify_rounded, 'value': TextAlign.justify},
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final current = provider.items.where((e) => e.id == id).firstOrNull;
          if (current == null) return const SizedBox.shrink();
          final fg = isDark ? Colors.white : const Color(0xFF222222);
          final bg = isDark ? const Color(0xFF17191E) : Colors.white;
          Widget iconButton(IconData icon, bool selected, VoidCallback onTap) =>
              InkWell(
                onTap: () {
                  onTap();
                  setSheetState(() {});
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFE5E5)
                        : (isDark
                        ? const Color(0xFF292B31)
                        : const Color(0xFFF2F2F2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.red : fg,
                    size: 23,
                  ),
                ),
              );
          Widget sliderRow(
              String title,
              double value,
              double min,
              double max,
              ValueChanged<double> onChanged,
              ) {
            final safeValue = value.clamp(min, max).toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        title,
                        style: TextStyle(color: fg, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF292B31)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        safeValue.round().toString(),
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 2,
                  child: SliderTheme(
                    data: SliderTheme.of(sheetContext).copyWith(
                      activeTrackColor: Colors.red,
                      inactiveTrackColor: Colors.black12,
                      thumbColor: Colors.red,
                      overlayColor: Colors.red.withValues(alpha: .12),
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: safeValue,
                      min: min,
                      max: max,
                      onChanged: (v) {
                        onChanged(v);
                        setSheetState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
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
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          'Format',
                          style: TextStyle(
                            color: fg,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE5E5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      iconButton(
                        Icons.format_bold_rounded,
                        provider.textWeight(id) == FontWeight.bold,
                            () => provider.toggleTextBold(id),
                      ),
                      iconButton(
                        Icons.text_fields_rounded,
                        false,
                            () =>
                            _showTextFontPicker(context, provider, id, isDark),
                      ),
                      iconButton(
                        Icons.format_italic_rounded,
                        provider.textStyle(id) == FontStyle.italic,
                            () => provider.toggleTextItalic(id),
                      ),
                      iconButton(
                        Icons.format_underlined_rounded,
                        provider.textUnderline(id),
                            () => provider.toggleTextUnderline(id),
                      ),
                      iconButton(Icons.strikethrough_s_rounded, false, () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: alignments
                        .map(
                          (a) => Expanded(
                        child: Center(
                          child: iconButton(
                            a['icon'] as IconData,
                            provider.textAlignment(id) == a['value'],
                                () => provider.updateTextAlignment(
                              id,
                              a['value'] as TextAlign,
                            ),
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  sliderRow(
                    'Text Size',
                    current.fontSize,
                    8,
                    300,
                        (v) => provider.updateFontSize(id, v),
                  ),
                  sliderRow(
                    'Rotate',
                    current.rotation,
                    -180,
                    180,
                        (v) => provider.updateRotation(id, v),
                  ),
                  sliderRow(
                    'Transparency',
                    current.opacity * 100,
                    0,
                    100,
                        (v) => provider.updateOpacity(id, v / 100),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTextFontPicker(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    final fonts = GoogleFonts.asMap().keys.toList()..sort();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          height: MediaQuery.of(sheetContext).size.height * 0.65,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView.builder(
            itemCount: fonts.length,
            itemBuilder: (_, index) => ListTile(
              title: AppText(
                fonts[index],
                style: GoogleFonts.getFont(fonts[index]),
              ),
              onTap: () {
                provider.updateFontFamily(id, fonts[index]);
                Navigator.pop(sheetContext);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showTextSpacingBottomSheet(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final letterSpacing = provider
                .textLetterSpacing(id)
                .clamp(-2.0, 20.0)
                .toDouble();
            final lineSpacing = provider
                .textLineSpacing(id)
                .clamp(0.7, 3.0)
                .toDouble();
            final foreground = isDark ? Colors.white : const Color(0xFF171717);

            Widget spacingControl({
              required String label,
              required double value,
              required double min,
              required double max,
              required ValueChanged<double> onChanged,
            }) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            label,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF292929)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppText(
                            value.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 25,
                      child: SliderTheme(
                        data: SliderTheme.of(sheetContext).copyWith(
                          trackHeight: 3,
                          activeTrackColor: const Color(0xFFFF252D),
                          inactiveTrackColor: isDark
                              ? Colors.white24
                              : const Color(0xFFE0E0E0),
                          thumbColor: const Color(0xFFFF252D),
                          overlayColor: const Color(0x22FF252D),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(
                          value: value,
                          min: min,
                          max: max,
                          onChanged: (next) {
                            onChanged(next);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            'Space',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(sheetContext),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF44292B)
                                  : const Color(0xFFFFE5E6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFFFF252D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    spacingControl(
                      label: 'Letter Spacing',
                      value: letterSpacing,
                      min: -2,
                      max: 20,
                      onChanged: (value) =>
                          provider.updateTextLetterSpacing(id, value),
                    ),
                    spacingControl(
                      label: 'Line Spacing',
                      value: lineSpacing,
                      min: 0.7,
                      max: 3,
                      onChanged: (value) =>
                          provider.updateTextLineSpacing(id, value),
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

  void _showTextAlignmentBottomSheet(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    final alignments = <Map<String, dynamic>>[
      {
        'label': 'Left',
        'icon': Icons.format_align_left,
        'value': TextAlign.left,
      },
      {
        'label': 'Center',
        'icon': Icons.format_align_center,
        'value': TextAlign.center,
      },
      {
        'label': 'Right',
        'icon': Icons.format_align_right,
        'value': TextAlign.right,
      },
      {
        'label': 'Justify',
        'icon': Icons.format_align_justify,
        'value': TextAlign.justify,
      },
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: alignments
              .map(
                (a) => ListTile(
              leading: Icon(a['icon'] as IconData),
              title: AppText(a['label'] as String),
              onTap: () {
                provider.updateTextAlignment(id, a['value'] as TextAlign);
                Navigator.pop(sheetContext);
              },
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  void _showTextOrderBottomSheet(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flip_to_front),
              title: const AppText('Bring to front'),
              onTap: () {
                provider.bringToFront(id);
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flip_to_back),
              title: const AppText('Send to back'),
              onTap: () {
                provider.sendToBack(id);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
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
    // Keep the sheet in a loading state until the first request completes.
    // Otherwise the initial frame briefly shows "No mask found" before the
    // post-frame API request has even started.
    bool hasFinishedInitialLoad = false;

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
                try {
                  await provider.fetchElementCategory(
                    'masks',
                    page: 1,
                    limit: 30,
                  );
                } finally {
                  if (sheetContext.mounted) {
                    setState(() => hasFinishedInitialLoad = true);
                  }
                }
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
                          child: AppText(
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
                    child:
                    (loading || !hasFinishedInitialLoad) && filtered.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                        ? const Center(child: AppText('No mask found'))
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
                        final url = provider.assetCdnUrl(mask.s3Key);
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
              AppText(
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
          const AppText(
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
                child: AppText(
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
          const AppText(
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
        ? (item.outlineColor)
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
              title: AppText(
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
                  AppText(
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
                  child: const AppText('CANCEL'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, current),
                  child: const AppText('APPLY'),
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
          child: AppText(
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
    if (id == null || provider.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemIndex = provider.items.indexWhere((e) => e.id == id);

    if (itemIndex == -1) {
      return const SizedBox.shrink();
    }

    final item = provider.items[itemIndex];

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
                    child: AppText(
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
                _buildSizeStepControl(item, (delta) {
                  final next = (item.scale + delta).clamp(0.05, 10.0);
                  provider.updateScale(id, next.toDouble());
                }),
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

  Widget _buildSizeStepControl(
      EditorItem item,
      ValueChanged<double> onChanged,
      ) {
    final percent = (item.scale * 100).round().clamp(5, 1000);

    return Container(
      width: 150,
      height: 72,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF20242C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3F49)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Decrease size',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(-0.05),
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText(
                  'SIZE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Increase size',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(0.05),
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 24,
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
            child: AppText(
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
                        AppText(
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
              child: AppText(
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

              AppText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.fontSize10,
                  fontWeight: FontWeight.w500,
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
              const AppText(
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
            child: AppText(
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
                  child: AppText(
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
              AppText(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppText(
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

      provider.setSelectedMusic(path: path, title: file.name);

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
                            child: AppText(
                              'Music',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
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
                          final selected =
                              provider.selectedMusicTitle == track['title'];
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
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
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          track['title']!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        AppText(
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
                                _showTextToAudioBottomSheet(
                                  context,
                                  provider,
                                  isDark,
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
      child: AppText(
        title,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNowPlayingBar(BuildContext context, EditorProvider provider) {
    final duration = provider.musicDuration.inMilliseconds;
    final position = provider.musicPosition.inMilliseconds;
    final progress = duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;

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
                AppText(
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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

  void _showTextToAudioBottomSheet(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final textController = TextEditingController();
    String selectedVoice = 'Female';
    bool isConverting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 48,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Header
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Text to Audio',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: isConverting
                                ? null
                                : () => Navigator.pop(sheetContext),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE7E7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Text input
                      TextField(
                        controller: textController,
                        minLines: 4,
                        maxLines: 5,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText: 'Type the text to convert',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          counterStyle: const TextStyle(fontSize: 10),
                          contentPadding: const EdgeInsets.all(10),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFF0F0F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFF0F0F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFBDBD),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Voice selection and convert button
                      Row(
                        children: [
                          const Text(
                            'Select voice',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(width: 8),

                          _voiceButton(
                            icon: Icons.record_voice_over,
                            selected: selectedVoice == 'Female',
                            color: const Color(0xFFFFD8ED),
                            onTap: () {
                              setSheetState(() {
                                selectedVoice = 'Female';
                              });
                            },
                          ),

                          const SizedBox(width: 8),

                          _voiceButton(
                            icon: Icons.face_rounded,
                            selected: selectedVoice == 'Male',
                            color: const Color(0xFFDCE7FF),
                            onTap: () {
                              setSheetState(() {
                                selectedVoice = 'Male';
                              });
                            },
                          ),

                          const Spacer(),

                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              onPressed: isConverting
                                  ? null
                                  : () async {
                                final text = textController.text.trim();

                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter text to convert',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  isConverting = true;
                                });

                                try {
                                  // Connect your TTS API here.
                                  // It should return an audio file or URL.
                                  /* await _generateTextAudio(
                                    text: text,
                                    voice: selectedVoice,
                                    provider: provider,
                                  );*/

                                  if (!sheetContext.mounted) return;

                                  Navigator.pop(sheetContext);

                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Audio generated successfully',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint('TTS error: $e');

                                  if (!sheetContext.mounted) return;

                                  setSheetState(() {
                                    isConverting = false;
                                  });

                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Audio generation failed. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: isConverting
                                  ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'CONVERT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _voiceButton({
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.redAccent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? Colors.redAccent : Colors.blueAccent,
        ),
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
          final musicName =
          provider.selectedMusicTitle?.trim().isNotEmpty == true
              ? provider.selectedMusicTitle!.trim()
              : 'selected_music.mp3';
          archive.addFile(
            ArchiveFile('music/$musicName', musicBytes.length, musicBytes),
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

  void _showExportSheet(BuildContext context, EditorProvider provider) {
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
                  child: AppText(
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
                        onTap: () async {
                          Navigator.pop(modalContext);

                          await _downloadProjectExport(context);
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
                        subtitle: provider.selectedMusicPath != null
                            ? 'JSON + PNG + Music'
                            : 'JSON + PNG',
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

  Future<String?> downloadExportFile({required String fileUrl}) async {
    try {
      if (!fileUrl.startsWith('http://') && !fileUrl.startsWith('https://')) {
        debugPrint('❌ Invalid download URL: $fileUrl');

        return null;
      }

      final directory = await getApplicationDocumentsDirectory();

      final fileName = 'project_${DateTime.now().millisecondsSinceEpoch}.png';

      final filePath = '${directory.path}/$fileName';

      debugPrint('📥 Download URL: $fileUrl');
      debugPrint('📁 Save path: $filePath');

      await Dio().download(fileUrl, filePath);

      debugPrint('✅ File saved: $filePath');

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('❌ Download error: $e');
      debugPrint(stackTrace.toString());

      return null;
    }
  }

  Future<void> _downloadProjectExport(BuildContext context) async {
    final projectProvider = context.read<ProjectProvider>();

    final projectUid = projectProvider.projectUid?.trim() ?? '';

    if (projectUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Project UID not available')),
      );
      return;
    }

    try {
      debugPrint('📤 Calling export API...');

      // API success மட்டும் check பண்ணுகிறோம்.
      await projectProvider.exportProject(projectUid: projectUid);

      if (!context.mounted) return;

      // IMPORTANT:
      // s3_key null இருந்தாலும் API response success என்றால்
      // canvas-ஐ download செய்ய வேண்டும்.

      if (projectProvider.exportError != null &&
          projectProvider.exportError!.isNotEmpty) {
        debugPrint('❌ Export API error: ${projectProvider.exportError}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(projectProvider.exportError!)),
        );

        return;
      }

      debugPrint('✅ Export API successful');

      // Give Flutter time to finish latest canvas changes.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) return;

      // -------------------------------------------------------
      // CAPTURE CANVAS
      // -------------------------------------------------------

      final renderObject = _canvasKey.currentContext?.findRenderObject();

      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        debugPrint('❌ RepaintBoundary not found');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Unable to capture design')),
        );

        return;
      }

      final boundary = renderObject;

      debugPrint('📸 Capturing canvas...');

      final image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ PNG conversion failed');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Unable to create image')),
        );

        return;
      }

      final bytes = byteData.buffer.asUint8List();

      debugPrint('✅ Canvas captured: ${bytes.length} bytes');

      // -------------------------------------------------------
      // SAVE TO GALLERY
      // -------------------------------------------------------

      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        await Gal.requestAccess();

        hasAccess = await Gal.hasAccess();
      }

      if (!hasAccess) {
        debugPrint('❌ Gallery permission denied');

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Gallery permission is required')),
        );

        return;
      }

      final fileName = 'MMB_${DateTime.now().millisecondsSinceEpoch}';

      await Gal.putImageBytes(bytes, name: fileName);

      debugPrint('✅ IMAGE SAVED TO GALLERY');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Image saved to Gallery successfully')),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Export/download error: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText('Unable to save image: $e')));
    }
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
            AppText(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            AppText(
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
                        child: AppText(
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
                                AppText(
                                  'Page ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                if (selected)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: AppText(
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
  double _resizeStartScale = 1.0;
  double _resizeStartWidth = 150.0;
  double _resizeStartHeight = 150.0;

  Offset _resizeStartPosition = Offset.zero;
  Offset _resizeStartGlobal = Offset.zero;

  // Actual source-image aspect ratio. The editor renders normal images with
  // BoxFit.contain, so the visible pixels can be smaller than item.width/height.
  double _imageAspectRatio = 1.0;
  bool _imageAspectReady = false;
  EditorProvider get _provider => context.read<EditorProvider>();

  // Normal media items are rendered inside a Transform.scale(scaleX), so
  // both axes use the canvas width scale. Background media is rendered by
  // _InteractiveBackgroundLayer with independent X/Y canvas scales.
  bool get _isText =>
      widget.item.type == 'text' || widget.item.type == 'textbox';

  Size get _naturalTextSize {
    final id = widget.item.id ?? '';
    final textValueForBounds = widget.item.text ?? '';
    final isMultilineForBounds =
        textValueForBounds.contains('\n') || textValueForBounds.contains('\r');

    final painter =
    TextPainter(
      text: TextSpan(
        text: textValueForBounds,
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
      maxLines: isMultilineForBounds ? null : 1,
      textDirection: TextDirection.ltr,
    )..layout(
      maxWidth: isMultilineForBounds && widget.item.width > 12.0
          ? widget.item.width
          : double.infinity,
    );
    return Size(math.max(1.0, painter.width), math.max(1.0, painter.height));
  }

  double get _baseVisualWidth {
    if (!_isText) return widget.item.width;
    final textValue = widget.item.text ?? "";
    final isMultiline = textValue.contains("\n") || textValue.contains("\r");
    if (!isMultiline) {
      return _naturalTextSize.width;
    }
    return (widget.item.width > 0)
        ? math.max(widget.item.width, _naturalTextSize.width)
        : _naturalTextSize.width;
  }

  double get _baseVisualHeight {
    if (!_isText) return widget.item.height;
    final textValue = widget.item.text ?? "";
    final isMultiline = textValue.contains("\n") || textValue.contains("\r");
    if (!isMultiline) {
      return _naturalTextSize.height;
    }

    // For text, the selection height should match what is actually rendered.
    // If it's wrapped (squeezed width), the height will increase.
    final w = _baseVisualWidth;
    final id = widget.item.id ?? '';
    final textValueForBounds = widget.item.text ?? '';

    final painter =
    TextPainter(
      text: TextSpan(
        text: textValueForBounds,
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
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(
      maxWidth: w,
    ); // Layout WITH the constrained width to get true height

    return math.max(widget.item.height, painter.height);
  }

  double get _width => _baseVisualWidth * widget.item.scale * widget.scaleX;

  double get _height =>
      _baseVisualHeight *
          widget.item.scale *
          (widget.isBackground ? widget.scaleY : widget.scaleX);

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

  // Since items (images/shapes) now use BoxFit.fill instead of BoxFit.contain,
  // the visual rectangle is exactly the scaled layout box.
  Rect get _visualRect {
    return Rect.fromLTWH(0, 0, _baseBoxWidth, _baseBoxHeight);
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

    // Expand the bounding box by 24 pixels on all sides so that handles
    // (which are 48x48) are fully enclosed in the touch area. This prevents
    // Flutter from ignoring touch events on the outer half of the handles.
    const double expandPadding = 24.0;

    return Positioned(
      left: _left - expandPadding,
      top: _top - expandPadding,
      width: width + expandPadding * 2,
      height: height + expandPadding * 2,
      child: Transform.rotate(
        angle: widget.item.rotation.isFinite ? widget.item.rotation : 0.0,
        // The rotation center remains the exact visual center because padding is symmetric
        alignment: Alignment.center,
        child: Stack(
          key: _overlayKey,
          clipBehavior: Clip.none,
          children: [
            // Drag the selected image from anywhere inside the actual box.
            Positioned(
              left: expandPadding,
              top: expandPadding,
              width: width,
              height: height,
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

                  final nextX = _startPosition.dx + dx;
                  final nextY = _startPosition.dy + dy;

                  _provider.updateItemTransform(
                    widget.item.id ?? '',
                    position: Offset(nextX, nextY),
                    clampToFrame: false,
                  );
                },
                onPanEnd: (_) => _provider.commitTransform(),
                onPanCancel: () => _provider.commitTransform(),
              ),
            ),

            // Selection UI follows the ACTUAL visible image rectangle.
            // Normal images use BoxFit.contain, so a landscape image inside a
            // square item must not get a square selection box around the empty
            // top/bottom space.
            Positioned(
              left: expandPadding + visual.left,
              top: expandPadding + visual.top,
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
                    // Thin side visuals have a generous transparent hit target.
                    _buildHandle(
                      alignment: Alignment.topCenter,
                      cursor: SystemMouseCursors.resizeUp,
                      width: visual.width,
                      height: visual.height,
                    ),
                    _buildHandle(
                      alignment: Alignment.centerLeft,
                      cursor: SystemMouseCursors.resizeLeft,
                      width: visual.width,
                      height: visual.height,
                    ),
                    _buildHandle(
                      alignment: Alignment.centerRight,
                      cursor: SystemMouseCursors.resizeRight,
                      width: visual.width,
                      height: visual.height,
                    ),
                    _buildHandle(
                      alignment: Alignment.bottomCenter,
                      cursor: SystemMouseCursors.resizeDown,
                      width: visual.width,
                      height: visual.height,
                    ),
                    // Corners last: priority over overlapping side hit areas.
                    _buildHandle(
                      alignment: Alignment.topLeft,
                      cursor: SystemMouseCursors.resizeUpLeft,
                      width: visual.width,
                      height: visual.height,
                    ),
                    _buildHandle(
                      alignment: Alignment.topRight,
                      cursor: SystemMouseCursors.resizeUpRight,
                      width: visual.width,
                      height: visual.height,
                    ),
                    _buildHandle(
                      alignment: Alignment.bottomRight,
                      cursor: SystemMouseCursors.resizeDownRight,
                      width: visual.width,
                      height: visual.height,
                    ),
                    _buildHandle(
                      alignment: Alignment.bottomLeft,
                      cursor: SystemMouseCursors.resizeDownLeft,
                      width: visual.width,
                      height: visual.height,
                    ),
                  ],
                ],
              ),
            ),

            // Rotation handle follows the visible image rectangle.
            Positioned(
              left: expandPadding + visual.left + visual.width / 2 - 24,
              top: expandPadding + visual.top - 48,
              width: 48,
              height: 48,
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
                onPanEnd: (_) => _provider.commitTransform(),
                onPanCancel: () => _provider.commitTransform(),
                child: Center(
                  child: _RotationHandleVisual(
                    angle: widget.item.rotation.isFinite
                        ? widget.item.rotation
                        : 0.0,
                  ),
                ),
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
      // _overlayKey belongs to the padded Stack inside the rotated widget.
      // Convert the visible image center into that Stack's local coordinates
      // by including the same padding used by Positioned/selection handles.
      // Omitting this offset makes the rotation pivot 24px up/left, causing
      // images to orbit/jump away from their original position while rotating.
      const double expandPadding = 24.0;
      return box.localToGlobal(
        Offset(
          expandPadding + visual.left + visual.width / 2,
          expandPadding + visual.top + visual.height / 2,
        ),
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
    required double width,
    required double height,
  }) {
    // Visual lines are thin, but each has a generous transparent hit target.
    const handleSize = 56.0;
    final targetX = (alignment.x + 1) / 2 * width;
    final targetY = (alignment.y + 1) / 2 * height;

    return Positioned(
      left: targetX - handleSize / 2,
      top: targetY - handleSize / 2,
      width: handleSize,
      height: handleSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _resizeStartScale = widget.item.scale.isFinite
              ? widget.item.scale
              : 1.0;
          _resizeStartWidth = widget.item.width;
          _resizeStartHeight = widget.item.height;
          _resizeStartPosition = widget.item.position;
          _resizeStartGlobal = details.globalPosition;
        },

        onPanUpdate: (details) {
          final baseWidth = math.max(1.0, _resizeStartWidth);
          final baseHeight = math.max(1.0, _resizeStartHeight);
          final globalDelta = details.globalPosition - _resizeStartGlobal;
          final canvasDx = globalDelta.dx / widget.scaleX;
          final canvasDy =
              globalDelta.dy /
                  (widget.isBackground ? widget.scaleY : widget.scaleX);

          final angle = widget.item.rotation.isFinite
              ? widget.item.rotation
              : 0.0;
          final cosA = math.cos(angle);
          final sinA = math.sin(angle);

          // Convert movement into the selected element's local coordinates.
          final dx = canvasDx * cosA + canvasDy * sinA;
          final dy = -canvasDx * sinA + canvasDy * cosA;

          // Left/right resize width only, anchoring the opposite edge.
          if (alignment.y == 0) {
            final signedDx = alignment.x == 1 ? dx : -dx;
            final nextWidth = (baseWidth + signedDx)
                .clamp(12.0, 4000.0)
                .toDouble();
            final delta = nextWidth - baseWidth;
            final localAnchorX = alignment.x == -1 ? -delta : 0.0;

            _provider.updateItemTransform(
              widget.item.id ?? '',
              width: nextWidth,
              position: Offset(
                _resizeStartPosition.dx + localAnchorX * cosA,
                _resizeStartPosition.dy + localAnchorX * sinA,
              ),
              clampToFrame: false,
            );
            return;
          }

          // Top/bottom resize height only, anchoring the opposite edge.
          if (alignment.x == 0) {
            final signedDy = alignment.y == 1 ? dy : -dy;
            final nextHeight = (baseHeight + signedDy)
                .clamp(12.0, 4000.0)
                .toDouble();
            final delta = nextHeight - baseHeight;
            final localAnchorY = alignment.y == -1 ? -delta : 0.0;

            _provider.updateItemTransform(
              widget.item.id ?? '',
              height: nextHeight,
              position: Offset(
                _resizeStartPosition.dx - localAnchorY * sinA,
                _resizeStartPosition.dy + localAnchorY * cosA,
              ),
              clampToFrame: false,
            );
            return;
          }

          // Corner handles resize proportionally and keep the opposite corner.
          final sx = alignment.x == 1 ? dx / baseWidth : -dx / baseWidth;
          final sy = alignment.y == 1 ? dy / baseHeight : -dy / baseHeight;
          final deltaScale = sx.abs() >= sy.abs() ? sx : sy;
          final nextScale = (_resizeStartScale + deltaScale)
              .clamp(0.02, 10.0)
              .toDouble();
          final scaleDelta = nextScale - _resizeStartScale;

          final localAnchorX = alignment.x == -1
              ? -baseWidth * scaleDelta
              : 0.0;
          final localAnchorY = alignment.y == -1
              ? -baseHeight * scaleDelta
              : 0.0;

          _provider.updateItemTransform(
            widget.item.id ?? '',
            scale: nextScale,
            position: Offset(
              _resizeStartPosition.dx +
                  localAnchorX * cosA -
                  localAnchorY * sinA,
              _resizeStartPosition.dy +
                  localAnchorX * sinA +
                  localAnchorY * cosA,
            ),
            clampToFrame: false,
          );
        },
        onPanEnd: (_) => _provider.commitTransform(),
        onPanCancel: () => _provider.commitTransform(),
        child: MouseRegion(
          cursor: cursor,
          child: Center(child: _ResizeHandleVisual(alignment: alignment)),
        ),
      ),
    );
  }
}

class _ResizeHandleVisual extends StatelessWidget {
  final Alignment alignment;

  const _ResizeHandleVisual({required this.alignment});

  @override
  Widget build(BuildContext context) {
    // Middle handles use thin lines; corner handles stay round.
    if (alignment.x == 0) {
      return Container(
        width: 20,
        height: 3,
        decoration: BoxDecoration(
          color: const Color(0xFF3568F5),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    if (alignment.y == 0) {
      return Container(
        width: 3,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFF3568F5),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3568F5), width: 1.5),
      ),
    );
  }
}

class _RotationHandleVisual extends StatelessWidget {
  final double angle;

  const _RotationHandleVisual({this.angle = 0.0});

  @override
  Widget build(BuildContext context) {
    final degrees = (angle * 180 / math.pi).round() % 360;
    final displayDegrees = degrees < 0 ? degrees + 360 : degrees;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (displayDegrees != 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${displayDegrees}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(width: 1.5, height: 18, color: const Color(0xFF3568F5)),
        const SizedBox(height: 2),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF3568F5), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 3),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.rotate_right_rounded,
              size: 14,
              color: Color(0xFF3568F5),
            ),
          ),
        ),
      ],
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

    // Selection frame is editor UI, not the object's actual outline/stroke.
    // Keep it consistently blue like Canva; line color/thickness controls
    // continue to affect the design object only.
    const selectionColor = Color(0xFF3568F5);
    const strokeWidth = 2.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final radius = borderRadius
        .clamp(0.0, math.min(rect.width, rect.height) / 2.0)
        .toDouble();
    final paint = Paint()
      ..color = selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
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
                child: SizedBox(
                  width: baseWidth,
                  height: baseHeight,
                  child: ClipRect(
                    child: SizedBox.expand(
                      child: EditableItemWidget.buildStandaloneMediaContent(
                        context,
                        item,
                      ),
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
}
