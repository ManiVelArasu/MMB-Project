import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Api Model/editor_model.dart';
import '../../../network/provider/editor_provider.dart';


class EditableItem extends StatelessWidget {
  final EditorItem item;

  const EditableItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          context.read<EditorProvider>().updatePosition(
            item.id,
            item.position + details.delta,
          );
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: Transform.scale(
            scale: item.scale,
            child: Text(
              item.text ?? "",
              style: const TextStyle(
                fontSize: 30,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}