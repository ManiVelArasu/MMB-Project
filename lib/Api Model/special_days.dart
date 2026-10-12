import 'dart:convert';

SpecialDays specialDaysFromJson(String str) =>
    SpecialDays.fromJson(json.decode(str));

String specialDaysToJson(SpecialDays data) =>
    json.encode(data.toJson());

class SpecialDays {
  final bool? success;
  final List<SpecialDaysList> data;
  final Meta? meta;

  SpecialDays({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory SpecialDays.fromJson(Map<String, dynamic> json) {
    return SpecialDays(
      success: json['success'] == true,
      data: (json['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SpecialDaysList.fromJson)
          .toList(),
      meta: json['meta'] is Map<String, dynamic>
          ? Meta.fromJson(json['meta'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data.map((e) => e.toJson()).toList(),
    'meta': meta?.toJson(),
  };
}

class SpecialDaysList {
  final String? id;
  final String? uid;
  final String? name;
  final String? description;
  final String? thumbnailS3Key;
  final String? bannerS3Key;
  final String? type;
  final String? eventDate;
  final String? fullDate;
  final int? isRecurring;
  final int? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? occursOn;
  final List<Template> templates;

  SpecialDaysList({
    this.id,
    this.uid,
    this.name,
    this.description,
    this.thumbnailS3Key,
    this.bannerS3Key,
    this.type,
    this.eventDate,
    this.fullDate,
    this.isRecurring,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.occursOn,
    this.templates = const [],
  });

  factory SpecialDaysList.fromJson(Map<String, dynamic> json) {
    final templatesJson = json['Templates'] ?? json['templates'];

    return SpecialDaysList(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      bannerS3Key: json['banner_s3_key']?.toString(),
      type: json['type']?.toString(),
      eventDate: json['event_date']?.toString(),
      fullDate: json['full_date']?.toString(),
      isRecurring: _toInt(json['is_recurring']),
      isActive: _toInt(json['is_active']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      occursOn: _toDateTime(json['occurs_on']),
      templates: (templatesJson as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Template.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'name': name,
    'description': description,
    'thumbnail_s3_key': thumbnailS3Key,
    'banner_s3_key': bannerS3Key,
    'type': type,
    'event_date': eventDate,
    'full_date': fullDate,
    'is_recurring': isRecurring,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'occurs_on': occursOn == null
        ? null
        : _formatDate(occursOn!),
    'Templates': templates.map((e) => e.toJson()).toList(),
  };
}

class Template {
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
  final Language? language;
  final TemplateSize? templateSize;
  final List<Language> availableLanguages;
  final List<TemplateSize> availableSizes;
  final bool isLocked;

  // Old model compatibility fields
  final String? content;
  final String? createdBy;

  Template({
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
    this.isLocked = false,
    this.content,
    this.createdBy,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    final languagesJson = json['available_languages'];
    final sizesJson = json['available_sizes'];

    return Template(
      id: _toInt(json['id']),
      uid: json['uid']?.toString(),
      familyId: _toInt(json['family_id'] ?? json['familyId']),
      familyUid:
      (json['family_uid'] ?? json['familyUid'])?.toString(),
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
          ? Language.fromJson(json['Language'])
          : null,
      templateSize: json['TemplateSize'] is Map<String, dynamic>
          ? TemplateSize.fromJson(json['TemplateSize'])
          : null,
      availableLanguages: (languagesJson as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Language.fromJson)
          .toList(),
      availableSizes: (sizesJson as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TemplateSize.fromJson)
          .toList(),
      isLocked: json['is_locked'] == true,
      content: json['content']?.toString(),
      createdBy: json['created_by']?.toString(),
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
    'content': content,
    'created_by': createdBy,
  };
}

class Language {
  final int? id;
  final String? code;
  final String? name;
  final String? nativeName;

  Language({
    this.id,
    this.code,
    this.name,
    this.nativeName,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
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

class TemplateSize {
  final int? id;
  final String? uid;
  final String? slug;
  final String? name;
  final int? width;
  final int? height;
  final String? platform;

  TemplateSize({
    this.id,
    this.uid,
    this.slug,
    this.name,
    this.width,
    this.height,
    this.platform,
  });

  factory TemplateSize.fromJson(Map<String, dynamic> json) {
    return TemplateSize(
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

class Meta {
  final Range? range;
  final dynamic types;

  Meta({
    this.range,
    this.types,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      range: json['range'] is Map<String, dynamic>
          ? Range.fromJson(json['range'])
          : null,
      types: json['types'],
    );
  }

  Map<String, dynamic> toJson() => {
    'range': range?.toJson(),
    'types': types,
  };
}

class Range {
  final DateTime? from;
  final DateTime? to;

  Range({
    this.from,
    this.to,
  });

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      from:json['from']==null?null: _toDateTime(json['from']),
      to:json['to']==null?null: _toDateTime(json['to']),
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from == null ? null : _formatDate(from!),
    'to': to == null ? null : _formatDate(to!),
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

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';