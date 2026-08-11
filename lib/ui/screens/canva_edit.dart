import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../Api Model/canva_item.dart';
import '../../network/provider/canva_provider.dart';


class CanvaEditorScreen extends StatefulWidget {
  const CanvaEditorScreen({super.key});

  @override
  State<CanvaEditorScreen> createState() => _CanvaEditorScreenState();
}

class _CanvaEditorScreenState extends State<CanvaEditorScreen> {
  final _picker = ImagePicker();
  final TransformationController _canvasController =
  TransformationController();

  double _zoom = 1;
  bool _showLayers = false;

  @override
  void dispose() {
    _canvasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CanvaProvider(),
      child: Consumer<CanvaProvider>(
        builder: (_, p, __) => Scaffold(
          backgroundColor: const Color(0xFFF4F4F6),
          appBar: _topBar(p),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _canvasController,
                      minScale: .25,
                      maxScale: 4,
                      boundaryMargin: const EdgeInsets.all(300),
                      child: Center(
                        child: _canvas(p),
                      ),
                    ),
                    if (p.selectedItem != null) _floatingSelectionToolbar(p),
                  ],
                ),
              ),
              _bottomToolbar(p),
            ],
          ),
          endDrawer: _layersDrawer(p),
        ),
      ),
    );
  }

  PreferredSizeWidget _topBar(CanvaProvider p) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'Post Edit',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      actions: [
        IconButton(
          tooltip: 'Undo',
          onPressed: p.canUndo ? p.undo : null,
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton(
          tooltip: 'Redo',
          onPressed: p.canRedo ? p.redo : null,
          icon: const Icon(Icons.redo_rounded),
        ),
        Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Layers',
            onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            icon: const Icon(Icons.layers_outlined),
          ),
        ),
        IconButton(
          tooltip: 'Preview',
          onPressed: () => _preview(p),
          icon: const Icon(Icons.visibility_outlined),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _canvas(CanvaProvider p) {
    return Container(
      width: p.document.width,
      height: p.document.height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: p.backgroundColor,
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: 2,
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final item in p.items.where((e) => e.visible))
            Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: _editorItem(p, item),
            ),
        ],
      ),
    );
  }

  Widget _editorItem(CanvaProvider p, CanvaItem item) {
    final selected = p.selectedId == item.id;
    final bg = p.isBackground(item);

    Widget content;

    switch (item.type) {
      case EditorItemType.text:
      case EditorItemType.emoji:
        content = SizedBox(
          width: item.width,
          height: item.height,
          child: Center(
            child: Text(
              item.text,
              textAlign: item.textAlign,
              style: TextStyle(
                fontSize: item.fontSize,
                fontWeight:
                item.bold ? FontWeight.w800 : FontWeight.w400,
                fontStyle:
                item.italic ? FontStyle.italic : FontStyle.normal,
                color: Color(item.textColorValue),
                letterSpacing: item.letterSpacing,
                height: item.lineHeight,
              ),
            ),
          ),
        );
        break;

      case EditorItemType.shape:
        content = Container(
          width: item.width,
          height: item.height,
          decoration: BoxDecoration(
            color: Color(item.fillColorValue),
            borderRadius: BorderRadius.circular(item.borderRadius),
            border: item.borderWidth > 0
                ? Border.all(
              color: Color(item.borderColorValue),
              width: item.borderWidth,
            )
                : null,
          ),
        );
        break;

      case EditorItemType.image:
      case EditorItemType.video:
        content = _imageWidget(item);
        break;
    }

    final transformed = Opacity(
      opacity: item.opacity.clamp(0, 1),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(item.flipX ? -item.scale : item.scale,
              item.flipY ? -item.scale : item.scale)
          ..rotateZ(item.rotation),
        child: content,
      ),
    );

    return GestureDetector(
      onTap: () => p.select(item.id),
      onScaleStart: item.locked && !bg ? null : (_) {},
      onScaleUpdate: item.locked && !bg
          ? null
          : (details) {
        if (bg) return;
        if (details.focalPointDelta != Offset.zero) {
          p.moveSelected(details.focalPointDelta);
        }
        if (details.scale != 1) {
          final next = (item.scale * details.scale).clamp(.15, 8.0);
          p.updateItem(item.id, scale: next);
        }
        if (details.rotation != 0) {
          p.updateItem(
            item.id,
            rotation: item.rotation + details.rotation,
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          transformed,
          if (selected)
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
          if (selected && !item.locked && !bg) _resizeHandle(p, item),
          if (selected && !item.locked && !bg) _rotateHandle(p, item),
        ],
      ),
    );
  }

  Widget _resizeHandle(CanvaProvider p, CanvaItem item) {
    return Positioned(
      right: -10,
      bottom: -10,
      child: GestureDetector(
        onPanUpdate: (d) {
          final w = math.max(40, item.width + d.delta.dx);
          final h = math.max(40, item.height + d.delta.dy);
          p.setSize(item.id, w.toDouble(), h.toDouble());
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotateHandle(CanvaProvider p, CanvaItem item) {
    return Positioned(
      top: -38,
      left: item.width / 2 - 10,
      child: GestureDetector(
        onPanUpdate: (d) {
          p.setRotation(item.id, item.rotation + d.delta.dx * .01);
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.red, width: 2),
            ),
          ),
          child: const Icon(Icons.rotate_right, size: 12),
        ),
      ),
    );
  }

  Widget _imageWidget(CanvaItem item) {
    if (item.isLocal && item.contentUrl.isNotEmpty) {
      return Image.file(
        File(item.contentUrl),
        width: item.width,
        height: item.height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    if (item.contentUrl.startsWith('http')) {
      return Image.network(
        item.contentUrl,
        width: item.width,
        height: item.height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    return _imageError();
  }

  Widget _imageError() => Container(
    width: 220,
    height: 220,
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported_outlined),
  );

  Widget _floatingSelectionToolbar(CanvaProvider p) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _quick('Duplicate', Icons.copy_rounded, p.duplicateSelected),
              _quick('Delete', Icons.delete_outline, p.deleteSelected),
              _quick('Front', Icons.vertical_align_top, () {
                final id = p.selectedId;
                if (id != null) p.bringToFront(id);
              }),
              _quick('Back', Icons.vertical_align_bottom, () {
                final id = p.selectedId;
                if (id != null) p.sendToBack(id);
              }),
              _quick('Lock', Icons.lock_outline, () {
                final id = p.selectedId;
                if (id != null) p.toggleLock(id);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quick(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _bottomToolbar(CanvaProvider p) {
    final item = p.selectedItem;

    final actions = item == null
        ? [
      ('Text', Icons.text_fields, () => p.addText()),
      ('Media', Icons.photo_library_outlined, _pickMedia),
      ('Elements', Icons.category_outlined, _elementsSheet),
      ('Background', Icons.wallpaper_outlined, _backgroundSheet),
      ('Layers', Icons.layers_outlined, () {
        Scaffold.of(context).openEndDrawer();
      }),
      ('More', Icons.more_horiz, _moreSheet),
    ]
        : _selectedActions(p, item);

    return SafeArea(
      top: false,
      child: Container(
        height: 82,
        color: Colors.white,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          children: [
            for (final a in actions)
              _bottomAction(a.$1, a.$2, a.$3),
          ],
        ),
      ),
    );
  }

  List<(String, IconData, VoidCallback)> _selectedActions(
      CanvaProvider p, CanvaItem item) {
    if (item.type == EditorItemType.text ||
        item.type == EditorItemType.emoji) {
      return [
        ('Edit', Icons.edit_outlined, () => _editText(p, item)),
        ('Font', Icons.font_download_outlined, () => _fontSheet(p, item)),
        ('Color', Icons.palette_outlined, () => _colorSheet(p, item)),
        ('Size', Icons.format_size, () => _sizeSheet(p, item)),
        ('Align', Icons.format_align_center, () => _alignSheet(p, item)),
        ('Spacing', Icons.format_line_spacing, () => _spacingSheet(p, item)),
        ('Opacity', Icons.opacity, () => _opacitySheet(p, item)),
        ('Order', Icons.layers_outlined, () => _orderSheet(p, item)),
      ];
    }

    if (item.type == EditorItemType.image) {
      return [
        ('Replace', Icons.image_outlined, () => _replaceImage(p, item)),
        ('Crop', Icons.crop_outlined, () => _cropImage(p, item)),
        ('Filter', Icons.filter_vintage_outlined, () => _filterSheet(p, item)),
        ('Adjust', Icons.tune, () => _adjustSheet(p, item)),
        ('Flip', Icons.flip, () => _flipSheet(p, item)),
        ('Opacity', Icons.opacity, () => _opacitySheet(p, item)),
        ('Order', Icons.layers_outlined, () => _orderSheet(p, item)),
        ('Duplicate', Icons.copy, p.duplicateSelected),
      ];
    }

    if (item.type == EditorItemType.shape) {
      return [
        ('Color', Icons.palette_outlined, () => _shapeColorSheet(p, item)),
        ('Radius', Icons.rounded_corner, () => _radiusSheet(p, item)),
        ('Border', Icons.border_style, () => _borderSheet(p, item)),
        ('Opacity', Icons.opacity, () => _opacitySheet(p, item)),
        ('Order', Icons.layers_outlined, () => _orderSheet(p, item)),
      ];
    }

    return [
      ('Replace', Icons.video_library_outlined, () => _replaceImage(p, item)),
      ('Opacity', Icons.opacity, () => _opacitySheet(p, item)),
      ('Order', Icons.layers_outlined, () => _orderSheet(p, item)),
    ];
  }

  Widget _bottomAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _layersDrawer(CanvaProvider p) {
    return Drawer(
      width: 340,
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'Layers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: p.items.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final item = p.items[oldIndex];
                  final current = p.items;
                  if (newIndex > current.length - 1) return;
                  if (newIndex > oldIndex) {
                    p.bringForward(item.id);
                  } else {
                    p.sendBackward(item.id);
                  }
                },
                itemBuilder: (_, index) {
                  final item = p.items[index];
                  return ListTile(
                    key: ValueKey(item.id),
                    selected: p.selectedId == item.id,
                    onTap: () {
                      p.select(item.id);
                      Navigator.pop(context);
                    },
                    leading: Icon(_iconFor(item.type)),
                    title: Text(
                      item.type == EditorItemType.text ||
                          item.type == EditorItemType.emoji
                          ? item.text
                          : item.type.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            item.visible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => p.toggleVisibility(item.id),
                        ),
                        IconButton(
                          icon: Icon(
                            item.locked
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                          ),
                          onPressed: () => p.toggleLock(item.id),
                        ),
                      ],
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

  IconData _iconFor(EditorItemType type) {
    switch (type) {
      case EditorItemType.text:
        return Icons.text_fields;
      case EditorItemType.emoji:
        return Icons.emoji_emotions_outlined;
      case EditorItemType.image:
        return Icons.image_outlined;
      case EditorItemType.video:
        return Icons.video_library_outlined;
      case EditorItemType.shape:
        return Icons.crop_square;
    }
  }

  Future<void> _pickMedia() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      if (!mounted) return;
      context.read<CanvaProvider>().addImage(file.path, isLocal: true);
    }
  }

  Future<void> _replaceImage(CanvaProvider p, CanvaItem item) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    if (p.isBackground(item)) {
      p.replaceBackgroundWith(item.id, file.path, isLocal: true);
    } else {
      p.updateItem(item.id, contentUrl: file.path, isLocal: true);
    }
  }

  Future<void> _cropImage(CanvaProvider p, CanvaItem item) async {
    if (!item.isLocal || item.contentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crop needs a local image. Replace it from Gallery first.')),
      );
      return;
    }

    final result = await ImageCropper().cropImage(
      sourcePath: item.contentUrl,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop'),
      ],
    );

    if (result != null) {
      p.updateItem(item.id, contentUrl: result.path, isLocal: true);
    }
  }

  Widget _layersIcon() => const Icon(Icons.layers_outlined);

  void _backgroundSheet() {
    final p = context.read<CanvaProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 430,
          child: Column(
            children: [
              const ListTile(
                title: Text(
                  'Background',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose image'),
                onTap: () async {
                  Navigator.pop(context);
                  final file =
                  await _picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    p.setBackgroundImage(file.path, isLocal: true);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Color'),
                onTap: () {
                  Navigator.pop(context);
                  _backgroundColors();
                },
              ),
              ListTile(
                leading: const Icon(Icons.layers_clear_outlined),
                title: const Text('Remove background'),
                onTap: () {
                  p.removeBackground();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _backgroundColors() {
    final p = context.read<CanvaProvider>();
    final colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      const Color(0xFFF2F2F2),
      const Color(0xFFE8F0FE),
      const Color(0xFFFFF1E8),
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 240,
        child: GridView.count(
          crossAxisCount: 6,
          padding: const EdgeInsets.all(20),
          children: [
            for (final color in colors)
              GestureDetector(
                onTap: () {
                  p.setBackgroundColor(color);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _elementsSheet() {
    final p = context.read<CanvaProvider>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 330,
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.all(20),
            children: [
              _element('Square', Icons.crop_square, () {
                p.addShape();
                Navigator.pop(context);
              }),
              _element('Circle', Icons.circle_outlined, () {
                p.addShape(shape: EditorShape.circle);
                Navigator.pop(context);
              }),
              _element('Line', Icons.horizontal_rule, () {
                p.addShape(shape: EditorShape.line);
                Navigator.pop(context);
              }),
              _element('Emoji', Icons.emoji_emotions_outlined, () {
                p.addEmoji('✨');
                Navigator.pop(context);
              }),
              _element('Heart', Icons.favorite_outline, () {
                p.addEmoji('❤️');
                Navigator.pop(context);
              }),
              _element('Star', Icons.star_outline, () {
                p.addEmoji('⭐');
                Navigator.pop(context);
              }),
              _element('Fire', Icons.local_fire_department_outlined, () {
                p.addEmoji('🔥');
                Navigator.pop(context);
              }),
              _element('Check', Icons.check_circle_outline, () {
                p.addEmoji('✅');
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _element(String title, IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _moreSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_in),
              title: const Text('Zoom in'),
              onTap: () {
                Navigator.pop(context);
                _setZoom(_zoom + .25);
              },
            ),
            ListTile(
              leading: const Icon(Icons.zoom_out),
              title: const Text('Zoom out'),
              onTap: () {
                Navigator.pop(context);
                _setZoom(_zoom - .25);
              },
            ),
            ListTile(
              leading: const Icon(Icons.center_focus_strong),
              title: const Text('Reset canvas'),
              onTap: () {
                Navigator.pop(context);
                _canvasController.value = Matrix4.identity();
                setState(() => _zoom = 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setZoom(double value) {
    final v = value.clamp(.25, 4.0);
    setState(() => _zoom = v);
    _canvasController.value = Matrix4.identity()..scale(v);
  }

  void _editText(CanvaProvider p, CanvaItem item) {
    final controller = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit text'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              p.setText(item.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _fontSheet(CanvaProvider p, CanvaItem item) {
    final fonts = ['sans-serif', 'serif', 'monospace'];
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final font in fonts)
            ListTile(
              title: Text(font, style: TextStyle(fontFamily: font)),
              onTap: () {
                p.updateItem(item.id, fontFamily: font);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _colorSheet(CanvaProvider p, CanvaItem item) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 180,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(30),
          children: [
            for (final color in colors)
              GestureDetector(
                onTap: () {
                  p.setTextColor(item.id, color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 45,
                  height: 45,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _sizeSheet(CanvaProvider p, CanvaItem item) {
    double value = item.fontSize;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, set) => SizedBox(
          height: 180,
          child: Column(
            children: [
              const Text('Font size'),
              Slider(
                min: 8,
                max: 120,
                value: value.clamp(8, 120),
                onChanged: (v) {
                  set(() => value = v);
                  p.setFontSize(item.id, v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _alignSheet(CanvaProvider p, CanvaItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.format_align_left),
            onPressed: () {
              p.updateItem(item.id, textAlign: TextAlign.left);
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_align_center),
            onPressed: () {
              p.updateItem(item.id, textAlign: TextAlign.center);
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_align_right),
            onPressed: () {
              p.updateItem(item.id, textAlign: TextAlign.right);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _spacingSheet(CanvaProvider p, CanvaItem item) {
    double letter = item.letterSpacing;
    double line = item.lineHeight;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, set) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Letter spacing'),
              Slider(
                min: -2,
                max: 12,
                value: letter.clamp(-2, 12),
                onChanged: (v) {
                  set(() => letter = v);
                  p.updateItem(item.id, letterSpacing: v);
                },
              ),
              const Text('Line height'),
              Slider(
                min: .7,
                max: 2.5,
                value: line.clamp(.7, 2.5),
                onChanged: (v) {
                  set(() => line = v);
                  p.updateItem(item.id, lineHeight: v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _opacitySheet(CanvaProvider p, CanvaItem item) {
    double value = item.opacity;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, set) => SizedBox(
          height: 180,
          child: Column(
            children: [
              const Text('Opacity'),
              Slider(
                value: value,
                onChanged: (v) {
                  set(() => value = v);
                  p.setOpacity(item.id, v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterSheet(CanvaProvider p, CanvaItem item) {
    const filters = ['none', 'grayscale', 'sepia', 'high_contrast'];
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          for (final filter in filters)
            ChoiceChip(
              label: Text(filter),
              selected: item.filterType == filter,
              onSelected: (_) {
                p.setFilter(item.id, filter);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _adjustSheet(CanvaProvider p, CanvaItem item) {
    double brightness = item.brightness;
    double contrast = item.contrast;
    double saturation = item.saturation;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, set) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Brightness'),
              Slider(
                min: -1,
                max: 1,
                value: brightness,
                onChanged: (v) {
                  set(() => brightness = v);
                  p.setImageAdjustments(item.id, brightness: v);
                },
              ),
              const Text('Contrast'),
              Slider(
                min: .5,
                max: 2,
                value: contrast,
                onChanged: (v) {
                  set(() => contrast = v);
                  p.setImageAdjustments(item.id, contrast: v);
                },
              ),
              const Text('Saturation'),
              Slider(
                min: 0,
                max: 2,
                value: saturation,
                onChanged: (v) {
                  set(() => saturation = v);
                  p.setImageAdjustments(item.id, saturation: v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _flipSheet(CanvaProvider p, CanvaItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.flip),
            onPressed: () {
              p.updateItem(item.id, flipX: !item.flipX);
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () {
              p.updateItem(item.id, flipY: !item.flipY);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _orderSheet(CanvaProvider p, CanvaItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.vertical_align_top),
            title: const Text('Bring to front'),
            onTap: () {
              p.bringToFront(item.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.keyboard_arrow_up),
            title: const Text('Bring forward'),
            onTap: () {
              p.bringForward(item.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.keyboard_arrow_down),
            title: const Text('Send backward'),
            onTap: () {
              p.sendBackward(item.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.vertical_align_bottom),
            title: const Text('Send to back'),
            onTap: () {
              p.sendToBack(item.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _shapeColorSheet(CanvaProvider p, CanvaItem item) {
    final colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          for (final color in colors)
            GestureDetector(
              onTap: () {
                p.updateItem(item.id, fillColor: color);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _radiusSheet(CanvaProvider p, CanvaItem item) {
    double value = item.borderRadius;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, set) => SizedBox(
          height: 170,
          child: Slider(
            min: 0,
            max: 100,
            value: value.clamp(0, 100),
            onChanged: (v) {
              set(() => value = v);
              p.updateItem(item.id, borderRadius: v);
            },
          ),
        ),
      ),
    );
  }

  void _borderSheet(CanvaProvider p, CanvaItem item) {
    double width = item.borderWidth;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, set) => SizedBox(
          height: 170,
          child: Slider(
            min: 0,
            max: 10,
            value: width.clamp(0, 10),
            onChanged: (v) {
              set(() => width = v);
              p.updateItem(
                item.id,
                borderWidth: v,
                borderColor: Colors.black,
              );
            },
          ),
        ),
      ),
    );
  }

  void _preview(CanvaProvider p) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: AspectRatio(
          aspectRatio: 1,
          child: _canvas(p),
        ),
      ),
    );
  }
}
