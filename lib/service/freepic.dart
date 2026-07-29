import 'dart:convert';
import 'package:http/http.dart' as http;


class PixabayService {
  // Pixabay-ல் இருந்து இலவசமாக கிடைக்கும் API Key
  final String apiKey = '56916218-d3f5cbb29ac2562600b88aa49';

  Future<List<String>> searchImages(String query) async {
    // Pixabay Search URL
    final url = Uri.parse(
      'https://pixabay.com/api/?key=$apiKey&q=${Uri.encodeComponent(query)}&image_type=photo&per_page=20',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> imageUrls = [];

        // Pixabay JSON-ல் 'hits' என்ற கீ-க்குள் தான் படங்கள் இருக்கும்
        for (var item in data['hits']) {
          // 'webformatURL' என்பது நல்ல தரமான படத்தைக் கொடுக்கும்
          imageUrls.add(item['webformatURL']);
        }
        return imageUrls;
      } else {
        print("Pixabay API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Pixabay Error: $e");
      return [];
    }
  }
}


