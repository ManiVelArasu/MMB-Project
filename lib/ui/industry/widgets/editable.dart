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
          provider.updatePosition(item.id, item.position + details.delta);
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
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: item.width,
              height: item.height,
              color: Colors.grey.shade800,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            width: item.width,
            height: item.height,
            color: Colors.grey.shade800,
            child: const Icon(Icons.broken_image, color: Colors.white, size: 30),
          ),
        );
      }

      // Shape Masking
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

      // 🚀 Safe Color Filter (Only apply if color is explicitly set and not black/transparent)
      Color? tintColor = item.color;
      if (tintColor == Colors.black || tintColor == null) {
        tintColor = Colors.transparent;
      }

      return Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(tintColor, BlendMode.modulate),
          child: maskedImage,
        ),
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
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          runSpacing: 10,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)))),
            const Text("Pro Editor Options", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

            // 🚀 Image-ku mattum Shape options kaattum
            if (item.type == 'image') ...[
              const Divider(color: Colors.white24),
              const Text("Choose Image Shape", style: TextStyle(color: Colors.amberAccent, fontSize: 14)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(icon: const Icon(Icons.circle, color: Colors.white), onPressed: () { provider.setImageShape(item.id, 'circle'); Navigator.pop(context); }),
                  IconButton(icon: const Icon(Icons.crop_square, color: Colors.white), onPressed: () { provider.setImageShape(item.id, 'rounded', radius: 24.0); Navigator.pop(context); }),
                  IconButton(icon: const Icon(Icons.favorite, color: Colors.redAccent), onPressed: () { provider.setImageShape(item.id, 'heart'); Navigator.pop(context); }),
                  IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () { provider.setImageShape(item.id, 'star'); Navigator.pop(context); }),
                  IconButton(icon: const Icon(Icons.hexagon, color: Colors.purpleAccent), onPressed: () { provider.setImageShape(item.id, 'hexagon'); Navigator.pop(context); }),
                ],
              ),
            ],

            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.flip_to_front, color: Colors.blueAccent),
              title: const Text("Bring to Front", style: TextStyle(color: Colors.white)),
              onTap: () { provider.bringToFront(item.id); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.flip_to_back, color: Colors.orangeAccent),
              title: const Text("Send to Back", style: TextStyle(color: Colors.white)),
              onTap: () { provider.sendToBack(item.id); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("Delete Item", style: TextStyle(color: Colors.redAccent)),
              onTap: () { provider.removeItem(item.id); Navigator.pop(context); },
            ),
          ],
        ),
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

