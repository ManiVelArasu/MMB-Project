import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_mmb/ui/screens/video_widget/editor_video.dart';
import 'package:provider/provider.dart';
import '../../Api Model/editor_model.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';
import '../../network/provider/custom_theme_provider.dart';

class TemplateEditScreen extends StatelessWidget {
  final String resizeSize;
  const TemplateEditScreen({super.key, this.resizeSize = "Post Square (1:1)"});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: Scaffold(
        body: SafeArea(child: EditorView(resizeSize: resizeSize)),
      ),
    );
  }
}

class EditorView extends StatefulWidget {
  final String resizeSize;
  const EditorView({super.key, required this.resizeSize});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  bool _isCanvasBackground(EditorItem item) {
    return item.position.dx == 0 &&
        item.position.dy == 0 &&
        (item.width) >= 1000 &&
        (item.height) >= 1000 &&
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
        provider.replaceBackgroundImage(imageUrl, selectedItemId);
      } else {
        // Background/stock image -> full-size background.
        provider.setBackgroundImage(imageUrl);
        provider.clearSelection();
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

    provider.loadItemsFromJson([
      {
        "version": "5.3.0",
        "type": "rect",
        "left": 0,
        "top": 0,
        "width": 1080,
        "height": 1080,
        "fill": "white",
        "name": "clip",
      },
      {
        "version": "5.3.0",
        "type": "image",
        "left": 0,
        "top": 0,
        "width": 1080,
        "height": 1080,
        "src": "https://picsum.photos/1080/1080",
      },
      {
        "version": "5.3.0",
        "type": "textbox",
        "left": 98.06,
        "top": 399.07,
        "width": 444.29,
        "height": 95.35,
        "fill": "rgba(0,0,0,1)",
        "fontSize": 20,
        "fontWeight": 700,
        "text": "STAY COZY",
      },
    ]);

    provider.fetchFreePikAssets("furniture");
    provider.fetchFreePikStickers("shapes");
  }

