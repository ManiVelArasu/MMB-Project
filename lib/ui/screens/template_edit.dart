import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/plugins/emoji_picker_flutter/src/config.dart';
import 'package:pro_image_editor/plugins/emoji_picker_flutter/src/emoji_picker.dart';
import 'package:provider/provider.dart';

import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';


class TemplateEditScreen extends StatelessWidget {
  const TemplateEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ChangeNotifierProvider(
        create: (_) => EditorProvider(),
        child: const EditorView(),
      ),
    );
  }
}

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  int _bottomNavIndex = 0;
  String? _selectedItemType;
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EditorProvider>(context, listen: false);
      provider.loadItemsFromJson([
        {
          "id": "1",
          "type": "image",
          "content_url": "https://picsum.photos/400/400",
          "position_x": 50.0,
          "position_y": 100.0,
          "width": 300.0,
          "height": 300.0,
          "text": "rounded",
        },
      ]);
    });
  }

  void _showFramesBottomSheet(BuildContext context) {
    final parentProvider = context.read<EditorProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: parentProvider,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              bool isStaticSelected = true;
              return Container(
                height: MediaQuery.of(context).size.height * 0.45,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(height: 4, width: 50, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("My Frames", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => Navigator.pop(modalContext)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => isStaticSelected = true),
                          child: Text("Static Frames", style: TextStyle(fontWeight: FontWeight.bold, color: isStaticSelected ? Colors.black : Colors.grey)),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => setModalState(() => isStaticSelected = false),
                          child: Text("Animated Frames", style: TextStyle(fontWeight: FontWeight.bold, color: !isStaticSelected ? Colors.black : Colors.grey)),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 12),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                            child: const Center(child: Icon(Icons.image, size: 40, color: Colors.blue)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showEmojiPicker(BuildContext context, EditorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      builder: (modalContext) {
        return SizedBox(
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              provider.addEmoji(emoji.emoji);
              Navigator.pop(modalContext);
            },
            config: const Config(height: 256),
          ),
        );
      },
    );
  }

  void _showMediaBottomSheet(BuildContext context) {
    final parentProvider = context.read<EditorProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              int selectedTab = 0;
              return Container(
                height: MediaQuery.of(context).size.height * 0.25,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Media", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.red, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => selectedTab = 0),
                          child: Text("Uploads", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 0 ? Colors.black : Colors.grey)),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => setModalState(() => selectedTab = 1),
                          child: Text("Elements", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 1 ? Colors.black : Colors.grey)),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            setModalState(() => selectedTab = 2);
                            _showEmojiPicker(context, parentProvider);
                          },
                          child: Text("Stickers", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 2 ? Colors.black : Colors.grey)),
                        ),
                      ],
                    ),
                    const Divider(height: 1, thickness: 1, color: Colors.black12),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.camera);
                              if (image != null) parentProvider.addImage(image.path, isLocal: true);
                            },
                            child: Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(color: const Color(0xFFFFECEE), borderRadius: BorderRadius.circular(14)),
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: Colors.red, size: 26), SizedBox(height: 6), Text("CAMERA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10))]),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) parentProvider.addImage(image.path, isLocal: true);
                            },
                            child: Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(color: const Color(0xFFFFECEE), borderRadius: BorderRadius.circular(14)),
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_library, color: Colors.red, size: 26), SizedBox(height: 6), Text("GALLERY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10))]),
                            ),
                          ),
                          _buildAssetCard(parentProvider, 'https://picsum.photos/300/300', context),
                          _buildAssetCard(parentProvider, 'https://picsum.photos/310/310', context),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssetCard(EditorProvider provider, String imageUrl, BuildContext sheetContext) {
    return GestureDetector(
      onTap: () {
        provider.addImage(imageUrl, isLocal: false);
        Navigator.pop(sheetContext);
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _showTextEditorDialog(BuildContext context, EditorProvider provider, {String? itemId, String initialText = ""}) {
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
                  if (itemId == null) {
                    provider.addText(initialText: textController.text);
                  } else {
                    provider.updateTextContent(itemId, textController.text);
                  }
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.red), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.undo, color: Colors.grey), onPressed: () => provider.undo()),
          IconButton(icon: const Icon(Icons.redo, color: Colors.grey), onPressed: () => provider.redo()),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.red),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Design Saved!")));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFFF0F2F5)),
          ...provider.items.map((item) => EditableItemWidget(
            item: item,
            onItemSelected: (type, id) {
              setState(() {
                _selectedItemType = type;
                _selectedItemId = id;
              });
            },
          )),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedItemType == 'text')
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFECEE), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🚀 Color Picker Button
                  IconButton(
                    icon: const Icon(Icons.color_lens, color: Colors.red, size: 18),
                    tooltip: "Font Color",
                    onPressed: () {
                      if (_selectedItemId != null) {
                        _showFontColorPicker(context, provider, _selectedItemId!);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.red, size: 18),
                    tooltip: "Edit Text",
                    onPressed: () {
                      if (_selectedItemId != null) {
                        final item = provider.items.firstWhere((e) => e.id == _selectedItemId);
                        _showTextEditorDialog(context, provider, itemId: item.id, initialText: item.text ?? "");
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.red, size: 18),
                    onPressed: () {
                      if (_selectedItemId != null) provider.duplicateItem(_selectedItemId!);
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () {
                      if (_selectedItemId != null) {
                        provider.removeItem(_selectedItemId!);
                        setState(() {
                          _selectedItemType = null;
                          _selectedItemId = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () { setState(() => _bottomNavIndex = 0); _showFramesBottomSheet(context); },
                  child: _buildBottomNavItem(Icons.layers, "FRAMES", _bottomNavIndex == 0),
                ),
                InkWell(
                  onTap: () => setState(() => _bottomNavIndex = 1),
                  child: _buildBottomNavItem(Icons.branding_watermark, "MY BRAND", _bottomNavIndex == 1),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _bottomNavIndex = 2);
                    _showTextEditorDialog(context, provider);
                  },
                  child: _buildBottomNavItem(Icons.text_fields, "TEXT", _bottomNavIndex == 2),
                ),
                InkWell(
                  onTap: () { setState(() => _bottomNavIndex = 3); _showMediaBottomSheet(context); },
                  child: _buildBottomNavItem(Icons.photo, "MEDIA", _bottomNavIndex == 3),
                ),
                InkWell(
                  onTap: () => setState(() => _bottomNavIndex = 4),
                  child: _buildBottomNavItem(Icons.wallpaper, "BACKGROUND", _bottomNavIndex == 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showFontColorPicker(BuildContext context, EditorProvider provider, String itemId) {
    // 🎨 Preset color circles list matching your design
    final List<Color> presetColors = [
      Colors.orange, Colors.red, Colors.blue, Colors.teal, Colors.lime, Colors.purple, Colors.pink,
      Colors.redAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.lightBlue, Colors.cyan,
      Colors.greenAccent, Colors.limeAccent, Colors.orangeAccent,
      Colors.green.shade200, Colors.lightGreen.shade200, Colors.teal.shade100, Colors.blue.shade100,
      Colors.indigo.shade100, Colors.purple.shade100, Colors.pink.shade100, Colors.red.shade100, Colors.orange.shade200
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.38,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              // Header Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Font Color",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Color Grid Palette
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: presetColors.length + 2, // +2 for color wheel and custom adjustment icons
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Multi-color wheel button
                      return GestureDetector(
                        onTap: () {
                          // Optional: Open advanced color picker here if needed
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
                            ),
                          ),
                          child: const Center(child: Icon(Icons.add, color: Colors.white, size: 16)),
                        ),
                      );
                    } else if (index == 1) {
                      // Sliders/Adjustment icon button
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.shade100,
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: const Center(child: Icon(Icons.tune, color: Colors.brown, size: 16)),
                      );
                    }

                    // Preset Color Circles
                    Color color = presetColors[index - 2];
                    return GestureDetector(
                      onTap: () {
                        provider.updateTextColor(itemId, color);
                        Navigator.pop(modalContext);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1),
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
  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
