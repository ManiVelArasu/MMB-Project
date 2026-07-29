import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../network/provider/editor_provider.dart';
import '../industry/widgets/editable.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: const EditorView(),
    );
  }
}

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EditorProvider>(context, listen: false);
      provider.loadItemsFromJson([
        {
          "id": "1",
          "type": "text",
          "text": "Pro Banner",
          "position_x": 100.0,
          "position_y": 80.0,
          "font_size": 32.0,
          "color": "#FFFFFF",
        },
        {
          "id": "2",
          "type": "image",
          "content_url":
              "https://picsum.photos/300/300", // Stable sample image link
          "position_x": 80.0,
          "position_y": 180.0,
          "width": 220.0,
          "height": 220.0,
          "text": "rounded",
        },
      ]);
    });
  }

  // 🚀 Native Phone Keyboard Emoji Picker Dialog
  void _showEmojiInputDialog(BuildContext context) {
    TextEditingController emojiController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          "Type / Paste Emoji",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: emojiController,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          decoration: const InputDecoration(
            hintText: "😀🔥🎉❤️",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (emojiController.text.isNotEmpty) {
                context.read<EditorProvider>().addEmoji(emojiController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
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
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          "Pro Image Editor",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            onPressed: () => provider.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.white),
            onPressed: () => provider.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.greenAccent),
            onPressed: () {
              print(provider.getItemsAsJson());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("JSON Exported to Console!")),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFF181822)),
          ...provider.items.map((item) => EditableItemWidget(item: item)),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E2C),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => provider.addText(initialText: "New Text"),
                icon: const Icon(Icons.text_fields, color: Colors.blueAccent),
                label: const Text(
                  "Text",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickImageFromGallery(context),
                icon: const Icon(Icons.photo, color: Colors.greenAccent),
                label: const Text(
                  "Gallery",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEmojiInputDialog(context),
                icon: const Icon(
                  Icons.emoji_emotions,
                  color: Colors.amberAccent,
                ),
                label: const Text(
                  "Emoji",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
