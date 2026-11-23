import 'dart:convert';

TemplatesResponseModel templatesResponseModelFromJson(String str) =>
    TemplatesResponseModel.fromJson(json.decode(str));

String templatesResponseModelToJson(TemplatesResponseModel data) =>
    json.encode(data.toJson());

class TemplatesResponseModel {
  final bool success;
  final List<TemplateModel> data;

  TemplatesResponseModel({
    required this.success,
    required this.data,
  });

  factory TemplatesResponseModel.fromJson(Map<String, dynamic> json) {
    return TemplatesResponseModel(
      success: json['success'] == true,
      data: (json['data'] as List? ?? [])
          .map(
            (e) => TemplateModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

class TemplateModel {
  final int? id;
  final String? uid;
  final int? familyId;
  final String? familyUid;
  final String? name;
  final int? categoryId;
  final int? languageId;
  final int? sizeId;
  final String? thumbnailS3Key;
  final String? templateType;
  final int? isPremium;
  final int? isPopular;
  final int? trendingScore;
  final int? viewsCount;
  final int? downloadsCount;
  final int? likesCount;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final LanguageModel? language;
  final TemplateSizeModel? templateSize;
  final List<LanguageModel> availableLanguages;
  final List<TemplateSizeModel> availableSizes;
  final bool? isLocked;

  /// NEW: language / size variants of this template (API `versions`).
  final List<TemplateVersion> versions;

  TemplateModel({
    this.id,
    this.uid,
    this.familyId,
    this.familyUid,
    this.name,
    this.categoryId,
    this.languageId,
    this.sizeId,
    this.thumbnailS3Key,
    this.templateType,
    this.isPremium,
    this.isPopular,
    this.trendingScore,
    this.viewsCount,
    this.downloadsCount,
    this.likesCount,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.language,
    this.templateSize,
    this.availableLanguages = const [],
    this.availableSizes = const [],
    this.isLocked,
    this.versions = const [],
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: _toInt(json['id']),
      uid: json['uid']?.toString(),
      familyId: _toInt(json['family_id']),
      familyUid: json['family_uid']?.toString(),
      name: json['name']?.toString(),
      categoryId: _toInt(json['category_id']),
      languageId: _toInt(json['language_id']),
      sizeId: _toInt(json['size_id']),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      templateType: json['template_type']?.toString(),
      isPremium: _toInt(json['is_premium']),
      isPopular: _toInt(json['is_popular']),
      trendingScore: _toInt(json['trending_score']),
      viewsCount: _toInt(json['views_count']),
      downloadsCount: _toInt(json['downloads_count']),
      likesCount: _toInt(json['likes_count']),
      status: json['status']?.toString(),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      language: json['Language'] is Map<String, dynamic>
          ? LanguageModel.fromJson(json['Language'])
          : null,
      templateSize: json['TemplateSize'] is Map<String, dynamic>
          ? TemplateSizeModel.fromJson(json['TemplateSize'])
          : null,
      availableLanguages:
      (json['available_languages'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LanguageModel.fromJson)
          .toList(),
      availableSizes: (json['available_sizes'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TemplateSizeModel.fromJson)
          .toList(),
      isLocked: json['is_locked'] ??false,
      versions: (json['versions'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TemplateVersion.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'family_id': familyId,
    'family_uid': familyUid,
    'name': name,
    'category_id': categoryId,
    'language_id': languageId,
    'size_id': sizeId,
    'thumbnail_s3_key': thumbnailS3Key,
    'template_type': templateType,
    'is_premium': isPremium,
    'is_popular': isPopular,
    'trending_score': trendingScore,
    'views_count': viewsCount,
    'downloads_count': downloadsCount,
    'likes_count': likesCount,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'Language': language?.toJson(),
    'TemplateSize': templateSize?.toJson(),
    'available_languages':
    availableLanguages.map((e) => e.toJson()).toList(),
    'available_sizes':
    availableSizes.map((e) => e.toJson()).toList(),
    'is_locked': isLocked,
    'versions': versions.map((e) => e.toJson()).toList(),
  };
}

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
    final lang = json['Language'] is Map<String, dynamic>
        ? json['Language'] as Map<String, dynamic>
        : null;
    final size = json['TemplateSize'] is Map<String, dynamic>
        ? json['TemplateSize'] as Map<String, dynamic>
        : null;

    return TemplateVersion(
      uid: (json['uid'] ?? '').toString(),
      languageName: (lang?['name'] ?? '').toString().trim(),
      languageCode: lang?['code']?.toString(),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      width: _toInt(size?['width']) ?? 0,
      height: _toInt(size?['height']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'thumbnail_s3_key': thumbnailS3Key,
    'Language': {'code': languageCode, 'name': languageName},
    'TemplateSize': {'width': width, 'height': height},
  };
}

class LanguageModel {
  final String? id;
  final String? code;
  final String? name;
  final String? nativeName;

  LanguageModel({
    this.id,
    this.code,
    this.name,
    this.nativeName,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id']?.toString(),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      nativeName: json['native_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'native_name': nativeName,
  };
}

class TemplateSizeModel {
  final int? id;
  final String? uid;
  final String? slug;
  final String? name;
  final int? width;
  final int? height;
  final String? platform;

  TemplateSizeModel({
    this.id,
    this.uid,
    this.slug,
    this.name,
    this.width,
    this.height,
    this.platform,
  });

  factory TemplateSizeModel.fromJson(Map<String, dynamic> json) {
    return TemplateSizeModel(
      id: _toInt(json['id']),
      uid: json['uid']?.toString(),
      slug: json['slug']?.toString(),
      name: json['name']?.toString(),
      width: _toInt(json['width']),
      height: _toInt(json['height']),
      platform: json['platform']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'slug': slug,
    'name': name,
    'width': width,
    'height': height,
    'platform': platform,
  };
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}