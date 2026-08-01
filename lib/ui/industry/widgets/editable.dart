import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Api Model/editor_model.dart';
import '../../../network/provider/editor_provider.dart';

class EditableItemWidget extends StatelessWidget {
  final EditorItem item;
  final Function(String type, String id) onItemSelected;

  const EditableItemWidget({super.key, required this.item, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final currentItem = provider.items.firstWhere((e) => e.id == item.id, orElse: () => item);

    return Positioned(
      left: currentItem.position.dx,
      top: currentItem.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          provider.updatePosition(currentItem.id??"", currentItem.position + details.delta);
        },
        onTap: () {
          onItemSelected(currentItem.type, currentItem.id??"");
          if (currentItem.type == 'text') {
            _showTextEditorDialog(context, provider, currentItem.id??"", currentItem.text ?? "");
          } else {
            _showProActionSheet(context, provider, currentItem);
          }
        },
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

  void _showTextEditorDialog(BuildContext context, EditorProvider provider, String itemId, String initialText) {
    final TextEditingController textController = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("Edit Text", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: "Type text here...",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent, width: 2)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  provider.updateTextContent(itemId, textController.text);
                }
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilteredImage(EditorItem item, Widget imageWidget) {
    ColorFilter? colorFilter;
    switch (item.filterType) {
      case 'grayscale':
        colorFilter = const ColorFilter.matrix(<double>[0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]);
        break;
      case 'sepia':
        colorFilter = const ColorFilter.matrix(<double>[0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]);
        break;
      case 'vintage':
        colorFilter = const ColorFilter.matrix(<double>[0.9, 0.5, 0.1, 0, 0, 0.3, 0.8, 0.2, 0, 0, 0.2, 0.3, 0.6, 0, 0, 0, 0, 0, 1, 0]);
        break;
      default:
        colorFilter = null;
    }
    if (colorFilter == null) return imageWidget;
    return ColorFiltered(colorFilter: colorFilter, child: imageWidget);
  }

  Widget _buildProFilteredImage(EditorItem item, Widget imageWidget) {
    double c = item.contrast;
    double b = item.brightness;
    double s = item.saturation;
    const double rwgt = 0.3086, gwgt = 0.6094, bwgt = 0.0820;
    double baseR = (1 - s) * rwgt + s, baseG = (1 - s) * gwgt, baseB = (1 - s) * bwgt;
    List<double> matrix = <double>[
      c * baseR, c * baseG, c * baseB, 0, b * 255,
      c * baseG, c * baseR, c * baseG, 0, b * 255,
      c * baseB, c * baseG, c * baseR, 0, b * 255,
      0, 0, 0, 1, 0,
    ];
    Widget filtered = ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: imageWidget);
    return _buildFilteredImage(item, filtered);
  }

  Widget _buildItemContent(EditorItem item) {
    if (item.type == 'image') {
      bool isLocalFile = item.isLocal || (item.contentUrl != null && (item.contentUrl!.startsWith('file://') || item.contentUrl!.startsWith('/data/')));
      Widget imageWidget = isLocalFile
          ? Image.file(
        File(item.contentUrl!.replaceFirst('file://', '')),
        width: item.width,
        height: item.height,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(width: item.width, height: item.height, color: Colors.grey, child: const Icon(Icons.broken_image)),
      )
          : Image.network(
        item.contentUrl ?? "",
        width: item.width,
        height: item.height,
        fit: BoxFit.cover,
        // 🚀 Modern AI Magic Glowing Loader Animation
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.2, end: 1.0),
            duration: const Duration(milliseconds: 900),
            builder: (context, value, childWidget) {
              return Container(
                width: item.width,
                height: item.height,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0),
                  border: Border.all(color: Colors.amberAccent.withOpacity(value), width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(value * 0.5), blurRadius: 15, spreadRadius: 2)],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 36),
                      SizedBox(height: 10),
                      Text("AI Magic Generating...", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      SizedBox(height: 4),
                      SizedBox(width: 50, child: LinearProgressIndicator(backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent), minHeight: 2)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        errorBuilder: (c, e, s) => Container(
          width: item.width,
          height: item.height,
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(16)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.wifi_off, color: Colors.amber, size: 28), SizedBox(height: 6), Text("Failed\nTry again", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10))]),
        ),
      );

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
        maskedImage = ClipRRect(borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0), child: imageWidget);
      }

      Widget filteredImage = _buildProFilteredImage(item, maskedImage);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0),
          border: item.outlineWidth > 0 ? Border.all(color: item.outlineColor, width: item.outlineWidth) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: filteredImage,
      );
    } else {
      return Text(item.text ?? "", style: TextStyle(fontSize: item.fontSize, color: item.color ?? Colors.white, fontWeight: FontWeight.bold));
    }
  }

  void _showProActionSheet(BuildContext context, EditorProvider provider, EditorItem item) {
    final TextEditingController aiPromptController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final currentItem = provider.items.firstWhere((e) => e.id == item.id, orElse: () => item);

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Pro Editing Tools", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.copy, color: Colors.blueAccent), onPressed: () { provider.duplicateItem(currentItem.id??""); Navigator.pop(modalContext); }),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () { provider.removeItem(currentItem.id??""); Navigator.pop(modalContext); }),
                            ],
                          )
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      Expanded(
                        child: ListView(
                          children: [
                            if (currentItem.type == 'image') ...[
                              const Text("Regenerate Image with AI", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF2A2A3D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: aiPromptController,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                        decoration: const InputDecoration(hintText: "Enter prompt (e.g., cartoon tiger)...", hintStyle: TextStyle(color: Colors.white54, fontSize: 12), border: InputBorder.none),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                                      onPressed: () {
                                        if (aiPromptController.text.isNotEmpty) {
                                          provider.regenerateImageWithAi(currentItem.id??"", aiPromptController.text);
                                          Navigator.pop(modalContext);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white24),
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
                              const Text("Brightness", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Slider(value: currentItem.brightness, min: -0.5, max: 0.5, activeColor: Colors.blueAccent, onChanged: (v) => setModalState(() => provider.updateImageColorAdjustments(currentItem.id??"", brightness: v))),
                              const Text("Contrast", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Slider(value: currentItem.contrast, min: 0.5, max: 1.5, activeColor: Colors.greenAccent, onChanged: (v) => setModalState(() => provider.updateImageColorAdjustments(currentItem.id??"", contrast: v))),
                              const Text("Saturation", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Slider(value: currentItem.saturation, min: 0.0, max: 2.0, activeColor: Colors.purpleAccent, onChanged: (v) => setModalState(() => provider.updateImageColorAdjustments(currentItem.id??"", saturation: v))),
                              const Divider(color: Colors.white24),
                              const Text("Image Mask / Shape", style: TextStyle(color: Colors.amberAccent, fontSize: 13)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(icon: const Icon(Icons.circle, color: Colors.white), onPressed: () => provider.setImageShape(currentItem.id??"", 'circle')),
                                  IconButton(icon: const Icon(Icons.crop_square, color: Colors.white), onPressed: () => provider.setImageShape(currentItem.id??"", 'rounded', radius: 24.0)),
                                  IconButton(icon: const Icon(Icons.favorite, color: Colors.redAccent), onPressed: () => provider.setImageShape(currentItem.id??"", 'heart')),
                                  IconButton(icon: const Icon(Icons.star, color: Colors.amber), onPressed: () => provider.setImageShape(currentItem.id??"", 'star')),
                                  IconButton(icon: const Icon(Icons.hexagon, color: Colors.purpleAccent), onPressed: () => provider.setImageShape(currentItem.id??"", 'hexagon')),
                                ],
                              ),
                              const Divider(color: Colors.white24),
                            ],
                            const Text("Rotation", style: TextStyle(color: Colors.white70)),
                            Slider(value: currentItem.rotation, min: 0.0, max: 6.28, activeColor: Colors.blueAccent, onChanged: (v) => setModalState(() => provider.updateRotation(currentItem.id??"", v))),
                            const Text("Zoom / Scale", style: TextStyle(color: Colors.white70)),
                            Slider(value: currentItem.scale, min: 0.5, max: 3.0, activeColor: Colors.greenAccent, onChanged: (v) => setModalState(() => provider.updateScale(currentItem.id??"", v))),
                            const Text("Opacity", style: TextStyle(color: Colors.white70)),
                            Slider(value: currentItem.opacity, min: 0.0, max: 1.0, activeColor: Colors.purpleAccent, onChanged: (v) => setModalState(() => provider.updateOpacity(currentItem.id??"", v))),
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

  Widget _filterButton(EditorProvider provider, EditorItem item, String label, String type, StateSetter setModalState) {
    return TextButton(
      onPressed: () => setModalState(() => provider.setImageFilter(item.id??"", type)),
      child: Text(label, style: TextStyle(color: item.filterType == type ? Colors.amber : Colors.white70)),
    );
  }
}

// ==================== 5. SHAPE CLIPPERS ====================
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
