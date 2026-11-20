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
import '../../network/provider/plan_provider.dart';
import '../industry/widgets/animation.dart';
import '../industry/widgets/editable.dart';
import '../../network/provider/custom_theme_provider.dart';
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
  String _shapeTab = 'style';
  // Image whose OUTLINE editor (shape-style inline panel) is open.
  String? _imageOutlineItemId;
  bool _showImageFilters = false;

  /// When equal to the selected item id, the ANIMATE panel is docked at the bottom.
  String? _animatePanelItemId;

  /// 0 = Effects (text only), 1 = Animate.
  int _animatePanelTab = 1;
  // Compact docked panel so the canvas stays big while an animation plays.
  bool _animatePanelCollapsed = false;

  // GROUP animation (multi-select) settings.
  ItemAnimationType _grpType = ItemAnimationType.none;
  ItemAnimationMode _grpMode = ItemAnimationMode.entrance;
  ItemAnimDirection _grpDir = ItemAnimation.empty.direction;
  ItemAnimAxis _grpAxis = ItemAnimation.empty.axis;
  double _grpDelay = 0.0;
  double _grpStagger = 0.2;
  bool _grpCollapsed = false;
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
        final bg = bgItems.first;
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

  // Canvas-level tap picking: a tap anywhere inside an item's box selects it,
  // even when the item's own gesture detector misses (clips, rings, overlaps).
  Offset? _tapDownPos;
  int _tapDownMs = 0;
  bool _tapSelectedByCanvas = false;
  Offset? _lastTapCanvasPos;

  String? _pickItemAt(EditorProvider provider, Offset canvasPoint) {
    // Shared geometry: is the point inside the item's (rotated) box?
    bool inBox(EditorItem it, double pad) {
      final t = (it.type ?? '').trim().toLowerCase();
      final isText =
          t == 'text' || t == 'textbox' || t == 'i-text' || t == 'itext';
      final sc = it.scale.isFinite && it.scale.abs() > 0
          ? it.scale.clamp(0.01, 10.0).toDouble()
          : 1.0;
      final Size body = isText
          ? EditableItemWidget.measureTextBox(it, provider)
          : Size(math.max(1.0, it.width), math.max(1.0, it.height));
      var local = (canvasPoint - it.position) / sc;
      final centre = Offset(body.width / 2, body.height / 2);
      final rel = local - centre;
      final a = -(it.rotation.isFinite ? it.rotation : 0.0);
      final rx = rel.dx * math.cos(a) - rel.dy * math.sin(a);
      final ry = rel.dx * math.sin(a) + rel.dy * math.cos(a);
      local = Offset(rx, ry) + centre;
      return Rect.fromLTWH(
        0,
        0,
        body.width,
        body.height,
      ).inflate(pad / sc).contains(local);
    }

    // Pass 1: topmost item whose VISIBLE pixel is under the finger
    // (transparent parts of an image never steal the tap).
    for (final it in provider.items.reversed) {
      if (it.id == null || _isCanvasBackground(it)) continue;
      if (!inBox(it, 0)) continue;
      if (EditableItemWidget.isVisibleAt(
        it,
        provider,
        canvasPoint - it.position,
      )) {
        return it.id;
      }
    }

    // Pass 2 (nothing visible there, e.g. hole of a ring / thin stroke):
    // fall back to the smallest box around the point, with touch slack.
    EditorItem? best;
    double bestArea = double.infinity;
    for (final it in provider.items.reversed) {
      if (it.id == null || _isCanvasBackground(it)) continue;
      if (!inBox(it, 6.0)) continue;
      final sc = it.scale.isFinite && it.scale.abs() > 0
          ? it.scale.clamp(0.01, 10.0).toDouble()
          : 1.0;
      final area = it.width * it.height * sc * sc;
      if (area < bestArea) {
        bestArea = area;
        best = it;
      }
    }
    return best?.id;
  }

  Timer? _projectSaveTimer;
  // Cached so dispose() can do the final save without touching `context`.
  EditorProvider? _editorRef;
  ProjectProvider? _projectRef;
  bool _projectSaveListenerAttached = false;
  bool _projectAutoSaveReady = false;
  bool _projectSaveRunning = false;
  bool _projectSaveQueued = false;
  String _projectSaveStatus = '';
  String? _lastQueuedContent;
  int _lastPageCount = 1;

  // Small preview of every page, keyed by the page's stable id. A page's
  // preview is refreshed whenever the Pages sheet opens while it is open.
  final Map<String, Uint8List> _pageThumbs = {};

  Future<void> _captureCurrentPageThumb(EditorProvider provider) async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;
      final w = boundary.size.width;
      if (w <= 0) return;
      final image = await boundary.toImage(pixelRatio: 160 / w);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data != null) {
          _pageThumbs[provider.pageIdAt(provider.currentPageIndex)] = data
              .buffer
              .asUint8List();
        }
      } finally {
        image.dispose();
      }
    } catch (_) {}
  }

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

    // A page was added / deleted -> call PATCH project/{id} right away
    // instead of waiting for the normal 500 ms debounce.
    final pageCountChanged = editorProvider.pageCount != _lastPageCount;
    _lastPageCount = editorProvider.pageCount;
    if (pageCountChanged) {
      _saveProjectNow();
      return;
    }

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

      final image = await boundary.toImage(pixelRatio: 1.0 / _canvasZoom);

      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) return null;

        final bytes = byteData.buffer.asUint8List();

        return 'data:image/png;base64,${base64Encode(bytes)}';
      } finally {
        image.dispose();
      }
    } catch (e, stackTrace) {
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

  Future<void> _saveProjectNow({bool force = false}) async {
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

    var forceThis = force;
    try {
      do {
        _projectSaveQueued = false;

        // Export the latest canvas content without truncating text.
        final content = jsonEncode(editorProvider.exportCurrentPageJson());

        // `force` = a page was deleted / duplicated from the Pages sheet:
        // always call PATCH project/{id}, even when the open page's JSON
        // did not change.
        if (!forceThis && content == _lastSavedProjectContent) {
          continue;
        }
        forceThis = false;
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
        // Phone back button behaves exactly like "Go Back": close the dialog
        // AND leave the editor (no editing allowed once the limit is hit).
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Navigator.of(dialogContext).pop();
            if (mounted) Navigator.of(context).maybePop();
          },
          child: AlertDialog(
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
                onPressed: () async {
                  // Do NOT pop the dialog: the plan screen opens on top of it,
                  // so coming back lands on the same dialog.
                  final planProvider = PlanProvider();
                  final bool hasActivePlan = await planProvider
                      .fetchMySubscription();

                  if (!dialogContext.mounted) return;

                  if (hasActivePlan) {
                    await Navigator.pushNamed(
                      dialogContext,
                      "/MySubscriptionScreen",
                    );
                  } else {
                    await Navigator.pushNamed(
                      dialogContext,
                      "/FreePlanScreen",
                      arguments: {"showSkip": true},
                    );
                  }
                },
                child: const AppText('Buy Plan'),
              ),
            ],
          ),
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
    _editorRef = editorProvider;
    _projectRef = context.read<ProjectProvider>();
    final initialContent = jsonEncode(editorProvider.exportCurrentPageJson());
    _lastQueuedContent = initialContent;
    _lastSavedProjectContent = initialContent;
    _lastPageCount = editorProvider.pageCount;

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
    try {
      await _loadTemplateJsonAndInitEditorImpl();
    } finally {
      // Whatever happened (success, error, early return) the init phase is
      // over. Blank designs never started preloading, so start it now.
      _initDone = true;
      if (mounted) {
        setState(() {});
        unawaited(_preloadCanvasAssets());
      }
    }
  }

  Future<void> _loadTemplateJsonAndInitEditorImpl() async {
    final editorProvider = Provider.of<EditorProvider>(context, listen: false);

    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );

    final hasExplicitResize = widget.resizeSize.trim().isNotEmpty;
    final resizeCanvas = hasExplicitResize ? _getCanvasSize() : null;
    final uid = widget.templateUid?.trim() ?? '';

    // EXISTING PROJECT (Download screen -> Edit)
    final openProjectUid = widget.projectUid?.trim() ?? '';
    if (openProjectUid.isNotEmpty) {
      await _openExistingProject(
        editorProvider,
        projectProvider,
        openProjectUid,
      );
      return;
    }

    // TEMPLATE DESIGN
    if (uid.isNotEmpty) {
      final templateSuccess = await editorProvider.loadTemplateByUid(
        uid,
        canvasWidth: resizeCanvas?.width,
        canvasHeight: resizeCanvas?.height,
      );

      if (!mounted) return;

      if (!templateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(
              editorProvider.templateDetailError ?? 'Unable to load template',
            ),
          ),
        );
        return;
      }

      // Template items are imported now: start downloading every image in
      // parallel with the project-create call below.
      unawaited(_preloadCanvasAssets());

      final detail = editorProvider.templateDetail;

      if (detail == null || detail.data.items.isEmpty) {
        return;
      }

      // Template API response
      final data = detail.data.items.first;

      // The API's template id is an integer (for example 32). Keep it as a
      // string in ProjectProvider because the update repository accepts a
      // nullable string templateId. Do not use uid/familyUid here.
      final int? templateId = int.tryParse(data.id ?? '');
      final int? templateUId = int.tryParse(data.familyId ?? '');
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

      final projectSuccess = await projectProvider.createProject(
        name: templateName,
        content: templateContent,
        id: templateUId,
      );

      if (!mounted) return;

      if (!projectSuccess) {
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
    } else {
      // CREATE NEW / BLANK DESIGN
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

      final projectSuccess = await projectProvider.createProject(
        name: projectName,
        content: blankContent,
        id: null, // Blank projects must not send template_id: 0.
      );

      if (!mounted) return;

      if (!projectSuccess) {
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
    unawaited(_preloadCanvasAssets());
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
          return false;
        },
      );

      if (!mounted) return;
      setState(() => _projectSaveStatus = success ? 'Saved' : 'Save failed');
    } catch (e, st) {
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
          provider.addShape(file.path, isLocal: true);
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
        provider.addShape(file.path, isLocal: true);

        if (context.mounted) Navigator.pop(context);
      } finally {
        client.close(force: true);
      }
    } catch (e) {
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

      provider.addShape(file.path, isLocal: true);

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
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1B1B);
    final mutedColor = isDark ? Colors.white54 : const Color(0xFF9A9A9A);
    final cardBorder = isDark ? Colors.white24 : const Color(0xFFE2E2E2);
    const accent = Color(0xFFFF252D);

    // Frames come from the same API as the business profile screen.
    // Opening the sheet always starts on "Static Frames".
    provider.updateFrameTab(0);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        // The sheet is a separate route: hand the editor provider down to it.
        return ChangeNotifierProvider<EditorProvider>.value(
          value: provider,
          child: Consumer<EditorProvider>(
            builder: (sheetContext, p, _) {
              final selectedTab = p.selectedFrameTab;
              final frames = p.selectedFrames;
              final applied = p.selectedFrameUrl;

              // "No frame" tile (only while a frame is applied).
              Widget noneCard() {
                return SizedBox(
                  width: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            p.clearSelectedFrame();
                            Navigator.pop(modalContext);
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFF6F6F6),
                              border: Border.all(color: cardBorder),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              size: 24,
                              color: mutedColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      AppText(
                        'None',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              Widget frameCard(dynamic frame) {
                final key = (frame.thumbnailS3Key ?? '').toString().trim();
                final imageUrl = key.isEmpty
                    ? ''
                    : '${ApiEndpoints.cdnImageUrl}/$key';
                final priceRaw = (frame.price ?? '').toString().trim();
                final isFree =
                    priceRaw.isEmpty ||
                        priceRaw == '0' ||
                        priceRaw == '0.0' ||
                        priceRaw == '0.00';
                final isApplied = imageUrl.isNotEmpty && applied == imageUrl;

                return SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: imageUrl.isEmpty
                              ? null
                              : () {
                            p.setSelectedFrame(imageUrl);
                            Navigator.pop(modalContext);
                            if (p.selectedItemType != 'image') {
                              Fluttertoast.showToast(
                                msg: 'Select an image to see the frame',
                              );
                            }
                          },
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2C2C2C)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isApplied ? accent : cardBorder,
                                      width: isApplied ? 1.8 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: imageUrl.isEmpty
                                        ? const Center(
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                        color: Colors.grey,
                                      ),
                                    )
                                        : Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (_, child, progress) {
                                        if (progress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: accent,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) =>
                                      const Center(
                                        child: Icon(
                                          Icons
                                              .image_not_supported_rounded,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isApplied)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      AppText(
                        isFree ? 'Free' : 'RS. $priceRaw',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isFree ? const Color(0xFF2E9E5B) : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              Widget framesBody() {
                if (p.isFramesLoading && frames.isEmpty) {
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    ),
                  );
                }

                if (frames.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          p.framesError ??
                              (selectedTab == 0
                                  ? 'No static frames available'
                                  : 'No animated frames available'),
                          style: TextStyle(color: mutedColor, fontSize: 12.5),
                        ),
                        if (p.framesError != null)
                          TextButton(
                            onPressed: () => p.loadFrames(
                              selectedTab == 0 ? 'static' : 'animated',
                            ),
                            child: const AppText('Retry'),
                          ),
                      ],
                    ),
                  );
                }

                final showNone = applied != null;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: frames.length + (showNone ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    if (showNone && index == 0) return noneCard();
                    return frameCard(frames[index - (showNone ? 1 : 0)]);
                  },
                );
              }

              // Height follows the content, so the sheet stays compact.
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
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
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFD6D6D6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            AppText(
                              'My Frames',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            _frameHeaderButton(
                              icon: Icons.edit_outlined,
                              onTap: () {
                                // Add your existing frame edit action here.
                              },
                            ),
                            const SizedBox(width: 8),
                            _frameHeaderButton(
                              icon: Icons.add_rounded,
                              onTap: () {
                                // Add your existing create-frame action here.
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tabs
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          children: [
                            _frameTab(
                              title: 'Static',
                              selected: selectedTab == 0,
                              onTap: () => p.updateFrameTab(0),
                              textColor: textColor,
                              mutedColor: mutedColor,
                            ),
                            const SizedBox(width: 22),
                            _frameTab(
                              title: 'Animated',
                              selected: selectedTab == 1,
                              onTap: () => p.updateFrameTab(1),
                              textColor: textColor,
                              mutedColor: mutedColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Frame cards (from the API)
                      SizedBox(height: 132, child: framesBody()),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFFF252D), size: 18),
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // Underline is exactly as wide as the label.
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? textColor : mutedColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF252D) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
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
    // Chips + templates all come from the API through EditorProvider.
    provider.fetchEditorTemplateCategories();
    final chipScroll = ScrollController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        // The sheet is a separate route: hand the editor provider down to it.
        return ChangeNotifierProvider<EditorProvider>.value(
          value: provider,
          child: Consumer<EditorProvider>(
            builder: (sheetContext, p, _) {
              final chips = p.editorTemplateChips;
              final selectedIndex = chips.isEmpty
                  ? 0
                  : p.selectedEditorTemplateCategoryIndex
                  .clamp(0, chips.length - 1)
                  .toInt();
              final templates = p.editorSelectedCategoryTemplates;
              final loadingTemplates = p.isEditorSelectedCategoryLoading;
              final fg = isDark ? Colors.white : Colors.black;
              final borderColor = isDark
                  ? Colors.white24
                  : const Color(0xFFD9D9D9);
              final mutedColor = isDark ? Colors.white60 : Colors.black54;

              Widget chip(int index) {
                final selected = index == selectedIndex;
                return GestureDetector(
                  onTap: () => p.selectEditorTemplateCategory(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark
                          ? const Color(0xFF4A2024)
                          : const Color(0xFFFFE3E3))
                          : (isDark ? const Color(0xFF24262B) : Colors.white),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? Colors.redAccent : borderColor,
                      ),
                    ),
                    child: AppText(
                      chips[index].name,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.redAccent
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              }

              // ‹ › buttons that scroll the chip row.
              Widget arrow(IconData icon, double delta) {
                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    if (!chipScroll.hasClients) return;
                    final target = (chipScroll.offset + delta)
                        .clamp(0.0, chipScroll.position.maxScrollExtent)
                        .toDouble();
                    chipScroll.animateTo(
                      target,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF24262B) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(icon, size: 20, color: fg),
                  ),
                );
              }

              Widget templateCard(dynamic template) {
                final uid = _templateStringValue(template, const [
                  'uid',
                  'templateUid',
                  'template_uid',
                ]);
                final imageKey = _templateStringValue(template, const [
                  'thumbnailS3Key',
                  'thumbnail_s3_key',
                  'previewS3Key',
                  'preview_s3_key',
                  's3Key',
                  's3_key',
                  'thumbnail',
                  'image',
                  'preview',
                ]);
                final imageUrl = _templateImageUrl(imageKey);

                return GestureDetector(
                  onTap: uid.isEmpty
                      ? null
                      : () async {
                    Navigator.pop(modalContext);
                    await provider.loadTemplateByUid(uid);
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF25272D)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
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
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                );
              }

              Widget body() {
                if (chips.isEmpty) {
                  if (p.isLoadingEditorTemplateCategories) {
                    return Center(child: _templatesLoadingLabel(mutedColor));
                  }
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          p.editorTemplateCategoryError ??
                              'No categories found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              p.fetchEditorTemplateCategories(force: true),
                          child: const AppText('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Request running and nothing to show yet.
                if (loadingTemplates && templates.isEmpty) {
                  return Center(child: _templatesLoadingLabel(mutedColor));
                }

                // Request finished, category has no templates.
                if (templates.isEmpty) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: CustomPaint(
                      painter: _DashedRRectPainter(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFD0D0D0),
                        radius: 14,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2026)
                              : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AppText(
                          'No templates in this category yet',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .8,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (_, index) => templateCard(templates[index]),
                );
              }

              return Container(
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
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      'Choose a template to replace the current design',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                    const SizedBox(height: 12),
                    if (chips.isNotEmpty)
                      Row(
                        children: [
                          arrow(Icons.chevron_left_rounded, -180),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ListView.builder(
                                controller: chipScroll,
                                scrollDirection: Axis.horizontal,
                                itemCount: chips.length,
                                itemBuilder: (_, index) => chip(index),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          arrow(Icons.chevron_right_rounded, 180),
                        ],
                      ),
                    if (chips.isNotEmpty) const SizedBox(height: 12),
                    Expanded(child: body()),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(chipScroll.dispose);
  }

  Widget _templatesLoadingLabel(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        const SizedBox(width: 8),
        AppText(
          'Loading...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
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
    // 0 uploads, 1 elements, 2 images, 3 videos
    int selectedTab = elementsOnly ? 1 : 0;
    String? expandedCategory;
    bool sheetOpen = true;
    bool elementsInitialLoadScheduled = false;
    bool uploadsInitialLoadScheduled = false;
    bool imagesInitialLoadScheduled = false;
    bool videosInitialLoadScheduled = false;
    // Default Media > Videos feed: /api/pexels/videos?term=travel+destination
    const defaultVideoQuery = 'travel destination';
    final searchController = TextEditingController();
    final videoSearchController = TextEditingController();

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

            // Initial Videos request, also after the current frame.
            if (selectedTab == 3 && !videosInitialLoadScheduled) {
              videosInitialLoadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!sheetOpen || !sheetContext.mounted) return;
                if (provider.mediaVideoAssets.isEmpty &&
                    !provider.isMediaVideosLoading) {
                  provider.fetchMediaVideos(defaultVideoQuery).then((_) {
                    if (sheetOpen && sheetContext.mounted) {
                      setSheetState(() {});
                    }
                  });
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
                          fontWeight: FontWeight.w600,
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
                              fontWeight: FontWeight.w600,
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

            Widget videosView() {
              final videos = provider.mediaVideoAssets;

              void search(String q) {
                final value = q.trim().isEmpty ? defaultVideoQuery : q.trim();
                provider.fetchMediaVideos(value).then((_) {
                  if (sheetOpen && sheetContext.mounted) setSheetState(() {});
                });
                setSheetState(() {});
              }

              Widget videoChip(String title, String query) {
                final selected = provider.mediaVideosQuery == query;
                return GestureDetector(
                  onTap: () {
                    videoSearchController.text = query;
                    search(query);
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

              Future<void> addToCanvas(PexelsVideoAsset asset) async {
                final canvasW = provider.canvasWidth > 0
                    ? provider.canvasWidth
                    : 1080.0;
                final canvasH = provider.canvasHeight > 0
                    ? provider.canvasHeight
                    : 1080.0;
                var sw = asset.width;
                var sh = asset.height;
                if (sw <= 0 || sh <= 0) {
                  final size = await _resolveNetworkVideoSize(asset.videoUrl);
                  sw = size?.width ?? 16;
                  sh = size?.height ?? 9;
                }
                // Fit inside 80% of the page, keeping the video's own ratio.
                final fit = math.min(canvasW * 0.8 / sw, canvasH * 0.8 / sh);
                provider.addVideo(
                  asset.videoUrl,
                  width: sw * fit,
                  height: sh * fit,
                );
                if (Navigator.canPop(modalContext)) Navigator.pop(modalContext);
              }

              Widget videoCard(PexelsVideoAsset asset, double ratio) {
                return GestureDetector(
                  onTap: () => addToCanvas(asset),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: isDark
                                ? const Color(0xFF24262B)
                                : const Color(0xFFEDEDED),
                          ),
                          if (asset.thumbnailUrl != null)
                            Image.network(
                              asset.thumbnailUrl!,
                              cacheWidth: 600,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                            ),
                          if (asset.durationLabel.isNotEmpty)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AppText(
                                  asset.durationLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Two-column masonry: each card keeps its own video ratio and
              // goes to whichever column is currently shorter.
              Widget masonry() {
                final left = <Widget>[];
                final right = <Widget>[];
                var leftH = 0.0, rightH = 0.0;
                for (final asset in videos) {
                  final ratio =
                  (asset.aspectRatio > 0 ? asset.aspectRatio : 16 / 9)
                      .clamp(0.55, 1.8)
                      .toDouble();
                  final card = Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: videoCard(asset, ratio),
                  );
                  if (leftH <= rightH) {
                    left.add(card);
                    leftH += 1 / ratio;
                  } else {
                    right.add(card);
                    rightH += 1 / ratio;
                  }
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(children: left)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(children: right)),
                    ],
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
                      controller: videoSearchController,
                      onSubmitted: search,
                      onChanged: (value) {
                        if (value.trim().isEmpty &&
                            provider.mediaVideosQuery != defaultVideoQuery) {
                          search('');
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search videos...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search_rounded, size: 20),
                          onPressed: () => search(videoSearchController.text),
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
                        return videoChip(
                          category['title']!,
                          category['query']!,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: provider.isMediaVideosLoading
                        ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : videos.isEmpty
                        ? const Center(
                      child: AppText(
                        'No videos found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : masonry(),
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
                            const SizedBox(width: 24),
                            _backgroundTab(
                              title: 'VIDEOS',
                              selected: selectedTab == 3,
                              onTap: () {
                                setSheetState(() => selectedTab = 3);
                                WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                    ) {
                                  if (!sheetOpen || !sheetContext.mounted) {
                                    return;
                                  }
                                  if (provider.mediaVideoAssets.isEmpty &&
                                      !provider.isMediaVideosLoading) {
                                    provider
                                        .fetchMediaVideos(defaultVideoQuery)
                                        .then((_) {
                                      if (sheetOpen &&
                                          sheetContext.mounted) {
                                        setSheetState(() {});
                                      }
                                    });
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
                            : selectedTab == 3
                            ? videosView()
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
            style: TextStyle(
              color: Colors.red,
              fontSize: AppFontSize.fontSize10,
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
                    fontSize: AppFontSize.fontSize13,
                    color: isDark ? Colors.white : const Color(0xFF222222),
                  ),
                  decoration: InputDecoration(
                    hintText: forVideos
                        ? 'Search background videos...'
                        : 'Search background...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF8A8A8A),
                      fontSize: AppFontSize.fontSize13,
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
                      fontSize: AppFontSize.fontSize11,
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
                      fontSize: AppFontSize.fontSize11,
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
                      fontSize: AppFontSize.fontSize13,
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
  void dispose() {
    _projectSaveTimer?.cancel();

    // Final save when the editor closes. dispose() must be synchronous: no
    // await, no setState, no context. Anything pending in the 500 ms debounce
    // (e.g. a mask applied right before pressing back) is flushed here.
    final editor = _editorRef;
    final project = _projectRef;
    if (editor != null && _projectSaveListenerAttached) {
      editor.removeListener(_onEditorChangedForProjectSave);
      _projectSaveListenerAttached = false;
    }
    if (_projectAutoSaveReady && editor != null && project != null) {
      try {
        final uid = project.projectUid?.trim() ?? '';
        if (uid.isNotEmpty) {
          final content = jsonEncode(editor.exportCurrentPageJson());
          if (content != _lastSavedProjectContent) {
            // ignore: discarded_futures
            ProjectRepository.instance.updateProject(
              projectUid: uid,
              name: project.projectName ?? 'Untitled design',
              content: content,
            );
          }
        }
      } catch (e, st) {
        debugPrintStack(stackTrace: st);
      }
    }

    _musicPositionSubscription?.cancel();
    _musicDurationSubscription?.cancel();
    _musicCompleteSubscription?.cancel();
    _musicStateSubscription?.cancel();
    _musicPlayer.dispose();
    _zoomH.dispose();
    _zoomV.dispose();
    super.dispose();
  }

  bool _isCapturingThumbnail = false;

  // ---------------- EDITOR OPEN: WAIT FOR ALL IMAGES ----------------
  // The canvas is only shown once the template/project is imported AND every
  // image on it is downloaded + decoded, so it opens fully drawn instead of
  // images popping in one by one.
  bool _initDone = false;
  bool _assetsReady = false;
  bool _assetsPreloadStarted = false;
  int _assetsTotal = 0;
  int _assetsLoaded = 0;

  static final RegExp _rasterUrl = RegExp(
    r'\.(png|jpe?g|webp|gif)(\?.*)?$',
    caseSensitive: false,
  );

  Future<void> _preloadCanvasAssets() async {
    if (_assetsPreloadStarted || !mounted) return;
    _assetsPreloadStarted = true;
    try {
      final provider = context.read<EditorProvider>();
      final imageSources = <String>{};
      final otherSources = <String>{};
      for (final it in provider.items) {
        final type = (it.type ?? '').trim().toLowerCase();
        final src = (it.contentUrl ?? '').trim();
        if (src.isEmpty) continue;
        if (type == 'image') {
          imageSources.add(src);
        } else if ((type == 'svg_group' || type == 'svg_element') &&
            src.startsWith('http') &&
            _rasterUrl.hasMatch(src)) {
          otherSources.add(src);
        }
      }
      final all = <String>{...imageSources, ...otherSources};
      // Masks saved with the project: download them now so they are ready
      // (and cached) before the canvas is shown.
      final maskSources = <String>{};
      for (final it in provider.items) {
        final m = provider.imageMaskUrl(it.id ?? '')?.trim() ?? '';
        if (m.isNotEmpty) maskSources.add(m);
      }
      if (mounted) {
        setState(() {
          _assetsTotal = all.length;
          _assetsLoaded = 0;
        });
      }

      await Future.wait(
        all.map((src) async {
          try {
            if (!mounted) return;
            final ImageProvider p =
            (src.startsWith('http://') || src.startsWith('https://'))
                ? NetworkImage(src)
                : FileImage(
              File(
                src.startsWith('file://')
                    ? src.replaceFirst('file://', '')
                    : src,
              ),
            );
            await precacheImage(
              p,
              context,
              onError: (_, __) {},
            ).timeout(const Duration(seconds: 25), onTimeout: () {});
            // Warm the alpha mask used for pixel-accurate tapping.
            if (imageSources.contains(src)) ItemAlphaCache.maskFor(src);
          } catch (_) {}
          if (mounted) setState(() => _assetsLoaded++);
        }),
      );
      await Future.wait(
        maskSources.map(
              (u) => ItemMaskCache.load(u).then<void>((_) {}, onError: (_) {}),
        ),
      );
    } catch (_) {}
    if (mounted) setState(() => _assetsReady = true);
  }

  Widget _buildEditorLoader(bool isDark) {
    final total = _assetsTotal;
    final done = _assetsLoaded.clamp(0, total == 0 ? 0 : total);
    final String label = total == 0
        ? 'Preparing editor...'
        : 'Loading images $done / $total';
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                value: total == 0 ? null : done / total,
              ),
            ),
            const SizedBox(height: 18),
            AppText(
              label,
              style: TextStyle(
                fontSize: AppFontSize.fontSize14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: done / total,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------- PINCH-ZOOM OF THE SELECTED ELEMENT ----------------
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

  double _pinchStartRotation = 0.0;

  /// Snapshots the selected element so a two-finger gesture on it can resize
  /// (pinch) and rotate (twist) it around its own centre, like Canva.
  /// Returns false when nothing is selected or the element is locked.
  bool _beginItemPinch() {
    final provider = context.read<EditorProvider>();
    final item = _selectedZoomItem(provider);
    if (item == null || provider.isItemLocked(item.id ?? '')) {
      _pinchId = '';
      return false;
    }
    _pinchId = item.id ?? '';
    _pinchStartScale = item.scale.isFinite
        ? item.scale.clamp(0.01, 10.0).toDouble()
        : 1.0;
    _pinchStartRotation = item.rotation.isFinite ? item.rotation : 0.0;
    _pinchBaseSize = EditableItemWidget.isTextType(item.type)
        ? EditableItemWidget.measureTextBox(item, provider)
        : Size(math.max(1.0, item.width), math.max(1.0, item.height));
    // Visual centre stays put while the element grows / shrinks.
    _pinchStartCenter =
        item.position +
            Offset(_pinchBaseSize.width, _pinchBaseSize.height) *
                (_pinchStartScale / 2);
    return true;
  }

  void _updateItemPinch(ScaleUpdateDetails d) {
    if (_pinchId.isEmpty) return;
    final provider = context.read<EditorProvider>();
    final newScale = (_pinchStartScale * d.scale).clamp(0.02, 10.0).toDouble();
    final half =
        Offset(_pinchBaseSize.width, _pinchBaseSize.height) * (newScale / 2);
    provider.updateItemTransform(
      _pinchId,
      scale: newScale,
      rotation: _snapAngle(_pinchStartRotation + d.rotation),
      position: _pinchStartCenter - half,
      clampToFrame: false,
    );
  }

  void _endItemPinch() {
    if (_pinchId.isEmpty) return;
    context.read<EditorProvider>().commitTransform();
    _pinchId = '';
  }

  /// Magnetic snap to 0 / 90 / 180 / 270 degrees while twisting.
  double _snapAngle(double a) {
    const step = math.pi / 2;
    const tolerance = 0.06; // ~3.5 degrees
    final n = (a / step).roundToDouble();
    return (a - n * step).abs() < tolerance ? n * step : a;
  }

  /// Two fingers on the canvas pinch-zoom ONLY the selected element.
  /// One-finger gestures (move / resize / rotate) are untouched.
  // ---------------- CANVAS ZOOM (precise editing of small items) ----------------
  // The canvas is laid out at (fit size * zoom) inside a two-axis scroll view.
  // Because the zoom changes the real layout size (not a Transform), every
  // existing gesture/overlay calculation (which divides by scaleX/scaleY)
  // stays correct, and handles keep their normal on-screen size.
  bool _zoomModeOn = false;

  /// "Hand" tool while zoomed in: one finger always pans the screen, objects
  /// are never moved / resized / rotated. Tapping an object still selects it.
  bool _panMode = false;
  double _canvasZoom = 1.0;
  double _zoomOffH = 0.0;
  double _zoomOffV = 0.0;
  Size _zoomViewSize = Size.zero;
  Size _zoomFit = Size.zero;
  Size _zoomCanvasLogical = const Size(1080, 1080);
  final ScrollController _zoomH = ScrollController();
  final ScrollController _zoomV = ScrollController();
  static const double _zoomMax = 4.0;
  // Breathing room around the page so edge handles stay visible / tappable.
  static const double _zoomPad = 28.0;
  static const List<double> _zoomLevels = <double>[1.0, 1.5, 2.0, 3.0, 4.0];
  double _zoomGestureStart = 1.0;
  Offset _zoomGestureFrac = Offset.zero;

  /// Where the canvas starts inside the scrolled content (it is centred when
  /// smaller than the viewport, plus 16px padding).
  double _zoomOrigin(double canvasLen, double viewLen) =>
      (math.max(viewLen, canvasLen + _zoomPad * 2) -
          (canvasLen + _zoomPad * 2)) /
          2 +
          _zoomPad;

  /// Fraction (0..1 over the canvas) that sits under [viewPoint].
  Offset _zoomFracAt(Offset viewPoint, double zoom) {
    final cw = _zoomFit.width * zoom;
    final ch = _zoomFit.height * zoom;
    return Offset(
      (_zoomOffH + viewPoint.dx - _zoomOrigin(cw, _zoomViewSize.width)) / cw,
      (_zoomOffV + viewPoint.dy - _zoomOrigin(ch, _zoomViewSize.height)) / ch,
    );
  }

  /// Sets the zoom so that canvas fraction [frac] ends up under [viewPoint].
  void _applyZoom(double zoom, Offset frac, Offset viewPoint) {
    if (_zoomFit.isEmpty || _zoomViewSize.isEmpty) return;
    final z = zoom.clamp(1.0, _zoomMax).toDouble();
    final vw = _zoomViewSize.width, vh = _zoomViewSize.height;
    final cw = _zoomFit.width * z, ch = _zoomFit.height * z;
    final maxH = math.max(0.0, math.max(vw, cw + _zoomPad * 2) - vw);
    final maxV = math.max(0.0, math.max(vh, ch + _zoomPad * 2) - vh);
    final h = (_zoomOrigin(cw, vw) + frac.dx * cw - viewPoint.dx)
        .clamp(0.0, maxH)
        .toDouble();
    final v = (_zoomOrigin(ch, vh) + frac.dy * ch - viewPoint.dy)
        .clamp(0.0, maxV)
        .toDouble();
    setState(() {
      _canvasZoom = z;
      _zoomOffH = h;
      _zoomOffV = v;
      if (z > 1.001) _zoomModeOn = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncZoomOffsets());
  }

  /// Pushes the wanted offsets into the scroll controllers (after layout).
  void _syncZoomOffsets() {
    if (!mounted) return;
    void sync(ScrollController c, double want) {
      if (!c.hasClients) return;
      final p = c.position;
      final t = want.clamp(0.0, p.maxScrollExtent).toDouble();
      if ((p.pixels - t).abs() > 0.5) c.jumpTo(t);
    }

    sync(_zoomH, _zoomOffH);
    sync(_zoomV, _zoomOffV);
  }

  /// Canvas fraction to zoom around: the selected item's centre when there is
  /// one, otherwise the middle of what is currently on screen.
  Offset _zoomAnchorFrac(EditorProvider p) {
    final id = p.selectedItemId;
    if (id != null) {
      for (final e in p.items) {
        if (e.id != id || _isCanvasBackground(e)) continue;
        final base = EditableItemWidget.isTextType(e.type)
            ? EditableItemWidget.measureTextBox(e, p)
            : Size(math.max(1.0, e.width), math.max(1.0, e.height));
        final sc = e.scale.isFinite
            ? e.scale.clamp(0.01, 10.0).toDouble()
            : 1.0;
        final c =
            e.position + Offset(base.width * sc / 2, base.height * sc / 2);
        return Offset(
          c.dx / _zoomCanvasLogical.width,
          c.dy / _zoomCanvasLogical.height,
        );
      }
    }
    return _zoomFracAt(
      Offset(_zoomViewSize.width / 2, _zoomViewSize.height / 2),
      _canvasZoom,
    );
  }

  void _stepZoom(EditorProvider p, int dir) {
    final cur = _canvasZoom;
    final next = dir > 0
        ? _zoomLevels.firstWhere((l) => l > cur + 0.01, orElse: () => _zoomMax)
        : _zoomLevels.lastWhere((l) => l < cur - 0.01, orElse: () => 1.0);
    _applyZoom(
      next,
      _zoomAnchorFrac(p),
      Offset(_zoomViewSize.width / 2, _zoomViewSize.height / 2),
    );
  }

  void _toggleZoomMode(EditorProvider p) {
    if (_zoomModeOn) {
      setState(() {
        _zoomModeOn = false;
        _panMode = false;
        _canvasZoom = 1.0;
        _zoomOffH = 0.0;
        _zoomOffV = 0.0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncZoomOffsets());
    } else {
      setState(() => _zoomModeOn = true);
      _applyZoom(
        2.0,
        _zoomAnchorFrac(p),
        Offset(_zoomViewSize.width / 2, _zoomViewSize.height / 2),
      );
    }
  }

  // ---- Canva-style gestures on the canvas viewport ----
  //  * normal mode, element selected        -> pinch anywhere resizes + rotates it
  //  * zoom mode, two fingers ON the element -> resize + rotate that element
  //  * otherwise two fingers                -> zoom (+ pan) the canvas
  //  * one finger on empty space (zoomed)   -> pan the canvas
  //  * one finger on the selected element   -> move it (selection overlay)
  bool _gestureOnItem = false;
  // After lifting a finger from an element pinch the rest of that gesture is
  // ignored, so the canvas does not suddenly start panning.
  bool _gestureSuppressed = false;

  /// True when [viewPoint] (viewport coordinates) is on / right next to the
  /// selected element.
  bool _isOverSelectedItem(Offset viewPoint) {
    final provider = context.read<EditorProvider>();
    final item = _selectedZoomItem(provider);
    if (item == null || _zoomFit.isEmpty) return false;

    final frac = _zoomFracAt(viewPoint, _canvasZoom);
    final point = Offset(
      frac.dx * _zoomCanvasLogical.width,
      frac.dy * _zoomCanvasLogical.height,
    );

    // Finger slack: 28 screen px, converted to canvas units.
    final unitsPerPx =
        _zoomCanvasLogical.width / (_zoomFit.width * _canvasZoom);
    final pad = 28.0 * unitsPerPx;

    final sc = item.scale.isFinite && item.scale.abs() > 0
        ? item.scale.clamp(0.01, 10.0).toDouble()
        : 1.0;
    final body = EditableItemWidget.isTextType(item.type)
        ? EditableItemWidget.measureTextBox(item, provider)
        : Size(math.max(1.0, item.width), math.max(1.0, item.height));
    final centre = Offset(body.width / 2, body.height / 2);
    final rel = (point - item.position) / sc - centre;
    final a = -(item.rotation.isFinite ? item.rotation : 0.0);
    final local =
        Offset(
          rel.dx * math.cos(a) - rel.dy * math.sin(a),
          rel.dx * math.sin(a) + rel.dy * math.cos(a),
        ) +
            centre;
    return Rect.fromLTWH(
      0,
      0,
      body.width,
      body.height,
    ).inflate(pad / sc).contains(local);
  }

  // ScaleGestureRecognizer calls onEnd + onStart again whenever a finger is
  // added or lifted, so every start re-decides what the gesture targets.
  void _onCanvasGestureStart(ScaleStartDetails d) {
    if (_gestureSuppressed) return;
    // Normal (not zoomed) mode: with an element selected, a pinch anywhere
    // resizes it. Zoom mode: only a pinch ON the element resizes it, a pinch
    // elsewhere zooms the canvas.
    final targetsItem = _panMode
        ? false
        : (_zoomModeOn ? _isOverSelectedItem(d.localFocalPoint) : true);
    _gestureOnItem = d.pointerCount >= 2 && targetsItem && _beginItemPinch();
    _zoomGestureStart = _canvasZoom;
    _zoomGestureFrac = _zoomFracAt(d.localFocalPoint, _canvasZoom);
  }

  void _onCanvasGestureUpdate(ScaleUpdateDetails d) {
    if (_gestureSuppressed) return;
    if (_gestureOnItem) {
      _updateItemPinch(d);
      return;
    }
    // Pinch = zoom around the fingers; moving the fingers = pan.
    _applyZoom(
      _zoomGestureStart * d.scale,
      _zoomGestureFrac,
      d.localFocalPoint,
    );
  }

  void _onCanvasGestureEnd(ScaleEndDetails d) {
    if (_gestureOnItem) {
      _endItemPinch();
      _gestureOnItem = false;
      // One finger was lifted but another is still down: ignore the rest of
      // this touch sequence (cleared in _onCanvasGestureIdle).
      if (d.pointerCount > 0) _gestureSuppressed = true;
    }
  }

  /// A brand new touch sequence begins (first finger down): always start clean.
  void _onCanvasGestureFresh() {
    _gestureSuppressed = false;
    _gestureOnItem = false;
  }

  /// All fingers are up. ScaleGestureRecognizer does NOT always send a final
  /// onEnd(pointerCount: 0) (e.g. after one finger was lifted first), so the
  /// reset / clean-up must not depend on it.
  void _onCanvasGestureIdle() {
    if (_gestureOnItem) {
      _endItemPinch();
      _gestureOnItem = false;
    }
    _gestureSuppressed = false;
    if (!mounted) return;
    // Pinched back to "fit": leave zoom mode, like Canva.
    if (_zoomModeOn && _canvasZoom < 1.02) {
      setState(() {
        _zoomModeOn = false;
        _panMode = false;
        _canvasZoom = 1.0;
        _zoomOffH = 0.0;
        _zoomOffV = 0.0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncZoomOffsets());
    }
  }

  // ---- Double-tap to zoom (Canva style) ----
  // Double-tap empty space: fit -> 200% around the finger, zoomed -> fit.
  // Detected with raw pointer events so a normal single tap is never delayed.
  int _dtPointers = 0;
  bool _dtMulti = false;
  Offset? _dtDownPos;
  int _dtDownMs = 0;
  Offset? _dtLastTapPos;
  int _dtLastTapMs = 0;

  void _dtDown(PointerDownEvent e) {
    _dtPointers++;
    if (_dtPointers > 1) {
      _dtMulti = true;
      _dtLastTapPos = null;
    } else {
      _dtMulti = false;
      _dtDownPos = e.localPosition;
      _dtDownMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _dtUp(PointerUpEvent e) {
    _dtPointers = math.max(0, _dtPointers - 1);
    if (_dtPointers > 0) return;
    final down = _dtDownPos;
    _dtDownPos = null;
    if (_dtMulti || down == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final quick =
        now - _dtDownMs < 250 && (e.localPosition - down).distance < 10;
    if (!quick) {
      _dtLastTapPos = null;
      return;
    }
    final last = _dtLastTapPos;
    if (last != null &&
        now - _dtLastTapMs < 320 &&
        (e.localPosition - last).distance < 40) {
      _dtLastTapPos = null;
      _onDoubleTapZoom(e.localPosition);
    } else {
      _dtLastTapPos = e.localPosition;
      _dtLastTapMs = now;
    }
  }

  void _dtCancel(PointerCancelEvent e) {
    _dtPointers = 0;
    _dtDownPos = null;
    _dtLastTapPos = null;
  }

  void _onDoubleTapZoom(Offset viewPoint) {
    if (_zoomFit.isEmpty || _zoomViewSize.isEmpty) return;
    // Double-tap on the selected item is left alone (e.g. edit text).
    if (_isOverSelectedItem(viewPoint)) return;
    if (_canvasZoom > 1.05) {
      _applyZoom(
        1.0,
        const Offset(0.5, 0.5),
        Offset(_zoomViewSize.width / 2, _zoomViewSize.height / 2),
      );
      setState(() {
        _zoomModeOn = false;
        _panMode = false;
      });
    } else {
      _applyZoom(2.0, _zoomFracAt(viewPoint, _canvasZoom), viewPoint);
    }
  }

  Widget _zoomViewport({
    required double aspectRatio,
    required Size canvasSize,
    required Widget canvas,
    Widget Function(double scaleX, double scaleY, Offset origin)?
    overlayBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final vw = c.maxWidth, vh = c.maxHeight;
        final availW = math.max(1.0, vw - _zoomPad * 2);
        final availH = math.max(1.0, vh - _zoomPad * 2);
        final fitW = math.min(availW, availH * aspectRatio);
        final fitH = fitW / aspectRatio;
        _zoomViewSize = Size(vw, vh);
        _zoomFit = Size(fitW, fitH);
        _zoomCanvasLogical = canvasSize;

        // Never change the layout while saving / exporting: the capture is
        // normalised through pixelRatio instead, so the user's zoom and scroll
        // position stay exactly as they were (no zoom-out / zoom-in flicker).
        final z = _canvasZoom;
        final cw = fitW * z, ch = fitH * z;
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncZoomOffsets());

        final scroller = SizedBox(
          width: vw,
          height: vh,
          child: SingleChildScrollView(
            controller: _zoomV,
            physics: const NeverScrollableScrollPhysics(),
            child: SingleChildScrollView(
              controller: _zoomH,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: vw, minHeight: vh),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(_zoomPad),
                    child: SizedBox(
                      width: cw,
                      height: ch,
                      // Pan mode: objects are untouchable, so a tap can
                      // never select anything. Turn pan mode off to edit.
                      child: IgnorePointer(ignoring: _panMode, child: canvas),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Selection box + handles are drawn in a viewport-sized layer on top
        // of the (clipped) canvas, so nothing is cut at the page edge and
        // handles outside the page can still be touched.
        Widget? overlay;
        if (overlayBuilder != null) {
          overlay = overlayBuilder(
            cw / canvasSize.width,
            ch / canvasSize.height,
            Offset(
              _zoomOrigin(cw, vw) - _zoomOffH,
              _zoomOrigin(ch, vh) - _zoomOffV,
            ),
          );
        }

        final layered = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              // Tap on the grey area around the page = unselect.
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_panMode) return;
                  context.read<EditorProvider>().clearSelection();
                },
                child: scroller,
              ),
            ),
            if (overlay != null)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _panMode,
                  child: Stack(clipBehavior: Clip.none, children: [overlay]),
                ),
              ),
          ],
        );

        return RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: <Type, GestureRecognizerFactory>{
            _TwoFingerScaleRecognizer:
            GestureRecognizerFactoryWithHandlers<_TwoFingerScaleRecognizer>(
                  () => _TwoFingerScaleRecognizer(),
                  (r) {
                r
                // One finger pans the canvas only while it is zoomed in.
                  ..allowSinglePointer = _canvasZoom > 1.01
                  ..onStart = _onCanvasGestureStart
                  ..onUpdate = _onCanvasGestureUpdate
                  ..onEnd = _onCanvasGestureEnd
                  ..onFreshSequence = _onCanvasGestureFresh
                  ..onIdle = _onCanvasGestureIdle;
              },
            ),
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _dtDown,
            onPointerUp: _dtUp,
            onPointerCancel: _dtCancel,
            child: SizedBox(width: vw, height: vh, child: layered),
          ),
        );
      },
    );
  }

  /// Selection box + handles of the selected (non-background) item.
  Widget _buildSelectionOverlay(
      EditorProvider provider,
      double scaleX,
      double scaleY,
      Offset origin,
      Size canvasSize,
      ) {
    if (provider.multiSelectMode) {
      return _buildMultiSelectHighlights(provider, scaleX, scaleY, origin);
    }
    final id = provider.selectedItemId;
    if (id == null) return const SizedBox.shrink();
    EditorItem? selected;
    for (final e in provider.items) {
      if (e.id == id) {
        selected = e;
        break;
      }
    }
    if (selected == null || _isCanvasBackground(selected)) {
      return const SizedBox.shrink();
    }
    return _TransformSelectionOverlay(
      key: ValueKey('selection_overlay_${selected.id}'),
      item: selected,
      scaleX: scaleX,
      scaleY: scaleY,
      origin: origin,
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
    );
  }

  Widget _buildZoomControls(EditorProvider provider, bool isDark) {
    final bg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final fg = isDark ? Colors.white : Colors.black87;

    Widget btn(
        IconData icon,
        String tip,
        VoidCallback onTap, {
          bool active = false,
        }) {
      return Tooltip(
        message: tip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFFFFC107) : null,
            ),
            child: Icon(icon, size: 22, color: active ? Colors.black : fg),
          ),
        ),
      );
    }

    return Positioned(
      left: 12,
      bottom: 12,
      child: Material(
        elevation: 4,
        color: bg,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(
                Icons.library_add_check_rounded,
                provider.multiSelectMode
                    ? 'Exit multi-select'
                    : 'Select multiple (group animation)',
                    () => _toggleMultiSelectMode(provider),
                active: provider.multiSelectMode,
              ),
              if (provider.selectedItemId != null)
                btn(
                  Icons.highlight_off_rounded,
                  'Unselect',
                      () => provider.clearSelection(),
                ),
              if (_zoomModeOn) ...[
                btn(Icons.add_rounded, 'Zoom in', () => _stepZoom(provider, 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${(_canvasZoom * 100).round()}%',
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize11,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
                btn(
                  Icons.remove_rounded,
                  'Zoom out',
                      () => _stepZoom(provider, -1),
                ),
                btn(
                  Icons.fit_screen_rounded,
                  'Fit to screen',
                      () => _applyZoom(
                    1.0,
                    const Offset(0.5, 0.5),
                    Offset(_zoomViewSize.width / 2, _zoomViewSize.height / 2),
                  ),
                ),
                btn(
                  Icons.pan_tool_rounded,
                  _panMode ? 'Pan mode on' : 'Move screen',
                      () {
                    setState(() => _panMode = !_panMode);
                    if (_panMode) provider.clearSelection();
                    Fluttertoast.showToast(
                      msg: _panMode
                          ? 'Pan mode: drag to move the screen'
                          : 'Edit mode: drag to move objects',
                    );
                  },
                  active: _panMode,
                ),
              ],
              btn(
                _zoomModeOn ? Icons.close_rounded : Icons.zoom_in_rounded,
                _zoomModeOn ? 'Exit zoom' : 'Zoom in to edit',
                    () => _toggleZoomMode(provider),
                active: _zoomModeOn,
              ),
            ],
          ),
        ),
      ),
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
                fontSize: AppFontSize.fontSize11,
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
              fontSize: AppFontSize.fontSize14,
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
                  fontSize: AppFontSize.fontSize14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Show the editor only when the design is imported and all its images
    // are downloaded.
    if (!_initDone || !_assetsReady) {
      return _buildEditorLoader(isDark);
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
            // Dark = something to undo, faded = nothing to undo.
            _editorToolbarButton(
              icon: Icons.undo_rounded,
              backgroundColor: provider.canUndo
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFFF1F1F1),
              iconColor: provider.canUndo
                  ? Colors.black
                  : const Color(0xFFBDBDBD),
              tooltip: 'Undo',
              onPressed: provider.canUndo ? provider.undo : null,
            ),
            const SizedBox(width: 10),
            // Dark = something to redo, faded = nothing to redo.
            _editorToolbarButton(
              icon: Icons.redo_rounded,
              backgroundColor: provider.canRedo
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFFF1F1F1),
              iconColor: provider.canRedo
                  ? Colors.black
                  : const Color(0xFFBDBDBD),
              tooltip: 'Redo',
              onPressed: provider.canRedo ? provider.redo : null,
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
              onPressed: () async {
                await _captureCurrentPageThumb(provider);
                if (!mounted) return;
                _showPagesSheet(this.context, provider, isDark);
              },
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
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          _zoomViewport(
            aspectRatio: aspectRatio,
            canvasSize: canvasSize,
            overlayBuilder: (sx, sy, origin) =>
                _buildSelectionOverlay(provider, sx, sy, origin, canvasSize),
            canvas: RepaintBoundary(
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

                      return Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (e) {
                          _tapDownPos = e.localPosition;
                          _tapDownMs = DateTime.now().millisecondsSinceEpoch;
                          _tapSelectedByCanvas = false;
                        },
                        onPointerUp: (e) {
                          final down = _tapDownPos;
                          _tapDownPos = null;
                          if (down == null) return;
                          final quick =
                              DateTime.now().millisecondsSinceEpoch -
                                  _tapDownMs <
                                  400;
                          if (!quick ||
                              (e.localPosition - down).distance > 10) {
                            return;
                          }
                          final dbgPt = Offset(
                            e.localPosition.dx / scaleX,
                            e.localPosition.dy / scaleY,
                          );
                          _lastTapCanvasPos = dbgPt;
                          final id = _pickItemAt(provider, dbgPt);
                          if (id == null) return;
                          _tapSelectedByCanvas = true;
                          // Multi-select: a tap toggles the item in the group.
                          if (provider.multiSelectMode) {
                            provider.toggleMultiSelect(id);
                            if (_grpType != ItemAnimationType.none &&
                                provider.isMultiSelected(id)) {
                              _applyGroupAnimation(provider, preview: false);
                            }
                            return;
                          }
                          if (provider.selectedItemId != id) {
                            final it = provider.items.firstWhere(
                                  (x) => x.id == id,
                            );
                            provider.setSelectedItem(it.type, it.id);
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_tapSelectedByCanvas) {
                              _tapSelectedByCanvas = false;
                              return;
                            }
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
                                    key: ValueKey(backgroundItems.first.id),
                                    // Zoomed in: one finger pans the canvas,
                                    // it must not drag the background.
                                    gesturesEnabled:
                                    _canvasZoom <= 1.01 &&
                                        !provider.multiSelectMode,
                                    item: backgroundItems.first,
                                    scaleX: scaleX,
                                    scaleY: scaleY,
                                    canvasWidth: canvasSize.width,
                                    canvasHeight: canvasSize.height,
                                    onSelected: () {
                                      if (provider.multiSelectMode) return;
                                      // A tap anywhere inside an item's box
                                      // belongs to that item, never to the
                                      // background lying underneath it.
                                      final tapAt = _lastTapCanvasPos;
                                      if (tapAt != null) {
                                        final hitId = _pickItemAt(
                                          provider,
                                          tapAt,
                                        );
                                        if (hitId != null) {
                                          final hit = provider.items.firstWhere(
                                                (x) => x.id == hitId,
                                          );
                                          provider.setSelectedItem(
                                            hit.type,
                                            hit.id,
                                          );
                                          return;
                                        }
                                      }
                                      final bg = backgroundItems.first;

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
                                      child: IgnorePointer(
                                        // Multi-select: items must not drag;
                                        // the canvas Listener handles taps.
                                        ignoring: provider.multiSelectMode,
                                        child: Transform.scale(
                                          scale: scaleX,
                                          alignment: Alignment.topLeft,
                                          child: EditableItemWidget(
                                            item: item,
                                            onItemSelected: (type, id) {
                                              // Canvas-level picking already chose the
                                              // topmost visible item for this tap; a lower
                                              // item's onTap must not override it.
                                              if (_tapSelectedByCanvas) return;
                                              provider.setSelectedItem(
                                                type,
                                                id,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                })(),

                                // FRAME ATTACHED TO SELECTED IMAGE
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
                                            // API frames are network images,
                                            // the old built-in ones are assets.
                                            child:
                                            provider.selectedFrameUrl!
                                                .startsWith('http')
                                                ? Image.network(
                                              provider.selectedFrameUrl!,
                                              fit: BoxFit.fill,
                                              errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                            )
                                                : Image.asset(
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
                          ),
                        ),
                      );
                    },
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
          _buildZoomControls(provider, isDark),
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
    required VoidCallback? onPressed,
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
    if (provider.multiSelectMode) {
      return _buildGroupAnimationPanel(context, provider, isDark);
    }

    // Selection moved away from the image whose outline editor was open.
    if (_imageOutlineItemId != null &&
        provider.selectedItemId != _imageOutlineItemId) {
      _imageOutlineItemId = null;
    }

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

    // Shapes picked from the Shapes panel are flat PNG images. They must open
    // the same bottom toolbar as every other shape (FILL / OUTLINE / ANIMATE /
    // FRONT / BACK / DUPLICATE / DELETE), not the image toolbar.
    if (animSelId != null &&
        type == 'image' &&
        provider.isShapeImage(animSelId)) {
      return _buildShapeEditorToolbar(context, provider, isDark);
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
                        fontSize: AppFontSize.fontSize13,
                        fontWeight: FontWeight.w600,
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
                              fontSize: AppFontSize.fontSize22,
                              fontWeight: FontWeight.w600,
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
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize19,
                          color: fg,
                        ),
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
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize19,
                          color: fg,
                        ),
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
          child: AppText(
            label,
            style: TextStyle(fontSize: AppFontSize.fontSize12),
          ),
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

  // ANIMATE panel (docked at the bottom when an item is selected).
  // ================= MULTI-SELECT + GROUP ANIMATION =================
  void _toggleMultiSelectMode(EditorProvider p) {
    final turnOn = !p.multiSelectMode;
    final current = p.selectedItemId;
    final currentType = p.selectedItemType;
    p.setMultiSelectMode(turnOn);
    if (turnOn) {
      // The item that was selected becomes the first one of the group.
      if (current != null && currentType != null) p.toggleMultiSelect(current);
      Fluttertoast.showToast(msg: 'Tap items to add them to the group');
    }
    setState(() {
      _animatePanelItemId = null;
      _animatePanelCollapsed = false;
      _grpCollapsed = true;
    });
  }

  /// Applies the current group settings to every selected item.
  void _applyGroupAnimation(EditorProvider provider, {bool preview = true}) {
    if (provider.multiSelectedIds.isEmpty) {
      Fluttertoast.showToast(msg: 'Select items on the canvas first');
      return;
    }
    provider.applyGroupAnimation(
      type: _grpType,
      mode: _grpMode,
      direction: _grpDir,
      axis: _grpAxis,
      baseDelay: _grpDelay,
      stagger: _grpStagger,
      preview: preview,
    );
    if (_grpType != ItemAnimationType.none && !_grpCollapsed && preview) {
      setState(() => _grpCollapsed = true);
    }
  }

  /// Blue box + order number on every multi-selected item. Drawn in the
  /// overlay layer (outside the capture boundary), so it never ends up in an
  /// exported image / GIF / video.
  Widget _buildMultiSelectHighlights(
      EditorProvider provider,
      double sx,
      double sy,
      Offset origin,
      ) {
    final out = <Widget>[];
    var order = 0;
    for (final id in provider.multiSelectedIds) {
      order++;
      final matches = provider.items.where((e) => e.id == id);
      if (matches.isEmpty) continue;
      final it = matches.first;
      final body = EditableItemWidget.isTextType(it.type)
          ? EditableItemWidget.measureTextBox(it, provider)
          : Size(math.max(1.0, it.width), math.max(1.0, it.height));
      final sc = it.scale.isFinite
          ? it.scale.clamp(0.01, 10.0).toDouble()
          : 1.0;
      out.add(
        Positioned(
          left: origin.dx + it.position.dx * sx,
          top: origin.dy + it.position.dy * sy,
          width: body.width * sc * sx,
          height: body.height * sc * sy,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: it.rotation.isFinite ? it.rotation : 0.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x1A3568F5),
                        border: Border.all(
                          color: const Color(0xFF3568F5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -9,
                    top: -9,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3568F5),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$order',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Stack(clipBehavior: Clip.none, children: out);
  }

  /// Same look as the single-item ANIMATE panel (header tab, quick buttons,
  /// type tiles, mode chips, dropdowns, sliders, preview button). After a
  /// choice it shrinks to a slim bar so the canvas preview is fully visible.
  Widget _buildGroupAnimationPanel(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final count = provider.multiSelectedIds.length;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF171717);
    final soft = isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF3F3F3);
    const accent = Color(0xFFE53935);
    final hasType = _grpType != ItemAnimationType.none;

    void apply({bool preview = true}) =>
        _applyGroupAnimation(provider, preview: preview);

    Widget quick(
        IconData icon,
        VoidCallback? onTap, {
          bool active = false,
          bool danger = false,
        }) {
      return Opacity(
        opacity: onTap == null ? .4 : 1,
        child: InkWell(
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
            child: Icon(
              icon,
              size: 22,
              color: (danger || active) ? accent : fg,
            ),
          ),
        ),
      );
    }

    Widget closeBtn() => InkWell(
      onTap: () => _toggleMultiSelectMode(provider),
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
    );

    // ---------- slim bar ----------
    if (_grpCollapsed) {
      Widget typeChip(ItemAnimationType t) {
        final sel = _grpType == t;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() => _grpType = t);
              if (count == 0) {
                Fluttertoast.showToast(
                  msg: 'Tap items on the canvas to add them to the group',
                );
                return;
              }
              apply();
            },
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? accent.withValues(alpha: .15) : soft,
                borderRadius: BorderRadius.circular(18),
                border: sel ? Border.all(color: accent) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 16, color: sel ? accent : fg),
                  const SizedBox(width: 6),
                  AppText(
                    t.label,
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize12,
                      fontWeight: FontWeight.w600,
                      color: sel ? accent : fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [
            BoxShadow(blurRadius: 10, color: Color(0x33000000)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3568F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: AppText(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.fontSize12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ItemAnimationType.values.map(typeChip).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                quick(
                  Icons.replay_rounded,
                      () => provider.previewGroupAnimation(),
                ),
                const SizedBox(width: 6),
                quick(
                  Icons.tune_rounded,
                      () => setState(() => _grpCollapsed = false),
                ),
                const SizedBox(width: 6),
                quick(
                  Icons.close_rounded,
                      () => _toggleMultiSelectMode(provider),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ---------- full panel ----------
    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: AppText(
        text,
        style: TextStyle(
          fontSize: AppFontSize.fontSize15,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
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
        style: TextStyle(
          fontSize: AppFontSize.fontSize14,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    Widget slider({
      required double value,
      required double max,
      required int divisions,
      required ValueChanged<double> onChanged,
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
          value: value.clamp(0.0, max).toDouble(),
          min: 0,
          max: max,
          divisions: divisions,
          onChanged: (v) => setState(() => onChanged(v)),
          onChangeEnd: (_) {
            if (hasType && count > 0) apply();
          },
        ),
      );
    }

    Widget labelledSlider(
        String label,
        String hint,
        double value,
        double max,
        int divisions,
        ValueChanged<double> onChanged,
        ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: TextStyle(
              fontSize: AppFontSize.fontSize13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: slider(
                  value: value,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
              valueBox('${value.toStringAsFixed(1)}s'),
            ],
          ),
          AppText(
            hint,
            style: TextStyle(
              fontSize: AppFontSize.fontSize11,
              color: fg.withValues(alpha: .55),
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    Widget typeTile(ItemAnimationType t) {
      final selected = _grpType == t;
      final isNone = t == ItemAnimationType.none;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() => _grpType = t);
            if (count == 0) {
              Fluttertoast.showToast(
                msg: 'Tap items on the canvas to add them to the group',
              );
              return;
            }
            apply();
          },
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
                    t.icon,
                    size: 28,
                    color: isNone ? Colors.grey.shade600 : accent,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  t.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize11,
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

    Widget modeChip(ItemAnimationMode m) {
      final selected =
          _grpMode == m ||
              (m == ItemAnimationMode.entrance &&
                  _grpMode == ItemAnimationMode.both);
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: m == ItemAnimationMode.exit ? 0 : 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _grpMode = m);
              apply();
            },
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
                m.label,
                style: TextStyle(
                  fontSize: AppFontSize.fontSize12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : fg,
                ),
              ),
            ),
          ),
        ),
      );
    }

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
          final sel = v == value;
          return PopupMenuItem<T>(
            value: v,
            height: 44,
            child: Row(
              children: [
                Icon(iconOf(v), size: 18, color: sel ? accent : fg),
                const SizedBox(width: 14),
                AppText(
                  labelOf(v),
                  style: TextStyle(
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    color: sel ? accent : fg,
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
                    fontSize: AppFontSize.fontSize13,
                    fontWeight: FontWeight.w600,
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

    Widget tab(String label) => Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: TextStyle(
              fontSize: AppFontSize.fontSize13,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: 52, color: accent),
        ],
      ),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
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
                  tab('ANIMATE'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3568F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      '$count selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.fontSize11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  closeBtn(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  quick(Icons.select_all_rounded, provider.selectAllForMulti),
                  quick(
                    Icons.deselect_rounded,
                    count == 0 ? null : provider.clearMultiSelection,
                  ),
                  quick(
                    Icons.replay_rounded,
                    (count == 0 || !hasType)
                        ? null
                        : () => provider.previewGroupAnimation(),
                  ),
                  quick(
                    Icons.check_rounded,
                        () => _toggleMultiSelectMode(provider),
                  ),
                ],
              ),
              if (count == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AppText(
                    'Tap text, images or shapes on the canvas to add them to the group.',
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize12,
                      color: fg.withValues(alpha: .65),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ItemAnimationType.values.map(typeTile).toList(),
                ),
              ),
              if (hasType) ...[
                sectionTitle('${_grpType.label} animation Settings'),
                Row(
                  children: ItemAnimationMode.values
                      .where((m) => m != ItemAnimationMode.both)
                      .map(modeChip)
                      .toList(),
                ),
                const SizedBox(height: 12),
                if (_grpType.hasDirection) ...[
                  dropdown<ItemAnimDirection>(
                    value: _grpDir,
                    values: ItemAnimDirection.values,
                    labelOf: (d) => d.label,
                    iconOf: (d) => d.icon,
                    onSelected: (d) {
                      setState(() => _grpDir = d);
                      apply();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                if (_grpType.hasAxis) ...[
                  dropdown<ItemAnimAxis>(
                    value: _grpAxis,
                    values: ItemAnimAxis.values,
                    labelOf: (a) => a.label,
                    iconOf: (a) => a.icon,
                    onSelected: (a) {
                      setState(() => _grpAxis = a);
                      apply();
                    },
                  ),
                  const SizedBox(height: 6),
                ],
                labelledSlider(
                  'Start delay (0-2.9s)',
                  'When the first item starts.',
                  _grpDelay,
                  2.9,
                  29,
                      (v) => _grpDelay = v,
                ),
                labelledSlider(
                  'Gap between items (0-1s)',
                  '0 = all together. More = one after another, in the order 1, 2, 3...',
                  _grpStagger,
                  1.0,
                  10,
                      (v) => _grpStagger = v,
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (count == 0) {
                      Fluttertoast.showToast(msg: 'Select items first');
                      return;
                    }
                    provider.previewGroupAnimation();
                    setState(() => _grpCollapsed = true);
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
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: accent,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        AppText(
                          'PREVIEW ANIMATION',
                          style: TextStyle(
                            color: accent,
                            fontSize: AppFontSize.fontSize13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _supportsAnimation(EditorProvider provider, String id) {
    final matches = provider.items.where((e) => e.id == id);
    if (matches.isEmpty) return false;
    return !_isCanvasBackground(matches.first);
  }

  void _openAnimatePanel(EditorProvider provider, String id, {int tab = 1}) {
    setState(() {
      _animatePanelItemId = id;
      _animatePanelTab = tab;
      // Animate opens as a slim bar so the canvas stays big; the tune
      // button expands the full settings.
      _animatePanelCollapsed = tab != 0;
    });
  }

  void _closeAnimatePanel() {
    if (_animatePanelItemId == null) return;
    setState(() {
      _animatePanelItemId = null;
      _animatePanelCollapsed = false;
    });
  }

  /// Shrinks the ANIMATE panel to a slim bar so the canvas (and the animation
  /// preview) gets almost the whole screen.
  void _collapseAnimatePanel() {
    if (_animatePanelCollapsed) return;
    setState(() => _animatePanelCollapsed = true);
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
                  fontSize: AppFontSize.fontSize13,
                  fontWeight: FontWeight.w600,
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
                    fontSize: AppFontSize.fontSize11,
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
        style: TextStyle(
          fontSize: AppFontSize.fontSize15,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
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
        style: TextStyle(
          fontSize: AppFontSize.fontSize15,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
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
                  fontSize: AppFontSize.fontSize14,
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
              fontSize: AppFontSize.fontSize13,
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
                  onChangeEnd: (_) {
                    provider.previewItemAnimation(id);
                    _collapseAnimatePanel();
                  },
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
                    fontSize: AppFontSize.fontSize14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
                    fontSize: AppFontSize.fontSize13,
                    fontWeight: FontWeight.w600,
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
                  fontSize: AppFontSize.fontSize14,
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

    // EFFECTS body (text only)
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
                                  fontSize: AppFontSize.fontSize12,
                                  fontWeight: FontWeight.w600,
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

    // ANIMATE body
    Widget modeChip(ItemAnimationMode mode) {
      // BOTH is the same as ENTRANCE now (item always stays visible).
      final selected =
          anim.mode == mode ||
              (mode == ItemAnimationMode.entrance &&
                  anim.mode == ItemAnimationMode.both);
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: mode == ItemAnimationMode.exit ? 0 : 8,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              provider.setItemAnimationMode(id, mode);
              _collapseAnimatePanel();
            },
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
                  fontSize: AppFontSize.fontSize12,
                  fontWeight: FontWeight.w600,
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
                onTap: () {
                  provider.setItemAnimationType(id, t);
                  if (t != ItemAnimationType.none) _collapseAnimatePanel();
                },
              );
            }).toList(),
          ),
        ),
        if (!anim.isNone) ...[
          sectionTitle('${anim.type.label} animation Settings'),
          Row(
            children: ItemAnimationMode.values
                .where((m) => m != ItemAnimationMode.both)
                .map(modeChip)
                .toList(),
          ),
          const SizedBox(height: 12),
          if (anim.type.hasDirection) ...[
            dropdown<ItemAnimDirection>(
              value: anim.direction,
              values: ItemAnimDirection.values,
              labelOf: (d) => d.label,
              iconOf: (d) => d.icon,
              onSelected: (d) {
                provider.setItemAnimationDirection(id, d);
                _collapseAnimatePanel();
              },
            ),
            const SizedBox(height: 10),
          ],
          if (anim.type.hasAxis) ...[
            dropdown<ItemAnimAxis>(
              value: anim.axis,
              values: ItemAnimAxis.values,
              labelOf: (a) => a.label,
              iconOf: (a) => a.icon,
              onSelected: (a) {
                provider.setItemAnimationAxis(id, a);
                _collapseAnimatePanel();
              },
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
            _collapseAnimatePanel();
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
              children: [
                Icon(Icons.play_arrow_rounded, color: accent, size: 22),
                SizedBox(width: 6),
                AppText(
                  'PREVIEW ANIMATION',
                  style: TextStyle(
                    color: accent,
                    fontSize: AppFontSize.fontSize13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Slim bar: the canvas gets the freed space, so the animation preview is
    // big enough to actually see. Type chips + replay stay reachable.
    if (_animatePanelCollapsed && !showEffects) {
      Widget typeChip(ItemAnimationType t) {
        final sel = anim.type == t;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => provider.setItemAnimationType(id, t),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? accent.withValues(alpha: .15) : soft,
                borderRadius: BorderRadius.circular(18),
                border: sel ? Border.all(color: accent) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 16, color: sel ? accent : fg),
                  const SizedBox(width: 6),
                  AppText(
                    t.label,
                    style: TextStyle(
                      fontSize: AppFontSize.fontSize12,
                      fontWeight: FontWeight.w600,
                      color: sel ? accent : fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [
            BoxShadow(blurRadius: 10, color: Color(0x33000000)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ItemAnimationType.values.map(typeChip).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                quick(Icons.replay_rounded, () {
                  if (anim.isNone) {
                    Fluttertoast.showToast(msg: 'Select an animation first');
                    return;
                  }
                  provider.previewItemAnimation(id);
                }),
                const SizedBox(width: 6),
                quick(
                  Icons.tune_rounded,
                      () => setState(() => _animatePanelCollapsed = false),
                ),
                const SizedBox(width: 6),
                quick(Icons.close_rounded, _closeAnimatePanel),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
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

  /// Single align implementation shared by the FORMAT sheet and the
  /// effects/animate panel "Align to page" sheet, so both behave the same.
  void _alignItemToPage(EditorProvider provider, String id, String where) {
    if (provider.isItemLocked(id)) {
      Fluttertoast.showToast(msg: 'Item is locked. Unlock it first.');
      return;
    }
    final matches = provider.items.where((e) => e.id == id);
    if (matches.isEmpty) return;
    final cur = matches.first;

    final s = cur.scale.clamp(0.01, 10.0).toDouble();
    final box = EditableItemWidget.isTextType(cur.type)
        ? EditableItemWidget.measureTextBox(cur, provider)
        : Size(cur.width, cur.height);
    final w = box.width * s;
    final h = box.height * s;

    // Rotation happens around the item's centre, so align using the
    // rotated bounding box instead of the raw (unrotated) box.
    final rot = cur.rotation.isFinite ? cur.rotation : 0.0;
    final cosA = math.cos(rot).abs();
    final sinA = math.sin(rot).abs();
    final bboxW = w * cosA + h * sinA;
    final bboxH = w * sinA + h * cosA;
    final padX = (bboxW - w) / 2; // how far the bbox sticks out of the box
    final padY = (bboxH - h) / 2;

    // Region to align inside: the smallest shape / image BEHIND this item that
    // contains its centre (e.g. the pill a text sits on). When the item is not
    // on top of anything, the whole page is used.
    var region = Rect.fromLTWH(
      0,
      0,
      provider.canvasWidth,
      provider.canvasHeight,
    );
    final selfIndex = provider.items.indexWhere((e) => e.id == id);
    final itemCentre = Offset(cur.position.dx + w / 2, cur.position.dy + h / 2);
    double bestArea = double.infinity;
    for (var i = 0; i < selfIndex; i++) {
      final o = provider.items[i];
      if (o.id == id) continue;
      final t = (o.type ?? '').toLowerCase();
      if (t == 'text' || t == 'textbox' || t == 'i-text' || t == 'video') {
        continue;
      }
      if (provider.isCanvasBackgroundItem(o)) continue;
      final os = o.scale.clamp(0.01, 10.0).toDouble();
      final ow = o.width * os;
      final oh = o.height * os;
      if (ow < 4 || oh < 4) continue;
      final oc = Offset(o.position.dx + ow / 2, o.position.dy + oh / 2);
      final orot = o.rotation.isFinite ? o.rotation : 0.0;
      final bw = ow * math.cos(orot).abs() + oh * math.sin(orot).abs();
      final bh = ow * math.sin(orot).abs() + oh * math.cos(orot).abs();
      final r = Rect.fromCenter(center: oc, width: bw, height: bh);
      // Must really hold the item, and must not be the full page.
      if (!r.contains(itemCentre)) continue;
      if (r.width >= provider.canvasWidth * 0.98 &&
          r.height >= provider.canvasHeight * 0.98) {
        continue;
      }
      if (r.width < bboxW * 0.9 && r.height < bboxH * 0.9) continue;
      final area = r.width * r.height;
      if (area < bestArea) {
        bestArea = area;
        region = r;
      }
    }

    var x = cur.position.dx;
    var y = cur.position.dy;
    switch (where) {
      case 'left':
        x = region.left + padX;
        break;
      case 'center':
        x = region.left + (region.width - w) / 2;
        break;
      case 'right':
        x = region.right - w - padX;
        break;
      case 'top':
        y = region.top + padY;
        break;
      case 'middle':
        y = region.top + (region.height - h) / 2;
        break;
      case 'bottom':
        y = region.bottom - h - padY;
        break;
    }
    // For text, left/center/right also set the inner text alignment so the
    // lines of multi-line text follow the same direction.
    if (EditableItemWidget.isTextType(cur.type)) {
      if (where == 'left') {
        provider.updateTextAlignment(id, TextAlign.left);
      } else if (where == 'center') {
        provider.updateTextAlignment(id, TextAlign.center);
      } else if (where == 'right') {
        provider.updateTextAlignment(id, TextAlign.right);
      }
    }
    provider.updatePosition(id, Offset(x, y));
  }

  void _showAlignSheet(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    void alignTo(String where) => _alignItemToPage(provider, id, where);

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
                  width: 18, height: 18,
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 7),
                AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.fontSize9,
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
              // Same "Align to page" sheet as the effects/animate panel.
              _showAlignSheet(context, provider, id, isDark);
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
                        style: TextStyle(
                          color: fg,
                          fontSize: AppFontSize.fontSize12,
                        ),
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
                            fontSize: AppFontSize.fontSize14,
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
                                () {
                              final v = a['value'] as TextAlign;
                              if (v == TextAlign.justify) {
                                // No page position for justify.
                                provider.updateTextAlignment(id, v);
                              } else {
                                _alignItemToPage(
                                  provider,
                                  id,
                                  v == TextAlign.left
                                      ? 'left'
                                      : v == TextAlign.center
                                      ? 'center'
                                      : 'right',
                                );
                              }
                            },
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
                              fontSize: AppFontSize.fontSize12,
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
                              fontSize: AppFontSize.fontSize12,
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
                              fontSize: AppFontSize.fontSize14,
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
                        Expanded(
                          child: AppText(
                            'Image Masks',
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize21,
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

    // Shape-images (Shapes panel) are recoloured through imageFill, real
    // shapes through item.color.
    final fillColor = item.type == 'image'
        ? (provider.imageFill(id) ?? Colors.black)
        : (item.color ?? Colors.white);
    final outlineColor = item.outlineColor;
    final outlineStyle = provider.outlineStyle(id);
    final outlineJoin = provider.outlineJoin(id);
    final hasCorner = provider.supportsCornerRadius(id);

    final tabs = <List<String>>[
      ['style', 'STYLE'],
      ['join', 'JOIN'],
      ['width', 'WIDTH'],
      if (hasCorner) ['corner', 'CORNER'],
      ['rotate', 'ROTATE'],
      ['opacity', 'OPACITY'],
    ];
    final activeTab = tabs.any((t) => t[0] == _shapeTab)
        ? _shapeTab
        : tabs.first[0];

    Widget panel;
    switch (activeTab) {
      case 'join':
        panel = _shapeJoinPanel(
          outlineJoin,
              (join) => provider.updateOutlineJoin(id, join),
        );
        break;
      case 'width':
        panel = _shapeStepSlider(
          valueText: item.outlineWidth.round().toString(),
          value: item.outlineWidth.clamp(0.0, 20.0).toDouble(),
          min: 0,
          max: 20,
          step: 1,
          onChanged: (v) => provider.updateOutline(id, v, outlineColor),
        );
        break;
      case 'corner':
        panel = _shapeStepSlider(
          valueText: provider.shapeCornerRadius(id).round().toString(),
          value: provider.shapeCornerRadius(id),
          min: 0,
          max: provider.shapeMaxCornerRadius(id),
          step: provider.shapeMaxCornerRadius(id) >= 40 ? 2 : 1,
          onChanged: (v) => provider.updateShapeCornerRadius(id, v),
        );
        break;
      case 'rotate':
        panel = _shapeStepSlider(
          valueText:
          '${(item.rotation.clamp(0.0, math.pi * 2) * 180 / math.pi).round()}°',
          value: item.rotation.clamp(0.0, math.pi * 2).toDouble(),
          min: 0,
          max: math.pi * 2,
          step: math.pi / 36,
          onChanged: (v) => provider.updateRotation(id, v),
        );
        break;
      case 'opacity':
        panel = _shapeStepSlider(
          valueText: '${(item.opacity.clamp(0.0, 1.0) * 100).round()}%',
          value: item.opacity.clamp(0.0, 1.0).toDouble(),
          min: 0,
          max: 1,
          step: 0.05,
          onChanged: (v) => provider.updateOpacity(id, v),
        );
        break;
      default:
        panel = _shapeStylePanel(
          outlineStyle,
              (style) => provider.updateOutlineStyle(id, style),
        );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_showImageFilters)
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _shapeSwatchTile(
                      'FILL',
                      fillColor,
                          () => _showShapeColorPicker(
                        context,
                        provider,
                        id,
                        isOutline: false,
                      ),
                    ),
                    _shapeSwatchTile(
                      'OUTLINE',
                      outlineColor,
                          () => _showShapeColorPicker(
                        context,
                        provider,
                        id,
                        isOutline: true,
                      ),
                    ),
                    _shapeTile(
                      Icons.animation,
                      'ANIMATE',
                          () => _openAnimatePanel(provider, id),
                    ),
                    _shapeTile(
                      Icons.flip_to_front_rounded,
                      'FRONT',
                          () => provider.bringToFront(id),
                    ),
                    _shapeTile(
                      Icons.flip_to_back_rounded,
                      'BACK',
                          () => provider.sendToBack(id),
                    ),
                    _shapeTile(
                      Icons.copy_rounded,
                      'COPY',
                          () => provider.duplicateItem(id),
                    ),
                    _shapeTile(
                      Icons.delete_outline_rounded,
                      'DELETE',
                          () => provider.removeItem(id),
                      danger: true,
                    ),
                    _shapeTile(
                      Icons.close_rounded,
                      'CLOSE',
                      provider.clearSelection,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _shapeTab = t[0]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: activeTab == t[0]
                                ? const Color(0xFFFFC107)
                                : const Color(0xFF1F232C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AppText(
                            t[1],
                            style: TextStyle(
                              color: activeTab == t[0]
                                  ? Colors.black
                                  : Colors.white70,
                              fontSize: AppFontSize.fontSize11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 74,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF14171D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: panel,
            ),
          ],
        ),
      ),
    );
  }

  /// Uniform square tile (icon + label) for the top row.
  Widget _shapeTile(
      IconData icon,
      String label,
      VoidCallback onTap, {
        bool danger = false,
      }) {
    final c = danger ? const Color(0xFFFF5A5A) : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1F232C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: c),
              const SizedBox(height: 5),
              AppText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c,
                  fontSize: AppFontSize.fontSize8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Same tile as [_shapeTile] but with a colour swatch instead of an icon.
  Widget _shapeSwatchTile(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1F232C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white70, width: 1.2),
                ),
              ),
              const SizedBox(height: 5),
              AppText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.fontSize8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// - / slider / + with the current value on top. Used by every numeric tab.
  Widget _shapeStepSlider({
    required String valueText,
    required double value,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
  }) {
    final hi = max <= min ? min + 1 : max;
    final v = value.isFinite ? value.clamp(min, hi).toDouble() : min;

    Widget btn(IconData icon, double delta) {
      return InkWell(
        onTap: () => onChanged((v + delta).clamp(min, hi).toDouble()),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF252A34),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, size: 20, color: Colors.amber),
        ),
      );
    }

    return Row(
      children: [
        btn(Icons.remove_rounded, -step),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: Colors.amber,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.amber,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(value: v, min: min, max: hi, onChanged: onChanged),
          ),
        ),
        btn(Icons.add_rounded, step),
        Container(
          width: 52,
          alignment: Alignment.centerRight,
          child: AppText(
            valueText,
            style: TextStyle(
              color: Colors.amber,
              fontSize: AppFontSize.fontSize14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _shapeStylePanel(String selected, ValueChanged<String> onChanged) {
    const styles = <String>['none', 'solid', 'dashed', 'dotted', 'fine_dotted'];
    const labels = <String>['NONE', 'SOLID', 'DASHED', 'DOTTED', 'FINE'];
    return Row(
      children: List.generate(styles.length, (i) {
        final active = selected == styles[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == styles.length - 1 ? 0 : 8),
            child: InkWell(
              onTap: () => onChanged(styles[i]),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFC107)
                      : const Color(0xFF252A34),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? const Color(0xFFFFC107) : Colors.white10,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(34, 14),
                      painter: _OutlineStylePreviewPainter(styles[i]),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      labels[i],
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white60,
                        fontSize: AppFontSize.fontSize8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _shapeJoinPanel(String selected, ValueChanged<String> onChanged) {
    const joins = <String>['miter', 'bevel', 'round'];
    const labels = <String>['MITER', 'BEVEL', 'ROUND'];
    IconData iconFor(String v) => v == 'round'
        ? Icons.rounded_corner
        : v == 'bevel'
        ? Icons.change_history_rounded
        : Icons.crop_square_rounded;
    return Row(
      children: List.generate(joins.length, (i) {
        final active = selected == joins[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == joins.length - 1 ? 0 : 8),
            child: InkWell(
              onTap: () => onChanged(joins[i]),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFC107)
                      : const Color(0xFF252A34),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? const Color(0xFFFFC107) : Colors.white10,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconFor(joins[i]),
                      size: 20,
                      color: active ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      labels[i],
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white60,
                        fontSize: AppFontSize.fontSize8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.fontSize8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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

    final isImageFill = !isOutline && item.type == 'image';
    Color current = isOutline
        ? (item.outlineColor)
        : isImageFill
        ? (provider.imageFill(id) ?? Colors.black)
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
                if (isImageFill)
                  TextButton(
                    // Transparent = "remove the recolour".
                    onPressed: () =>
                        Navigator.pop(dialogContext, Colors.transparent),
                    child: const AppText('RESET'),
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
    } else if (isImageFill) {
      provider.updateImageFill(id, picked.a == 0 ? null : picked);
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
    if (_imageOutlineItemId == id) {
      return _buildImageOutlineToolbar(context, provider, isDark);
    }
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
                // Shapes from the Shapes panel: same first tools as a shape.
                if (provider.isShapeImage(id)) ...[
                  _shapeColorTool(
                    'FILL',
                    provider.imageFill(id) ?? Colors.black,
                        () => _showShapeColorPicker(
                      context,
                      provider,
                      id,
                      isOutline: false,
                    ),
                  ),
                  _bottomTool(
                    Icons.border_style_rounded,
                    'OUTLINE',
                        () => _openImageOutline(provider, id),
                  ),
                ],
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
                if (!provider.isShapeImage(id) &&
                    !_isCanvasBackground(item) &&
                    item.type != 'video')
                  _bottomTool(
                    Icons.border_style_rounded,
                    'OUTLINE',
                        () => _openImageOutline(provider, id),
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
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: AppText(
                      'Flip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.fontSize14,
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

  // ---- Image OUTLINE: same inline design as the shape toolbar ----

  void _openImageOutline(EditorProvider provider, String id) {
    setState(() {
      _imageOutlineItemId = id;
      _shapeTab = 'style';
    });
  }

  void _closeImageOutline() {
    if (_imageOutlineItemId == null) return;
    setState(() => _imageOutlineItemId = null);
  }

  /// Picking a colour / style / width switches a hidden outline on and makes
  /// sure it is actually VISIBLE (solid style, real width, opaque colour).
  void _ensureImageOutlineOn(EditorProvider provider, String id) {
    final matches = provider.items.where((e) => e.id == id);
    if (matches.isEmpty) return;
    final it = matches.first;
    if (provider.outlineStyle(id) == 'none') {
      provider.updateOutlineStyle(id, 'solid');
    }
    final cur = provider.items.firstWhere((e) => e.id == id);
    final needWidth = cur.outlineWidth <= 0;
    final needColor = cur.outlineColor.a == 0;
    if (needWidth || needColor) {
      // Scale with the image so a big photo gets a visible border.
      final auto = (math.min(it.width, it.height) * 0.02)
          .clamp(3.0, 12.0)
          .toDouble();
      provider.updateOutline(
        id,
        needWidth ? auto : cur.outlineWidth,
        needColor ? Colors.black : cur.outlineColor,
      );
    }
  }

  Widget _buildImageOutlineToolbar(
      BuildContext context,
      EditorProvider provider,
      bool isDark,
      ) {
    final id = provider.selectedItemId;
    if (id == null) return const SizedBox.shrink();
    final matches = provider.items.where((e) => e.id == id);
    if (matches.isEmpty) return const SizedBox.shrink();
    final item = matches.first;

    final outlineColor = item.outlineColor;
    final outlineStyle = provider.outlineStyle(id);
    final outlineJoin = provider.outlineJoin(id);

    const tabs = <List<String>>[
      ['style', 'STYLE'],
      ['join', 'JOIN'],
      ['width', 'WIDTH'],
    ];
    final activeTab = tabs.any((t) => t[0] == _shapeTab)
        ? _shapeTab
        : tabs.first[0];

    Widget panel;
    switch (activeTab) {
      case 'join':
        panel = _shapeJoinPanel(outlineJoin, (join) {
          _ensureImageOutlineOn(provider, id);
          provider.updateOutlineJoin(id, join);
        });
        break;
      case 'width':
        panel = _shapeStepSlider(
          valueText: item.outlineWidth.round().toString(),
          value: item.outlineWidth.clamp(0.0, 20.0).toDouble(),
          min: 0,
          max: 20,
          step: 1,
          onChanged: (v) {
            if (v > 0) _ensureImageOutlineOn(provider, id);
            final cur = provider.items.firstWhere((e) => e.id == id);
            provider.updateOutline(id, v, cur.outlineColor);
          },
        );
        break;
      default:
        panel = _shapeStylePanel(outlineStyle, (style) {
          provider.updateOutlineStyle(id, style);
          if (style != 'none') _ensureImageOutlineOn(provider, id);
        });
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _shapeTile(
                    Icons.arrow_back_rounded,
                    'BACK',
                    _closeImageOutline,
                  ),
                  _shapeSwatchTile('OUTLINE', outlineColor, () async {
                    _ensureImageOutlineOn(provider, id);
                    await _showShapeColorPicker(
                      context,
                      provider,
                      id,
                      isOutline: true,
                    );
                  }),
                  _shapeTile(
                    Icons.close_rounded,
                    'CLOSE',
                        () {
                      _closeImageOutline();
                      provider.clearSelection();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _shapeTab = t[0]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: activeTab == t[0]
                                ? const Color(0xFFFFC107)
                                : const Color(0xFF1F232C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AppText(
                            t[1],
                            style: TextStyle(
                              color: activeTab == t[0]
                                  ? Colors.black
                                  : Colors.white70,
                              fontSize: AppFontSize.fontSize11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 74,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF14171D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: panel,
            ),
          ],
        ),
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

  /// Outline colour / thickness / style for an image (or any item).
  void _showOutlineSheet(
      BuildContext context,
      EditorProvider provider,
      String id,
      bool isDark,
      ) {
    const swatches = <Color>[
      Colors.white,
      Colors.black,
      Color(0xFFF44336),
      Color(0xFFFF9800),
      Color(0xFFFFEB3B),
      Color(0xFF66BB6A),
      Color(0xFF03A9F4),
      Color(0xFF4054B2),
      Color(0xFF9C27B0),
      Color(0xFFEC407A),
    ];
    const styles = <String>['none', 'solid', 'dashed', 'dotted', 'fine_dotted'];
    const labels = <String, String>{
      'none': 'None',
      'solid': 'Solid',
      'dashed': 'Dashed',
      'dotted': 'Dotted',
      'fine_dotted': 'Fine',
    };

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              final matches = provider.items.where((e) => e.id == id);
              if (matches.isEmpty) return const SizedBox.shrink();
              final item = matches.first;
              final style = provider.outlineStyle(id);
              final active = style != 'none' && item.outlineWidth > 0;
              final fg = isDark ? Colors.white : const Color(0xFF222222);

              // Picking a colour / thickness switches the outline on.
              void ensureOn() {
                if (provider.outlineStyle(id) == 'none') {
                  provider.updateOutlineStyle(id, 'solid');
                }
              }

              return _sheetShell(
                isDark: isDark,
                title: 'Outline',
                height: 330,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Color',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final c in swatches)
                              GestureDetector(
                                onTap: () {
                                  ensureOn();
                                  final cur = provider.items.firstWhere(
                                        (e) => e.id == id,
                                  );
                                  provider.updateOutline(
                                    id,
                                    cur.outlineWidth > 0
                                        ? cur.outlineWidth
                                        : 3.0,
                                    c,
                                  );
                                  setSheetState(() {});
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: active && item.outlineColor == c
                                          ? const Color(0xFF3568F5)
                                          : Colors.grey.shade400,
                                      width: active && item.outlineColor == c
                                          ? 3
                                          : 1,
                                    ),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () async {
                                ensureOn();
                                await _showShapeColorPicker(
                                  context,
                                  provider,
                                  id,
                                  isOutline: true,
                                );
                                setSheetState(() {});
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Icon(
                                  Icons.colorize,
                                  size: 18,
                                  color: fg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AppText(
                            'Thickness',
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          AppText(
                            item.outlineWidth.toStringAsFixed(0),
                            style: TextStyle(color: fg),
                          ),
                        ],
                      ),
                      Slider(
                        value: item.outlineWidth.clamp(0.0, 30.0).toDouble(),
                        min: 0,
                        max: 30,
                        onChanged: (v) {
                          if (v > 0) ensureOn();
                          provider.updateOutline(id, v, item.outlineColor);
                          setSheetState(() {});
                        },
                      ),
                      AppText(
                        'Style',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final st in styles)
                            ChoiceChip(
                              label: Text(labels[st]!),
                              selected: style == st,
                              onSelected: (_) {
                                provider.updateOutlineStyle(id, st);
                                setSheetState(() {});
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.fontSize12,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.fontSize9,
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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: AppFontSize.fontSize8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppText(
                title == 'OPACITY'
                    ? '${(safeValue * 100).round()}%'
                    : safeValue.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: AppFontSize.fontSize8,
                  fontWeight: FontWeight.w600,
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
                          Expanded(
                            child: AppText(
                              'Music',
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize17,
                                fontWeight: FontWeight.w600,
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
                                            style: TextStyle(
                                              fontSize: AppFontSize.fontSize12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          AppText(
                                            'Duration: ${track['duration']}',
                                            style: TextStyle(
                                              fontSize: AppFontSize.fontSize10,
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
          fontSize: AppFontSize.fontSize11,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.fontSize10,
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
                          Expanded(
                            child: AppText(
                              'Text to Audio',
                              style: TextStyle(
                                fontSize: AppFontSize.fontSize14,
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
                            fontSize: AppFontSize.fontSize11,
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
                          AppText(
                            'Select voice',
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize11,
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
                                  : AppText(
                                'CONVERT',
                                style: TextStyle(
                                  fontSize: AppFontSize.fontSize11,
                                  fontWeight: FontWeight.w600,
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

    // Hide the selection box / handles so they are not in the exported PNG.
    if (mounted) setState(() => _isCapturingThumbnail = true);
    await WidgetsBinding.instance.endOfFrame;

    final ui.Image image;
    try {
      image = await boundary.toImage(pixelRatio: 3.0 / _canvasZoom);
    } finally {
      if (mounted) setState(() => _isCapturingThumbnail = false);
    }
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
    } catch (e) {
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
                fontSize: AppFontSize.fontSize16,
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
                        style: TextStyle(
                          fontSize: AppFontSize.fontSize14,
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
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();

      final fileName = 'project_${DateTime.now().millisecondsSinceEpoch}.png';

      final filePath = '${directory.path}/$fileName';

      await Dio().download(fileUrl, filePath);

      return filePath;
    } catch (e, stackTrace) {
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
      // API success மட்டும் check பண்ணுகிறோம்.
      await projectProvider.exportProject(projectUid: projectUid);

      if (!context.mounted) return;

      // IMPORTANT:
      // s3_key null இருந்தாலும் API response success என்றால்
      // canvas-ஐ download செய்ய வேண்டும்.

      if (projectProvider.exportError != null &&
          projectProvider.exportError!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AppText(projectProvider.exportError!)),
        );

        return;
      }

      // Give Flutter time to finish latest canvas changes.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) return;

      // CAPTURE CANVAS
      final renderObject = _canvasKey.currentContext?.findRenderObject();

      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Unable to capture design')),
        );

        return;
      }

      final boundary = renderObject;

      // Hide the selection box / handles so they are not in the saved image.
      if (mounted) setState(() => _isCapturingThumbnail = true);
      await WidgetsBinding.instance.endOfFrame;

      final ui.Image image;
      try {
        image = await boundary.toImage(
          pixelRatio: _exportPixelRatio(boundary, scale),
        );
      } finally {
        if (mounted) setState(() => _isCapturingThumbnail = false);
      }

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Unable to create image')),
        );

        return;
      }

      final bytes = byteData.buffer.asUint8List();

      // SAVE TO GALLERY
      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        await Gal.requestAccess();

        hasAccess = await Gal.hasAccess();
      }

      if (!hasAccess) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Gallery permission is required')),
        );

        return;
      }

      final fileName = 'MMB_${DateTime.now().millisecondsSinceEpoch}';

      await Gal.putImageBytes(bytes, name: fileName);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Image saved to Gallery successfully')),
      );
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: AppText('Unable to save image: $e')));
    }
  }

  /// "Delete page?" confirmation. Returns true only when the user taps
  /// "Delete page".
  Future<bool> _confirmDeletePage(
      BuildContext ctx,
      String pageName,
      bool isDark,
      ) async {
    final bg = isDark ? const Color(0xFF1E2026) : Colors.white;
    final footerBg = isDark ? const Color(0xFF17191E) : const Color(0xFFF8F8F8);
    final fg = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white60 : const Color(0xFF7A7A7A);

    final result = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: bg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Delete page?',
                          style: TextStyle(
                            fontSize: AppFontSize.fontSize18,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          '\u201C$pageName\u201D and everything on it will be '
                              'removed. This can\u2019t be undone.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: footerBg,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.transparent
                                : Colors.white,
                            foregroundColor: fg,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFE0E0E0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: AppText(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBE0E0),
                            foregroundColor: const Color(0xFFE5000F),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const AppText(
                            'Delete page',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE5000F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result == true;
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
        return SafeArea(
          child: StatefulBuilder(
            builder: (sheetContext, setModalState) {
              final fg = isDark ? Colors.white : Colors.black;

              Widget pageRow(int index) {
                final id = provider.pageIdAt(index);
                final selected = index == provider.currentPageIndex;
                final thumb = _pageThumbs[id];
                return Container(
                  key: ValueKey(id),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                        ? const Color(0xFF3A2528)
                        : const Color(0xFFFFE6E4))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      provider.switchPage(index);
                      Navigator.pop(modalContext);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          // Hold the handle and drag to reorder pages.
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE6E6E6),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: thumb == null
                                ? null
                                : Image.memory(
                              thumb,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppText(
                              provider.pageNameAt(index),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: fg,
                              ),
                            ),
                          ),
                          // Per-page actions.
                          IconButton(
                            tooltip: 'Duplicate page',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            iconSize: 20,
                            onPressed: () {
                              final srcId = provider.pageIdAt(index);
                              provider.duplicatePageAt(index);
                              // The copy starts with the same preview.
                              final t = _pageThumbs[srcId];
                              if (t != null) {
                                _pageThumbs[provider.pageIdAt(
                                  provider.currentPageIndex,
                                )] =
                                    t;
                              }
                              _lastPageCount = provider.pageCount;
                              setModalState(() {});
                              _saveProjectNow(force: true);
                            },
                            icon: const Icon(
                              Icons.library_add_rounded,
                              color: Colors.red,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete page',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            iconSize: 20,
                            // The last remaining page cannot be deleted.
                            onPressed: provider.pageCount <= 1
                                ? null
                                : () async {
                              final removedId = provider.pageIdAt(index);
                              final ok = await _confirmDeletePage(
                                sheetContext,
                                provider.pageNameAt(index),
                                isDark,
                              );
                              if (!ok || !mounted) return;
                              // Page list can't change under a modal
                              // dialog, but stay safe.
                              if (index >= provider.pageCount ||
                                  provider.pageIdAt(index) != removedId) {
                                return;
                              }
                              provider.deletePageAt(index);
                              _pageThumbs.remove(removedId);
                              _lastPageCount = provider.pageCount;
                              setModalState(() {});
                              _saveProjectNow(force: true);
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: provider.pageCount <= 1
                                  ? Colors.grey
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Container(
                height: MediaQuery.of(context).size.height * .62,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF17191E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                            'Pages · ${provider.pageCount}',
                            style: TextStyle(
                              fontSize: AppFontSize.fontSize18,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: EdgeInsets.zero,
                        itemCount: provider.pageCount,
                        proxyDecorator: (child, index, animation) => Material(
                          color: Colors.transparent,
                          elevation: 6,
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        ),
                        onReorder: (oldIndex, newIndex) {
                          provider.reorderPage(oldIndex, newIndex);
                          setModalState(() {});
                        },
                        itemBuilder: (_, index) => pageRow(index),
                      ),
                    ),
                    Divider(
                      height: 12,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        provider.addPage();
                        setModalState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFF555555),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppText(
                              'Add page',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

/// Dashed rounded-rectangle border (empty-state box).
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({required this.color, this.radius = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + dash, metric.length),
          ),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

class _TransformSelectionOverlay extends StatefulWidget {
  final EditorItem item;
  final double scaleX;
  final double scaleY;
  final bool isBackground;
  final double canvasWidth;
  final double canvasHeight;

  /// Where the canvas' top-left corner sits inside the area this overlay is
  /// laid out in. The overlay lives in a viewport-sized layer (NOT inside the
  /// clipped canvas) so handles at the page edge are never cut off and stay
  /// tappable.
  final Offset origin;

  const _TransformSelectionOverlay({
    super.key,
    this.origin = Offset.zero,
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
  // Small items (tiny text) still get a finger-sized drag zone.
  static const double _minMoveArea = 64.0;

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

  double get _left =>
      widget.item.position.dx * widget.scaleX + widget.origin.dx;

  double get _top => widget.item.position.dy * widget.scaleY + widget.origin.dy;

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
              left: _pad - math.max(0.0, (_minMoveArea - width) / 2),
              top: _pad - math.max(0.0, (_minMoveArea - height) / 2),
              width: math.max(width, _minMoveArea),
              height: math.max(height, _minMoveArea),
              // Eager recognizer: starts after a few px and measures from the
              // touch-down point, so small text stays under the finger.
              child: RawGestureDetector(
                behavior: HitTestBehavior.translucent,
                gestures: <Type, GestureRecognizerFactory>{
                  EagerPanRecognizer:
                  GestureRecognizerFactoryWithHandlers<EagerPanRecognizer>(
                        () => EagerPanRecognizer(),
                        (r) {
                      r
                        ..onStart = (down) {
                          _startPosition = widget.item.position;
                          _startFocalPoint = down;
                        }
                        ..onUpdate = (position) {
                          final dx =
                              (position.dx - _startFocalPoint.dx) /
                                  widget.scaleX;
                          final dy =
                              (position.dy - _startFocalPoint.dy) /
                                  widget.scaleY;
                          _provider.updateItemTransform(
                            widget.item.id ?? '',
                            position: Offset(
                              _startPosition.dx + dx,
                              _startPosition.dy + dy,
                            ),
                            clampToFrame: false,
                          );
                        }
                        ..onEnd = () => _provider.commitTransform();
                    },
                  ),
                },
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

  /// When false only taps are handled (no drag / pinch / rotate).
  final bool gesturesEnabled;

  const _InteractiveBackgroundLayer({
    super.key,
    this.gesturesEnabled = true,
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

        onScaleStart: !widget.gesturesEnabled
            ? null
            : (details) {
          widget.onSelected();

          _startPosition = item.position;
          _startFocalPoint = details.focalPoint;

          _startScale = item.scale;
          _startRotation = item.rotation;
        },

        onScaleUpdate: !widget.gesturesEnabled
            ? null
            : (details) {
          final provider = context.read<EditorProvider>();

          // Move
          final dx =
              (details.focalPoint.dx - _startFocalPoint.dx) /
                  widget.scaleX;

          final dy =
              (details.focalPoint.dy - _startFocalPoint.dy) /
                  widget.scaleY;

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
                              fontSize: AppFontSize.fontSize16,
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

  /// When true a one-finger drag is handled too (used to pan a zoomed canvas).
  /// When false only gestures with two or more fingers are handled.
  bool allowSinglePointer = false;

  /// Called when the first finger of a new touch sequence goes down.
  VoidCallback? onFreshSequence;

  /// Called when the last finger of a touch sequence is gone.
  VoidCallback? onIdle;

  final Set<int> _down = <int>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_down.isEmpty) onFreshSequence?.call();
    super.addAllowedPointer(event);
    _down.add(event.pointer);
    if (_down.length >= 2) resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _down.remove(event.pointer);
    }
    if (!allowSinglePointer && _down.length < 2 && event is PointerMoveEvent) {
      return;
    }
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
    onIdle?.call();
  }
}