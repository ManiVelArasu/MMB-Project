class ThemeDetailView {
  bool success;
  SingleData? data;

  ThemeDetailView({required this.success, required this.data});

  factory ThemeDetailView.fromJson(Map<String, dynamic> json) => ThemeDetailView(
    success: json["success"] ?? false,
    data: SingleData.fromJson(json["data"] ?? {}),
  );
}

class SingleData {
  String? id;
  String? uid;
  String? seriesId;
  String? badgeId;
  String? name;
  String? description;
  String? thumbnailS3Key;
  String? likesCount;
  String? displayOrder;
  String? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;
  BrandSeries? brandSeries;
  String? variantBadge;
  List<BusinessCategory> businessCategories;
  bool isLocked;
  List<Template> templates;
  String? templatesCount;

  SingleData({
    required this.id,
    required this.uid,
    required this.seriesId,
    required this.badgeId,
    required this.name,
    required this.description,
    required this.thumbnailS3Key,
    required this.likesCount,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.brandSeries,
    required this.variantBadge,
    required this.businessCategories,
    required this.isLocked,
    required this.templates,
    required this.templatesCount,
  });

  factory SingleData.fromJson(Map<String, dynamic> json) => SingleData(
    id: json["id"] ?.toString(),
    uid: json["uid"]  ?.toString(),
    seriesId: json["series_id"] ?.toString(),
    badgeId: json["badge_id"] ?.toString(),
    name: json["name"] ?.toString(),
    description: json["description"] ?.toString(),
    thumbnailS3Key: json["thumbnail_s3_key"] ?.toString(),
    likesCount: json["likes_count"]  ?.toString(),
    displayOrder: json["display_order"]  ?.toString(),
    isActive: json["is_active"]  ?.toString(),
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : DateTime.now(),
    brandSeries: BrandSeries.fromJson(json["BrandSeries"] ?? {}),
    variantBadge: json["variant_badge"] ?.toString(),
    businessCategories: List<BusinessCategory>.from((json["BusinessCategories"] ?? []).map((x) => BusinessCategory.fromJson(x))),
    isLocked: json["is_locked"] ?? false,
    templates: List<Template>.from((json["Templates"] ?? []).map((x) => Template.fromJson(x))),
    templatesCount: json["templates_count"] ?.toString(),
  );
}

class BrandSeries {
  String? id;
  String? uid;
  String? slug;
  String? name;
  String? iconS3Key;
  String? caption;
  String? description;
  List<dynamic> stylePersonalities;
  List<dynamic> tags;
  List<dynamic> colors;

  BrandSeries({
    required this.id,
    required this.uid,
    required this.slug,
    required this.name,
    required this.iconS3Key,
    required this.caption,
    required this.description,
    required this.stylePersonalities,
    required this.tags,
    required this.colors,
  });

  factory BrandSeries.fromJson(Map<String, dynamic> json) => BrandSeries(
    id: json["id"] ?.toString(),
    uid: json["uid"]  ?.toString(),
    slug: json["slug"] ?.toString(),
    name: json["name"]  ?.toString(),
    iconS3Key: json["icon_s3_key"] ?.toString(),
    caption: json["caption"] ?.toString(),
    description: json["description"] ?.toString(),
    stylePersonalities: List<dynamic>.from(json["style_personalities"] ?? []),
    tags: List<dynamic>.from(json["tags"] ?? []),
    colors: List<dynamic>.from(json["colors"] ?? []),
  );
}

class BusinessCategory {
  String? id;
  String? uid;
  String? slug;
  String? name;

  BusinessCategory({required this.id, required this.uid, required this.slug, required this.name});

  factory BusinessCategory.fromJson(Map<String, dynamic> json) => BusinessCategory(
    id: json["id"] ?.toString(),
    uid: json["uid"]  ?.toString(),
    slug: json["slug"]  ?.toString(),
    name: json["name"] ?.toString(),
  );
}

class Template {
  String? id;
  String? uid;
  String? categoryId;
  String? name;
  String? thumbnailS3Key;
  String? templateType;
  String? isPremium;
  String? trendingScore;
  String? viewsCount;
  String? downloadsCount;
  String? likesCount;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isLocked;

  Template({
    required this.id,
    required this.uid,
    required this.categoryId,
    required this.name,
    required this.thumbnailS3Key,
    required this.templateType,
    required this.isPremium,
    required this.trendingScore,
    required this.viewsCount,
    required this.downloadsCount,
    required this.likesCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json["id"] ?.toString(),
    uid: json["uid"]?.toString(),
    categoryId: json["category_id"] ?.toString(),
    name: json["name"] ?.toString(),
    thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
    templateType: json["template_type"]?.toString(),
    isPremium: json["is_premium"]?.toString(),
    trendingScore: json["trending_score"] ?.toString(),
    viewsCount: json["views_count"]?.toString(),
    downloadsCount: json["downloads_count"]?.toString(),
    likesCount: json["likes_count"] ?.toString(),
    status: json["status"] ?.toString(),
    createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
    updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : DateTime.now(),
    isLocked: json["is_locked"] ?? false,
  );
}