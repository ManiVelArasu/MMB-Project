import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../network/provider/editor_provider.dart';
import 'canvas.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Image Editor"),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                context.read<EditorProvider>().addText();
              },
              child: const Icon(Icons.add),
            );
          },
        ),
        body: Container(
          color: Colors.white,
          child: const CanvasWidget(),
        ),
      ),
    );
  }
}