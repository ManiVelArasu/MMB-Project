import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../network/provider/editor_provider.dart';

class CanvaExtraTools extends StatelessWidget {
  final bool isDark;

  const CanvaExtraTools({
    super.key,
    this.isDark = true,
  });

  Color get bgColor =>
      isDark ? const Color(0xFF1B1B1F) : Colors.white;

  Color get itemColor =>
      isDark ? Colors.white : Colors.black;

  Color get subColor =>
      isDark ? Colors.white70 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    final selectedId = provider.selectedItemId;

    if (selectedId == null) {
      return _mainToolbar(context, provider);
    }

    final itemIndex = provider.items.indexWhere(
          (e) => e.id == selectedId,
    );

    if (itemIndex == -1) {
      return _mainToolbar(context, provider);
    }

    final item = provider.items[itemIndex];

    if (item.type == 'text' || item.type == 'textbox') {
      return _textToolbar(context, provider, item);
    }

    if (item.type == 'image') {
      return _imageToolbar(context, provider, item);
    }

    return _elementToolbar(context, provider, item);
  }

  // ============================================================
  // MAIN TOOLBAR
  // ============================================================

  Widget _mainToolbar(
      BuildContext context,
      EditorProvider provider,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tool(
                icon: Icons.text_fields_rounded,
                title: "Text",
                onTap: () => _showTextDialog(
                  context,
                  provider,
                ),
              ),
              _tool(
                icon: Icons.image_outlined,
                title: "Media",
                onTap: () {},
              ),
              _tool(
                icon: Icons.auto_awesome_outlined,
                title: "Elements",
                onTap: () {},
              ),
              _tool(
                icon: Icons.crop_square_rounded,
                title: "Shapes",
                onTap: () => _showShapeSheet(
                  context,
                  provider,
                ),
              ),
              _tool(
                icon: Icons.color_lens_outlined,
                title: "Background",
                onTap: () {},
              ),
              _tool(
                icon: Icons.grid_view_rounded,
                title: "Templates",
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEXT TOOLBAR
  // ============================================================

  Widget _textToolbar(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tool(
                icon: Icons.font_download_outlined,
                title: "Font",
                onTap: () => _showFontSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.format_size_rounded,
                title: "Size",
                onTap: () => _showFontSizeSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.format_color_text_rounded,
                title: "Color",
                onTap: () => _showTextColorSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.format_align_left_rounded,
                title: "Align",
                onTap: () => _showAlignmentSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.space_bar_rounded,
                title: "Spacing",
                onTap: () => _showSpacingSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.layers_outlined,
                title: "Layer",
                onTap: () => _showLayerSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.copy_outlined,
                title: "Duplicate",
                onTap: () {
                  provider.duplicateItem(item.id ?? "");
                },
              ),

              _tool(
                icon: Icons.delete_outline_rounded,
                title: "Delete",
                color: Colors.redAccent,
                onTap: () {
                  provider.removeItem(item.id ?? "");
                  provider.clearSelection();
                },
              ),

              _tool(
                icon: Icons.close_rounded,
                title: "Close",
                onTap: () {
                  provider.clearSelection();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE TOOLBAR
  // ============================================================

  Widget _imageToolbar(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tool(
                icon: Icons.crop_rounded,
                title: "Crop",
                onTap: () => _showCropSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.flip_rounded,
                title: "Flip",
                onTap: () => _showFlipSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.rotate_right_rounded,
                title: "Rotate",
                onTap: () => _showRotateSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.tune_rounded,
                title: "Adjust",
                onTap: () => _showAdjustSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.auto_fix_high_outlined,
                title: "Filter",
                onTap: () => _showFilterSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.rounded_corner,
                title: "Radius",
                onTap: () => _showRadiusSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.layers_outlined,
                title: "Layer",
                onTap: () => _showLayerSheet(
                  context,
                  provider,
                  item,
                ),
              ),

              _tool(
                icon: Icons.copy_outlined,
                title: "Duplicate",
                onTap: () {
                  provider.duplicateItem(item.id ?? "");
                },
              ),

              _tool(
                icon: Icons.delete_outline_rounded,
                title: "Delete",
                color: Colors.redAccent,
                onTap: () {
                  provider.removeItem(item.id ?? "");
                  provider.clearSelection();
                },
              ),

              _tool(
                icon: Icons.close_rounded,
                title: "Close",
                onTap: () {
                  provider.clearSelection();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ELEMENT TOOLBAR
  // ============================================================

  Widget _elementToolbar(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tool(
                icon: Icons.layers_outlined,
                title: "Layer",
                onTap: () => _showLayerSheet(
                  context,
                  provider,
                  item,
                ),
              ),
              _tool(
                icon: Icons.align_horizontal_center_rounded,
                title: "Align",
                onTap: () => _showAlignmentSheet(
                  context,
                  provider,
                  item,
                ),
              ),
              _tool(
                icon: Icons.rotate_right_rounded,
                title: "Rotate",
                onTap: () => _showRotateSheet(
                  context,
                  provider,
                  item,
                ),
              ),
              _tool(
                icon: Icons.copy_outlined,
                title: "Duplicate",
                onTap: () {
                  provider.duplicateItem(item.id ?? "");
                },
              ),
              _tool(
                icon: Icons.delete_outline_rounded,
                title: "Delete",
                color: Colors.redAccent,
                onTap: () {
                  provider.removeItem(item.id ?? "");
                  provider.clearSelection();
                },
              ),
              _tool(
                icon: Icons.close_rounded,
                title: "Close",
                onTap: () {
                  provider.clearSelection();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOOL BUTTON
  // ============================================================

  Widget _tool({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(
          vertical: 5,
          horizontal: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? itemColor,
              size: 22,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color ?? subColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FONT
  // ============================================================

  void _showFontSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    final fonts = [
      "Roboto",
      "Poppins",
      "Montserrat",
      "Lato",
      "Open Sans",
      "Oswald",
      "Raleway",
      "Playfair Display",
      "Pacifico",
      "Dancing Script",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 430,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: fonts.length,
              itemBuilder: (_, index) {
                final font = fonts[index];

                return ListTile(
                  title: Text(
                    font,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: 18,
                      fontFamily: font,
                    ),
                  ),
                  trailing: item.fontFamily == font
                      ? const Icon(
                    Icons.check_circle,
                    color: Colors.amber,
                  )
                      : null,
                  onTap: () {
                    provider.updateFontFamily(
                      item.id ?? "",
                      font,
                    );
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FONT SIZE
  // ============================================================

  void _showFontSizeSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    double size = item.fontSize;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Font Size  ${size.toInt()}",
                      style: TextStyle(
                        color: itemColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      min: 8,
                      max: 150,
                      value: size.clamp(8, 150),
                      onChanged: (value) {
                        setState(() => size = value);

                        final index = provider.items.indexWhere(
                              (e) => e.id == item.id,
                        );

                        if (index != -1) {
                          provider.items[index] = provider
                              .items[index]
                              .copyWith(fontSize: value);

                          provider.notifyListeners();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TEXT COLOR
  // ============================================================

  void _showTextColorSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    final colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.teal,
      Colors.brown,
      Colors.grey,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    final index = provider.items.indexWhere(
                          (e) => e.id == item.id,
                    );

                    if (index != -1) {
                      provider.items[index] = provider
                          .items[index]
                          .copyWith(color: color);

                      provider.notifyListeners();
                    }

                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ALIGNMENT
  // ============================================================

  void _showAlignmentSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _alignmentButton(
                  Icons.align_horizontal_left,
                  "Left",
                      () {
                    _updatePosition(
                      provider,
                      item,
                      dx: 0,
                    );
                    Navigator.pop(context);
                  },
                ),
                _alignmentButton(
                  Icons.align_horizontal_center,
                  "Center",
                      () {
                    _updatePosition(
                      provider,
                      item,
                      dx: 440,
                    );
                    Navigator.pop(context);
                  },
                ),
                _alignmentButton(
                  Icons.align_horizontal_right,
                  "Right",
                      () {
                    _updatePosition(
                      provider,
                      item,
                      dx: 850,
                    );
                    Navigator.pop(context);
                  },
                ),
                _alignmentButton(
                  Icons.vertical_align_top,
                  "Top",
                      () {
                    _updatePosition(
                      provider,
                      item,
                      dy: 0,
                    );
                    Navigator.pop(context);
                  },
                ),
                _alignmentButton(
                  Icons.vertical_align_center,
                  "Middle",
                      () {
                    _updatePosition(
                      provider,
                      item,
                      dy: 440,
                    );
                    Navigator.pop(context);
                  },
                ),
                _alignmentButton(
                  Icons.vertical_align_bottom,
                  "Bottom",
                      () {
                    _updatePosition(
                      provider,
                      item,
                      dy: 850,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _alignmentButton(
      IconData icon,
      String text,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: itemColor,
            ),
            const SizedBox(height: 5),
            Text(
              text,
              style: TextStyle(
                color: subColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePosition(
      EditorProvider provider,
      dynamic item, {
        double? dx,
        double? dy,
      }) {
    provider.updatePosition(
      item.id ?? "",
      Offset(
        dx ?? item.position.dx,
        dy ?? item.position.dy,
      ),
    );
  }

  // ============================================================
  // SPACING
  // ============================================================

  void _showSpacingSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    double spacing = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Text Spacing",
                      style: TextStyle(
                        color: itemColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      min: -5,
                      max: 20,
                      value: spacing,
                      onChanged: (value) {
                        setState(() => spacing = value);

                        final index = provider.items.indexWhere(
                              (e) => e.id == item.id,
                        );

                        /*if (index != -1) {
                          provider.items[index] = provider
                              .items[index]
                              .copyWith(
                            letterSpacing: value,
                          );

                          provider.notifyListeners();
                        }*/
                      },
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

  // ============================================================
  // LAYER
  // ============================================================

  void _showLayerSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _layerTile(
                Icons.vertical_align_top,
                "Bring to Front",
                    () {
                  provider.bringToFront(item.id ?? "");
                  Navigator.pop(context);
                },
              ),
              _layerTile(
                Icons.keyboard_arrow_up,
                "Bring Forward",
                    () {
                  provider.bringToFront(item.id ?? "");
                  Navigator.pop(context);
                },
              ),
              _layerTile(
                Icons.keyboard_arrow_down,
                "Send Backward",
                    () {
                  provider.sendToBack(item.id ?? "");
                  Navigator.pop(context);
                },
              ),
              _layerTile(
                Icons.vertical_align_bottom,
                "Send to Back",
                    () {
                  provider.sendToBack(item.id ?? "");
                  Navigator.pop(context);
                },
              ),
              _layerTile(
                Icons.copy,
                "Duplicate",
                    () {
                  provider.duplicateItem(item.id ?? "");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _layerTile(
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(
        icon,
        color: itemColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: itemColor),
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // ROTATE
  // ============================================================

  void _showRotateSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    double angle = item.rotation;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Rotate",
                      style: TextStyle(
                        color: itemColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      min: -math.pi,
                      max: math.pi,
                      value: angle.clamp(
                        -math.pi,
                        math.pi,
                      ),
                      onChanged: (value) {
                        setState(() => angle = value);

                        provider.updateRotation(
                          item.id ?? "",
                          value,
                        );
                      },
                    ),
                    Text(
                      "${(angle * 180 / math.pi).round()}°",
                      style: TextStyle(
                        color: subColor,
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

  // ============================================================
  // IMAGE FILTER
  // ============================================================

  void _showFilterSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    final filters = {
      "Normal": "normal",
      "Gray": "grayscale",
      "Sepia": "sepia",
      "Vintage": "vintage",
      "Invert": "invert",
      "Cool": "cool",
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filters.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.key),
                  selected: item.filterType == entry.value,
                  onSelected: (_) {
                    provider.setImageFilter(
                      item.id ?? "",
                      entry.value,
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // IMAGE ADJUST
  // ============================================================

  void _showAdjustSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _slider(
                  title: "Scale",
                  value: item.scale,
                  min: 0.5,
                  max: 3,
                  onChanged: (value) {
                    provider.updateScale(
                      item.id ?? "",
                      value,
                    );
                  },
                ),
                _slider(
                  title: "Opacity",
                  value: item.opacity,
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    provider.updateOpacity(
                      item.id ?? "",
                      value,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slider({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          min: min,
          max: max,
          value: value.clamp(min, max),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ============================================================
  // RADIUS
  // ============================================================

  void _showRadiusSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    double radius = item.borderRadius;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Corner Radius",
                      style: TextStyle(
                        color: itemColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      min: 0,
                      max: 100,
                      value: radius.clamp(0, 100),
                      onChanged: (value) {
                        setState(() => radius = value);

                        final index = provider.items.indexWhere(
                              (e) => e.id == item.id,
                        );

                        if (index != -1) {
                          provider.items[index] = provider
                              .items[index]
                              .copyWith(
                            borderRadius: value,
                          );

                          provider.notifyListeners();
                        }
                      },
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

  // ============================================================
  // CROP
  // ============================================================

  void _showCropSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cropOption(
                context,
                "1 : 1",
                1,
                item,
                provider,
              ),
              _cropOption(
                context,
                "4 : 5",
                4 / 5,
                item,
                provider,
              ),
              _cropOption(
                context,
                "9 : 16",
                9 / 16,
                item,
                provider,
              ),
              _cropOption(
                context,
                "16 : 9",
                16 / 9,
                item,
                provider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cropOption(
      BuildContext context,
      String title,
      double ratio,
      dynamic item,
      EditorProvider provider,
      ) {
    return ListTile(
      leading: const Icon(
        Icons.crop,
        color: Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(color: itemColor),
      ),
      onTap: () {
        final width = item.width ?? 300.0;
        final newHeight = width / ratio;

        final index = provider.items.indexWhere(
              (e) => e.id == item.id,
        );

        if (index != -1) {
          provider.items[index] = provider.items[index].copyWith(
            width: width,
            height: newHeight,
          );

          provider.notifyListeners();
        }

        Navigator.pop(context);
      },
    );
  }

  // ============================================================
  // FLIP
  // ============================================================

  void _showFlipSheet(
      BuildContext context,
      EditorProvider provider,
      dynamic item,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.flip,
                  color: itemColor,
                ),
                title: Text(
                  "Flip Horizontal",
                  style: TextStyle(color: itemColor),
                ),
                onTap: () {
                  _flipHorizontal(
                    provider,
                    item,
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.flip_camera_android,
                  color: itemColor,
                ),
                title: Text(
                  "Flip Vertical",
                  style: TextStyle(color: itemColor),
                ),
                onTap: () {
                  _flipVertical(
                    provider,
                    item,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _flipHorizontal(
      EditorProvider provider,
      dynamic item,
      ) {
    final index = provider.items.indexWhere(
          (e) => e.id == item.id,
    );

    if (index == -1) return;

    final current = provider.items[index];

    provider.items[index] = current.copyWith(
      rotation: current.rotation + math.pi,
    );

    provider.notifyListeners();
  }

  void _flipVertical(
      EditorProvider provider,
      dynamic item,
      ) {
    final index = provider.items.indexWhere(
          (e) => e.id == item.id,
    );

    if (index == -1) return;

    final current = provider.items[index];

    provider.items[index] = current.copyWith(
      rotation: current.rotation + math.pi,
    );

    provider.notifyListeners();
  }

  // ============================================================
  // SHAPES
  // ============================================================

  void _showShapeSheet(
      BuildContext context,
      EditorProvider provider,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _shapeButton(
                  Icons.crop_square,
                  "Rectangle",
                      () {
                    _addShape(
                      provider,
                      Colors.red,
                      false,
                    );
                    Navigator.pop(context);
                  },
                ),
                _shapeButton(
                  Icons.circle_outlined,
                  "Circle",
                      () {
                    _addShape(
                      provider,
                      Colors.blue,
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shapeButton(
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            Icon(
              icon,
              size: 38,
              color: itemColor,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addShape(
      EditorProvider provider,
      Color color,
      bool circle,
      ) {
    /*
     * உங்கள் existing EditorProvider-ல் shape add method இருந்தால்
     * அதை இங்கே call செய்யவும்.
     *
     * Example:
     *
     * provider.addShape(
     *   color: color,
     *   isCircle: circle,
     * );
     */
  }

  // ============================================================
  // ADD TEXT
  // ============================================================

  void _showTextDialog(
      BuildContext context,
      EditorProvider provider,
      ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            "Add Text",
            style: TextStyle(
              color: itemColor,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(
              color: itemColor,
            ),
            decoration: InputDecoration(
              hintText: "Type something...",
              hintStyle: TextStyle(
                color: subColor,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                /*
                 * உங்கள் existing addText method இங்கே call செய்யவும்.
                 *
                 * Example:
                 *
                 * provider.addText(
                 *   controller.text,
                 * );
                 */

                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
}