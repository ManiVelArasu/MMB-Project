import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
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
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../../Api Model/editor_model.dart';
import '../../Repository/freePic.dart';
import '../../Repository/project.dart';
import '../../component/custom_widget.dart';
import '../../core/api/api_endpoints.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/animation.dart';
import '../industry/widgets/editable.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/home_screen_provider.dart';
import '../../network/provider/prpject_provider.dart';
import 'dart:core';

import '../industry/widgets/gif.dart';
import '../industry/widgets/text_effect.dart';

class TemplateEditScreen extends StatelessWidget {
  final String? resizeSize;
  final String? templateUid;

  final double? canvasWidth;
  final double? canvasHeight;

  /// Open an EXISTING project (Download screen -> Edit).
  final String? projectUid;
  final String? projectName;
  final String? projectContent;
  final int? projectTemplateId;

  const TemplateEditScreen({
    super.key,
    this.resizeSize,
    this.templateUid,
    this.canvasWidth,
    this.canvasHeight,
    this.projectUid,
    this.projectName,
    this.projectContent,
    this.projectTemplateId,
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

    String? resolvedProjectUid = projectUid;
    String? resolvedProjectName = projectName;
    String? resolvedProjectContent = projectContent;
    if (args is Map) {
      final pu = args['projectUid'] ?? args['project_uid'];
      if (pu != null && pu.toString().trim().isNotEmpty) {
        resolvedProjectUid = pu.toString().trim();
      }
      final pn = args['projectName'] ?? args['project_name'];
      if (pn != null) resolvedProjectName = pn.toString();
      final pc = args['projectContent'] ?? args['project_content'];
      if (pc != null) resolvedProjectContent = pc.toString();
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
            projectUid: resolvedProjectUid,
            projectName: resolvedProjectName,
            projectContent: resolvedProjectContent,
            projectTemplateId: projectTemplateId,
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
  final String? projectUid;
  final String? projectName;
  final String? projectContent;
  final int? projectTemplateId;

  const EditorView({
    super.key,
    required this.resizeSize,
    this.templateUid,
    this.canvasWidth,
    this.canvasHeight,
    this.projectUid,
    this.projectName,
    this.projectContent,
    this.projectTemplateId,
  });

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  bool _showFlipOptions = false;
  bool _showImageFilters = false;

  /// When equal to the selected item id, the ANIMATE panel is docked at the bottom.
  String? _animatePanelItemId;

  /// 0 = Effects (text only), 1 = Animate.
  int _animatePanelTab = 1;
  final AudioPlayer _musicPlayer = AudioPlayer();
  StreamSubscription<Duration>? _musicPositionSubscription;
  StreamSubscription<Duration>? _musicDurationSubscription;
  StreamSubscription<void>? _musicCompleteSubscription;
  StreamSubscription<PlayerState>? _musicStateSubscription;

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
    final matchingItems = provider.items.where((e) => e.id == itemId);

    if (matchingItems.isEmpty) return;

    final item = matchingItems.first;

    if (item.type != 'image' || (item.contentUrl ?? '').isEmpty) {
      return;
    }

    // Show a loading indicator while a network image is downloaded locally.
    // Close it before launching the native crop screen.
    var loadingDialogShown = false;
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      loadingDialogShown = true;
    }

    String? sourcePath;
    try {
      sourcePath = await _prepareCropSource(item.contentUrl!);
    } finally {
      if (loadingDialogShown && mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
      }
    }

    if (!mounted) return;

    if (sourcePath == null) {
      Fluttertoast.showToast(msg: 'Unable to open image for crop');
      return;
    }

    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      // Preserve transparency.
      compressFormat: ImageCompressFormat.png,
      compressQuality: 100,
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
          title: const AppText(
            'Plan Limit Reached',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const AppText(
            'You have reached your Business Posts Templates limit. '
            'Please upgrade your plan or buy a top-up to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).maybePop();
              },
              child: const AppText('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // TODO: Navigate to your existing Buy Plan screen.
                // Example:
                // Get.to(() => const SubscriptionScreen());
              },
              child: const AppText('Buy Plan'),
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
    // EXISTING PROJECT (Download screen -> Edit)
    // =====================================================
    final openProjectUid = widget.projectUid?.trim() ?? '';
    if (openProjectUid.isNotEmpty) {
      await _openExistingProject(
        editorProvider,
        projectProvider,
        openProjectUid,
      );
      return;
    }

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

  bool _projectOpened = false;
  String? _projectOpenError;

  bool get _isOpeningProject => (widget.projectUid?.trim() ?? '').isNotEmpty;

  /// Loads a saved project into the editor, then calls the UPDATE project API.
  Future<void> _openExistingProject(
    EditorProvider editorProvider,
    ProjectProvider projectProvider,
    String projectUid,
  ) async {
    final content = widget.projectContent?.trim() ?? '';

    if (content.isEmpty) {
      if (mounted) {
        setState(() => _projectOpenError = 'Project content not available');
      }
      return;
    }

    final fallbackSize = _getCanvasSize();
    final ok = editorProvider.loadProjectContent(
      content,
      canvasWidth: fallbackSize.width,
      canvasHeight: fallbackSize.height,
    );

    if (!mounted) return;

    if (!ok) {
      setState(() => _projectOpenError = 'Unable to open this project');
      return;
    }

    projectProvider.setExistingProject(
      uid: projectUid,
      name: widget.projectName,
      templateId: widget.projectTemplateId,
    );

    _enableProjectAutoSave();
    setState(() => _projectOpened = true);

    editorProvider.fetchFreePikAssets('furniture');
    editorProvider.fetchFreePikStickers('stickers');

    // UPDATE PROJECT API on open. The content is sent exactly as it was
    // loaded (not re-exported), so nothing in the project can change; the
    // thumbnail is not sent either (the canvas is still loading images).
    setState(() => _projectSaveStatus = 'Saving...');
    try {
      final name = (widget.projectName?.trim().isNotEmpty ?? false)
          ? widget.projectName!.trim()
          : (projectProvider.projectName ?? 'Untitled design');

      final result = await ProjectRepository.instance.updateProject(
        projectUid: projectUid,
        name: name,
        content: content,
      );

      final success = result.when(
        success: (_) => true,
        failure: (error) {
          debugPrint('Project update on open failed: ${error.message}');
          return false;
        },
      );

      if (!mounted) return;
      setState(() => _projectSaveStatus = success ? 'Saved' : 'Save failed');
    } catch (e, st) {
      debugPrint('Project update on open error: $e\n$st');
      if (mounted) setState(() => _projectSaveStatus = 'Save failed');
    }
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
    int selectedTab = 0;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.white54 : Colors.black26;
    final cardBorder = isDark ? Colors.white24 : Colors.grey.shade300;

    final staticFrames = <Map<String, String>>[
      {'asset': 'assets/images/thumbnail1.png', 'name': 'Free', 'price': ''},
      {
        'asset': 'assets/images/thumbnail1.png',
        'name': 'Rs.0 (Rs.100 Unlocked)',
        'price': '',
      },
      {'asset': 'assets/images/thumbnail1.png', 'name': 'Free', 'price': ''},
      {'asset': 'assets/images/thumbnail1.png', 'name': 'Free', 'price': ''},
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final frames = staticFrames;

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.50,
              padding: const EdgeInsets.fromLTRB(20, 12, 0, 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 100,
                        height: 5,
                        decoration: BoxDecoration(
                          color: mutedColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Header
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        children: [
                          AppText(
                            'My Frames',
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize18,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE5E7),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.circle,
                                color: Color(0xFFEF2029),
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Edit button
                          _frameHeaderButton(
                            icon: Icons.edit_outlined,
                            onTap: () {
                              // Add your existing frame edit action here.
                            },
                          ),
                          const SizedBox(width: 12),

                          // Add button
                          _frameHeaderButton(
                            icon: Icons.add,
                            onTap: () {
                              // Add your existing create-frame action here.
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        children: [
                          _frameTab(
                            title: 'Static Frames',
                            selected: selectedTab == 0,
                            onTap: () {
                              setSheetState(() => selectedTab = 0);
                            },
                            textColor: textColor,
                            mutedColor: mutedColor,
                          ),
                          const SizedBox(width: 22),
                          _frameTab(
                            title: 'Animated Frames',
                            selected: selectedTab == 1,
                            onTap: () {
                              setSheetState(() => selectedTab = 1);
                            },
                            textColor: textColor,
                            mutedColor: mutedColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Frame cards
                    Expanded(
                      child: selectedTab == 0
                          ? ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(
                                right: 20,
                                bottom: 12,
                              ),
                              itemCount: frames.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final frame = frames[index];

                                return SizedBox(
                                  width: 105,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            provider.setSelectedFrame(
                                              frame['asset']!,
                                            );
                                            Navigator.pop(modalContext);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF2C2C2C)
                                                  : Colors.white,
                                              border: Border.all(
                                                color: cardBorder,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                              child: Image.asset(
                                                frame['asset']!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.image_outlined,
                                                          size: 42,
                                                          color: Colors.blue,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      AppText(
                                        frame['name']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: AppText(
                                'No animated frames available',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 14,
                                ),
                              ),
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

  Widget _frameHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFF252D), size: 22),
      ),
    );
  }

  Widget _frameTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required Color textColor,
    required Color mutedColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              title,
              style: TextStyle(
                fontSize: AppFontSize.fontSize18,
                fontWeight: FontWeight.w500,
                color: selected ? textColor : mutedColor,
              ),
            ),
            const SizedBox(height: 5),
            if (selected)
              Container(
                height: 2,
                width: title == 'Static Frames' ? 142 : 160,
                color: const Color(0xFFFF252D),
              ),
          ],
        ),
      ),
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
            if (selectedTab == 0 &&
                !elementsOnly &&
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
                    child:
                        provider.isLoadingMyUploads &&
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

    // Single source of truth for the play/pause icon: the real player state.
    _musicStateSubscription = _musicPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      context.read<EditorProvider>().setMusicPlaying(
        state == PlayerState.playing,
      );
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
    _musicStateSubscription?.cancel();
    _musicPlayer.dispose();
    super.dispose();
  }

  bool _isCapturingThumbnail = false;

  // ---------------- PINCH-ZOOM OF THE SELECTED ELEMENT ----------------
  final GlobalKey _pinchKey = GlobalKey();
  String _pinchId = '';
  double _pinchStartScale = 1.0;
  Offset _pinchStartCenter = Offset.zero; // canvas units
  Size _pinchBaseSize = const Size(1, 1); // un-scaled layout size

  EditorItem? _selectedZoomItem(EditorProvider provider) {
    final id = provider.selectedItemId;
    if (id == null) return null;
    for (final e in provider.items) {
      if (e.id == id) return _isCanvasBackground(e) ? null : e;
    }
    return null;
  }

  void _onPinchStart(ScaleStartDetails d) {
    final provider = context.read<EditorProvider>();
    final item = _selectedZoomItem(provider);
    if (item == null) {
      _pinchId = '';
      return;
    }
    _pinchId = item.id ?? '';
    _pinchStartScale = item.scale.isFinite
        ? item.scale.clamp(0.01, 10.0).toDouble()
        : 1.0;
    _pinchBaseSize = EditableItemWidget.isTextType(item.type)
        ? EditableItemWidget.measureTextBox(item, provider)
        : Size(math.max(1.0, item.width), math.max(1.0, item.height));
    // Visual centre stays put while the element grows / shrinks.
    _pinchStartCenter =
        item.position +
        Offset(_pinchBaseSize.width, _pinchBaseSize.height) *
            (_pinchStartScale / 2);
  }

  void _onPinchUpdate(ScaleUpdateDetails d) {
    if (_pinchId.isEmpty) return;
    final provider = context.read<EditorProvider>();
    final newScale = (_pinchStartScale * d.scale).clamp(0.02, 10.0).toDouble();
    final half =
        Offset(_pinchBaseSize.width, _pinchBaseSize.height) * (newScale / 2);
    provider.updateItemTransform(
      _pinchId,
      scale: newScale,
      position: _pinchStartCenter - half,
      clampToFrame: false,
    );
  }

  void _onPinchEnd(ScaleEndDetails d) {
    if (_pinchId.isEmpty) return;
    context.read<EditorProvider>().commitTransform();
    _pinchId = '';
  }

  /// Two fingers on the canvas pinch-zoom ONLY the selected element.
  /// One-finger gestures (move / resize / rotate) are untouched.
  Widget _pinchZoomLayer({required bool enabled, required Widget child}) {
    return RawGestureDetector(
      key: _pinchKey,
      behavior: HitTestBehavior.translucent,
      gestures: enabled
          ? <Type, GestureRecognizerFactory>{
              _TwoFingerScaleRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _TwoFingerScaleRecognizer
                  >(() => _TwoFingerScaleRecognizer(), (r) {
                    r
                      ..onStart = _onPinchStart
                      ..onUpdate = _onPinchUpdate
                      ..onEnd = _onPinchEnd;
                  }),
            }
          : const <Type, GestureRecognizerFactory>{},
      child: child,
    );
  }

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

    if (_isOpeningProject && _projectOpenError != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        ),
        body: Center(
          child: AppText(
            _projectOpenError!,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      );
    }
    if (_isOpeningProject && !_projectOpened) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

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
    final Size canvasSize = (hasTemplateUid || _isOpeningProject)
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
          _pinchZoomLayer(
            enabled: _selectedZoomItem(provider) != null,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: provider.backgroundColor,
                      ),
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
                                        provider.setSelectedItem(
                                          bg.type,
                                          bg.id,
                                        );

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
                                              provider.setSelectedItem(
                                                type,
                                                id,
                                              );
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
                                                  e.id ==
                                                  provider.selectedItemId,
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
                                          width:
                                              item.width * item.scale * scaleX,
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

    final animSelId = provider.selectedItemId;
    if (animSelId != null &&
        _animatePanelItemId == animSelId &&
        _supportsAnimation(provider, animSelId)) {
      return _buildAnimatePanel(context, provider, isDark);
    }

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

  // ---------------------------------------------------------------------
  // ANIMATE panel (docked at the bottom when an item is selected).
  // ---------------------------------------------------------------------
  bool _supportsAnimation(EditorProvider provider, String id) {
    final matches = provider.items.where((e) => e.id == id);
    if (matches.isEmpty) return false;
    return !_isCanvasBackground(matches.first);
  }

  void _openAnimatePanel(EditorProvider provider, String id, {int tab = 1}) {
    setState(() {
      _animatePanelItemId = id;
      _animatePanelTab = tab;
    });
  }

  void _closeAnimatePanel() {
    if (_animatePanelItemId == null) return;
    setState(() => _animatePanelItemId = null);
  }

  Widget _buildAnimatePanel(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    final id = provider.selectedItemId;
    if (id == null) return const SizedBox.shrink();
    final matches = provider.items.where((e) => e.id == id);
    if (matches.isEmpty) return const SizedBox.shrink();

    final item = matches.first;
    final anim = provider.itemAnimation(id);
    final locked = provider.isItemLocked(id);
    final isText = EditableItemWidget.isTextType(item.type);
    // Effects tab only exists for text.
    final showEffects = isText && _animatePanelTab == 0;

    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF171717);
    final soft = isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF3F3F3);
    const accent = Color(0xFFE53935);

    final firstTabLabel = isText
        ? 'EFFECTS'
        : (item.type == 'image'
              ? 'IMAGE'
              : (item.type == 'video' ? 'VIDEO' : 'ELEMENT'));

    Widget tab(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? accent : fg.withValues(alpha: .65),
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 2, width: active ? 52 : 0, color: accent),
            ],
          ),
        ),
      );
    }

