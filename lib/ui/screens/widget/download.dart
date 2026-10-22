import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadThumbnail(String? thumbnailUrl) async {
  final url = thumbnailUrl?.trim() ?? '';

  if (url.isEmpty) {
    debugPrint('Thumbnail URL is empty');
    return;
  }

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      debugPrint('Download failed: ${response.statusCode}');
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(response.bodyBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Downloaded thumbnail',
    );
  } catch (e) {
    debugPrint('Thumbnail download error: $e');
  }
}