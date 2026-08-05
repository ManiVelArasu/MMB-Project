import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../network/provider/editor_provider.dart';
import 'dart:io';

import '../../Api Model/editor_model.dart';

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
  String? _selectedFrameUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplateJsonAndInitEditor();
    });
  }

  Future<void> _loadTemplateJsonAndInitEditor() async {
    final provider = Provider.of<EditorProvider>(context, listen: false);

    provider.loadItemsFromJson([
      {
        "version": "5.3.0",
        "type": "rect",
        "left": 0,
        "top": 0,
        "width": 1080,
        "height": 1080,
        "fill": "white",
        "name": "clip",
      },
      {
        "version": "5.3.0",
        "type": "image",
        "left": 0,
        "top": 0,
        "width": 1080,
        "height": 1080,
        "src": "https://picsum.photos/1080/1080",
      },
      {
        "version": "5.3.0",
        "type": "circle",
        "left": -121.11,
        "top": -115.24,
        "width": 373.95,
        "height": 373.95,
        "stroke": "rgba(255,255,255,1)",
        "strokeWidth": 40,
        "radius": 186.97,
      },
      {
        "version": "5.3.0",
        "type": "image",
        "left": 0,
        "top": 0,
        "width": 415,
        "height": 415,
        "scaleX": 0.80,
        "scaleY": 0.80,
        "angle": -180,
        "src": "https://picsum.photos/415/415",
      },
      {
        "version": "5.3.0",
        "type": "textbox",
        "left": 98.06,
        "top": 399.07,
        "width": 444.29,
        "height": 95.35,
        "fill": "rgba(0,0,0,1)",
        "fontSize": 20,
        "fontWeight": 700,
        "text": "STAY COZY",
      },
      {
        "version": "5.3.0",
        "type": "textbox",
        "left": 98.06,
        "top": 481.09,
        "width": 529.87,
        "height": 95.35,
        "fill": "rgba(255,255,255,1)",
        "fontSize": 20,
        "fontWeight": 700,
        "text": "THIS SEASON",
      },
      {
        "version": "5.3.0",
        "type": "textbox",
        "left": 98.06,
        "top": 581.39,
        "width": 479.98,
        "height": 134.75,
        "fill": "rgba(0,0,0,1)",
        "fontSize": 25,
        "fontWeight": 400,
        "text": "Upgrade your home with stylish \nfurniture designed for comfort \nand everyday living.",
      },
      {
        "version": "5.3.0",
        "type": "rect",
        "left": 98.95,
        "top": 830.53,
        "width": 355.50,
        "height": 76.59,
        "fill": "rgba(0,0,0,1)",
        "rx": 38.3,
        "ry": 38.3,
      },
      {
        "version": "5.3.0",
        "type": "textbox",
        "left": 193.26,
        "top": 850.39,
        "width": 221.73,
        "height": 47.67,
        "fill": "rgba(255,255,255,1)",
        "fontSize": 22,
        "fontWeight": 700,
        "text": "SHOP NOW",
      },
      {
        "version": "5.3.0",
        "type": "image",
        "left": 583.80,
        "top": 266.28,
        "width": 360,
        "height": 360,
        "scaleX": 2.09,
        "scaleY": 2.09,
        "src": "https://picsum.photos/360/360",
      },
    ]);

    provider.fetchFreepikAssets("furniture");
    provider.fetchFreepikStickers("shapes");
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 45,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("My Frames", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                        InkWell(
                          onTap: () => Navigator.pop(modalContext),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.red, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => isStaticSelected = true),
                          child: Column(
                            children: [
                              const Text("Static Frames", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                              const SizedBox(height: 4),
                              if (isStaticSelected) Container(height: 2, width: 75, color: Colors.red)
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => setModalState(() => isStaticSelected = false),
                          child: Column(
                            children: [
                              const Text("Animated Frames", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              if (!isStaticSelected) Container(height: 2, width: 95, color: Colors.red)
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
                    Expanded(
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 14),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFrameUrl = "assets/images/thumbnail1.png";
                              });
                              Navigator.pop(modalContext);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.image_rounded, size: 40, color: Colors.blueAccent),
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
          ),
        );
      },
    );
  }

  void _showMyBrandBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 45,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Upload Image", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {},
                    child: const Text("LOGO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {},
                    child: const Text("MOBILE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {},
                    child: const Text("WEBSITE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  void _showTextStylesBottomSheet(BuildContext context, EditorProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 45,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Add Text", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("My Heading", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      onTap: () {
                        provider.addText(initialText: "My Heading");
                        Navigator.pop(modalContext);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text("My Subheading", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onTap: () {
                        provider.addText(initialText: "My Subheading");
                        Navigator.pop(modalContext);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text("My Paragraph", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      onTap: () {
                        provider.addText(initialText: "My Paragraph");
                        Navigator.pop(modalContext);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showMediaBottomSheet(BuildContext context) {
    final parentProvider = context.read<EditorProvider>();
    parentProvider.fetchFreepikAssets("furniture");
    parentProvider.fetchFreepikStickers("shapes");
    int selectedTab = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final keyboardHeight = MediaQuery.of(modalContext).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: SafeArea(
            child: ChangeNotifierProvider.value(
              value: parentProvider,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final provider = context.watch<EditorProvider>();

                  return Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            height: 4,
                            width: 45,
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Media & Shapes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                            InkWell(
                              onTap: () => Navigator.pop(modalContext),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.red, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setModalState(() => selectedTab = 0),
                              child: Text("Uploads", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 0 ? Colors.black : Colors.grey)),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () => setModalState(() => selectedTab = 1),
                              child: Text("Photos", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 1 ? Colors.black : Colors.grey)),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () => setModalState(() => selectedTab = 2),
                              child: Text("Shapes", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 2 ? Colors.black : Colors.grey)),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        Expanded(
                          child: selectedTab == 0
                              ? ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(modalContext);
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(source: ImageSource.camera);
                                  if (image != null) provider.addImage(image.path, isLocal: true);
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECEE),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_rounded, color: Colors.red, size: 28),
                                      SizedBox(height: 8),
                                      Text("CAMERA", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(modalContext);
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) provider.addImage(image.path, isLocal: true);
                                },
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECEE),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_library_rounded, color: Colors.red, size: 28),
                                      SizedBox(height: 8),
                                      Text("GALLERY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                              : ListView(
                            scrollDirection: Axis.horizontal,
                            children: (selectedTab == 1 ? provider.freepikAssets : provider.freepikStickers)
                                .map((url) => _buildAssetCard(provider, url, modalContext))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBackgroundBottomSheet(BuildContext context) {
    final parentProvider = context.read<EditorProvider>();
    int selectedTab = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return SafeArea(
          child: ChangeNotifierProvider.value(
            value: parentProvider,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final provider = context.watch<EditorProvider>();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 45,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Background", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                          InkWell(
                            onTap: () => Navigator.pop(modalContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.red, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setModalState(() => selectedTab = 0),
                            child: Text("Uploads", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 0 ? Colors.black : Colors.grey)),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () => setModalState(() => selectedTab = 1),
                            child: Text("Photos", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 1 ? Colors.black : Colors.grey)),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () => setModalState(() => selectedTab = 2),
                            child: Text("Colors", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: selectedTab == 2 ? Colors.black : Colors.grey)),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Expanded(
                        child: selectedTab == 0
                            ? ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                Navigator.pop(modalContext);
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) provider.addImage(image.path, isLocal: true);
                              },
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECEE),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_library_rounded, color: Colors.red, size: 28),
                                    SizedBox(height: 8),
                                    Text("GALLERY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                            : ListView(
                          scrollDirection: Axis.horizontal,
                          children: provider.freepikAssets.map((url) => _buildAssetCard(provider, url, modalContext)).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showFontStyleBottomSheet(BuildContext context, EditorProvider provider, String itemId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.40,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Font Style", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text("Roboto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onTap: () => Navigator.pop(modalContext),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text("Poppins", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onTap: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontColorPicker(BuildContext context, EditorProvider provider, String itemId) {
    final List<Color> presetColors = [
      Colors.orange, Colors.red, Colors.blue, Colors.teal, Colors.lime, Colors.purple, Colors.pink, Colors.redAccent,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.38,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Font Color", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 14, crossAxisSpacing: 14),
                  itemCount: presetColors.length,
                  itemBuilder: (context, index) {
                    Color color = presetColors[index];
                    return GestureDetector(
                      onTap: () {
                        provider.updateTextColor(itemId, color);
                        Navigator.pop(modalContext);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          border: Border.all(color: Colors.white, width: 2),
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

  void _showTextEditorDialog(BuildContext context, EditorProvider provider, {String? itemId, String initialText = ""}) {
    final textController = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Edit Text", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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

  Widget _buildAssetCard(EditorProvider provider, String imageUrl, BuildContext sheetContext) {
    return GestureDetector(
      onTap: () {
        provider.addImage(imageUrl, isLocal: false);
        Navigator.pop(sheetContext);
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
        ),
      ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.undo_rounded, color: Colors.grey), onPressed: () => provider.undo()),
          IconButton(icon: const Icon(Icons.redo_rounded, color: Colors.grey), onPressed: () => provider.redo()),
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.red),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Design Saved!"))),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double scaleX = constraints.maxWidth / 1080;
                  double scaleY = constraints.maxHeight / 1080;

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      ...provider.items.map((item) {
                        return Positioned(
                          left: item.position.dx * scaleX,
                          top: item.position.dy * scaleY,
                          child: Transform.scale(
                            scale: scaleX,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: item.width ?? 200,
                              child: EditableItemWidget(
                                item: item,
                                onItemSelected: (type, id) {
                                  setState(() {
                                    _selectedItemType = type;
                                    _selectedItemId = id;
                                  });
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_selectedFrameUrl != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Image.asset(_selectedFrameUrl!, fit: BoxFit.cover),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _selectedItemType == 'text'
            ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                if (_selectedItemId != null) {
                  final item = provider.items.firstWhere((e) => e.id == _selectedItemId);
                  _showTextEditorDialog(context, provider, itemId: item.id, initialText: item.text ?? "");
                }
              },
              child: _buildTextActionItem(Icons.edit_rounded, "EDIT"),
            ),
            InkWell(
              onTap: () {
                if (_selectedItemId != null) {
                  _showFontStyleBottomSheet(context, provider, _selectedItemId!);
                }
              },
              child: _buildTextActionItem(Icons.font_download_rounded, "FONT STYLE"),
            ),
            InkWell(
              onTap: () {},
              child: _buildTextActionItem(Icons.format_align_left_rounded, "FORMAT"),
            ),
            InkWell(
              onTap: () {},
              child: _buildTextActionItem(Icons.space_bar_rounded, "SPACING"),
            ),
            InkWell(
              onTap: () {
                if (_selectedItemId != null) {
                  _showFontColorPicker(context, provider, _selectedItemId!);
                }
              },
              child: _buildTextActionItem(Icons.color_lens_rounded, "COLOR"),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 0);
                _showFramesBottomSheet(context);
              },
              child: _buildBottomNavItem(Icons.layers_rounded, "FRAMES", _bottomNavIndex == 0),
            ),
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 1);
                _showMyBrandBottomSheet(context);
              },
              child: _buildBottomNavItem(Icons.branding_watermark_rounded, "MY BRAND", _bottomNavIndex == 1),
            ),
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 2);
                _showTextStylesBottomSheet(context, provider);
              },
              child: _buildBottomNavItem(Icons.text_fields_rounded, "TEXT", _bottomNavIndex == 2),
            ),
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 3);
                _showMediaBottomSheet(context);
              },
              child: _buildBottomNavItem(Icons.photo_library_rounded, "MEDIA", _bottomNavIndex == 3),
            ),
            InkWell(
              onTap: () {
                setState(() => _bottomNavIndex = 4);
                _showBackgroundBottomSheet(context);
              },
              child: _buildBottomNavItem(Icons.wallpaper_rounded, "BACKGROUND", _bottomNavIndex == 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextActionItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade500, size: 22),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ==========================================
// 2. EDITABLE ITEM WIDGET
// ==========================================
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
        // 🚀 Separate Action Sheet for Text vs Image
        if (currentItem.type == 'text') {
          _showTextSizeActionSheet(context, provider, currentItem);
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

  // 🚀 Dedicated Action Sheet for Text Size Adjustment & Layering
  void _showTextSizeActionSheet(BuildContext context, EditorProvider provider, EditorItem item) {
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
                  height: MediaQuery.of(context).size.height * 0.40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Text Size & Tools", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                tooltip: "Bring to Front",
                                icon: const Icon(Icons.flip_to_front, color: Colors.amberAccent),
                                onPressed: () => provider.bringToFront(currentItem.id ?? ""),
                              ),
                              IconButton(
                                tooltip: "Send to Back",
                                icon: const Icon(Icons.flip_to_back, color: Colors.blueAccent),
                                onPressed: () => provider.sendToBack(currentItem.id ?? ""),
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
                            const Text("Font Size (Increase / Decrease)", style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Slider(
                              value: currentItem.fontSize,
                              min: 10.0,
                              max: 120.0,
                              activeColor: Colors.amberAccent,
                              inactiveColor: Colors.white24,
                              onChanged: (v) => setModalState(() {
                                int index = provider.items.indexWhere((e) => e.id == currentItem.id);
                                if (index != -1) {
                                  provider.items[index] = provider.items[index].copyWith(fontSize: v);
                                  provider.notifyListeners();
                                }
                              }),
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

  // Action Sheet for Images
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
                          const Text("Pro Editing Tools", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                tooltip: "Bring to Front",
                                icon: const Icon(Icons.flip_to_front, color: Colors.amberAccent),
                                onPressed: () => provider.bringToFront(currentItem.id ?? ""),
                              ),
                              IconButton(
                                tooltip: "Send to Back",
                                icon: const Icon(Icons.flip_to_back, color: Colors.blueAccent),
                                onPressed: () => provider.sendToBack(currentItem.id ?? ""),
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

// ==========================================
// 2. EDITABLE ITEM WIDGET
// ==========================================


// ==========================================
// 2. EDITABLE ITEM WIDGET
// ==========================================

