import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';
import '../../network/provider/custom_theme_provider.dart';

class TemplateEditScreen extends StatefulWidget {
  const TemplateEditScreen({super.key});

  @override
  State<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  String resizeSize = "Post Square (1:1)";
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        resizeSize = args;
      }
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ChangeNotifierProvider(
          create: (_) => EditorProvider(),
          child: EditorView(resizeSize: resizeSize),
        ),
      ),
    );
  }
}

class EditorView extends StatefulWidget {
  final String resizeSize;
  const EditorView({super.key, required this.resizeSize});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  int _bottomNavIndex = 0;

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
    ]);

    provider.fetchFreePikAssets("furniture");
    provider.fetchFreePikStickers("shapes");
  }

  void _showFontFamilyBottomSheet(
      BuildContext context,
      EditorProvider provider,
      String itemId,
      bool isDark,
      ) {

    final List<String> fontList = [
      "Inter",
      "Janda Manatee Solid",
      "JekoVariable",
      "Anton",
      "Roboto",
      "Poppins",
      "Pacifico",
      "Playfair Display",
      "Montserrat"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.60, // கொஞ்சம் உயரம் அதிகரிப்பு
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header with Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText("Fonts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                  InkWell(
                    onTap: () {
                      provider.clearSelection();
                      Navigator.pop(modalContext);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF2A1A1C) : Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Font List
              Expanded(
                child: ListView.separated(
                  itemCount: fontList.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey.withOpacity(0.2)),
                  itemBuilder: (context, index) {
                    final font = fontList[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: AppText(
                        "Aa - $font",
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {
                        provider.updateFontFamily(itemId, font);
                        Navigator.pop(modalContext);
                      },
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


  void _showFontColorBottomSheet(BuildContext context, EditorProvider provider, String itemId, bool isDark) {
    int selectedTab = 0;
    Color pickerColor = Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText("Colors", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          provider.clearSelection();
                          Navigator.pop(modalContext);
                        },
                      ),
                    ],
                  ),

                  // Tab Selection
                  Row(
                    children: [
                      _buildTab(selectedTab == 0, "Presets", () => setModalState(() => selectedTab = 0)),
                      const SizedBox(width: 20),
                      _buildTab(selectedTab == 1, "Custom", () => setModalState(() => selectedTab = 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Content
                  Expanded(
                    child: selectedTab == 0
                        ? GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
                      itemCount: Colors.primaries.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => provider.updateTextColor(itemId, Colors.primaries[index]),
                          child: Container(decoration: BoxDecoration(color: Colors.primaries[index], shape: BoxShape.circle)),
                        );
                      },
                    )
                        : SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (color) {
                          setModalState(() => pickerColor = color);
                          provider.updateTextColor(itemId, color);
                        },
                        enableAlpha: false,
                        displayThumbColor: true,
                        paletteType: PaletteType.hueWheel,
                      ),
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

// Helper Widget for Tabs
  Widget _buildTab(bool isSelected, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AppText(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.red : Colors.grey)),
          if (isSelected) Container(height: 2, width: 30, color: Colors.red, margin: const EdgeInsets.only(top: 4)),
        ],
      ),
    );
  }

  void _showFormatBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    final item = provider.items.firstWhere(
      (e) => e.id == itemId,
      orElse: () => provider.items.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.45,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Format",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            Navigator.pop(modalContext), // 🚀 Close button
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A1C)
                                : Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(
                        "Text Size",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      AppText("${item.fontSize.toInt()}"),
                    ],
                  ),
                  Slider(
                    value: item.fontSize ?? 20.0,
                    min: 10.0,
                    max: 100.0,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setModalState(() {
                        provider.updateFontSize(itemId, val);
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppText(
                        "Transparency",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      AppText(
                        "${((item.opacity ?? 1.0) * 100).toStringAsFixed(0)}%",
                      ),
                    ],
                  ),
                  Slider(
                    value: item.opacity ?? 1.0,
                    min: 0.0,
                    max: 1.0,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setModalState(() {
                        provider.updateOpacity(itemId, val);
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showImageUploadsBottomSheet(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    provider.fetchFreePikAssets("nature");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.45,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      "Freepik Uploads",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          Navigator.pop(modalContext), // 🚀 Close button
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A1A1C)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: provider.isFreePikLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : provider.freePikAssets.isEmpty
                      ? Center(
                          child: AppText(
                            "No images found",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: provider.freePikAssets.length,
                          itemBuilder: (context, index) {
                            final imgUrl = provider.freePikAssets[index];
                            return GestureDetector(
                              onTap: () {
                                provider.addImage(imgUrl, isLocal: false);
                                Navigator.pop(modalContext);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(imgUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageTransparencyBottomSheet(
    BuildContext context,
    EditorProvider provider,
    String itemId,
    bool isDark,
  ) {
    final item = provider.items.firstWhere(
      (e) => e.id == itemId,
      orElse: () => provider.items.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.25,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Transparency",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(
                          modalContext,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A1A1C)
                                : Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: item.opacity,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            setModalState(() {
                              provider.updateOpacity(itemId, val);
                            });
                          },
                        ),
                      ),
                      AppText(
                        "${((item.opacity) * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFramesBottomSheet(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "My Frames",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1A1C)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        provider.setSelectedFrame(
                          "assets/images/thumbnail1.png",
                        );
                        Navigator.pop(modalContext);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.grey.shade50,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_rounded,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
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

  void _showMyBrandBottomSheet(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Upload Brand Assets",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1A1C)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(modalContext);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    provider.addImage(image.path, isLocal: true);
                  }
                },
                child: const AppText(
                  "UPLOAD LOGO / IMAGE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTextStylesBottomSheet(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    "Add Text",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(modalContext),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1A1C)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: AppText(
                  "My Heading",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  provider.addText(initialText: "My Heading");
                  Navigator.pop(modalContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMediaBottomSheet(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    int selectedTab = 2;
    String searchQuery = "shapes";

    provider.fetchFreePikAssets("furniture");
    provider.fetchFreePikStickers("shapes");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: ChangeNotifierProvider.value(
            value: provider,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final edProvider = context.watch<EditorProvider>();
                return Container(
                  height: MediaQuery.of(context).size.height * 0.60,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 45,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            "Media",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(modalContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A1A1C)
                                    : Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setModalState(() => selectedTab = 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Uploads",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTab == 0
                                        ? (isDark ? Colors.white : Colors.black)
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (selectedTab == 0)
                                  Container(
                                    height: 2,
                                    width: 55,
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () {
                              setModalState(() => selectedTab = 1);
                              edProvider.fetchFreePikAssets("design elements");
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Elements",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTab == 1
                                        ? (isDark ? Colors.white : Colors.black)
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (selectedTab == 1)
                                  Container(
                                    height: 2,
                                    width: 60,
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: () {
                              setModalState(() => selectedTab = 2);
                              edProvider.fetchFreePikStickers("shapes");
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Stickers",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTab == 2
                                        ? (isDark ? Colors.white : Colors.black)
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (selectedTab == 2)
                                  Container(
                                    height: 2,
                                    width: 50,
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        height: 20,
                        thickness: 1,
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),

                      if (selectedTab == 0) ...[
                        Expanded(
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(modalContext);
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(
                                    source: ImageSource.camera,
                                  );
                                  if (image != null)
                                    edProvider.addImage(
                                      image.path,
                                      isLocal: true,
                                    );
                                },
                                child: Container(
                                  width: 95,
                                  height: 95,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A1A1C)
                                        : const Color(0xFFFFECEE),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                      SizedBox(height: 6),
                                      AppText(
                                        "CAMERA",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(modalContext);
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image != null)
                                    edProvider.addImage(
                                      image.path,
                                      isLocal: true,
                                    );
                                },
                                child: Container(
                                  width: 95,
                                  height: 95,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A1A1C)
                                        : const Color(0xFFFFECEE),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_library,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                      SizedBox(height: 6),
                                      AppText(
                                        "GALLERY",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: TextField(
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onChanged: (val) {
                              setModalState(() => searchQuery = val);
                              if (selectedTab == 1) {
                                edProvider.fetchFreePikAssets(val);
                              } else {
                                edProvider.fetchFreePikStickers(val);
                              }
                            },
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.search,
                                color: Colors.grey.shade500,
                              ),
                              hintText: "Find your Industry",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              suffixIcon: const Icon(
                                Icons.mic,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                [
                                  "Super",
                                  "Greetings",
                                  "Thank You",
                                  "Birthday",
                                  "Offers",
                                  "Shapes",
                                ].map((category) {
                                  bool isChipSelected =
                                      searchQuery.toLowerCase() ==
                                      category.toLowerCase();
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(
                                        () => searchQuery = category,
                                      );
                                      if (selectedTab == 1) {
                                        edProvider.fetchFreePikAssets(category);
                                      } else {
                                        edProvider.fetchFreePikStickers(
                                          category,
                                        );
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isChipSelected
                                            ? Colors.grey.shade800
                                            : (isDark
                                                  ? const Color(0xFF2C2C2C)
                                                  : Colors.white),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade300,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: AppText(
                                          category,
                                          style: TextStyle(
                                            color: isChipSelected
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              (selectedTab == 1
                                  ? edProvider.isFreePikLoading
                                  : edProvider.isStickersLoading)
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                    strokeWidth: 2,
                                  ),
                                )
                              : (selectedTab == 1
                                        ? edProvider.freePikAssets
                                        : edProvider.freePikStickers)
                                    .isEmpty
                              ? Center(
                                  child: AppText(
                                    "No items found",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                  itemCount: selectedTab == 1
                                      ? edProvider.freePikAssets.length
                                      : edProvider.freePikStickers.length,
                                  itemBuilder: (context, index) {
                                    final itemUrl = selectedTab == 1
                                        ? edProvider.freePikAssets[index]
                                        : edProvider.freePikStickers[index];
                                    return GestureDetector(
                                      onTap: () {
                                        edProvider.addImage(
                                          itemUrl,
                                          isLocal: false,
                                        );
                                        Navigator.pop(modalContext);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(itemUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
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

  void _showBackgroundBottomSheet(
    BuildContext context,
    EditorProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final edProvider = context.watch<EditorProvider>();
                return Container(
                  height: MediaQuery.of(context).size.height * 0.50,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            "Background",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(modalContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A1A1C)
                                    : Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: edProvider.freePikAssets.length,
                          itemBuilder: (context, index) {
                            final bgUrl = edProvider.freePikAssets[index];
                            return GestureDetector(
                              onTap: () {
                                edProvider.addImage(bgUrl, isLocal: false);
                                Navigator.pop(modalContext);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(bgUrl),
                                    fit: BoxFit.cover,
                                  ),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final themeProvider = context.watch<CustomThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    double aspectRatio = 1 / 1;
    if (widget.resizeSize.contains("4:5")) {
      aspectRatio = 4 / 5;
    } else if (widget.resizeSize.contains("9:16")) {
      aspectRatio = 9 / 16;
    } else if (widget.resizeSize.contains("Horizontal")) {
      aspectRatio = 1200 / 628;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          widget.resizeSize,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.grey),
            onPressed: () => provider.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, color: Colors.grey),
            onPressed: () => provider.redo(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
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
                                  provider.setSelectedItem(type, id);
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                      if (provider.selectedFrameUrl != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Image.asset(
                              provider.selectedFrameUrl!,
                              fit: BoxFit.cover,
                            ),
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
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child:
            provider.selectedItemType == 'textbox' ||
                provider.selectedItemType == 'text'
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showFontFamilyBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.font_download_rounded,
                      "FONT",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showFormatBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.text_format_rounded,
                      "FORMAT",
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: _buildTextActionItem(
                      Icons.space_bar_rounded,
                      "SPACING",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showFontColorBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.color_lens_rounded,
                      "COLOR",
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: _buildTextActionItem(
                      Icons.format_align_left_rounded,
                      "ALIGN",
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: _buildTextActionItem(Icons.layers_rounded, "ORDER"),
                  ),
                  InkWell(
                    onTap: () {
                      provider
                          .clearSelection(); // 🚀 Selection-ai clear seithu main menu-vukku return aagum
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1A1C)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              )
            : provider.selectedItemType == 'image'
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      _showImageUploadsBottomSheet(context, provider, isDark);
                    },
                    child: _buildTextActionItem(
                      Icons.upload_rounded,
                      "UPLOADS",
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        provider.addImage(image.path, isLocal: true);
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.photo_library_rounded,
                      "PHOTOS",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (provider.selectedItemId != null) {
                        _showImageTransparencyBottomSheet(
                          context,
                          provider,
                          provider.selectedItemId!,
                          isDark,
                        );
                      }
                    },
                    child: _buildTextActionItem(
                      Icons.opacity_rounded,
                      "TRANSPARENCY",
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: _buildTextActionItem(
                      Icons.layers_rounded,
                      "POSITION",
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: _buildTextActionItem(
                      Icons.auto_awesome_rounded,
                      "MAGIC MEDIA",
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      provider.clearSelection();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1A1C)
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 0);
                      _showFramesBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.layers_rounded,
                      "FRAMES",
                      _bottomNavIndex == 0,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 1);
                      _showMyBrandBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.branding_watermark_rounded,
                      "MY BRAND",
                      _bottomNavIndex == 1,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 2);
                      _showTextStylesBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.text_fields_rounded,
                      "TEXT",
                      _bottomNavIndex == 2,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 3);
                      _showMediaBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.photo_library_rounded,
                      "MEDIA",
                      _bottomNavIndex == 3,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _bottomNavIndex = 4);
                      _showBackgroundBottomSheet(context, provider, isDark);
                    },
                    child: _buildBottomNavItem(
                      Icons.wallpaper_rounded,
                      "BACKGROUND",
                      _bottomNavIndex == 4,
                    ),
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
        AppText(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade500,
          size: 22,
        ),
        const SizedBox(height: 5),
        AppText(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
