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
      isLocked: json['is_locked'] == true,
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
  };
}

class LanguageModel {
  final int? id;
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
      id: _toInt(json['id']),
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