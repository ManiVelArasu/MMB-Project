import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PexelsVideoAsset {
  final String videoUrl;
  final String? thumbnailUrl;

  const PexelsVideoAsset({required this.videoUrl, this.thumbnailUrl});
}

class AssetCategoryItem {
  final int? id;
  final String name;
  final String s3Key;
  final String? thumbnailS3Key;
  final String assetType;
  final bool isPremium;
  final bool isLocked;

  const AssetCategoryItem({
    this.id,
    required this.name,
    required this.s3Key,
    this.thumbnailS3Key,
    required this.assetType,
    required this.isPremium,
    required this.isLocked,
  });

  factory AssetCategoryItem.fromJson(Map<String, dynamic> json) {
    return AssetCategoryItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      name: json['name']?.toString() ?? '',
      s3Key: (json['s3_key'] ?? json['key'] ?? json['path'] ??
          json['url'] ?? json['asset_url'] ?? json['preview_url'] ?? '')
          .toString(),
      thumbnailS3Key: (json['thumbnail_s3_key'] ??
          json['thumbnail_url'] ?? json['thumbnailUrl'] ??
          json['preview_url'] ?? json['previewUrl'])?.toString(),
      assetType: (json['asset_type'] ?? json['type'] ?? '').toString(),
      isPremium: json['is_premium'] == 1 || json['is_premium'] == true,
      isLocked: json['is_locked'] == true,
    );
  }

  String get previewKey {
    final key = (thumbnailS3Key ?? '').trim().isNotEmpty
        ? thumbnailS3Key!.trim()
        : s3Key.trim();

    if (key.isEmpty) return '';
    if (key.startsWith('http://') || key.startsWith('https://')) return key;

    return '${FreePikService.assetCdnBaseUrl}/${key.replaceFirst(RegExp(r'^/+'), '')}';
  }
}

class FreePikService {
  /// Original SVG returned alongside each thumbnail by the backend.
  static final Map<String, String> _svgByThumbnail = <String, String>{};

  static String? svgForThumbnail(String thumbnailUrl) =>
      _svgByThumbnail[thumbnailUrl];
  static const String proxyBaseUrl =
      'https://mmb-v3.vercel.app/api/freepik/stickers';
  static const String assetCategoryBaseUrl =
      'https://mmb-v3.vercel.app/api/assets';
  static const String assetCdnBaseUrl =
      'https://temp-m2b-assets.s3.ap-south-1.amazonaws.com';

