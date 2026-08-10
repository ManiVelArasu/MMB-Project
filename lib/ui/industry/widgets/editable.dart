import 'dart:io';

import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:project_mmb/ui/screens/video_widget/video_widget.dart';
import 'package:provider/provider.dart';
import '../../../Api Model/editor_model.dart';
import '../../../network/provider/editor_provider.dart';
import 'package:image/image.dart' as img;

import '../../screens/video_widget/editor_video.dart';

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
    final provider = context.watch<EditorProvider>();
    final currentItem = provider.items.firstWhere(
      (e) => e.id == item.id,
      orElse: () => item,
    );

    return KeyedSubtree(
      key: ValueKey(
        "${currentItem.id}_${currentItem.filterType}_${currentItem.rotation}_${currentItem.scale}",
      ),
      child: GestureDetector(
        onPanUpdate: (details) => provider.updatePosition(
          currentItem.id!,
          currentItem.position + details.delta,
        ),
        onTap: () {
          onItemSelected(currentItem.type ?? '', currentItem.id!);
          if (currentItem.type == 'text' || currentItem.type == 'textbox') {
            _showTextEditorDialog(
              context,
              provider,
              currentItem.id ?? "",
              currentItem.text ?? "",
            );
          } else {
            _showProActionSheet(context, provider, currentItem);
          }
        },
        child: Opacity(
          opacity: currentItem.opacity,
          child: Transform.rotate(
            angle: currentItem.rotation,
            child: Transform.scale(
              scale: currentItem.scale,
              child: _buildItemContent(currentItem),
            ),
          ),
        ),
      ),
    );
  }

  // 🚀 1. பழைய பில்டர் மேட்ரிக்ஸ் லாஜிக் (Color Change ஆக இதுதான் காரணம்)
  Widget _buildFilteredImage(EditorItem item, Widget imageWidget) {
    ColorFilter? colorFilter;
    switch (item.filterType) {
      case 'grayscale':
        colorFilter = const ColorFilter.matrix(<double>[
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
        ]);
        break;
      case 'sepia':
        colorFilter = const ColorFilter.matrix(<double>[
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
        break;
      case 'vintage':
        colorFilter = const ColorFilter.matrix(<double>[
          0.9,
          0.5,
          0.1,
          0,
          0,
          0.3,
          0.8,
          0.2,
          0,
          0,
          0.2,
          0.3,
          0.6,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
        break;
      default:
        colorFilter = null;
    }
    if (colorFilter == null) return imageWidget;
    return ColorFiltered(colorFilter: colorFilter, child: imageWidget);
  }

  Widget _buildItemContent(EditorItem item) {
    if (item.type == 'image') {
      bool isLocalFile =
          item.isLocal ||
          (item.contentUrl != null &&
              (item.contentUrl!.startsWith('file://') ||
                  item.contentUrl!.startsWith('/data/')));

      Widget imageWidget = isLocalFile
          ? Image.file(
              File(item.contentUrl!.replaceFirst('file://', '')),
              width: item.width,
              height: item.height,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: item.width,
                height: item.height,
                color: Colors.grey,
                child: const Icon(Icons.broken_image),
              ),
            )
          : Image.network(
              item.contentUrl ?? "",
              width: item.width,
              height: item.height,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: item.width,
                height: item.height,
                color: Colors.grey.shade900,
                child: const Icon(Icons.wifi_off, color: Colors.amber),
              ),
            );

      // Shape Masking (Circle or Rounded Square)
      Widget maskedImage;
      if (item.type == 'video') {
        return BrandVideoCard(
          videoUrl: item.contentUrl ?? '',
          thumbnailUrl: '',
        );
      }
      if (item.text == 'circle') {
        maskedImage = ClipOval(child: imageWidget);
      } else {
        maskedImage = ClipRRect(
          borderRadius: BorderRadius.circular(
            item.borderRadius > 0 ? item.borderRadius : 16.0,
          ),
          child: imageWidget,
        );
      }

      // 🚀 பில்டரை இமேஜுடன் இணைத்தல்
      Widget filteredImage = _buildFilteredImage(item, maskedImage);

      return Container(
        decoration: BoxDecoration(
          borderRadius: item.text == 'circle'
              ? null
              : BorderRadius.circular(
                  item.borderRadius > 0 ? item.borderRadius : 16.0,
                ),
          shape: item.text == 'circle' ? BoxShape.circle : BoxShape.rectangle,
          border: item.outlineWidth > 0
              ? Border.all(color: item.outlineColor, width: item.outlineWidth)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: filteredImage,
      );
    } else {
      return SizedBox(
        width: item.width ?? 450,
        child: Text(
          item.text ?? "",
          style: TextStyle(
            fontSize: item.fontSize,
            color: item.color ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
          softWrap: true,
        ),
      );
    }
  }

  void _showProActionSheet(
    BuildContext context,
    EditorProvider provider,
    EditorItem item,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final currentItem = provider.items.firstWhere(
                (e) => e.id == item.id,
                orElse: () => item,
              );

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Pro Editing Tools",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: "Bring to Front",
                                    icon: const Icon(
                                      Icons.flip_to_front,
                                      color: Colors.amberAccent,
                                    ),
                                    onPressed: () => provider.bringToFront(
                                      currentItem.id ?? "",
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "Send to Back",
                                    icon: const Icon(
                                      Icons.flip_to_back,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () => provider.sendToBack(
                                      currentItem.id ?? "",
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "Duplicate",
                                    icon: const Icon(
                                      Icons.copy,
                                      color: Colors.greenAccent,
                                    ),
                                    onPressed: () => provider.duplicateItem(
                                      currentItem.id ?? "",
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      provider.removeItem(currentItem.id ?? "");
                                      Navigator.pop(modalContext);
                                    },
                                  ),
                                  const Text(
                                    "Crop / Size",
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  const Divider(color: Colors.white24),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24),

                      Expanded(
                        child: ListView(
                          children: [
                            if (currentItem.type == 'image') ...[
                              const Text(
                                "Photo Filters",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  _filterButton(
                                    provider,
                                    currentItem,
                                    'Normal',
                                    'normal',
                                    setModalState,
                                  ),
                                  _filterButton(
                                    provider,
                                    currentItem,
                                    'Gray',
                                    'grayscale',
                                    setModalState,
                                  ),
                                  _filterButton(
                                    provider,
                                    currentItem,
                                    'Sepia',
                                    'sepia',
                                    setModalState,
                                  ),
                                  _filterButton(
                                    provider,
                                    currentItem,
                                    'Vintage',
                                    'vintage',
                                    setModalState,
                                  ),
                                ],
                              ),
                              const Text(
                                "Manual Crop",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amberAccent,
                                ),
                                icon: const Icon(
                                  Icons.crop,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  "Crop by Touch",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(
                                    modalContext,
                                  ); // Bottom sheet-ஐ க்ளோஸ் செய்துவிட்டு Crop Screen போகும்
                                  _openCropScreen(
                                    context,
                                    provider,
                                    currentItem,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Shapes",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.crop_square,
                                      color: currentItem.text == 'square'
                                          ? Colors.amber
                                          : Colors.white,
                                    ),
                                    onPressed: () => setModalState(
                                      () => provider.updateImageShape(
                                        currentItem.id!,
                                        'square',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.circle,
                                      color: currentItem.text == 'circle'
                                          ? Colors.amber
                                          : Colors.white,
                                    ),
                                    onPressed: () => setModalState(
                                      () => provider.updateImageShape(
                                        currentItem.id!,
                                        'circle',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                "Outline Width",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Slider(
                                value: currentItem.outlineWidth,
                                min: 0.0,
                                max: 20.0,
                                activeColor: Colors.amberAccent,
                                onChanged: (v) => setModalState(
                                  () => provider.updateOutline(
                                    currentItem.id!,
                                    v,
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const Divider(color: Colors.white24),
                            ],

                            const Text(
                              "Zoom / Scale",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Slider(
                              value: currentItem.scale,
                              min: 0.5,
                              max: 3.0,
                              activeColor: Colors.greenAccent,
                              onChanged: (v) => setModalState(
                                () => provider.updateScale(
                                  currentItem.id ?? "",
                                  v,
                                ),
                              ),
                            ),
                            const Text(
                              "Rotation",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Slider(
                              value: currentItem.rotation,
                              min: 0.0,
                              max: 6.28,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) => setModalState(
                                () => provider.updateRotation(
                                  currentItem.id ?? "",
                                  v,
                                ),
                              ),
                            ),
                            const Text(
                              "Opacity",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Slider(
                              value: currentItem.opacity,
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.purpleAccent,
                              onChanged: (v) => setModalState(
                                () => provider.updateOpacity(
                                  currentItem.id ?? "",
                                  v,
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
          ),
        );
      },
    );
  }

  Widget _cropButton(
    EditorProvider provider,
    EditorItem item,
    String label,
    double w,
    double h,
  ) {
    return TextButton(
      onPressed: () => provider.updateSize(item.id!, w, h),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _filterButton(
    EditorProvider provider,
    EditorItem item,
    String label,
    String type,
    StateSetter setModalState,
  ) {
    return TextButton(
      onPressed: () =>
          setModalState(() => provider.setImageFilter(item.id ?? "", type)),
      child: Text(
        label,
        style: TextStyle(
          color: item.filterType == type ? Colors.amber : Colors.white70,
        ),
      ),
    );
  }

  void _showTextEditorDialog(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    String initialText,
  ) {
    final TextEditingController textController = TextEditingController(
      text: initialText,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text(
            "Edit Text",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: "Type text here...",
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
              ),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  provider.updateTextContent(itemId, textController.text);
                }
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
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
  }

  Future<void> _openCropScreen(
    BuildContext context,
    EditorProvider provider,
    EditorItem item,
  ) async {
    final GlobalKey<ExtendedImageEditorState> editorKey =
        GlobalKey<ExtendedImageEditorState>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              "Crop Image",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.check,
                  color: Colors.amberAccent,
                  size: 28,
                ),
                onPressed: () async {
                  final state = editorKey.currentState;
                  if (state != null) {
                    // 🚀 ராவ் டேட்டாவை (Raw Bytes) பாதுகாப்பாக எடுத்தல்
                    final Uint8List? rawImage = state.rawImageData;
                    final Rect? rect = state.getCropRect();

                    if (rawImage != null && rect != null) {
                      // இமேஜைக் கிராப் செய்யும் ஹெல்பர் மெத்தட்
                      final croppedData = await _cropImageBytes(rawImage, rect);

                      if (croppedData != null) {
                        final tempDir = Directory.systemTemp;
                        final file = File(
                          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );
                        await file.writeAsBytes(croppedData);

                        // Provider-ல் கிராப் செய்த புதிய ஃபைல் பாথ்சை அனுப்புதல்
                        provider.updateCroppedImage(item.id!, file.path);
                        Navigator.pop(context);
                      }
                    }
                  }
                },
              ),
            ],
          ),
          body: Center(
            child:
                (item.isLocal ||
                    (item.contentUrl != null &&
                        item.contentUrl!.startsWith('/')))
                ? ExtendedImage.file(
                    File(item.contentUrl!.replaceFirst('file://', '')),
                    fit: BoxFit.contain,
                    mode: ExtendedImageMode.editor,
                    extendedImageEditorKey: editorKey,
                    cacheRawData: true, // 🚀 லோக்கல் ஃபைலுக்கும் இது அவசியம்
                  )
                : ExtendedImage.network(
                    item.contentUrl ?? "",
                    fit: BoxFit.contain,
                    mode: ExtendedImageMode.editor,
                    extendedImageEditorKey: editorKey,
                    cacheRawData: true, // 🚀 நெட்வொர்க் இமேஜிற்கு இது கட்டாயம்
                  ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _cropImageBytes(Uint8List rawBytes, Rect rect) async {
    try {
      img.Image? src = img.decodeImage(rawBytes);
      if (src == null) return null;

      // சேஃப் ரெக்டாங்கிள் பவுண்டரி செக் (Index out of bounds வராமல் இருக்க)
      int x = rect.left.toInt().clamp(0, src.width);
      int y = rect.top.toInt().clamp(0, src.height);
      int w = rect.width.toInt().clamp(1, src.width - x);
      int h = rect.height.toInt().clamp(1, src.height - y);

      img.Image cropped = img.copyCrop(src, x: x, y: y, width: w, height: h);
      return Uint8List.fromList(img.encodeJpg(cropped));
    } catch (e) {
      debugPrint("Crop Error: $e");
      return null;
    }
  }
}

// 🚀 Hexagon Clipper
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width, h = size.height;
    path.moveTo(w / 2, h / 5);
    path.cubicTo(w * 5 / 6, 0, w, h / 3, w, h / 2);
    path.cubicTo(w, h * 3 / 4, w / 2, h, w / 2, h);
    path.cubicTo(w / 2, h, 0, h * 3 / 4, 0, h / 2);
    path.cubicTo(0, h / 3, w / 6, 0, w / 2, h / 5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width, h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w * 0.65, h * 0.35);
    path.lineTo(w, h * 0.4);
    path.lineTo(w * 0.75, h * 0.65);
    path.lineTo(w * 0.82, h);
    path.lineTo(w * 0.5, h * 0.8);
    path.lineTo(w * 0.18, h);
    path.lineTo(w * 0.25, h * 0.65);
    path.lineTo(0, h * 0.4);
    path.lineTo(w * 0.35, h * 0.35);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ShapeClipper extends CustomClipper<Path> {
  final String shape;
  ShapeClipper(this.shape);

  @override
  Path getClip(Size size) {
    Path path = Path();
    switch (shape) {
      case 'circle':
        path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
        break;
      case 'hexagon':
        path.moveTo(size.width * 0.5, 0);
        path.lineTo(size.width, size.height * 0.25);
        path.lineTo(size.width, size.height * 0.75);
        path.lineTo(size.width * 0.5, size.height);
        path.lineTo(0, size.height * 0.75);
        path.lineTo(0, size.height * 0.25);
        path.close();
        break;
      case 'heart':
        path.moveTo(size.width * 0.5, size.height * 0.8);
        path.cubicTo(
          0,
          size.height * 0.2,
          size.width * 0.3,
          -size.height * 0.1,
          size.width * 0.5,
          size.height * 0.3,
        );
        path.cubicTo(
          size.width * 0.7,
          -size.height * 0.1,
          size.width,
          size.height * 0.2,
          size.width * 0.5,
          size.height * 0.8,
        );
        path.close();
        break;
      default: // Square / Rounded
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
