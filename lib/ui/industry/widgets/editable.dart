import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../Api Model/editor_model.dart';
import '../../../network/provider/editor_provider.dart' hide EditorItem;
class EditableItemWidget extends StatelessWidget {
  final EditorItem item;
  const EditableItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // 🚀 1. Provider-ai watch panna thaan state changes (sliders, filters, shapes) instant-ah UI-la reflect aagum
    final provider = context.watch<EditorProvider>();

    // 🚀 2. Get latest live item from provider list using ID
    final currentItem = provider.items.firstWhere(
          (element) => element.id == item.id,
      orElse: () => item,
    );

    return Positioned(
      left: currentItem.position.dx,
      top: currentItem.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          provider.updatePosition(currentItem.id??"", currentItem.position + details.delta);
        },
        onTap: () => _showProActionSheet(context, provider, currentItem),
        child: Opacity(
          opacity: currentItem.opacity,
          child: Transform.scale(
            scale: currentItem.scale,
            child: Transform.rotate(
              angle: currentItem.rotation,
              child: _buildItemContent(currentItem),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredImage(EditorItem item, Widget imageWidget) {
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

  Widget _buildProFilteredImage(EditorItem item, Widget imageWidget) {
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

    return _buildFilteredImage(item, filtered);
  }

  Widget _buildItemContent(EditorItem item) {
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

      Widget filteredImage = _buildProFilteredImage(item, maskedImage);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0),
          border: item.outlineWidth > 0
              ? Border.all(color: item.outlineColor, width: item.outlineWidth)
              : null,
         
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

  void _showProActionSheet(BuildContext context, EditorProvider provider, EditorItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // 🚀 3. Get latest item inside bottom sheet too
          final currentItem = provider.items.firstWhere((e) => e.id == item.id, orElse: () => item);

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
                          onPressed: () { provider.duplicateItem(currentItem.id??""); Navigator.pop(context); },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: "Delete",
                          onPressed: () { provider.removeItem(currentItem.id??""); Navigator.pop(context); },
                        ),
                      ],
                    )
                  ],
                ),
                const Divider(color: Colors.white24),

                Expanded(
                  child: ListView(
                    children: [
                      if (currentItem.type == 'image') ...[
                        const Text("Photo Filters", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _filterButton(provider, currentItem, 'Normal', 'normal', setModalState),
                            _filterButton(provider, currentItem, 'Gray', 'grayscale', setModalState),
                            _filterButton(provider, currentItem, 'Sepia', 'sepia', setModalState),
                            _filterButton(provider, currentItem, 'Vintage', 'vintage', setModalState),
                          ],
                        ),
                        const Divider(color: Colors.white24),
                        const Text("Pro Color Adjustments", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                        const SizedBox(height: 6),

                        const Text("Brightness", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: currentItem.brightness,
                          min: -0.5,
                          max: 0.5,
                          activeColor: Colors.blueAccent,
                          onChanged: (val) {
                            setModalState(() => provider.updateImageColorAdjustments(currentItem.id??"", brightness: val));
                          },
                        ),

                        const Text("Contrast", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: currentItem.contrast,
                          min: 0.5,
                          max: 1.5,
                          activeColor: Colors.greenAccent,
                          onChanged: (val) {
                            setModalState(() => provider.updateImageColorAdjustments(currentItem.id??"", contrast: val));
                          },
                        ),

                        const Text("Saturation", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: currentItem.saturation,
                          min: 0.0,
                          max: 2.0,
                          activeColor: Colors.purpleAccent,
                          onChanged: (val) {
                            setModalState(() => provider.updateImageColorAdjustments(currentItem.id??"", saturation: val));
                          },
                        ),
                        const Divider(color: Colors.white24),
                        const Text("Image Mask / Shape", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(icon: const Icon(Icons.circle, color: Colors.white), onPressed: () { provider.setImageShape(currentItem.id??"", 'circle'); }),
                            IconButton(icon: const Icon(Icons.crop_square, color: Colors.white), onPressed: () { provider.setImageShape(currentItem.id??"", 'rounded', radius: 24.0); }),
                            IconButton(icon: const Icon(Icons.favorite, color: Colors.redAccent), onPressed: () { provider.setImageShape(currentItem.id??"", 'heart'); }),
                            IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () { provider.setImageShape(currentItem.id??"", 'star'); }),
                            IconButton(icon: const Icon(Icons.hexagon, color: Colors.purpleAccent), onPressed: () { provider.setImageShape(currentItem.id??"", 'hexagon'); }),
                          ],
                        ),
                        const Divider(color: Colors.white24),
                      ],

                      const Text("Rotation", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: currentItem.rotation,
                        min: 0.0,
                        max: 6.28,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateRotation(currentItem.id??"", val));
                        },
                      ),

                      const Text("Zoom / Scale", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: currentItem.scale,
                        min: 0.5,
                        max: 3.0,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateScale(currentItem.id??"", val));
                        },
                      ),

                      const Text("Opacity", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: currentItem.opacity,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.purpleAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateOpacity(currentItem.id??"", val));
                        },
                      ),

                      const Text("Alignment", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          /*ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A3D)),
                            icon: const Icon(Icons.align_horizontal_center, size: 16),
                            label: const Text("Center H"),
                            onPressed: () { provider.alignItem(currentItem.id??"", 'center_h'); },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A3D)),
                            icon: const Icon(Icons.align_vertical_center, size: 16),
                            label: const Text("Center V"),
                            onPressed: () { provider.alignItem(currentItem.id??"", 'center_v'); },
                          ),*/
                        ],
                      ),
                      const SizedBox(height: 10),

                      const Text("Outline Border", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () { provider.updateOutline(currentItem.id??"", 4.0, Colors.white); },
                            child: const Text("White", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () { provider.updateOutline(currentItem.id??"", 4.0, Colors.amber); },
                            child: const Text("Gold", style: TextStyle(color: Colors.amber)),
                          ),
                          TextButton(
                            onPressed: () { provider.updateOutline(currentItem.id??"", 0.0, Colors.transparent); },
                            child: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),

                      const Divider(color: Colors.white24),

                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.flip_to_front, color: Colors.blueAccent),
                        title: const Text("Bring to Front", style: TextStyle(color: Colors.white)),
                        onTap: () { provider.bringToFront(currentItem.id??""); },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.flip_to_back, color: Colors.orangeAccent),
                        title: const Text("Send to Back", style: TextStyle(color: Colors.white)),
                        onTap: () { provider.sendToBack(currentItem.id??""); },
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

  Widget _filterButton(EditorProvider provider, EditorItem item, String label, String type, StateSetter setModalState) {
    return TextButton(
      onPressed: () {
        setModalState(() {
          provider.setImageFilter(item.id??"", type);
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

