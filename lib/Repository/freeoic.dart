import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FreePikService {
  static const String baseUrl = "https://api.freepik.com/v1";
  static const String apiKey = "MSa1300387e1bf43988b4bb3db2f59a143";

  static Future<List<String>> searchAssets(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resources?term=$query&limit=20'),
        headers: {'x-freepik-api-key': apiKey, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List items = data['data'] ?? [];
        return items.map<String>((item) {
          return item['image']['source']['url'].toString();
        }).toList();
      }
    } catch (e) {
      debugPrint("Freepik Search Error: $e");
    }
    return [];
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
      "https://assets.mixkit.co/videos/preview/mixkit-waves-in-the-water-1164-large.mp4",
      "https://assets.mixkit.co/videos/preview/mixkit-tree-branches-in-the-breeze-1195-large.mp4",
      "https://assets.mixkit.co/videos/preview/mixkit-clouds-and-blue-sky-2408-large.mp4",
      "https://assets.mixkit.co/videos/preview/mixkit-aerial-view-of-city-traffic-at-night-4167-large.mp4",
      "https://assets.mixkit.co/videos/preview/mixkit-cosmos-of-the-milky-way-galaxy-4235-large.mp4",
      "https://assets.mixkit.co/videos/preview/mixkit-hands-holding-a-smartphone-with-a-green-screen-42861-large.mp4",
    ];
  }
}
