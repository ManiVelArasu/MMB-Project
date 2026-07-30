import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/plugins/emoji_picker_flutter/src/config.dart' hide Config;
import 'package:pro_image_editor/plugins/emoji_picker_flutter/src/emoji_picker.dart' hide EmojiPicker;
import 'package:project_mmb/utils/theme/app.colors.dart';
import 'package:provider/provider.dart';
import '../../Api Model/editor_model.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/*
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: const EditorView(),
    );
  }
}

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EditorProvider>(context, listen: false);
      provider.loadItemsFromJson([
        {
          "id": "1",
          "type": "text",
          "text": "Pro Banner",
          "position_x": 100.0,
          "position_y": 80.0,
          "font_size": 32.0,
          "color": "#FFFFFF",
        },
        {
          "id": "2",
          "type": "image",
          "content_url": "https://picsum.photos/300/300",
          "position_x": 80.0,
          "position_y": 180.0,
          "width": 220.0,
          "height": 220.0,
          "text": "rounded",
        },
      ]);
    });
  }

  void _showEmojiPicker(BuildContext context) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      builder: (context) => SizedBox(
        height: 300,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            parentContext.read<EditorProvider>().addEmoji(emoji.emoji);
            Navigator.pop(context);
          },
          config: const Config(height: 256),
        ),
      ),
    );
  }

  void _showStickerPicker(BuildContext context) {
    final parentContext = context;
    final stickers = [
      'https://cdn-icons-png.flaticon.com/512/742/742751.png',
      'https://cdn-icons-png.flaticon.com/512/3177/3177440.png',
      'https://cdn-icons-png.flaticon.com/512/4282/4282252.png',
      'https://cdn-icons-png.flaticon.com/512/1039/1039356.png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Pro Sticker",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      parentContext.read<EditorProvider>().addImage(stickers[index], isLocal: false);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.network(stickers[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && context.mounted) {
      context.read<EditorProvider>().addImage(image.path, isLocal: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Pro Image Editor", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: () => provider.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.white),
            onPressed: () => provider.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.greenAccent),
            onPressed: () {
              print(provider.getItemsAsJson());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("JSON Exported to Console!")),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFFF0F2F5)),
          ...provider.items.map((item) => EditableItemWidget(item: item)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E2C),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => provider.addText(initialText: "New Text"),
                icon: const Icon(Icons.text_fields, color: Colors.blueAccent),
                label: const Text("Text", style: TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => _pickImageFromGallery(context),
                icon: const Icon(Icons.photo, color: Colors.greenAccent),
                label: const Text("Gallery", style: TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => _showEmojiPicker(context),
                icon: const Icon(Icons.emoji_emotions, color: Colors.amberAccent),
                label: const Text("Emoji", style: TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => _showStickerPicker(context),
                icon: const Icon(Icons.star, color: Colors.purpleAccent),
                label: const Text("Stickers", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditableItemWidget extends StatelessWidget {
  final EditorItem item;
  const EditableItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EditorProvider>();

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          provider.updatePosition(item.id ?? '', item.position + details.delta);
        },
        onTap: () => _showProActionSheet(context, provider),
        child: Opacity(
          opacity: item.opacity,
          child: Transform.scale(
            scale: item.scale,
            child: Transform.rotate(
              angle: item.rotation,
              child: _buildItemContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredImage(Widget imageWidget) {
    ColorFilter? colorFilter;

    switch (item.filterType) {
      case 'grayscale':
        colorFilter = const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        break;
      case 'sepia':
        colorFilter = const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        break;
      case 'vintage':
        colorFilter = const ColorFilter.matrix(<double>[
          0.9, 0.5, 0.1, 0, 0,
          0.3, 0.8, 0.2, 0, 0,
          0.2, 0.3, 0.6, 0, 0,
          0, 0, 0, 1, 0,
        ]);
        break;
      default:
        colorFilter = null;
    }

    if (colorFilter == null) return imageWidget;

    return ColorFiltered(
      colorFilter: colorFilter,
      child: imageWidget,
    );
  }

  Widget _buildProFilteredImage(Widget imageWidget) {
    double c = item.contrast;
    double b = item.brightness;
    double s = item.saturation;

    const double rwgt = 0.3086;
    const double gwgt = 0.6094;
    const double bwgt = 0.0820;

    double baseR = (1 - s) * rwgt + s;
    double baseG = (1 - s) * gwgt;
    double baseB = (1 - s) * bwgt;

    List<double> matrix = <double>[
      c * baseR, c * baseG, c * baseB, 0, b * 255,
      c * baseG, c * baseR, c * baseG, 0, b * 255,
      c * baseB, c * baseG, c * baseR, 0, b * 255,
      0, 0, 0, 1, 0,
    ];

    Widget filtered = ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: imageWidget,
    );

    return _buildFilteredImage(filtered);
  }

  Widget _buildItemContent() {
    if (item.type == 'image') {
      bool isLocalFile = item.isLocal ||
          (item.contentUrl != null && (item.contentUrl!.startsWith('file://') || item.contentUrl!.startsWith('/data/')));

      Widget imageWidget;
      if (isLocalFile) {
        String cleanPath = item.contentUrl!.replaceFirst('file://', '');
        imageWidget = Image.file(
          File(cleanPath),
          width: item.width,
          height: item.height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: item.width,
            height: item.height,
            color: Colors.grey.shade800,
            child: const Icon(Icons.broken_image, color: Colors.white, size: 30),
          ),
        );
      } else {
        imageWidget = Image.network(
          item.contentUrl ?? "",
          width: item.width,
          height: item.height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: item.width,
            height: item.height,
            color: Colors.grey.shade800,
            child: const Icon(Icons.broken_image, color: Colors.white, size: 30),
          ),
        );
      }

      String shape = item.text ?? 'rounded';
      Widget maskedImage;

      if (shape == 'circle') {
        maskedImage = ClipOval(child: imageWidget);
      } else if (shape == 'heart') {
        maskedImage = ClipPath(clipper: HeartClipper(), child: imageWidget);
      } else if (shape == 'star') {
        maskedImage = ClipPath(clipper: StarClipper(), child: imageWidget);
      } else if (shape == 'hexagon') {
        maskedImage = ClipPath(clipper: HexagonClipper(), child: imageWidget);
      } else {
        maskedImage = ClipRRect(
          borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0),
          child: imageWidget,
        );
      }

      Widget filteredImage = _buildProFilteredImage(maskedImage);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0),
          border: item.outlineWidth > 0
              ? Border.all(color: item.outlineColor, width: item.outlineWidth)
              : null,
          //
        ),
        child: filteredImage,
      );
    } else {
      return Text(
        item.text ?? "",
        style: TextStyle(
          fontSize: item.fontSize,
          color: item.color ?? Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(2, 2))],
        ),
      );
    }
  }

  void _showProActionSheet(BuildContext context, EditorProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.6,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Pro Editing Tools", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.blueAccent),
                          tooltip: "Duplicate",
                          onPressed: () { provider.duplicateItem(item.id ?? ''); Navigator.pop(context); },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: "Delete",
                          onPressed: () { provider.removeItem(item.id ?? ''); Navigator.pop(context); },
                        ),
                      ],
                    )
                  ],
                ),
                const Divider(color: Colors.white24),

                Expanded(
                  child: ListView(
                    children: [
                      if (item.type == 'image') ...[
                        const Text("Photo Filters", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _filterButton(provider, 'Normal', 'normal', setModalState),
                            _filterButton(provider, 'Gray', 'grayscale', setModalState),
                            _filterButton(provider, 'Sepia', 'sepia', setModalState),
                            _filterButton(provider, 'Vintage', 'vintage', setModalState),
                          ],
                        ),
                        const Divider(color: Colors.white24),
                        const Text("Pro Color Adjustments", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                        const SizedBox(height: 6),

                        const Text("Brightness", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: item.brightness,
                          min: -0.5,
                          max: 0.5,
                          activeColor: Colors.blueAccent,
                          onChanged: (val) {
                            setModalState(() => provider.updateImageColorAdjustments(item.id ?? "", brightness: val));
                          },
                        ),

                        const Text("Contrast", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: item.contrast,
                          min: 0.5,
                          max: 1.5,
                          activeColor: Colors.greenAccent,
                          onChanged: (val) {
                            setModalState(() => provider.updateImageColorAdjustments(item.id ?? "", contrast: val));
                          },
                        ),

                        const Text("Saturation", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: item.saturation,
                          min: 0.0,
                          max: 2.0,
                          activeColor: Colors.purpleAccent,
                          onChanged: (val) {
                            setModalState(() => provider.updateImageColorAdjustments(item.id ?? "", saturation: val));
                          },
                        ),
                        const Divider(color: Colors.white24),
                        const Text("Image Mask / Shape", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(icon: const Icon(Icons.circle, color: Colors.white), onPressed: () { provider.setImageShape(item.id ?? '', 'circle'); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.crop_square, color: Colors.white), onPressed: () { provider.setImageShape(item.id ?? '', 'rounded', radius: 24.0); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.favorite, color: Colors.redAccent), onPressed: () { provider.setImageShape(item.id ?? '', 'heart'); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () { provider.setImageShape(item.id ?? '', 'star'); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.hexagon, color: Colors.purpleAccent), onPressed: () { provider.setImageShape(item.id ?? '', 'hexagon'); Navigator.pop(context); }),
                          ],
                        ),
                        const Divider(color: Colors.white24),
                      ],

                      const Text("Rotation", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: item.rotation,
                        min: 0.0,
                        max: 6.28,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateRotation(item.id ?? '', val));
                        },
                      ),

                      const Text("Zoom / Scale", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: item.scale,
                        min: 0.5,
                        max: 3.0,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateScale(item.id ?? '', val));
                        },
                      ),

                      const Text("Opacity", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: item.opacity,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.purpleAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateOpacity(item.id ?? '', val));
                        },
                      ),

                      const Text("Alignment", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A3D)),
                            icon: const Icon(Icons.align_horizontal_center, size: 16),
                            label: const Text("Center H"),
                            onPressed: () { provider.alignItem(item.id ?? '', 'center_h'); Navigator.pop(context); },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A3D)),
                            icon: const Icon(Icons.align_vertical_center, size: 16),
                            label: const Text("Center V"),
                            onPressed: () { provider.alignItem(item.id ?? '', 'center_v'); Navigator.pop(context); },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      const Text("Outline Border", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () { provider.updateOutline(item.id ?? '', 4.0, Colors.white); Navigator.pop(context); },
                            child: const Text("White Border", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () { provider.updateOutline(item.id ?? '', 4.0, Colors.amber); Navigator.pop(context); },
                            child: const Text("Gold Border", style: TextStyle(color: Colors.amber)),
                          ),
                          TextButton(
                            onPressed: () { provider.updateOutline(item.id ?? '', 0.0, Colors.transparent); Navigator.pop(context); },
                            child: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),

                      const Divider(color: Colors.white24),

                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.flip_to_front, color: Colors.blueAccent),
                        title: const Text("Bring to Front", style: TextStyle(color: Colors.white)),
                        onTap: () { provider.bringToFront(item.id ?? ''); Navigator.pop(context); },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.flip_to_back, color: Colors.orangeAccent),
                        title: const Text("Send to Back", style: TextStyle(color: Colors.white)),
                        onTap: () { provider.sendToBack(item.id ?? ''); Navigator.pop(context); },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterButton(EditorProvider provider, String label, String type, StateSetter setModalState) {
    return TextButton(
      onPressed: () {
        setModalState(() {
          provider.setImageFilter(item.id ?? "", type);
        });
      },
      child: Text(
        label,
        style: TextStyle(color: item.filterType == type ? Colors.amber : Colors.white70),
      ),
    );
  }
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

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double w = size.width, h = size.height;
    path.moveTo(w * 0.25, 0);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.75, h);
    path.lineTo(w * 0.25, h);
    path.lineTo(0, h * 0.5);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
*/
