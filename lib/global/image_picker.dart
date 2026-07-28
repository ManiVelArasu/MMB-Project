import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';

final ImagePicker _picker = ImagePicker();

Future<void> pickImage(BuildContext context) async {
  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

  if (file == null) return;

  openEditor(context, File(file.path));
}

Future<void> openEditor(BuildContext context, File image) async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProImageEditor.file(
        image,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (Uint8List bytes) async {
            Navigator.pop(context);
            print("Edited Image Size : ${bytes.length}");
          },
        ),
      ),
    ),
  );
}


Future<File> assetToFile(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final dir = await getTemporaryDirectory();

  final file = File('${dir.path}/${assetPath.split('/').last}');
  await file.writeAsBytes(
    data.buffer.asUint8List(),
  );

  return file;
}