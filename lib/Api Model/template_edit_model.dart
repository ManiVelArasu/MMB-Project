class TemplateEdit {
  final bool success;
  final TemplateListEdit data;

  TemplateEdit({required this.success, required this.data});

  factory TemplateEdit.fromJson(Map<String, dynamic> json) => TemplateEdit(
    success: json['success'] ?? false,
    data: TemplateListEdit.fromJson(
      Map<String, dynamic>.from(json['data'] ?? {}),
    ),
  );

  Map<String, dynamic> toJson() => {'success': success, 'data': data.toJson()};
}

class TemplateListEdit {
  final List<TemplateItem> items;

  TemplateListEdit({required this.items});

  factory TemplateListEdit.fromJson(Map<String, dynamic> json) {
    // New response: data.items
    if (json['items'] is List) {
      return TemplateListEdit(
        items: (json['items'] as List)
            .whereType<Map>()
            .map((e) => TemplateItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }

    // Old response: data itself is one template
    if (json.containsKey('uid') || json.containsKey('id')) {
      return TemplateListEdit(items: [TemplateItem.fromJson(json)]);
    }

    return TemplateListEdit(items: []);
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class TemplateItem {
  final String? id;
  final String? uid;
  final String? familyId;
  final String? familyUid;
  final String? categoryId;
  final String? languageId;
  final String? sizeId;
  final String? name;
  final String? thumbnailS3Key;
  final String? content;
  final String? templateType;
  final String? isPremium;
  final String? isPopular;
  final String? trendingScore;
  final String? viewsCount;
  final String? downloadsCount;
  final String? likesCount;
  final String? status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLocked;
  final Map<String, dynamic>? language;
  final Map<String, dynamic>? templateSize;
  final List<dynamic> availableLanguages;
  final List<dynamic> availableSizes;

  TemplateItem({
    this.id,
    this.uid,
    this.familyId,
    this.familyUid,
    this.categoryId,
    this.languageId,
    this.sizeId,
    this.name,
    this.thumbnailS3Key,
    this.content,
    this.templateType,
    this.isPremium,
    this.isPopular,
    this.trendingScore,
    this.viewsCount,
    this.downloadsCount,
    this.likesCount,
    this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isLocked = false,
    this.language,
    this.templateSize,
    this.availableLanguages = const [],
    this.availableSizes = const [],
  });

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      familyId: json['family_id']?.toString(),
      familyUid: json['family_uid']?.toString(),
      categoryId: json['category_id']?.toString(),
      languageId: json['language_id']?.toString(),
      sizeId: json['size_id']?.toString(),
      name: json['name']?.toString(),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      content: json['content']?.toString(),
      templateType: json['template_type']?.toString(),
      isPremium: json['is_premium']?.toString(),
      isPopular: json['is_popular']?.toString(),
      trendingScore: json['trending_score']?.toString(),
      viewsCount: json['views_count']?.toString(),
      downloadsCount: json['downloads_count']?.toString(),
      likesCount: json['likes_count']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
      isLocked: json['is_locked'] == true,
      language: json['Language'] is Map
          ? Map<String, dynamic>.from(json['Language'])
          : null,
      templateSize: json['TemplateSize'] is Map
          ? Map<String, dynamic>.from(json['TemplateSize'])
          : null,
      availableLanguages: json['available_languages'] is List
          ? List<dynamic>.from(json['available_languages'])
          : [],
      availableSizes: json['available_sizes'] is List
          ? List<dynamic>.from(json['available_sizes'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'family_id': familyId,
    'family_uid': familyUid,
    'category_id': categoryId,
    'language_id': languageId,
    'size_id': sizeId,
    'name': name,
    'thumbnail_s3_key': thumbnailS3Key,
    'content': content,
    'template_type': templateType,
    'is_premium': isPremium,
    'is_popular': isPopular,
    'trending_score': trendingScore,
    'views_count': viewsCount,
    'downloads_count': downloadsCount,
    'likes_count': likesCount,
    'status': status,
    'created_by': createdBy,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'is_locked': isLocked,
    'Language': language,
    'TemplateSize': templateSize,
    'available_languages': availableLanguages,
    'available_sizes': availableSizes,
  };
}
