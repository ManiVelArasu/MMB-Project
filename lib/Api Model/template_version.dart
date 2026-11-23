// ===== Template_model.dart-ல சேர்க்க வேண்டியது =====

/// One entry of API `versions` (a language variant of the template).
class TemplateVersion {
  final String uid;
  final String languageName; // "Tamil" / "English"
  final String? languageCode; // "ta" / "en"
  final String? thumbnailS3Key;
  final int width;
  final int height;

  const TemplateVersion({
    required this.uid,
    required this.languageName,
    this.languageCode,
    this.thumbnailS3Key,
    this.width = 0,
    this.height = 0,
  });

  factory TemplateVersion.fromJson(Map<String, dynamic> json) {
    final lang = json['Language'] as Map<String, dynamic>?;
    final size = json['TemplateSize'] as Map<String, dynamic>?;
    return TemplateVersion(
      uid: (json['uid'] ?? '').toString(),
      languageName: (lang?['name'] ?? '').toString().trim(),
      languageCode: lang?['code']?.toString(),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      width: (size?['width'] as num?)?.toInt() ?? 0,
      height: (size?['height'] as num?)?.toInt() ?? 0,
    );
  }
}

// ----- TemplateModel class-ல -----
// 1) field:
//    final List<TemplateVersion> versions;
// 2) constructor:
//    this.versions = const [],
// 3) fromJson-ல (மற்ற fields மாதிரியே):
//    versions: (json['versions'] as List? ?? [])
//        .map((e) => TemplateVersion.fromJson(e as Map<String, dynamic>))
//        .toList(),