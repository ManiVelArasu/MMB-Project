import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mmb_app/core/api/api_endpoints.dart';

/// Brand red used across the business-frames screens.
const Color kBrandRed = Color(0xFFE53935);
const Color kBrandRedTint = Color(0xFFFFECEE);

/// Red filled button style (GET FRAME / UPDATE / REMOVE BG ...).
ButtonStyle brandButtonStyle({
  required double radius,
  EdgeInsetsGeometry? padding,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: kBrandRed,
    foregroundColor: Colors.white,
    padding: padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}

/// First non-empty value returned by [getters]. The frame / profile models
/// use different field names, so a missing field never breaks the build.
String pick(dynamic obj, List<dynamic Function(dynamic)> getters) {
  for (final get in getters) {
    try {
      final v = get(obj);
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    } catch (_) {}
  }
  return '';
}

/// S3 key -> full CDN url (full urls are returned as they are).
String cdnUrl(String raw) {
  if (raw.isEmpty) return '';
  return raw.startsWith('http') ? raw : '${ApiEndpoints.cdnImageUrl}/$raw';
}

// ------------------------------------------------------------------
// FRAME LIST ITEM (static / animated / my brand frames)
// ------------------------------------------------------------------

/// Id used for GET frames/{id}. "My brand frames" items may use a different
/// field name than the normal frames.
String frameUid(dynamic frame) => pick(frame, [
      (f) => f.uid,
      (f) => f.id,
      (f) => f.frameUid,
      (f) => f.frameId,
      (f) => f.frame?.uid,
      (f) => f.frame?.id,
    ]);

String frameThumbUrl(dynamic frame) => cdnUrl(
      pick(frame, [
        (f) => f.previewS3Key,
        (f) => f.thumbnailS3Key,
        (f) => f.imageS3Key,
        (f) => f.s3Key,
        (f) => f.imageUrl,
        (f) => f.previewUrl,
        (f) => f.url,
      ]),
    );

String frameLabel(dynamic frame) {
  final name = pick(frame, [(f) => f.name, (f) => f.title]);
  return name.isEmpty ? 'Free' : name;
}

// ------------------------------------------------------------------
// frames/{id} RESPONSE
// ------------------------------------------------------------------

/// Image of the frames/{id} response. Keys are checked in this order,
/// change the list if the API uses a different key.
String frameDetailImageUrl(Map<String, dynamic> detail) {
  const keys = [
    'preview_s3_key',
    'image_s3_key',
    'frame_s3_key',
    's3_key',
    'thumbnail_s3_key',
    'image_url',
    'preview_url',
    'url',
    'image',
  ];
  final sources = <Map<String, dynamic>>[
    detail,
    if (detail['frame'] is Map) Map<String, dynamic>.from(detail['frame']),
  ];
  for (final source in sources) {
    for (final key in keys) {
      final v = source[key];
      if (v is String && v.trim().isNotEmpty) return cdnUrl(v.trim());
    }
  }
  return '';
}

/// `content` of the frames/{id} response as a JSON string (also when the API
/// returns it already decoded or nested under frame / data).
String? frameContentJson(Map<String, dynamic>? detail) {
  if (detail == null) return null;

  dynamic c = detail['content'];
  if (c == null && detail['frame'] is Map) c = detail['frame']['content'];
  if (c == null && detail['data'] is Map) c = detail['data']['content'];
  if (c == null) return null;
  if (c is String) return c;

  try {
    return jsonEncode(c);
  } catch (_) {
    return null;
  }
}

/// Branded frame = needs logo / mobile / website. Detected from a flag or a
/// category containing "brand" in the frames/{id} response, or from the
/// selected category chip.
bool isBrandedFrame({
  required String? selectedCategorySlug,
  Map<String, dynamic>? detail,
}) {
  bool truthy(dynamic v) =>
      v == true || v == 1 || v?.toString().toLowerCase() == 'true';

  if (detail != null) {
    for (final key in const [
      'is_branded',
      'branded',
      'is_brand_frame',
      'brand_frame',
      'is_branding',
      'has_branding',
    ]) {
      if (truthy(detail[key])) return true;
    }

    final cat = detail['category'];
    final text = [
      cat is Map ? (cat['slug'] ?? cat['name']) : cat,
      detail['category_slug'],
      detail['category_name'],
    ].join(' ').toLowerCase();
    if (text.contains('brand')) return true;
  }
  return (selectedCategorySlug ?? '').toLowerCase().contains('brand');
}
