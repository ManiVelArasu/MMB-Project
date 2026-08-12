import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/cupertino.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveImageToGallery(Uint8List bytes) async {
  try {
    final hasAccess = await Gal.hasAccess();

    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        debugPrint('Gallery permission denied');
        return;
      }
    }

    final tempDir = await getTemporaryDirectory();

    final file = File(
      '${tempDir.path}/mmb_design_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(bytes);

    await Gal.putImage(file.path);

    debugPrint('Image saved successfully');
  } catch (e) {
    debugPrint('Save image error: $e');
  }
}