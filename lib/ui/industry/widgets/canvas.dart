import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../network/provider/editor_provider.dart';
import 'editable.dart';

class CanvasWidget extends StatelessWidget {
  const CanvasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Stack(
      children: [
        if (provider.backgroundImage != null)
          Positioned.fill(
            child: Image.file(provider.backgroundImage!, fit: BoxFit.cover),
          ),

        ...provider.items.map((e) => EditableItem(item: e)),
      ],
    );
  }
}