  void _showFontFamilyBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    final List<String> fontList = [
      "Inter",
      "Janda Manatee Solid",
      "JekoVariable",
      "Anton",
      "Roboto",
      "Poppins",
      "Pacifico",
      "Playfair Display",
      "Montserrat",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.60,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Fonts",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      provider.clearSelection();
                      Navigator.pop(modalContext);
                    },
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
              Expanded(
                child: ListView.separated(
                  itemCount: fontList.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.withValues(alpha: .2)),
                  itemBuilder: (context, index) {
                    final font = fontList[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: AppText(
                        "Aa - $font",
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        provider.updateFontFamily(itemId, font);
                        Navigator.pop(modalContext);
                      },
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

  void _showFontColorBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    int selectedTab = 0;
    Color pickerColor = Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Colors",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          provider.clearSelection();
                          Navigator.pop(modalContext);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTab(
                        selectedTab == 0,
                        "Presets",
                        () => setModalState(() => selectedTab = 0),
                      ),
                      const SizedBox(width: 20),
                      _buildTab(
                        selectedTab == 1,
                        "Custom",
                        () => setModalState(() => selectedTab = 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: selectedTab == 0
                        ? GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                ),
                            itemCount: Colors.primaries.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => provider.updateTextColor(
                                  itemId,
                                  Colors.primaries[index],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.primaries[index],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          )
                        : SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: pickerColor,
                              onColorChanged: (color) {
                                setModalState(() => pickerColor = color);
                                provider.updateTextColor(itemId, color);
                              },
                              enableAlpha: false,
                              displayThumbColor: true,
                              paletteType: PaletteType.hueWheel,
                            ),
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

  void _showSpacingBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    double letter = provider.textLetterSpacing(itemId);
    double line = provider.textLineSpacing(itemId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return _textSheetContainer(
            isDark: isDark,
            height: .40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Spacing',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(modalContext),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Text('Letter spacing')),
                    Text(letter.toStringAsFixed(1)),
                  ],
                ),
                Slider(
                  value: letter.clamp(-2.0, 20.0),
                  min: -2,
                  max: 20,
                  activeColor: Colors.red,
                  onChanged: (v) {
                    setModalState(() => letter = v);
                    provider.updateTextLetterSpacing(itemId, v);
                  },
                ),
                Row(
                  children: [
                    const Expanded(child: Text('Line spacing')),
                    Text(line.toStringAsFixed(1)),
                  ],
                ),
                Slider(
                  value: line.clamp(.7, 3.0),
                  min: .7,
                  max: 3,
                  activeColor: Colors.red,
                  onChanged: (v) {
                    setModalState(() => line = v);
                    provider.updateTextLineSpacing(itemId, v);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAlignBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _textSheetContainer(
        isDark: isDark,
        height: .30,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Alignment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(modalContext),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _alignmentButton(
                  modalContext,
                  provider,
                  itemId,
                  TextAlign.left,
                  Icons.format_align_left_rounded,
                  'Left',
                ),
                _alignmentButton(
                  modalContext,
                  provider,
                  itemId,
                  TextAlign.center,
                  Icons.format_align_center_rounded,
                  'Center',
                ),
                _alignmentButton(
                  modalContext,
                  provider,
                  itemId,
                  TextAlign.right,
                  Icons.format_align_right_rounded,
                  'Right',
                ),
                _alignmentButton(
                  modalContext,
                  provider,
                  itemId,
                  TextAlign.justify,
                  Icons.format_align_justify_rounded,
                  'Justify',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _alignmentButton(
    BuildContext context,
    EditorProvider provider,
    String id,
    TextAlign alignment,
    IconData icon,
    String label,
  ) {
    final selected = provider.textAlignment(id) == alignment;
    return InkWell(
      onTap: () {
        provider.updateTextAlignment(id, alignment);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Icon(
            icon,
            color: selected ? Colors.red : Colors.grey.shade700,
            size: 30,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: selected ? Colors.red : null),
          ),
        ],
      ),
    );
  }

  void _showTextOrderBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _textSheetContainer(
        isDark: isDark,
        height: .28,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Layer Order',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(modalContext),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.bringToFront(itemId);
                      Navigator.pop(modalContext);
                    },
                    icon: const Icon(Icons.flip_to_front),
                    label: const Text('Bring Front'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.sendToBack(itemId);
                      Navigator.pop(modalContext);
                    },
                    icon: const Icon(Icons.flip_to_back),
                    label: const Text('Send Back'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  void _showFormatBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    final item = provider.items.firstWhere(
      (e) => e.id == itemId,
      orElse: () => provider.items.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.45,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Format",
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(
                        "Text Size",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      AppText("${item.fontSize.toInt()}"),
                    ],
                  ),
                  Slider(
                    value: item.fontSize,
                    min: 10.0,
                    max: 100.0,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setModalState(() {
                        provider.updateFontSize(itemId, val);
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(
                        "Transparency",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      AppText("${((item.opacity) * 100).toStringAsFixed(0)}%"),
                    ],
                  ),
                  Slider(
                    value: item.opacity,
                    min: 0.0,
                    max: 1.0,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setModalState(() {
                        provider.updateOpacity(itemId, val);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _formatToggle(
                        icon: Icons.format_bold_rounded,
                        label: 'Bold',
                        selected:
                            provider.textWeight(itemId) == FontWeight.bold,
                        onTap: () {
                          provider.toggleTextBold(itemId);
                          setModalState(() {});
                        },
                      ),
                      _formatToggle(
                        icon: Icons.format_italic_rounded,
                        label: 'Italic',
                        selected:
                            provider.textStyle(itemId) == FontStyle.italic,
                        onTap: () {
                          provider.toggleTextItalic(itemId);
                          setModalState(() {});
                        },
                      ),
                      _formatToggle(
                        icon: Icons.format_underline_rounded,
                        label: 'Underline',
                        selected: provider.textUnderline(itemId),
                        onTap: () {
                          provider.toggleTextUnderline(itemId);
                          setModalState(() {});
                        },
                      ),
                      _formatToggle(
                        icon: Icons.text_fields_rounded,
                        label: 'Normal',
                        selected:
                            provider.textWeight(itemId) == FontWeight.normal &&
                            provider.textStyle(itemId) == FontStyle.normal &&
                            !provider.textUnderline(itemId),
                        onTap: () {
                          provider.setTextNormal(itemId);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  void _showImageTransparencyBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    final item = provider.items.firstWhere(
      (e) => e.id == itemId,
      orElse: () => provider.items.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.25,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Transparency",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: item.opacity,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            setModalState(() {
                              provider.updateOpacity(itemId, val);
                            });
                          },
                        ),
                      ),
                      AppText(
                        "${((item.opacity) * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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

  void _showMediaBottomSheet(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    int selectedTab = 1; // 0 uploads, 1 elements, 2 stickers
    String? expandedCategory;
    bool sheetOpen = true;
    final searchController = TextEditingController();

    const categories = <Map<String, String>>[
      {'title': 'Shapes', 'query': 'shapes'},
      {'title': 'Stickers', 'query': 'stickers'},
      {'title': 'Social Media', 'query': 'social media icons'},
      {'title': 'E-commerce', 'query': 'ecommerce shopping'},
    ];

    void loadCategory(String query, void Function(void Function()) setState) {
      if (provider.elementCategoryAssets(query).isNotEmpty ||
          provider.isElementCategoryLoading(query)) {
        return;
      }

      provider.fetchElementCategory(query).then((_) {
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

            Widget elementCard(String url) {
              return GestureDetector(
                onTap: () {
                  provider.addImage(url, isLocal: false);
                  Navigator.pop(modalContext);
                },
                child: Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF24262B)
                        : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE8E8E8),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    url,
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
                  ),
                ),
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
                        loadCategory(query, setSheetState);
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
              final items = provider.elementCategoryAssets(query);
              final preview = items.take(4).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  categoryTitle(title, query),
                  SizedBox(
                    height: 58,
                    child: provider.isElementCategoryLoading(query)
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                              ),
                            ),
                          )
                        : preview.isEmpty
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
                            children: preview
                                .map(
                                  (url) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: elementCard(url),
                                    ),
                                  ),
                                )
                                .toList(),
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
                final items = provider.elementCategoryAssets(query);
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
                      child: provider.isElementCategoryLoading(query)
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
                              itemCount: items.length,
                              itemBuilder: (_, index) =>
                                  elementCard(items[index]),
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

            Widget stickersView() {
              final stickers = provider.freePikStickers;
              if (!provider.isStickersLoading && stickers.isEmpty) {
                Future.microtask(
                  () => provider.fetchFreePikStickers('stickers'),
                );
              }
              if (provider.isStickersLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return Column(
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
                      onChanged: (value) => provider.fetchFreePikStickers(
                        value.isEmpty ? 'stickers' : value,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search stickers...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: stickers.length,
                      itemBuilder: (_, index) => elementCard(stickers[index]),
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
                              title: 'STICKERS',
                              selected: selectedTab == 2,
                              onTap: () => setSheetState(() => selectedTab = 2),
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
                            : stickersView(),
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
    String searchQuery = 'abstract background';
    bool sheetOpen = true;
    bool backgroundRequestStarted = false;
    final searchController = TextEditingController(text: searchQuery);

    const chips = <String>[
      'Abstract background',
      'Gradient',
      'Soft background',
      'Minimal',
      'Nature',
      'Texture',
    ];

    void fetchImages(String query, void Function(void Function()) setState) {
      final value = query.trim().isEmpty ? 'abstract background' : query.trim();
      searchQuery = value;
      setState(() {});

      provider.fetchBackgroundAssets(value).then((_) {
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

            Widget searchBox() {
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
                  controller: searchController,
                  onSubmitted: (value) => fetchImages(value, setSheetState),
                  onChanged: (value) {
                    searchQuery = value;
                    setSheetState(() {});
                  },
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF222222),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search backgrounds...',
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
                      onPressed: () =>
                          fetchImages(searchController.text, setSheetState),
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
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey),
                    ),
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

              final items = provider.backgroundAssets.take(24).toList();
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
              if (!provider.isVideosLoading && provider.freePikVideos.isEmpty) {
                Future.microtask(
                  () => provider.fetchFreePikVideos('background'),
                );
              }
              if (provider.isVideosLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (provider.freePikVideos.isEmpty) {
                return const Center(
                  child: Text(
                    'No videos found',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .78,
                ),
                itemCount: provider.freePikVideos.length,
                itemBuilder: (_, index) {
                  final videoUrl = provider.freePikVideos[index];
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
                        provider.setBackgroundVideo(videoUrl);
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill_rounded, size: 44),
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
                        child: searchBox(),
                      ),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          scrollDirection: Axis.horizontal,
                          children: chips.map(chip).toList(),
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

    double aspectRatio = 1 / 1;
    if (widget.resizeSize.contains("4:5")) {
      aspectRatio = 4 / 5;
    } else if (widget.resizeSize.contains("9:16")) {
      aspectRatio = 9 / 16;
    } else if (widget.resizeSize.contains("Horizontal")) {
      aspectRatio = 1200 / 628;
    }

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
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double scaleX = constraints.maxWidth / 1080;
                    double scaleY = constraints.maxHeight / 1080;

                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Background is rendered exactly once. Full-canvas background
                        // items are excluded from the normal editable-item stack below.
                        // Background image/video remains editable after it is set.
                        // Tap any empty area of the canvas to select the background.
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              final backgrounds = provider.items
                                  .where(_isCanvasBackground)
                                  .toList();
                              if (backgrounds.isNotEmpty) {
                                final bg = backgrounds.last;
                                provider.setSelectedItem(bg.type, bg.id);
                                // Use the same premium editor sheet for the
                                // full-canvas background and normal images.
                                EditableItemWidget.showUnifiedImageActions(
                                  context,
                                  provider,
                                  bg,
                                );
                              }
                            },
                            child: _buildCanvasBackground(provider),
                          ),
                        ),

                        // Show selection border when the background is selected.
                        if (provider.selectedItemId != null &&
                            provider.items.any(
                              (item) =>
                                  item.id == provider.selectedItemId &&
                                  _isCanvasBackground(item),
                            ))
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ...provider.items.where((item) => !_isCanvasBackground(item)).map((
                          item,
                        ) {
                          return Positioned(
                            left: item.position.dx * scaleX,
                            top: item.position.dy * scaleY,
                            child: Transform.scale(
                              scale: scaleX,
                              alignment: Alignment.topLeft,
                              // Do not impose item.width on the editor widget.
                              // Images already have their own width/height, while
                              // text needs intrinsic width so changing font size
                              // changes the actual text box size.
                              child: EditableItemWidget(
                                item: item,
                                onItemSelected: (type, id) {
                                  provider.setSelectedItem(type, id);
                                },
                              ),
                            ),
                          );
                        }),

                        // 3. Frame Layer
                        if (provider.selectedFrameUrl != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Image.asset(
                                provider.selectedFrameUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child:
            provider.selectedItemType == 'textbox' ||
                provider.selectedItemType == 'text'
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showFontFamilyBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.font_download_rounded,
                      "FONT",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showFormatBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.text_format_rounded,
                      "FORMAT",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showSpacingBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.space_bar_rounded,
                      "SPACING",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showFontColorBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.color_lens_rounded,
                      "COLOR",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showAlignBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.format_align_left_rounded,
                      "ALIGN",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showTextOrderBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(Icons.layers_rounded, "ORDER"),
                  ),
                  InkWell(
                    onTap: () {
                      provider.clearSelection();
                    },
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
              )
            : provider.selectedItemType == 'image'
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Replace selected image as the background.
                  InkWell(
                    onTap: () {
                      final currentId = provider.selectedItemId;
                      if (currentId == null) return;
                      final selectedItem =
                          provider.items.where((e) => e.id == currentId).isEmpty
                          ? null
                          : provider.items.firstWhere((e) => e.id == currentId);
                      final imageUrl = selectedItem?.contentUrl;
                      if (selectedItem != null &&
                          selectedItem.type == 'image' &&
                          imageUrl != null &&
                          imageUrl.isNotEmpty) {
                        _confirmReplaceBackground(
                          context,
                          provider,
                          imageUrl,
                          selectedItemId: currentId,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.wallpaper_rounded,
                      "REPLACE BG",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final currentId = provider.selectedItemId;
                      if (currentId != null) {
                        _cropSelectedImage(context, provider, currentId);
                      }
                    },
                    child: _buildTextActionItem(Icons.crop_rounded, "CROP"),
                  ),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image == null) return;

                      final selected = provider.items
                          .where((e) => e.id == provider.selectedItemId)
                          .toList();

                      // If the selected image is the current background,
                      // replace the background instead of adding a small image layer.
                      if (selected.isNotEmpty &&
                          _isCanvasBackground(selected.first)) {
                        await _confirmReplaceBackground(
                          context,
                          provider,
                          image.path,
                          selectedItemId: selected.first.id,
                        );
                      } else {
                        provider.addImage(image.path, isLocal: true);
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.photo_library_rounded,
                      "PHOTOS",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showImageTransparencyBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.opacity_rounded,
                      "TRANSPARENCY",
                    ),
                  ),
                  InkWell(
                    onTap: () => provider.clearSelection(),
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
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 0);
                      _showFramesBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.layers_rounded,
                      "FRAMES",
                      _bottomNavIndex == 0,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 1);
                      _showMyBrandBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.branding_watermark_rounded,
                      "MY BRAND",
                      _bottomNavIndex == 1,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 2);
                      _showTextStylesBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.text_fields_rounded,
                      "TEXT",
                      _bottomNavIndex == 2,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 3);
                      _showMediaBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.photo_library_rounded,
                      "MEDIA",
                      _bottomNavIndex == 3,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 4);
                      _showBackgroundBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.wallpaper_rounded,
                      "BACKGROUND",
                      _bottomNavIndex == 4,
                    ),
                  ),
                ],
              ),
      ),
    );
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

      // Use the Android/iOS system share/save sheet. This avoids the old
      // image_gallery_saver_plus Android Registrar compatibility problem.
      if (!context.mounted) return;
      /* await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'MMB Design PNG',
        text: 'Save this MMB design image.',
      );*/
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
      /*await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'MMB Editor JSON',
        text: 'Exported MMB editor page JSON.',
      );*/
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