    Widget quick(
      IconData icon,
      VoidCallback onTap, {
      bool active = false,
      bool danger = false,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: danger
                ? const Color(0xFFFFE5E5)
                : (active ? accent.withValues(alpha: .15) : soft),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: (danger || active) ? accent : fg),
        ),
      );
    }

    // One selectable tile (used by both the effects and animation rows).
    Widget tile({
      required IconData icon,
      required String label,
      required bool selected,
      required bool isNone,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isNone
                        ? soft
                        : (selected ? accent.withValues(alpha: .08) : bg),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? accent
                          : (isNone
                                ? Colors.transparent
                                : accent.withValues(alpha: .28)),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isNone ? Colors.grey.shade600 : accent,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? accent : fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: AppText(
        text,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg),
      ),
    );

    Widget valueBox(String text) => Container(
      width: 58,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE6E6E6),
        ),
      ),
      child: AppText(
        text,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg),
      ),
    );

    Widget slider({
      required double value,
      required double min,
      required double max,
      required ValueChanged<double> onChanged,
      ValueChanged<double>? onChangeEnd,
      int? divisions,
    }) {
      return SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          activeTrackColor: fg,
          inactiveTrackColor: fg.withValues(alpha: .15),
          thumbColor: fg,
          overlayColor: fg.withValues(alpha: .1),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
        child: Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      );
    }

    // "Offset  ----o----  [30]" row used by effect settings.
    Widget labelledSlider({
      required String label,
      required double value,
      required double min,
      required double max,
      required String display,
      required ValueChanged<double> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: AppText(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            Expanded(
              child: slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            valueBox(display),
          ],
        ),
      );
    }

    // "Delay (0-2.9s)" with the slider underneath.
    Widget delaySlider() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Delay (0-2.9s)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: slider(
                  value: anim.delay,
                  min: 0,
                  max: 2.9,
                  divisions: 29,
                  onChanged: (v) => provider.setItemAnimationDelay(id, v),
                  onChangeEnd: (_) => provider.previewItemAnimation(id),
                ),
              ),
              valueBox(anim.delay.toStringAsFixed(1)),
            ],
          ),
        ],
      );
    }

    // Grey rounded dropdown button + popup list (red = selected).
    Widget dropdown<T>({
      required T value,
      required List<T> values,
      required String Function(T) labelOf,
      required IconData Function(T) iconOf,
      required ValueChanged<T> onSelected,
    }) {
      return PopupMenuButton<T>(
        onSelected: onSelected,
        color: bg,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 60,
        ),
        itemBuilder: (_) => values.map((v) {
          final selected = v == value;
          return PopupMenuItem<T>(
            value: v,
            height: 44,
            child: Row(
              children: [
                Icon(iconOf(v), size: 18, color: selected ? accent : fg),
                const SizedBox(width: 14),
                AppText(
                  labelOf(v),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? accent : fg,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          height: 48,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(iconOf(value), size: 18, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  labelOf(value).toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: fg.withValues(alpha: .8),
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, color: fg, size: 26),
            ],
          ),
        ),
      );
    }

    Widget colorChips(Color current, ValueChanged<Color> onPick) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: AppText(
                'Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: kTextEffectColors.map((c) {
                    final active = c.toARGB32() == current.toARGB32();
                    return GestureDetector(
                      onTap: () => onPick(c),
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active ? accent : Colors.grey.shade400,
                            width: active ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------------
    // EFFECTS body (text only)
    // ------------------------------------------------------------------
    List<Widget> effectsBody() {
      final fx = provider.textEffect(id);
      return [
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: TextEffectType.values.map((t) {
              return tile(
                icon: t.icon,
                label: t.label,
                selected: fx.type == t,
                isNone: t == TextEffectType.none,
                onTap: () => provider.setTextEffectType(id, t),
              );
            }).toList(),
          ),
        ),
        if (!fx.isNone) ...[
          sectionTitle('${fx.type.label} Settings'),
          ...fx.type.sliders.map((spec) {
            final v = fx.valueOf(spec.key);
            return labelledSlider(
              label: spec.label,
              value: v,
              min: spec.min,
              max: spec.max,
              display: '${v.round()}${spec.unit}',
              onChanged: (nv) => provider.updateTextEffect(
                id,
                (e) => e.withValue(spec.key, nv.roundToDouble()),
              ),
            );
          }),
          if (fx.type.hasColor)
            colorChips(
              fx.color,
              (c) => provider.updateTextEffect(id, (e) => e.copyWith(color: c)),
            ),
          if (fx.type.hasGlitchPresets) ...[
            const SizedBox(height: 6),
            Row(
              children: List.generate(kGlitchPresets.length, (i) {
                final selected = fx.glitchPreset == i;
                final colors = kGlitchPresets[i];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == kGlitchPresets.length - 1 ? 0 : 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => provider.updateTextEffect(
                        id,
                        (e) => e.copyWith(glitchPreset: i),
                      ),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? accent
                                : (isDark
                                      ? Colors.white12
                                      : const Color(0xFFE6E6E6)),
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 22,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: colors[0],
                                    ),
                                  ),
                                  Positioned(
                                    left: 11,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: colors[1],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: AppText(
                                kGlitchPresetNames[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ];
    }

    // ------------------------------------------------------------------
    // ANIMATE body
    // ------------------------------------------------------------------
    Widget modeChip(ItemAnimationMode mode) {
      final selected = anim.mode == mode;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: mode == ItemAnimationMode.exit ? 0 : 8,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => provider.setItemAnimationMode(id, mode),
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.black : soft,
                borderRadius: BorderRadius.circular(12),
                border: isDark && selected
                    ? Border.all(color: Colors.white24)
                    : null,
              ),
              child: AppText(
                mode.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : fg,
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> animateBody() {
      return [
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ItemAnimationType.values.map((t) {
              return tile(
                icon: t.icon,
                label: t.label,
                selected: anim.type == t,
                isNone: t == ItemAnimationType.none,
                onTap: () => provider.setItemAnimationType(id, t),
              );
            }).toList(),
          ),
        ),
        if (!anim.isNone) ...[
          sectionTitle('${anim.type.label} animation Settings'),
          Row(children: ItemAnimationMode.values.map(modeChip).toList()),
          const SizedBox(height: 12),
          if (anim.type.hasDirection) ...[
            dropdown<ItemAnimDirection>(
              value: anim.direction,
              values: ItemAnimDirection.values,
              labelOf: (d) => d.label,
              iconOf: (d) => d.icon,
              onSelected: (d) => provider.setItemAnimationDirection(id, d),
            ),
            const SizedBox(height: 10),
          ],
          if (anim.type.hasAxis) ...[
            dropdown<ItemAnimAxis>(
              value: anim.axis,
              values: ItemAnimAxis.values,
              labelOf: (a) => a.label,
              iconOf: (a) => a.icon,
              onSelected: (a) => provider.setItemAnimationAxis(id, a),
            ),
            const SizedBox(height: 6),
          ],
          delaySlider(),
        ],
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (anim.isNone) {
              Fluttertoast.showToast(msg: 'Select an animation first');
              return;
            }
            provider.previewItemAnimation(id);
          },
          child: Container(
            height: 46,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow_rounded, color: accent, size: 22),
                SizedBox(width: 6),
                AppText(
                  'PREVIEW ANIMATION',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x33000000))],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  tab(firstTabLabel, showEffects, () {
                    if (isText) {
                      setState(() => _animatePanelTab = 0);
                    } else {
                      _closeAnimatePanel();
                    }
                  }),
                  tab('ANIMATE', !showEffects, () {
                    setState(() => _animatePanelTab = 1);
                  }),
                  const Spacer(),
                  // Close the panel -> back to the normal toolbar.
                  InkWell(
                    onTap: _closeAnimatePanel,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE5E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: accent, size: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  quick(Icons.layers_rounded, () {
                    _showLayerSheet(context, provider, id, isDark);
                  }),
                  quick(Icons.align_horizontal_left_rounded, () {
                    _showAlignSheet(context, provider, id, isDark);
                  }),
                  quick(
                    locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    () {
                      provider.toggleItemLock(id);
                      Fluttertoast.showToast(
                        msg: provider.isItemLocked(id) ? 'Locked' : 'Unlocked',
                      );
                    },
                    active: locked,
                  ),
                  quick(Icons.content_copy_rounded, () {
                    provider.duplicateItem(id);
                    if (provider.items.isNotEmpty) {
                      final last = provider.items.last;
                      if (last.id != null && last.id != id) {
                        provider.setSelectedItem(last.type, last.id);
                        setState(() => _animatePanelItemId = last.id);
                      }
                    }
                  }),
                  quick(Icons.delete_rounded, () {
                    provider.removeItem(id);
                    provider.clearSelection();
                    _closeAnimatePanel();
                  }, danger: true),
                ],
              ),
              const SizedBox(height: 12),
              ...(showEffects ? effectsBody() : animateBody()),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlignSheet(
    BuildContext context,
    EditorProvider provider,
    String id,
    bool isDark,
  ) {
    void alignTo(String where) {
      if (provider.isItemLocked(id)) {
        Fluttertoast.showToast(msg: 'Item is locked. Unlock it first.');
        return;
      }
      final matches = provider.items.where((e) => e.id == id);
      if (matches.isEmpty) return;
      final cur = matches.first;

      final canvas = Size(provider.canvasWidth, provider.canvasHeight);
      final s = cur.scale.clamp(0.01, 10.0).toDouble();
      final box = EditableItemWidget.isTextType(cur.type)
          ? EditableItemWidget.measureTextBox(cur, provider)
          : Size(cur.width, cur.height);
      final w = box.width * s;
      final h = box.height * s;

      var x = cur.position.dx;
      var y = cur.position.dy;
      switch (where) {
        case 'left':
          x = 0;
          break;
        case 'center':
          x = (canvas.width - w) / 2;
          break;
        case 'right':
          x = canvas.width - w;
          break;
        case 'top':
          y = 0;
          break;
        case 'middle':
          y = (canvas.height - h) / 2;
          break;
        case 'bottom':
          y = canvas.height - h;
          break;
      }
      provider.updatePosition(id, Offset(x, y));
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget btn(IconData icon, String label, String where) {
          return OutlinedButton.icon(
            onPressed: () {
              alignTo(where);
              Navigator.pop(ctx);
            },
            icon: Icon(icon, size: 18),
            label: Text(label, style: const TextStyle(fontSize: 12)),
          );
        }

        return SafeArea(
          child: _sheetShell(
            isDark: isDark,
            title: 'Align to page',
            height: 230,
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 2.3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                btn(Icons.align_horizontal_left, 'Left', 'left'),
                btn(Icons.align_horizontal_center, 'Center', 'center'),
                btn(Icons.align_horizontal_right, 'Right', 'right'),
                btn(Icons.align_vertical_top, 'Top', 'top'),
                btn(Icons.align_vertical_center, 'Middle', 'middle'),
                btn(Icons.align_vertical_bottom, 'Bottom', 'bottom'),
              ],
            ),
          ),
        );
      },
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
      return SizedBox(
        width: 64,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
            tool(Icons.auto_awesome, 'EFFECTS', () {
              _openAnimatePanel(provider, id, tab: 0);
            }),
            tool(Icons.animation, 'ANIMATE', () {
              _openAnimatePanel(provider, id, tab: 1);
            }),
          ],
        ),
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
    final outlineColor = item.outlineColor;
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
          if (!_showImageFilters)
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
                    Icons.animation,
                    'ANIMATE',
                    () => _openAnimatePanel(provider, id),
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
    return Container(
      height: 124,
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Delete action sits above the image tools, matching the requested layout.
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.white,
            alignment: Alignment.center,
            child: Material(
              color: const Color(0xFFFFE2E2),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () {
                  provider.removeItem(id);
                  provider.clearSelection();
                },
                child: const SizedBox(
                  width: 60,
                  height: 42,
                  child: Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFF04444),
                    size: 23,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView(
              key: PageStorageKey<String>('image-tools-$id'),
              scrollDirection: Axis.horizontal,
              controller: ScrollController(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              children: [
                _bottomTool(
                  Icons.close,
                  'CLOSE',
                  () => provider.clearSelection(),
                ),
                if (!_isCanvasBackground(item))
                  _bottomTool(
                    Icons.animation,
                    'ANIMATE',
                    () => _openAnimatePanel(provider, id),
                  ),
                _bottomTool(
                  Image.asset("assets/images/edit_upload.png"),
                  'UPLOADS',
                  () => _showMediaBottomSheet(context, provider, isDark),
                ),
                _bottomTool(
                  Image.asset("assets/images/gallery.png"),
                  'IMAGES',
                  () => _showMediaBottomSheet(context, provider, isDark),
                ),
                _bottomTool(
                  Image.asset("assets/images/crop.png"),
                  'CROP',
                  () => _cropSelectedImage(context, provider, id),
                ),
                _bottomTool(
                  Image.asset("assets/images/set_us_bg.png"),
                  'SET US BG',
                  () async {
                    final url = item.contentUrl;
                    if (url != null && url.isNotEmpty) {
                      await _confirmReplaceBackground(
                        context,
                        provider,
                        url,
                        selectedItemId: id,
                      );
                    }
                  },
                ),
                _bottomTool(
                  Image.asset("assets/images/mask.png"),
                  'MASK',
                  () => _showApiMaskSheet(context, provider, id),
                ),
                _bottomTool(
                  Image.asset("assets/images/magic_pen.png"),
                  'REMOVE BG',
                  () => _showRemoveBackgroundSheet(
                    context,
                    isDark,
                    onSlideComplete: () {
                      // Connect your actual background-removal API here.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Slide completed. Connect the background-removal API here.',
                          ),
                        ),
                      );
                    },
                  ),
                ),

                _bottomTool(
                  Image.asset("assets/images/scan_barcode.png"),
                  'ADJUST',
                  () => _showAdjustSheet(context, provider, id, isDark),
                ),
                _bottomTool(
                  Image.asset("assets/images/gallery_edit.png"),
                  'EDIT',
                  () => _showEditSheet(context, provider, id, isDark),
                ),
                _bottomTool(
                  Image.asset("assets/images/layer.png"),
                  'LAYER',
                  () => _showLayerSheet(context, provider, id, isDark),
                ),
                _bottomTool(
                  Image.asset("assets/images/lock.png"),
                  provider.isItemLocked(id) ? 'UNLOCK' : 'LOCK',
                  () {
                    provider.toggleItemLock(id);
                    Fluttertoast.showToast(
                      msg: provider.isItemLocked(id) ? 'Locked' : 'Unlocked',
                    );
                  },
                ),
              ],
            ),
          ),
          if (_showFlipOptions && !_showImageFilters)
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
        ],
      ),
    );
  }

  Widget _sheetShell({
    required bool isDark,
    required String title,
    required Widget child,
    double height = 250,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppText(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _showAdjustSheet(
    BuildContext context,
    EditorProvider provider,
    String id,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final current = provider.items.firstWhere((e) => e.id == id);
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              final item = provider.items.firstWhere((e) => e.id == id);
              return _sheetShell(
                isDark: isDark,
                title: 'Adjust',
                child: Column(
                  children: [
                    _compactAdjustSlider('Opacity', item.opacity, 0, 1, (v) {
                      provider.updateOpacity(id, v);
                      setSheetState(() {});
                    }),
                    _compactAdjustSlider(
                      'Rotate',
                      item.rotation,
                      0,
                      math.pi * 2,
                      (v) {
                        provider.updateRotation(id, v);
                        setSheetState(() {});
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        'Flip',
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => provider.flipImageHorizontal(id),
                            icon: const Icon(Icons.flip),
                            label: const Text('HORIZONTAL'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => provider.flipImageVertical(id),
                            icon: const Icon(Icons.flip),
                            label: const Text('VERTICAL'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _compactAdjustSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final shown = value.clamp(min, max).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: AppText(
            label,
            style: TextStyle(
              fontSize: AppFontSize.fontSize12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Slider(min: min, max: max, value: shown, onChanged: onChanged),
        ),
        SizedBox(
          width: 35,
          child: AppText(
            label == 'Rotate'
                ? '${(shown * 180 / math.pi).round()}°'
                : '${(shown * 100).round()}',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  List<double> _filterPreviewMatrix(String filter) {
    switch (filter.toLowerCase()) {
      case 'festive':
      case 'summer':
        return const [
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
        return const [
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
        return const [
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
        return const [
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
        return const [
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
        return const [
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
        return const [
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
        return const [
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
        return const [
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
        return const [
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
      default:
        return const [
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
    }
  }

  void _showEditSheet(
    BuildContext context,
    EditorProvider provider,
    String id,
    bool isDark,
  ) {
    const filters = [
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            final item = provider.items.firstWhere((e) => e.id == id);
            return _sheetShell(
              isDark: isDark,
              title: 'Filters',
              height: 420,
              child: Column(
                children: [
                  SizedBox(
                    height: 154,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final selected =
                            item.filterType.toLowerCase() == filter;
                        final source = (item.contentUrl ?? '').trim();
                        return GestureDetector(
                          onTap: () {
                            provider.setImageFilter(id, filter);
                            setSheetState(() {});
                          },
                          child: SizedBox(
                            width: 146,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 112,
                                  width: 116,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selected
                                          ? Colors.blue
                                          : Colors.black12,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: source.isEmpty
                                      ? Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            size: 32,
                                          ),
                                        )
                                      : ColorFiltered(
                                          colorFilter: ColorFilter.matrix(
                                            _filterPreviewMatrix(filter),
                                          ),
                                          child:
                                              source.startsWith('http://') ||
                                                  source.startsWith('https://')
                                              ? Image.network(
                                                  source,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                        child: const Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                        ),
                                                      ),
                                                )
                                              : Image.file(
                                                  File(source),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                        child: const Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                        ),
                                                      ),
                                                ),
                                        ),
                                ),
                                const SizedBox(height: 5),
                                AppText(
                                  filter[0].toUpperCase() + filter.substring(1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppFontSize.fontSize12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        _compactAdjustSlider(
                          'Intensity',
                          provider.imageFilterIntensity(id),
                          0,
                          1,
                          (v) {
                            provider.updateImageFilterIntensity(id, v);
                            setSheetState(() {});
                          },
                        ),
                        _compactAdjustSlider(
                          'Brightness',
                          item.brightness,
                          -1,
                          1,
                          (v) {
                            provider.updateImageColorAdjustments(
                              id,
                              brightness: v,
                            );
                            setSheetState(() {});
                          },
                        ),
                        _compactAdjustSlider('Contrast', item.contrast, .5, 2, (
                          v,
                        ) {
                          provider.updateImageColorAdjustments(id, contrast: v);
                          setSheetState(() {});
                        }),
                        _compactAdjustSlider(
                          'Saturation',
                          item.saturation,
                          0,
                          2,
                          (v) {
                            provider.updateImageColorAdjustments(
                              id,
                              saturation: v,
                            );
                            setSheetState(() {});
                          },
                        ),
                        _compactAdjustSlider(
                          'Tint',
                          provider.imageTint(id),
                          -100,
                          100,
                          (v) {
                            provider.updateImageTint(id, v);
                            setSheetState(() {});
                          },
                        ),
                        _compactAdjustSlider(
                          'Blur',
                          provider.imageBlur(id),
                          0,
                          20,
                          (v) {
                            provider.updateImageBlur(id, v);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        provider.setImageFilter(id, 'normal');
                        provider.updateImageFilterIntensity(id, 1);
                        provider.updateImageColorAdjustments(
                          id,
                          brightness: 0,
                          contrast: 1,
                          saturation: 1,
                        );
                        provider.updateImageTint(id, 0);
                        provider.updateImageBlur(id, 0);
                        setSheetState(() {});
                      },
                      child: const Text('REVERT TO ORIGINAL'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLayerSheet(
    BuildContext context,
    EditorProvider provider,
    String id,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: _sheetShell(
          isDark: isDark,
          title: 'Layer',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.bringToFront(id);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.flip_to_front),
                      label: const Text('Forward'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.sendToBack(id);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.flip_to_back),
                      label: const Text('Backward'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.bringToFront(id);
                        Navigator.pop(ctx);
                      },
                      child: const Text('To Front'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.sendToBack(id);
                        Navigator.pop(ctx);
                      },
                      child: const Text('To Back'),
                    ),
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  'Nudge',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Text(
                'Use arrow keys or drag the selected image to adjust its position.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveBackgroundSheet(
    BuildContext context,
    bool isDark, {
    required VoidCallback onSlideComplete,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RemoveBackgroundSlideSheet(
        isDark: isDark,
        onSlideComplete: onSlideComplete,
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
      padding: const EdgeInsets.only(right: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 62,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon is IconData)
                Icon(icon, color: danger ? Colors.red : Colors.white, size: 18)
              else if (icon is Widget)
                SizedBox(width: 18, height: 18, child: icon),
              const SizedBox(height: 4),
              Flexible(
                child: AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Source _musicSource(String path) => path.startsWith('http')
      ? UrlSource(path)
      : path.startsWith('assets/')
      ? AssetSource(path.replaceFirst('assets/', ''))
      : DeviceFileSource(path);

  Future<void> _toggleEditorMusic(EditorProvider provider) async {
    final path = provider.selectedMusicPath;
    if (path == null) return;

    try {
      // Decide from the real player state, not the provider flag, so the two
      // can never get out of sync.
      switch (_musicPlayer.state) {
        case PlayerState.playing:
          await _musicPlayer.pause();
          break;
        case PlayerState.paused:
          await _musicPlayer.resume();
          break;
        default:
          // stopped / completed / disposed: the source is released, so
          // resume() does nothing. Start again from the source.
          await _musicPlayer.stop();
          await _musicPlayer.play(_musicSource(path));
      }
    } catch (e) {
      debugPrint('Music toggle error: $e');
      provider.setMusicPlaying(false);
    }
  }

  /// Selects a track in the sheet: same track -> play/pause, new track -> play.
  Future<void> _onMusicTrackTap(
    EditorProvider provider,
    Map<String, String> track,
  ) async {
    final path = track['path'];
    if (path == null || path.isEmpty) {
      Fluttertoast.showToast(msg: 'This track is not available yet');
      return;
    }
    if (provider.selectedMusicPath == path) {
      await _toggleEditorMusic(provider);
    } else {
      await _playMusicPath(provider, path, track['title'] ?? 'Music');
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
      await _musicPlayer.play(_musicSource(path));
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
      await _musicPlayer.play(_musicSource(path));
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
                      // Rebuild when the provider changes (play/pause/select),
                      // otherwise the sheet keeps showing stale icons.
                      child: AnimatedBuilder(
                        animation: provider,
                        builder: (_, __) => ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          itemCount: filtered.length,
                          itemBuilder: (_, index) {
                            final track = filtered[index];
                            // Compare by path (titles repeat in the demo list).
                            final selected =
                                provider.selectedMusicPath != null &&
                                provider.selectedMusicPath == track['path'];
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onMusicTrackTap(provider, track),
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
                                        provider.isEditorMusicPlaying &&
                                                selected
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
                                          : Icons
                                                .check_box_outline_blank_rounded,
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
                    ),
                    AnimatedBuilder(
                      animation: provider,
                      builder: (_, __) => provider.selectedMusicPath != null
                          ? _buildNowPlayingBar(context, provider)
                          : const SizedBox.shrink(),
                    ),
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
                ValueListenableBuilder<Duration>(
                  valueListenable: provider.musicPositionNotifier,
                  builder: (_, position, __) {
                    final duration = provider.musicDuration.inMilliseconds;
                    final progress = duration > 0
                        ? (position.inMilliseconds / duration).clamp(0.0, 1.0)
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      backgroundColor: Colors.white54,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              provider.clearMusic();
              await _musicPlayer.stop();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final fg = dark ? Colors.white : Colors.black87;

    Widget row(IconData icon, String label, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: fg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 15, color: bg),
            ),
            const SizedBox(width: 14),
            AppText(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    Widget divider() => Divider(height: 1, color: fg.withValues(alpha: 0.12));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        void run(VoidCallback fn) {
          Navigator.pop(modalContext);
          fn();
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 6),
                row(
                  Icons.north_east_rounded,
                  'PNG 1x',
                  () => run(() => _downloadProjectExport(context, scale: 1.0)),
                ),
                row(
                  Icons.north_east_rounded,
                  'PNG 2x',
                  () => run(() => _downloadProjectExport(context, scale: 2.0)),
                ),
                divider(),
                row(
                  Icons.movie_creation_outlined,
                  'MP4 · 6s',
                  () => run(() => _exportAnimated(context, gif: false)),
                ),
                row(
                  Icons.gif_box_outlined,
                  'GIF · 6s',
                  () => run(() => _exportAnimated(context, gif: true)),
                ),
                divider(),
                row(
                  Icons.data_object_rounded,
                  'JSON · page data',
                  () => run(() => _exportCurrentPageJson(context)),
                ),
                row(
                  Icons.folder_zip_rounded,
                  provider.selectedMusicPath != null
                      ? 'ZIP · JSON + PNG + Music'
                      : 'ZIP · JSON + PNG',
                  () => run(() => _exportCurrentPageZip(context)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pixel ratio that gives the real design size (e.g. 1080 px wide) times
  /// [scale], independent of how big the canvas is on this phone.
  double _exportPixelRatio(RenderRepaintBoundary boundary, double scale) {
    final provider = context.read<EditorProvider>();
    final logicalWidth = boundary.size.width;
    final designWidth = provider.canvasWidth > 0
        ? provider.canvasWidth
        : 1080.0;
    if (logicalWidth <= 0) return scale;
    return designWidth / logicalWidth * scale;
  }

  /// MP4 / GIF: renders the 6 s timeline frame by frame (item animations and
  /// text effects included), then encodes the frames.
  Future<void> _exportAnimated(
    BuildContext context, {
    required bool gif,
  }) async {
    final provider = context.read<EditorProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    final progress = ValueNotifier<double>(0);
    final label = ValueNotifier<String>('Preparing…');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, value, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: label,
                      builder: (_, text, __) => Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: value == 0 ? null : value,
                      color: const Color(0xFFED1C24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Directory? workDir;
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      if (!await Gal.hasAccess()) {
        messenger.showSnackBar(
          const SnackBar(content: AppText('Gallery permission is required')),
        );
        return;
      }

      final object = _canvasKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) {
        messenger.showSnackBar(
          const SnackBar(content: AppText('Unable to capture design')),
        );
        return;
      }

      // Hide the selection box while frames are captured.
      if (mounted) setState(() => _isCapturingThumbnail = true);
      await WidgetsBinding.instance.endOfFrame;

      final fps = gif ? 12 : 24;
      final frames = kExportDurationMs ~/ 1000 * fps;
      // MP4: full design size. GIF: half size (keeps the file small).
      final pixelRatio = _exportPixelRatio(object, gif ? 0.5 : 1.0);

      final tmp = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      workDir = await Directory('${tmp.path}/mmb_export_$stamp').create();

      final paths = <String>[];
      label.value = 'Rendering frames…';
      for (var i = 0; i < frames; i++) {
        kExportClockMs.value = i * 1000.0 / fps;
        await WidgetsBinding.instance.endOfFrame;

        final boundary =
            _canvasKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) throw Exception('Canvas disappeared');

        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (data == null) throw Exception('Frame capture failed');

        final path = '${workDir.path}/f_${i.toString().padLeft(4, '0')}.png';
        await File(path).writeAsBytes(data.buffer.asUint8List(), flush: true);
        paths.add(path);
        progress.value = (i + 1) / frames * 0.8;
      }
      kExportClockMs.value = null;

      label.value = gif ? 'Creating GIF…' : 'Creating MP4…';
      progress.value = 0.85;

      if (gif) {
        final bytes = await ExportEncoder.encodeGif(paths, fps);
        if (bytes == null) throw Exception('GIF encoding failed');
        final out = File('${tmp.path}/MMB_$stamp.gif');
        await out.writeAsBytes(bytes, flush: true);
        await Gal.putImage(out.path, album: 'MMB');
        await out.delete();
      } else {
        final out = '${tmp.path}/MMB_$stamp.mp4';
        final ok = await ExportEncoder.encodeMp4(
          framesDir: workDir.path,
          fps: fps,
          outPath: out,
          audioPath: provider.selectedMusicPath,
        );
        if (!ok) throw Exception('MP4 encoding failed');
        await Gal.putVideo(out, album: 'MMB');
        await File(out).delete();
      }

      progress.value = 1;
      messenger.showSnackBar(
        SnackBar(
          content: AppText(
            gif ? 'GIF saved to Gallery' : 'MP4 saved to Gallery',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('❌ Animated export error: $e\n$st');
      messenger.showSnackBar(
        SnackBar(content: AppText('Unable to export: $e')),
      );
    } finally {
      kExportClockMs.value = null;
      if (mounted) setState(() => _isCapturingThumbnail = false);
      if (rootNavigator.canPop()) rootNavigator.pop(); // close dialog
      try {
        await workDir?.delete(recursive: true);
      } catch (_) {}
      progress.dispose();
      label.dispose();
    }
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

  Future<void> _downloadProjectExport(
    BuildContext context, {
    double scale = 1.0,
  }) async {
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

      final image = await boundary.toImage(
        pixelRatio: _exportPixelRatio(boundary, scale),
      );

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
  // Transparent padding around the box so the handles (esp. the rotation
  // handle that sits OUTSIDE the box) stay inside the widget's hit-test bounds.
  // Flutter ignores touches that land outside a parent's size.
  static const double _pad = 76.0;

  final GlobalKey _overlayKey = GlobalKey();

  // Move gesture snapshot.
  Offset _startPosition = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  // Rotate gesture snapshot.
  double _startRotation = 0.0;
  Offset _rotationCenterGlobal = Offset.zero;
  double _rotationStartAngle = 0.0;

  // Resize gesture snapshot (taken once on pan start, never re-read from the
  // live item, so the maths does not compound while dragging).
  Offset _gStartGlobal = Offset.zero;
  Offset _gStartPos = Offset.zero;
  double _gStartScale = 1.0;
  double _gStartVisW = 1.0; // un-scaled layout width
  double _gStartVisH = 1.0; // un-scaled layout height
  double _gStartRot = 0.0;

  EditorProvider get _provider => context.read<EditorProvider>();

  bool get _isText => EditableItemWidget.isTextType(widget.item.type);

  bool get _isMultilineText =>
      _isText && EditableItemWidget.isMultilineText(widget.item);

  // Text uses the very same measurement as the rendered text widget, so the
  // box, the rotation pivot and the drawn glyphs can never disagree.
  Size get _textBox =>
      EditableItemWidget.measureTextBox(widget.item, _provider);

  double get _baseVisualWidth => _isText ? _textBox.width : widget.item.width;

  double get _baseVisualHeight =>
      _isText ? _textBox.height : widget.item.height;

  // Same clamp EditableItemWidget applies when drawing.
  double get _itemScale => widget.item.scale.isFinite
      ? widget.item.scale.clamp(0.01, 10.0).toDouble()
      : 1.0;

  double get _rotation =>
      widget.item.rotation.isFinite ? widget.item.rotation : 0.0;

  double get _unitY => widget.isBackground ? widget.scaleY : widget.scaleX;

  double get _left => widget.item.position.dx * widget.scaleX;

  double get _top => widget.item.position.dy * widget.scaleY;

  // On-screen box size in logical pixels.
  double get _boxWidth => _baseVisualWidth * _itemScale * widget.scaleX;

  double get _boxHeight => _baseVisualHeight * _itemScale * _unitY;

  Offset _rot(Offset v, double a) {
    final c = math.cos(a), s = math.sin(a);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  /// Returns the new un-rotated top-left position that keeps the point [a0]
  /// of the old box (local coords, canvas units) at the same place on the
  /// canvas after the box becomes [s1] with that point now at [a1].
  /// Items rotate about their CENTER, so a plain "move top-left by delta"
  /// only works at 0 degrees; this works for every angle.
  Offset _placeTopLeft({
    required Offset p0,
    required Size s0,
    required Offset a0,
    required Size s1,
    required Offset a1,
    required double rot,
  }) {
    final c0 = Offset(s0.width / 2, s0.height / 2);
    final c1 = Offset(s1.width / 2, s1.height / 2);
    final anchorWorld = p0 + c0 + _rot(a0 - c0, rot);
    final newCenter = anchorWorld - _rot(a1 - c1, rot);
    return newCenter - c1;
  }

  double _selectionBorderRadius(Size size) {
    if (size.width <= 0 || size.height <= 0) return 0;
    final maxRadius = size.height / 2.0;
    final proportionalRadius = size.height * 0.28;
    return math.min(10.0, math.min(maxRadius, proportionalRadius));
  }

  MouseCursor _cursorFor(Alignment a) {
    if (a.x == 0) return SystemMouseCursors.resizeUpDown;
    if (a.y == 0) return SystemMouseCursors.resizeLeftRight;
    return a.x == a.y
        ? SystemMouseCursors.resizeUpLeftDownRight
        : SystemMouseCursors.resizeUpRightDownLeft;
  }

  @override
  Widget build(BuildContext context) {
    final width = _boxWidth;
    final height = _boxHeight;

    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return const SizedBox.shrink();
    }

    // Canva-style corner buttons: delete (TL), edit (TR, text only),
    // rotate (BL) and resize (BR). They sit on the corners; when the box is
    // tiny they slide outward just enough so they never overlap each other
    // or hide the content.
    const btnGap = 40.0; // min distance between two button centres
    final dx = math.max(0.0, (btnGap - width) / 2);
    final dy = math.max(0.0, (btnGap - height) / 2);
    final tl = Offset(-dx, -dy);
    final tr = Offset(width + dx, -dy);
    final bl = Offset(-dx, height + dy);
    final br = Offset(width + dx, height + dy);

    // Edge handles (circles on left/right, bars on top/bottom) live BETWEEN
    // the corner buttons; touch zone reaches outside the box, only a few px in.
    const outer = 26.0;
    final innerX = math.min(8.0, width * 0.2);
    final innerY = math.min(8.0, height * 0.2);
    final insetX = math.max(0.0, 22.0 - dx);
    final insetY = math.max(0.0, 22.0 - dy);
    final sideLenV = height - insetY * 2;
    final sideLenH = width - insetX * 2;
    final itemId = widget.item.id ?? '';

    return Positioned(
      left: _left - _pad,
      top: _top - _pad,
      width: width + _pad * 2,
      height: height + _pad * 2,
      child: Transform.rotate(
        angle: _rotation,
        // Padding is symmetric, so the pivot stays the box's exact center.
        alignment: Alignment.center,
        child: Stack(
          key: _overlayKey,
          clipBehavior: Clip.none,
          children: [
            // Drag-move from anywhere inside the box.
            Positioned(
              left: _pad,
              top: _pad,
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
                  _provider.updateItemTransform(
                    widget.item.id ?? '',
                    position: Offset(
                      _startPosition.dx + dx,
                      _startPosition.dy + dy,
                    ),
                    clampToFrame: false,
                  );
                },
                onPanEnd: (_) => _provider.commitTransform(),
                onPanCancel: () => _provider.commitTransform(),
              ),
            ),

            // Selection outline.
            Positioned(
              left: _pad,
              top: _pad,
              width: width,
              height: height,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ImageSelectionPainter(
                    style: _provider.outlineStyle(widget.item.id ?? ''),
                    outlineWidth: widget.item.outlineWidth,
                    outlineColor:
                        widget.item.outlineColor ?? const Color(0xFFD9D9D9),
                    borderRadius: _selectionBorderRadius(Size(width, height)),
                  ),
                ),
              ),
            ),

            if (sideLenV >= 14) ...[
              _handle(
                alignment: Alignment.centerLeft,
                box: Size(width, height),
                hit: Rect.fromLTRB(-outer, insetY, innerX, height - insetY),
              ),
              _handle(
                alignment: Alignment.centerRight,
                box: Size(width, height),
                hit: Rect.fromLTRB(
                  width - innerX,
                  insetY,
                  width + outer,
                  height - insetY,
                ),
              ),
            ],
            if (!_isText && sideLenH >= 14) ...[
              _handle(
                alignment: Alignment.topCenter,
                box: Size(width, height),
                hit: Rect.fromLTRB(insetX, -outer, width - insetX, innerY),
              ),
              _handle(
                alignment: Alignment.bottomCenter,
                box: Size(width, height),
                hit: Rect.fromLTRB(
                  insetX,
                  height - innerY,
                  width - insetX,
                  height + outer,
                ),
              ),
            ],

            // Delete (top-left).
            _actionButton(
              center: tl,
              icon: Icons.close_rounded,
              background: const Color(0xFFE5533D),
              foreground: Colors.white,
              onTap: () => _provider.removeItem(itemId),
            ),

            // Edit text (top-right, text items only).
            if (_isText)
              _actionButton(
                center: tr,
                icon: Icons.edit_rounded,
                background: Colors.white,
                foreground: Colors.black87,
                onTap: () => EditableItemWidget.showTextEditor(
                  context,
                  _provider,
                  itemId,
                  widget.item.text ?? '',
                ),
              ),

            // Rotate (bottom-left).
            _actionButton(
              center: bl,
              icon: Icons.rotate_right_rounded,
              background: Colors.white,
              foreground: Colors.black87,
              onPanStart: (details) {
                _startRotation = _rotation;
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
                _provider.updateItemTransform(
                  itemId,
                  rotation:
                      _startRotation +
                      _normalizeAngle(currentAngle - _rotationStartAngle),
                );
              },
            ),

            // Resize (bottom-right): drag along the diagonal to scale.
            _actionButton(
              center: br,
              icon: Icons.open_in_full_rounded,
              flipIcon: true,
              background: Colors.white,
              foreground: Colors.black87,
              onPanStart: _onResizeStart,
              onPanUpdate: (d) => _onResizeUpdate(Alignment.bottomRight, d),
            ),
          ],
        ),
      ),
    );
  }

  /// Round Canva-style button centred on [center] (box coordinates).
  /// Icons are counter-rotated so they stay upright on a rotated item.
  Widget _actionButton({
    required Offset center,
    required IconData icon,
    required Color background,
    required Color foreground,
    bool flipIcon = false,
    VoidCallback? onTap,
    GestureDragStartCallback? onPanStart,
    GestureDragUpdateCallback? onPanUpdate,
  }) {
    const hit = 44.0;
    const size = 32.0;
    Widget glyph = Icon(icon, size: 18, color: foreground);
    if (flipIcon) glyph = Transform.flip(flipX: true, child: glyph);
    return Positioned(
      left: _pad + center.dx - hit / 2,
      top: _pad + center.dy - hit / 2,
      width: hit,
      height: hit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanStart == null
            ? null
            : (_) => _provider.commitTransform(),
        onPanCancel: onPanStart == null
            ? null
            : () => _provider.commitTransform(),
        child: Center(
          child: Transform.rotate(
            angle: -_rotation,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(child: glyph),
            ),
          ),
        ),
      ),
    );
  }

  Offset _globalCenter() {
    final box = _overlayKey.currentContext?.findRenderObject();
    if (box is RenderBox) {
      return box.localToGlobal(
        Offset(_pad + _boxWidth / 2, _pad + _boxHeight / 2),
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

  /// [hit] is the touch zone in box coordinates (may extend outside the box).
  /// The visible knob is always drawn exactly on the corner / edge middle.
  Widget _handle({
    required Alignment alignment,
    required Size box,
    required Rect hit,
  }) {
    final px = (alignment.x + 1) / 2 * box.width - hit.left;
    final py = (alignment.y + 1) / 2 * box.height - hit.top;
    return Positioned(
      left: _pad + hit.left,
      top: _pad + hit.top,
      width: hit.width,
      height: hit.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onResizeStart,
        onPanUpdate: (d) => _onResizeUpdate(alignment, d),
        onPanEnd: (_) => _provider.commitTransform(),
        onPanCancel: () => _provider.commitTransform(),
        child: MouseRegion(
          cursor: _cursorFor(alignment),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: px,
                top: py,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _ResizeHandleVisual(alignment: alignment),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onResizeStart(DragStartDetails d) {
    _gStartGlobal = d.globalPosition;
    _gStartPos = widget.item.position;
    _gStartScale = _itemScale;
    _gStartVisW = _baseVisualWidth;
    _gStartVisH = _baseVisualHeight;
    _gStartRot = _rotation;
  }

  void _onResizeUpdate(Alignment al, DragUpdateDetails d) {
    final item = widget.item;
    final id = item.id ?? '';

    // Finger movement in canvas units, then in the item's own (rotated) axes.
    final g = d.globalPosition - _gStartGlobal;
    final canvasDelta = Offset(g.dx / widget.scaleX, g.dy / _unitY);
    final local = _rot(canvasDelta, -_gStartRot);

    // Box size at gesture start, in canvas units.
    final w0 = _gStartVisW * _gStartScale;
    final h0 = _gStartVisH * _gStartScale;
    final s0 = Size(w0, h0);
    final hx = al.x, hy = al.y;

    // Side handles stretch (images/shapes; multi-line text wraps). Everything
    // else - corners, and sides of single-line text - scales uniformly.
    final stretchX = hy == 0 && (!_isText || _isMultilineText);
    final stretchY = hx == 0 && !_isText;

    if (stretchX) {
      final newItemW = ((w0 + hx * local.dx) / _gStartScale)
          .clamp(12.0, 4000.0)
          .toDouble();
      Size s1;
      if (_isText) {
        final box = EditableItemWidget.measureTextBox(
          item,
          _provider,
          widthOverride: newItemW,
        );
        s1 = Size(box.width * _gStartScale, box.height * _gStartScale);
      } else {
        s1 = Size(newItemW * _gStartScale, h0);
      }
      // Opposite edge (top corner of it) stays pinned.
      final a0 = Offset(hx == 1 ? 0.0 : w0, 0);
      final a1 = Offset(hx == 1 ? 0.0 : s1.width, 0);
      _provider.updateItemTransform(
        id,
        width: newItemW,
        position: _placeTopLeft(
          p0: _gStartPos,
          s0: s0,
          a0: a0,
          s1: s1,
          a1: a1,
          rot: _gStartRot,
        ),
        clampToFrame: false,
      );
      return;
    }

    if (stretchY) {
      final newItemH = ((h0 + hy * local.dy) / _gStartScale)
          .clamp(12.0, 4000.0)
          .toDouble();
      final s1 = Size(w0, newItemH * _gStartScale);
      final a0 = Offset(0, hy == 1 ? 0.0 : h0);
      final a1 = Offset(0, hy == 1 ? 0.0 : s1.height);
      _provider.updateItemTransform(
        id,
        height: newItemH,
        position: _placeTopLeft(
          p0: _gStartPos,
          s0: s0,
          a0: a0,
          s1: s1,
          a1: a1,
          rot: _gStartRot,
        ),
        clampToFrame: false,
      );
      return;
    }

    // Uniform scale. Corners follow the finger's projection onto the diagonal
    // (smooth, no axis flip-flopping); sides use their own axis.
    double k;
    if (hx != 0 && hy != 0) {
      final dx = hx * w0, dy = hy * h0;
      k = 1 + (local.dx * dx + local.dy * dy) / (dx * dx + dy * dy);
    } else if (hx != 0) {
      k = 1 + hx * local.dx / w0;
    } else {
      k = 1 + hy * local.dy / h0;
    }
    final newScale = (_gStartScale * k).clamp(0.02, 10.0).toDouble();
    k = newScale / _gStartScale;

    // Pin the opposite corner / edge-middle.
    final a0 = Offset(
      hx == 1 ? 0.0 : (hx == -1 ? w0 : w0 / 2),
      hy == 1 ? 0.0 : (hy == -1 ? h0 : h0 / 2),
    );
    _provider.updateItemTransform(
      id,
      scale: newScale,
      position: _placeTopLeft(
        p0: _gStartPos,
        s0: s0,
        a0: a0,
        s1: Size(w0 * k, h0 * k),
        a1: a0 * k,
        rot: _gStartRot,
      ),
      clampToFrame: false,
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
      // Left / right: round white knob like the reference editor.
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
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

class _RemoveBackgroundSlideSheet extends StatefulWidget {
  const _RemoveBackgroundSlideSheet({
    required this.isDark,
    required this.onSlideComplete,
  });

  final bool isDark;
  final VoidCallback onSlideComplete;

  @override
  State<_RemoveBackgroundSlideSheet> createState() =>
      _RemoveBackgroundSlideSheetState();
}

class _RemoveBackgroundSlideSheetState
    extends State<_RemoveBackgroundSlideSheet> {
  double _progress = 0;
  bool _completed = false;

  void _updateDrag(DragUpdateDetails details, double width) {
    if (_completed || width <= 0) return;
    setState(() {
      _progress = (_progress + details.delta.dx / width).clamp(0.0, 1.0);
    });
  }

  void _finishDrag() {
    if (_progress >= 0.92 && !_completed) {
      setState(() {
        _progress = 1;
        _completed = true;
      });
      // The action is invoked only after the slider reaches the end.
      widget.onSlideComplete();
      Navigator.of(context).pop();
    } else {
      setState(() => _progress = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final foreground = dark ? Colors.white : const Color(0xFF171717);
    final trackColor = dark ? const Color(0xFF353535) : Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 124,
              height: 6,
              decoration: BoxDecoration(
                color: dark ? Colors.white30 : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppText(
                    'Remove Background',
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize18,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE5E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 25),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _updateDrag(details, width),
                  onHorizontalDragEnd: (_) => _finishDrag(),
                  onTapDown: (details) {
                    if (details.localPosition.dx > width * 0.75) {
                      setState(() => _progress = 1);
                      _finishDrag();
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: trackColor,
                      border: Border.all(
                        color: const Color(0xFFFF202A),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: AppText(
                            _completed
                                ? 'Removing Background...'
                                : 'Slide to remove Background',
                            style: TextStyle(
                              color: foreground.withValues(alpha: .75),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.clamp(0.0, 1.0),
                            heightFactor: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x22FF202A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(_progress * 2 - 1, 0),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF202A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                "assets/images/slide.png",
                                width: 15,
                                height: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Image.asset(
                  "assets/images/magicpen.png",
                  height: 15,
                  width: 15,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppText(
                    '20 AI Credits Available',
                    style: TextStyle(
                      color: foreground,
                      fontSize: AppFontSize.fontSize14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                AppText(
                  '2 credits will be used',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoFingerScaleRecognizer extends ScaleGestureRecognizer {
  _TwoFingerScaleRecognizer({super.debugOwner});

  final Set<int> _down = <int>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _down.add(event.pointer);
    if (_down.length >= 2) resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _down.remove(event.pointer);
    }
    if (_down.length < 2 && event is PointerMoveEvent) return;
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _down.remove(pointer);
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _down.clear();
    super.didStopTrackingLastPointer(pointer);
  }
}