  /// Fetches sticker assets from the backend proxy.
  ///
  /// The backend response shape is:
  /// { data: [{ thumbnails: [{ url: "..." }] }], meta: {...} }
  static Future<List<AssetCategoryItem>> fetchAssetsByCategory(
      String category, {
        int page = 1,
        int perPage = 30,
      }) async {
    final slug = category.trim().toLowerCase();
    if (slug.isEmpty) return <AssetCategoryItem>[];

    try {
      final uri = Uri.parse(assetCategoryBaseUrl).replace(
        queryParameters: {
          'category': slug,
          'page': '$page',
          'per_page': '$perPage',
        },
      );

      final response = await http
          .get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint(
          'Asset category error [$slug]: '
              '${response.statusCode} ${response.body}',
        );
        return <AssetCategoryItem>[];
      }

      final decoded = jsonDecode(response.body);

      // The assets API has returned a few response shapes across versions:
      // {data:[...]}, {items:[...]}, {assets:[...]}, and sometimes a nested
      // {data:{items:[...]}}. Accept all of them.
      dynamic data = decoded;
      if (data is Map) {
        data = data['items'] ?? data['data'] ?? data['assets'];
        if (data is Map) {
          data = data['items'] ?? data['assets'] ?? data['results'];
        }
      }
      if (data is! List) {
        debugPrint('Assets API [$slug] returned unexpected shape: ${response.body}');
        return <AssetCategoryItem>[];
      }

      final items = <AssetCategoryItem>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        // Accept backend naming variants. If a direct URL is supplied, keep
        // it as s3Key so previewKey returns the URL unchanged.
        final directUrl = (item['url'] ??
            item['asset_url'] ??
            item['preview_url'] ??
            item['previewUrl'] ??
            item['thumbnail_url'] ??
            item['thumbnailUrl'])?.toString().trim();
        if ((item['s3_key'] == null || item['s3_key'].toString().trim().isEmpty) &&
            directUrl != null && directUrl.isNotEmpty) {
          item['s3_key'] = directUrl;
        }
        if ((item['thumbnail_s3_key'] == null ||
            item['thumbnail_s3_key'].toString().trim().isEmpty) &&
            directUrl != null && directUrl.isNotEmpty) {
          item['thumbnail_s3_key'] = directUrl;
        }
        final parsed = AssetCategoryItem.fromJson(item);
        if (parsed.previewKey.trim().isNotEmpty) items.add(parsed);
      }
      return items;
    } catch (e) {
      debugPrint('Asset category request failed [$slug]: $e');
      return <AssetCategoryItem>[];
    }
  }

  static Future<List<String>> searchAssets(
      String query, {
        int page = 1,
        int limit = 4,
      }) async {
    try {
      final uri = Uri.parse(proxyBaseUrl).replace(
        queryParameters: {
          'page': '$page',
          'per_page': '$limit',
          if (query.trim().isNotEmpty) 'term': query.trim(),
        },
      );

      final response = await http
          .get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
          'Freepik proxy error: ${response.statusCode} ${response.body}',
        );
        return <String>[];
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;

      if (data is! List) return <String>[];

      final urls = <String>[];
      for (final item in data) {
        if (item is! Map) continue;
        final thumbnails = item['thumbnails'];
        if (thumbnails is! List || thumbnails.isEmpty) continue;

        final first = thumbnails.first;
        if (first is Map) {
          final url = first['url']?.toString().trim();
          final svg = item['svg']?.toString();
          if (url != null && url.isNotEmpty) {
            urls.add(url);
            if (svg != null && svg.trim().isNotEmpty) {
              _svgByThumbnail[url] = svg;
            }
          }
        }
      }

      return urls.toSet().toList();
    } catch (e) {
      debugPrint('Freepik proxy error: $e');
      return <String>[];
    }
  }

  /// Fetches stickers from the dedicated backend stickers endpoint.
  /// The endpoint returns:
  /// { data: [{ thumbnails: [{ url: "..." }] }], meta: {...} }
  static Future<List<String>> searchStickers({
    String? term,
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final uri = Uri.parse(proxyBaseUrl).replace(
        queryParameters: {
          'page': '$page',
          'per_page': '$perPage',
          if (term != null && term.trim().isNotEmpty) 'term': term.trim(),
        },
      );

      final response = await http
          .get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache',
        },
      )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        'Freepik stickers status: ${response.statusCode}, '
            'page=$page, per_page=$perPage, term=${term ?? ""}',
      );

      if (response.statusCode != 200) {
        debugPrint('Freepik stickers error: ${response.body}');
        return <String>[];
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is! List) return <String>[];

      final urls = <String>[];

      for (final item in data) {
        if (item is! Map) continue;

        final thumbnails = item['thumbnails'];
        if (thumbnails is! List) continue;

        String? imageUrl;
        for (final thumbnail in thumbnails) {
          if (thumbnail is Map) {
            final url = thumbnail['url']?.toString().trim();
            if (url != null && url.isNotEmpty) {
              imageUrl = url;
              break;
            }
          }
        }

        if (imageUrl != null) {
          urls.add(imageUrl);
        }
      }

      debugPrint('Freepik stickers parsed: ${urls.length}');
      return urls.toSet().toList();
    } catch (e) {
      debugPrint('Freepik stickers exception: $e');
      return <String>[];
    }
  }

  static const String pexelsPhotosProxyUrl =
      'https://mmb-v3.vercel.app/api/pexels/photos';

  static const String pexelsVideosProxyUrl =
      'https://mmb-v3.vercel.app/api/pexels/videos';

  /// Category terms used by the Media > Images section.
  /// Each category is searched against Pexels through the backend proxy.
  static const Map<String, String> pexelsImageCategories = {
    'Nature': 'nature landscape',
    'People': 'people portrait',
    'Business': 'business',
    'Technology': 'technology',
    'Travel': 'travel',
    'Food': 'food',
    'Animals': 'animals',
    'Fashion': 'fashion',
    'Sports': 'sports',
    'Architecture': 'architecture',
    'Wedding': 'wedding',
    'Background': 'background',
  };

  /// Returns the Pexels search term for a category shown in the Media UI.
  /// Unknown categories are still accepted and searched as-is.
  static String pexelsTermForCategory(String category) {
    final key = category.trim();
    if (key.isEmpty) return 'background';
    return pexelsImageCategories[key] ?? key.toLowerCase();
  }

  /// Fetch images for a specific Media category.
  ///
  /// Example:
  ///   searchPexelsImagesByCategory('Nature')
  /// calls:
  ///   /api/pexels/photos?page=1&per_page=24&term=nature+landscape
  static Future<List<String>> searchPexelsImagesByCategory(
      String category, {
        int page = 1,
        int limit = 24,
      }) {
    return searchPexelsPhotos(
      pexelsTermForCategory(category),
      page: page,
      limit: limit,
    );
  }

  /// Pexels background images. The backend can return a normal Pexels
  /// response (`photos`), or a wrapped response (`data` / `results`).
  static Future<List<String>> searchPexelsPhotos(
      String query, {
        int page = 1,
        int limit = 24,
      }) async {
    try {
      final uri = Uri.parse(pexelsPhotosProxyUrl).replace(
        queryParameters: {
          'page': '$page',
          'per_page': '$limit',
          if (query.trim().isNotEmpty) 'term': query.trim(),
        },
      );

      final response = await http
          .get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache',
        },
      )
          .timeout(const Duration(seconds: 20));

      debugPrint('Pexels photos status: ${response.statusCode}');
      debugPrint('Pexels photos response length: ${response.body.length}');

      if (response.statusCode != 200) {
        debugPrint('Pexels photos proxy error: ${response.body}');
        return <String>[];
      }

      final decoded = jsonDecode(response.body);
      final items = _extractList(decoded, const [
        'photos',
        'data',
        'results',
        'items',
      ]);

      final urls = <String>[];
      for (final item in items) {
        if (item is! Map) continue;

        final src = item['src'];
        if (src is Map) {
          for (final key in const [
            'medium',
            'large',
            'large2x',
            'portrait',
            'landscape',
            'original',
          ]) {
            final value = src[key]?.toString().trim();
            if (value != null && value.isNotEmpty) {
              urls.add(value);
              break;
            }
          }
        }

        // Support backend wrappers.
        for (final key in const [
          'image',
          'image_url',
          'imageUrl',
          'thumbnail',
          'thumbnail_url',
          'thumbnailUrl',
          'url',
        ]) {
          final value = item[key]?.toString().trim();
          if (value != null && value.isNotEmpty) {
            urls.add(value);
            break;
          }
        }
      }

      debugPrint('Pexels photos parsed: ${urls.length}');
      return urls.toSet().toList();
    } catch (e, stackTrace) {
      debugPrint('Pexels photo parse error: $e');
      debugPrint('$stackTrace');
      return <String>[];
    }
  }

  /// The same backend endpoint is used by the app for the video tab.
  /// It may return a normal Pexels `videos` response, a wrapped `data`
  /// response, or a list containing `video_files` / `videos`.
  static Future<List<PexelsVideoAsset>> searchPexelsVideoAssets(
      String query, {
        int page = 1,
        int limit = 24,
      }) async {
    try {
      final uri = Uri.parse(pexelsVideosProxyUrl).replace(
        queryParameters: {
          'page': '$page',
          'per_page': '$limit',
          if (query.trim().isNotEmpty) 'term': query.trim(),
        },
      );

      final response = await http
          .get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache',
        },
      )
          .timeout(const Duration(seconds: 20));

      debugPrint('Pexels videos endpoint: $pexelsVideosProxyUrl');
      debugPrint('Pexels videos status: ${response.statusCode}');
      debugPrint('Pexels videos response length: ${response.body.length}');

      if (response.statusCode != 200) {
        debugPrint('Pexels videos proxy error: ${response.body}');
        return <PexelsVideoAsset>[];
      }

      final decoded = jsonDecode(response.body);
      // The backend may return videos under `videos`, `data`, `results`,
      // `items`, or (in the current proxy) even under `photos`.
      final items = _extractVideoItems(decoded);

      final assets = <PexelsVideoAsset>[];
      final seen = <String>{};

      for (final item in items) {
        if (item is! Map) continue;

        String? videoUrl;
        final files =
            item['video_files'] ??
                item['videoFiles'] ??
                item['files'] ??
                item['videos'];

        if (files is List) {
          final candidates = files.whereType<Map>().toList();
          candidates.sort((a, b) {
            final aw = int.tryParse('${a['width'] ?? 0}') ?? 0;
            final bw = int.tryParse('${b['width'] ?? 0}') ?? 0;
            return aw.compareTo(bw);
          });

          // Prefer a real mp4/webm URL. Avoid thumbnail/image URLs.
          for (final file in candidates.reversed) {
            final value =
            (file['link'] ??
                file['url'] ??
                file['video_url'] ??
                file['videoUrl'])
                ?.toString()
                .trim();
            if (_isHttpUrl(value) && _looksLikeVideoUrl(value!)) {
              videoUrl = value;
              break;
            }
          }
        }

        final direct =
        (item['video'] ??
            item['video_url'] ??
            item['videoUrl'] ??
            item['link'] ??
            item['url'])
            ?.toString()
            .trim();
        if (videoUrl == null &&
            _isHttpUrl(direct) &&
            _looksLikeVideoUrl(direct!)) {
          videoUrl = direct;
        }
        if (videoUrl == null) continue;
        if (seen.contains(videoUrl)) continue;

        String? thumbnail;

        // Pexels video response normally exposes `image` as the poster.
        for (final key in const [
          'image',
          'thumbnail',
          'thumbnail_url',
          'thumbnailUrl',
          'image_url',
          'imageUrl',
          'picture',
          'poster',
          'preview',
        ]) {
          final value = item[key]?.toString().trim();
          if (_isHttpUrl(value)) {
            thumbnail = value;
            break;
          }
        }

        // Some Pexels responses expose poster frames in `video_pictures`.
        if (thumbnail == null) {
          final pictures =
              item['video_pictures'] ??
                  item['videoPictures'] ??
                  item['pictures'];
          if (pictures is List) {
            for (final picture in pictures) {
              if (picture is Map) {
                final value =
                (picture['picture'] ?? picture['url'] ?? picture['image'])
                    ?.toString()
                    .trim();
                if (_isHttpUrl(value)) {
                  thumbnail = value;
                  break;
                }
              } else if (picture is String && _isHttpUrl(picture.trim())) {
                thumbnail = picture.trim();
                break;
              }
            }
          }
        }

        // Fallback to an image field nested inside `src`.
        if (thumbnail == null) {
          final src = item['src'];
          if (src is Map) {
            for (final key in const [
              'large2x',
              'large',
              'medium',
              'portrait',
              'landscape',
              'original',
            ]) {
              final value = src[key]?.toString().trim();
              if (_isHttpUrl(value)) {
                thumbnail = value;
                break;
              }
            }
          }
        }

        seen.add(videoUrl);
        assets.add(
          PexelsVideoAsset(videoUrl: videoUrl, thumbnailUrl: thumbnail),
        );
      }

      debugPrint('Pexels videos parsed: ${assets.length}');
      return assets;
    } catch (e, stackTrace) {
      debugPrint('Pexels video parse error: $e');
      debugPrint('$stackTrace');
      return <PexelsVideoAsset>[];
    }
  }

  static List<dynamic> _extractVideoItems(dynamic decoded) {
    final found = <dynamic>[];

    void walk(dynamic value, {int depth = 0}) {
      if (depth > 5 || value == null) return;

      if (value is List) {
        for (final item in value) {
          if (item is Map && _looksLikeVideoItem(item)) {
            found.add(item);
          } else if (item is Map || item is List) {
            walk(item, depth: depth + 1);
          }
        }
        return;
      }

      if (value is Map) {
        // Search all common containers instead of stopping at `photos`.
        for (final key in const [
          'videos',
          'data',
          'results',
          'items',
          'photos',
          'result',
          'response',
          'payload',
        ]) {
          final child = value[key];
          if (child is Map || child is List) {
            walk(child, depth: depth + 1);
          }
        }

        // Also support a response containing a single video object.
        if (_looksLikeVideoItem(value)) found.add(value);
      }
    }

    walk(decoded);

    final unique = <String, dynamic>{};
    for (final item in found) {
      if (item is Map) {
        final key =
            '${item['id'] ?? ''}|${item['url'] ?? item['video_url'] ?? ''}|${item['image'] ?? ''}';
        unique.putIfAbsent(key, () => item);
      }
    }
    return unique.values.toList();
  }

  static bool _looksLikeVideoItem(Map item) {
    final files =
        item['video_files'] ??
            item['videoFiles'] ??
            item['files'] ??
            item['videos'];
    if (files is List && files.isNotEmpty) return true;

    for (final key in const ['video', 'video_url', 'videoUrl']) {
      if (_isHttpUrl(item[key]?.toString())) return true;
    }
    return false;
  }

  static bool _looksLikeVideoUrl(String value) {
    final lower = value.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.webm') ||
        lower.contains('.mov') ||
        lower.contains('.m3u8') ||
        lower.contains('video');
  }

  static Future<List<String>> searchPexelsVideos(
      String query, {
        int page = 1,
        int limit = 24,
      }) async {
    final assets = await searchPexelsVideoAssets(
      query,
      page: page,
      limit: limit,
    );
    return assets.map((e) => e.videoUrl).toList();
  }

  static bool _isHttpUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static List<dynamic> _extractList(dynamic decoded, List<String> keys) {
    if (decoded is List) return decoded;
    if (decoded is! Map) return const <dynamic>[];

    for (final key in keys) {
      final value = decoded[key];
      if (value is List) return value;
    }

    // Some proxies wrap the actual payload one level deeper.
    for (final key in const ['data', 'result', 'response', 'payload']) {
      final value = decoded[key];
      if (value is Map) {
        final nested = _extractList(value, keys);
        if (nested.isNotEmpty) return nested;
      }
    }

    return const <dynamic>[];
  }

  static Future<String?> removeBackground(String imageUrl) async {
    return null;
  }
}
