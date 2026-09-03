import 'dart:convert';

class ThemeApiResponse {
  final bool success;
  final List<ThemeItem> data;

  ThemeApiResponse({required this.success, required this.data});

  factory ThemeApiResponse.fromJson(Map<String, dynamic> json) {
    return ThemeApiResponse(
      success: json['success'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => ThemeItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data.map((item) => item.toJson()).toList(),
  };
}

class ThemeItem {
  final String? id;
  final String? uid;
  final String? name;
  final String? slug;
  final String? iconS3Key;
  final String? caption;
  final String? description;
  final String? displayOrder;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final List<StylePersonality> stylePersonalities;
  final List<dynamic> tags;
  final List<dynamic> colors;
  final String? variantsCount;
  final String? templatesCount;
  final String? unlockedVariantsCount;
  final bool isLocked;
  final List<Variant> variants;

  ThemeItem({
    required this.id,
    required this.uid,
    required this.name,
    required this.slug,
    this.iconS3Key,
    this.caption,
    this.description,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.stylePersonalities,
    required this.tags,
    required this.colors,
    required this.variantsCount,
    required this.templatesCount,
    required this.unlockedVariantsCount,
    required this.isLocked,
    required this.variants,
  });

  factory ThemeItem.fromJson(Map<String, dynamic> json) {
    final personalityJson =
        json['stylePersonalities'] ??
            json['StylePersonalities'] ??
            [];

    final variantsJson =
        json['Variants'] ??
            json['variants'] ??
            [];

    return ThemeItem(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      name: json['name']?.toString(),
      slug: json['slug']?.toString(),
      iconS3Key: json['icon_s3_key']?.toString(),
      caption: json['caption']?.toString(),
      description: json['description']?.toString(),
      displayOrder: json['display_order']?.toString(),
      isActive: json['is_active']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),

      // ✅ Style Personalities
      stylePersonalities: personalityJson is List
          ? personalityJson
          .map((item) {
        if (item is Map<String, dynamic>) {
          return StylePersonality.fromJson(item);
        }

        if (item is Map) {
          return StylePersonality.fromJson(
            Map<String, dynamic>.from(item),
          );
        }

        return null;
      })
          .whereType<StylePersonality>()
          .toList()
          : <StylePersonality>[],

      // ✅ Tags
      tags: json['tags'] is List
          ? List<dynamic>.from(json['tags'])
          : <dynamic>[],

      // ✅ Colors
      colors: json['colors'] is List
          ? List<dynamic>.from(json['colors'])
          : <dynamic>[],

      variantsCount:
      json['variants_count']?.toString(),

      templatesCount:
      json['templates_count']?.toString(),

      unlockedVariantsCount:
      json['unlocked_variants_count']?.toString(),

      isLocked:
      json['is_locked'] == true,

      // ✅ Variants
      variants: variantsJson is List
          ? variantsJson
          .map((item) {
        if (item is Map<String, dynamic>) {
          return Variant.fromJson(item);
        }

        if (item is Map) {
          return Variant.fromJson(
            Map<String, dynamic>.from(item),
          );
        }

        return null;
      })
          .whereType<Variant>()
          .toList()
          : <Variant>[],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'name': name,
    'slug': slug,
    'icon_s3_key': iconS3Key,
    'caption': caption,
    'description': description,
    'display_order': displayOrder,
    'is_active': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'StylePersonalities': stylePersonalities,
    'Tags': tags,
    'Colors': colors,
    'variants_count': variantsCount,
    'templates_count': templatesCount,
    'unlocked_variants_count': unlockedVariantsCount,
    'is_locked': isLocked,
    'Variants': variants.map((v) => v.toJson()).toList(),
  };
}

class Variant {
  final String? id;
  final String? uid;
  final String? seriesId;
  final String? badgeId;
  final String? name;
  final String? description;
  final String? thumbnailS3Key;
  final String? likesCount;
  final String? displayOrder;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? variantBadge;
  final List<BusinessCategory> businessCategories;
  final String? templatesCount;
  final bool isLocked;

  Variant({
    required this.id,
    required this.uid,
    required this.seriesId,
    this.badgeId,
    required this.name,
    this.description,
    this.thumbnailS3Key,
    required this.likesCount,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.variantBadge,
    required this.businessCategories,
    required this.templatesCount,
    required this.isLocked,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      seriesId: json['series_id']?.toString(),
      badgeId: json['badge_id']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      likesCount: json['likes_count']?.toString(),
      displayOrder: json['display_order']?.toString(),
      isActive: json['is_active']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      variantBadge: json['VariantBadge']?.toString(),
      businessCategories:
          (json['BusinessCategories'] as List<dynamic>?)
              ?.map((bc) => BusinessCategory.fromJson(bc))
              .toList() ??
          [],
      templatesCount: json['templates_count']?.toString(),
      isLocked: json['is_locked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'series_id': seriesId,
    'badge_id': badgeId,
    'name': name,
    'description': description,
    'thumbnail_s3_key': thumbnailS3Key,
    'likes_count': likesCount,
    'display_order': displayOrder,
    'is_active': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'VariantBadge': variantBadge,
    'BusinessCategories': businessCategories.map((bc) => bc.toJson()).toList(),
    'templates_count': templatesCount,
    'is_locked': isLocked,
  };
}

class BusinessCategory {
  final String? id;
  final String? uid;
  final String? slug;
  final String? name;

  BusinessCategory({
    required this.id,
    required this.uid,
    required this.slug,
    required this.name,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      slug: json['slug']?.toString(),
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'slug': slug,
    'name': name,
  };
}

class StylePersonality {
  final String? id;
  final String? uid;
  final String? slug;
  final String? name;

  StylePersonality({
    required this.id,
    required this.uid,
    required this.slug,
    required this.name,
  });

  factory StylePersonality.fromJson(Map<String, dynamic> json) =>
      StylePersonality(
        id: json["id"]?.toString(),
        uid: json["uid"]?.toString(),
        slug: json["slug"]?.toString(),
        name: json["name"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "slug": slug,
    "name": name,
  };
}
