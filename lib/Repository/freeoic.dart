import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------
// 🚀 1. Freepik Service (Without SharedPreferences)
// ---------------------------------------------------------
class FreepikService {
  static const String baseUrl = "https://api.freepik.com/v1";
  static const String apiKey = "MSa1300387e1bf43988b4bb3db2f59a143";

  // Search Freepik Resources (Images, Vectors, Stickers)
  static Future<List<String>> searchAssets(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resources?term=$query&limit=20'),
        headers: {
          'x-freepik-api-key': apiKey,
          'Accept': 'application/json',
        },
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

  // AI Background Remover
  static Future<String?> removeBackground(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/tasks/v1/remove-background'),
        headers: {
          'x-freepik-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "image": {"url": imageUrl}
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
}

