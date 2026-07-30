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
    final provider = context.read<EditorProvider>();

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          provider.updatePosition(item.id??'', item.position + details.delta);
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

      // 🚀 Outline & Border Application
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0),
          border: item.outlineWidth > 0
              ? Border.all(color: item.outlineColor, width: item.outlineWidth)
              : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: maskedImage,
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

  // 🚀 Comprehensive Pro Action Sheet (Rotation, Zoom, Duplicate, Outline, Alignment, Opacity)
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
                    // Duplicate & Delete Quick Actions
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.blueAccent),
                          tooltip: "Duplicate",
                          onPressed: () { provider.duplicateItem(item.id??''); Navigator.pop(context); },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: "Delete",
                          onPressed: () { provider.removeItem(item.id??''); Navigator.pop(context); },
                        ),
                      ],
                    )
                  ],
                ),
                const Divider(color: Colors.white24),

                Expanded(
                  child: ListView(
                    children: [
                      // 1. Image Shapes
                      if (item.type == 'image') ...[
                        const Text("Image Mask / Shape", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(icon: const Icon(Icons.circle, color: Colors.white), onPressed: () { provider.setImageShape(item.id??'', 'circle'); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.crop_square, color: Colors.white), onPressed: () { provider.setImageShape(item.id??'', 'rounded', radius: 24.0); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.favorite, color: Colors.redAccent), onPressed: () { provider.setImageShape(item.id??'', 'heart'); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () { provider.setImageShape(item.id??'', 'star'); Navigator.pop(context); }),
                            IconButton(icon: const Icon(Icons.hexagon, color: Colors.purpleAccent), onPressed: () { provider.setImageShape(item.id??'', 'hexagon'); Navigator.pop(context); }),
                          ],
                        ),
                        const Divider(color: Colors.white24),
                      ],

                      // 2. Rotation Slider (0 to 360 deg)
                      const Text("Rotation", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: item.rotation,
                        min: 0.0,
                        max: 6.28, // 2 * PI
                        activeColor: Colors.blueAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateRotation(item.id??'', val));
                        },
                      ),

                      // 3. Zoom / Scale Slider (0.5x to 3.0x)
                      const Text("Zoom / Scale", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: item.scale,
                        min: 0.5,
                        max: 3.0,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateScale(item.id??'', val));
                        },
                      ),

                      // 4. Opacity Slider
                      const Text("Opacity", style: TextStyle(color: Colors.white70)),
                      Slider(
                        value: item.opacity,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.purpleAccent,
                        onChanged: (val) {
                          setModalState(() => provider.updateOpacity(item.id??'', val));
                        },
                      ),

                      // 5. Alignment Options
                      const Text("Alignment", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A3D)),
                            icon: const Icon(Icons.align_horizontal_center, size: 16),
                            label: const Text("Center H"),
                            onPressed: () { provider.alignItem(item.id??'', 'center_h'); Navigator.pop(context); },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A3D)),
                            icon: const Icon(Icons.align_vertical_center, size: 16),
                            label: const Text("Center V"),
                            onPressed: () { provider.alignItem(item.id??'', 'center_v'); Navigator.pop(context); },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 6. Outline / Border Color & Width
                      const Text("Outline Border", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () { provider.updateOutline(item.id??'', 4.0, Colors.white); Navigator.pop(context); },
                            child: const Text("White Border", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () { provider.updateOutline(item.id??'', 4.0, Colors.amber); Navigator.pop(context); },
                            child: const Text("Gold Border", style: TextStyle(color: Colors.amber)),
                          ),
                          TextButton(
                            onPressed: () { provider.updateOutline(item.id??'', 0.0, Colors.transparent); Navigator.pop(context); },
                            child: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),

                      const Divider(color: Colors.white24),

                      // 7. Layers Management
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.flip_to_front, color: Colors.blueAccent),
                        title: const Text("Bring to Front", style: TextStyle(color: Colors.white)),
                        onTap: () { provider.bringToFront(item.id??''); Navigator.pop(context); },
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.flip_to_back, color: Colors.orangeAccent),
                        title: const Text("Send to Back", style: TextStyle(color: Colors.white)),
                        onTap: () { provider.sendToBack(item.id??''); Navigator.pop(context); },
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

