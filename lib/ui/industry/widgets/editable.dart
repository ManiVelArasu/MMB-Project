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

    return GestureDetector(
      onPanUpdate: (details) {
        provider.updatePosition(currentItem.id ?? "", currentItem.position + details.delta);
      },
      onTap: () {
        onItemSelected(currentItem.type, currentItem.id ?? "");
        if (currentItem.type == 'text') {
          _showTextEditorDialog(context, provider, currentItem.id ?? "", currentItem.text ?? "");
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
        errorBuilder: (c, e, s) => Container(
          width: item.width,
          height: item.height,
          color: Colors.grey.shade900,
          child: const Icon(Icons.wifi_off, color: Colors.amber),
        ),
      );

      String shape = item.text ?? 'rounded';
      Widget maskedImage;
      if (shape == 'circle') {
        maskedImage = ClipOval(child: imageWidget);
      } else {
        maskedImage = ClipRRect(borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0), child: imageWidget);
      }

      Widget filteredImage = _buildProFilteredImage(item, maskedImage);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(item.borderRadius > 0 ? item.borderRadius : 16.0),
          border: item.outlineWidth > 0 ? Border.all(color: item.outlineColor, width: item.outlineWidth) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
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

  // 🚀 Pro Action Sheet with Font Size adjustment for Text, and Filters/Layers for Images
  void _showProActionSheet(BuildContext context, EditorProvider provider, EditorItem item) {
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
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(currentItem.type == 'text' ? "Text Size & Tools" : "Pro Editing Tools", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                tooltip: "Bring to Front",
                                icon: const Icon(Icons.flip_to_front, color: Colors.amberAccent),
                                onPressed: () {
                                  provider.bringToFront(currentItem.id ?? "");
                                },
                              ),
                              IconButton(
                                tooltip: "Send to Back",
                                icon: const Icon(Icons.flip_to_back, color: Colors.blueAccent),
                                onPressed: () {
                                  provider.sendToBack(currentItem.id ?? "");
                                },
                              ),
                              IconButton(
                                tooltip: "Delete",
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  provider.removeItem(currentItem.id ?? "");
                                  Navigator.pop(modalContext);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      Expanded(
                        child: ListView(
                          children: [
                            // 🚀 Text Size Slider (Only visible when text is selected)
                            if (currentItem.type == 'text') ...[
                              const Text("Font Size", style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                              Slider(
                                value: currentItem.fontSize,
                                min: 10.0,
                                max: 100.0,
                                activeColor: Colors.amberAccent,
                                onChanged: (v) => setModalState(() {
                                  // Update font size method in provider or directly using copyWith
                                  int index = provider.items.indexWhere((e) => e.id == currentItem.id);
                                  if (index != -1) {
                                    provider.items[index] = provider.items[index].copyWith(fontSize: v);
                                    provider.notifyListeners();
                                  }
                                }),
                              ),
                              const Divider(color: Colors.white24),
                            ],
                            if (currentItem.type == 'image') ...[
                              const Text("Photo Filters", style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
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
                            ],
                            const Text("Rotation", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Slider(
                              value: currentItem.rotation,
                              min: 0.0,
                              max: 6.28,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) => setModalState(() => provider.updateRotation(currentItem.id ?? "", v)),
                            ),
                            const Text("Zoom / Scale", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Slider(
                              value: currentItem.scale,
                              min: 0.5,
                              max: 3.0,
                              activeColor: Colors.greenAccent,
                              onChanged: (v) => setModalState(() => provider.updateScale(currentItem.id ?? "", v)),
                            ),
                            const Text("Opacity", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Slider(
                              value: currentItem.opacity,
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.purpleAccent,
                              onChanged: (v) => setModalState(() => provider.updateOpacity(currentItem.id ?? "", v)),
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

  Widget _filterButton(EditorProvider provider, EditorItem item, String label, String type, StateSetter setModalState) {
    return TextButton(
      onPressed: () => setModalState(() => provider.setImageFilter(item.id ?? "", type)),
      child: Text(label, style: TextStyle(color: item.filterType == type ? Colors.amber : Colors.white70)),
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
