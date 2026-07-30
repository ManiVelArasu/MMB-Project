import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/plugins/emoji_picker_flutter/src/config.dart';
import 'package:pro_image_editor/plugins/emoji_picker_flutter/src/emoji_picker.dart';
import 'package:provider/provider.dart';

import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// Neenga munnadi create panna EditorScreen-ki inga import pannikonga:
// import 'editor_screen.dart';

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

  // 🚀 Frames Bottom Sheet (Screenshot-il irukkum adhe design)
  void _showFramesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
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
                  Center(
                    child: Container(
                      height: 4,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "My Frames",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.red, size: 20), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.add_circle, color: Colors.red, size: 24), onPressed: () {}),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setModalState(() => isStaticSelected = true),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Static Frames",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isStaticSelected ? Colors.black : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isStaticSelected) Container(height: 2, width: 85, color: Colors.red),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => setModalState(() => isStaticSelected = false),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Animated Frames",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: !isStaticSelected ? Colors.black : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!isStaticSelected) Container(height: 2, width: 100, color: Colors.red),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  ),
                                  child: Center(child: Icon(Icons.image, size: 40, color: Colors.blue.shade300)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  index == 1 ? "Rs.0 (Rs.100 Unlocked)" : "Free",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ],
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
      },
    );
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
      backgroundColor: const Color(0xFFF0F2F5), // Canva style light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.grey),
            onPressed: () => provider.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.grey),
            onPressed: () => provider.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.red),
            onPressed: () {
             // print(provider.getItemsAsJson());
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 0);
                _showFramesBottomSheet(context);
              },
              child: _buildBottomNavItem(Icons.layers, "FRAMES", _bottomNavIndex == 0),
            ),
            InkWell(
              onTap: () => setState(() => _bottomNavIndex = 1),
              child: _buildBottomNavItem(Icons.branding_watermark, "MY BRAND", _bottomNavIndex == 1),
            ),
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 2);
                provider.addText(initialText: "New Text");
              },
              child: _buildBottomNavItem(Icons.text_fields, "TEXT", _bottomNavIndex == 2),
            ),
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 3);
                _showMediaBottomSheet(context);
              },
              child: _buildBottomNavItem(Icons.photo, "MEDIA", _bottomNavIndex == 3),
            ),
            InkWell(
              onTap: () => setState(() => _bottomNavIndex = 4),
              child: _buildBottomNavItem(Icons.wallpaper, "BACKGROUND", _bottomNavIndex == 4),
            ),
          ],
        ),
      ),
    );
  }
  void _showMediaBottomSheet(BuildContext context) {
    final parentContext = context;
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
                    // Top Drag Handle
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
          
                    // Header Title & Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Media",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.red, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
          
                    // Tabs Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => selectedTab = 0),
                          child: Text(
                            "Uploads",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedTab == 0 ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => setModalState(() => selectedTab = 1),
                          child: Text(
                            "Elements",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedTab == 1 ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => setModalState(() => selectedTab = 2),
                          child: Text(
                            "Stickers",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: selectedTab == 2 ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1, color: Colors.black12),
                    const SizedBox(height: 8),
          
                    // Tab Content Grid/Options (Compact width & height)
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // 1. Camera Button Card
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.camera);
                              if (image != null && parentContext.mounted) {
                                parentContext.read<EditorProvider>().addImage(image.path, isLocal: true);
                              }
                            },
                            child: Container(
                              width: 90, // 🚀 Compact size
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECEE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.red, size: 26),
                                  SizedBox(height: 6),
                                  Text("CAMERA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
          
                          // 2. Gallery Button Card
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null && parentContext.mounted) {
                                parentContext.read<EditorProvider>().addImage(image.path, isLocal: true);
                              }
                            },
                            child: Container(
                              width: 90, // 🚀 Compact size
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECEE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library, color: Colors.red, size: 26),
                                  SizedBox(height: 6),
                                  Text("GALLERY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
          
                          // 3. Sample / Uploaded Asset Cards
                          _buildAssetCard(parentContext, 'https://picsum.photos/300/300', context),
                          _buildAssetCard(parentContext, 'https://picsum.photos/310/310', context),
                          _buildAssetCard(parentContext, 'https://picsum.photos/320/320', context),
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

  Widget _buildAssetCard(BuildContext parentContext, String imageUrl, BuildContext sheetContext) {
    return GestureDetector(
      onTap: () {
        parentContext.read<EditorProvider>().addImage(imageUrl, isLocal: false);
        Navigator.pop(sheetContext);
      },
      child: Container(
        width: 90, // 🚀 Compact size
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
