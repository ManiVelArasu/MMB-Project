import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class FreePikService {
  static const String baseUrl = "https://api.freepik.com/v1";
  static const String apiKey = "MSa1300387e1bf43988b4bb3db2f59a143";

  static Future<List<String>> searchAssets(
      String query, {
        int limit = 20,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl/resources').replace(
        queryParameters: {
          'term': query.trim(),
          'limit': '$limit',
        },
      );

      final response = await http
          .get(
        uri,
        headers: {
          'x-freepik-api-key': apiKey,
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
          'Freepik Search Error: HTTP ${response.statusCode}: ${response.body}',
        );
        return <String>[];
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> items =
      decoded is Map<String, dynamic> && decoded['data'] is List
          ? List<dynamic>.from(decoded['data'] as List)
          : <dynamic>[];

      final urls = <String>[];
      for (final item in items) {
        if (item is! Map) continue;

        final image = item['image'];
        final source = image is Map ? image['source'] : null;
        final url = source is Map ? source['url']?.toString() : null;

        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      }

      // Preserve API order while removing duplicates.
      return urls.toSet().toList();
    } catch (e) {
      debugPrint("Freepik Search Error: $e");
      return <String>[];
    }
  }


  static Future<String?> removeBackground(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/tasks/v1/remove-background'),
        headers: {
          'x-freepik-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "image": {"url": imageUrl},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['image']?['url'];
      }
    } catch (e) {
      debugPrint("AI Background Removal Error: $e");
    }
    return null;
  }

  static Future<List<String>> searchVideos(String query) async {
    return [
      "https://www.youtube.com/watch?v=9xwazD5SyVg",
      "https://www.youtube.com/watch?v=9xwazD5SyVg",
      "https://www.youtube.com/watch?v=9xwazD5SyVg",
      "https://www.youtube.com/watch?v=9xwazD5SyVg",
      "https://www.youtube.com/watch?v=9xwazD5SyVg",
      "https://www.youtube.com/watch?v=9xwazD5SyVg",
    ];
  }
}
