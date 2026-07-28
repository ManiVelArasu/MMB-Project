class ThemeGroupResponse {
  final bool? success;
  final List<ThemeGroup>? data;

  ThemeGroupResponse({this.success, this.data});

  factory ThemeGroupResponse.fromJson(Map<String, dynamic> json) {
    return ThemeGroupResponse(
      success: json["success"],
      data: json["data"] == null
          ? []
          : List<ThemeGroup>.from(
              json["data"].map((x) => ThemeGroup.fromJson(x)),
            ),
    );
  }
}

class ThemeGroup {
  final String? id;
  final String? uid;
  final String? name;
  final String? slug;
  final String? displayOrder;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final List<ThemeModel>? themes;

  ThemeGroup({
    this.id,
    this.uid,
    this.name,
    this.slug,
    this.displayOrder,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.themes,
  });

  factory ThemeGroup.fromJson(Map<String, dynamic> json) {
    return ThemeGroup(
      id: json["id"]?.toString(),
      uid: json["uid"]?.toString(),
      name: json["name"]?.toString(),
      slug: json["slug"]?.toString(),
      displayOrder: json["display_order"]?.toString(),
      isActive: json["is_active"]?.toString(),
      createdAt: json["created_at"]?.toString(),
      updatedAt: json["updated_at"]?.toString(),
      themes: json["Themes"] == null
          ? []
          : List<ThemeModel>.from(
              json["Themes"].map((x) => ThemeModel.fromJson(x)),
            ),
    );
  }
}

class ThemeModel {
  final String? id;
  final String? uid;
  final String? groupId;
  final String? name;
  final String? description;
  final String? thumbnailS3Key;
  final String? likesCount;
  final String? displayOrder;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;
  final List<BusinessCategory>? businessCategories;

  ThemeModel({
    this.id,
    this.uid,
    this.groupId,
    this.name,
    this.description,
    this.thumbnailS3Key,
    this.likesCount,
    this.displayOrder,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.businessCategories,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json["id"]?.toString(),
      uid: json["uid"]?.toString(),
      groupId: json["group_id"]?.toString(),
      name: json["name"]?.toString(),
      description: json["description"]?.toString(),
      thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
      likesCount: json["likes_count"]?.toString(),
      displayOrder: json["display_order"]?.toString(),
      isActive: json["is_active"]?.toString(),
      createdAt: json["created_at"]?.toString(),
      updatedAt: json["updated_at"]?.toString(),
      businessCategories: json["BusinessCategories"] == null
          ? []
          : List<BusinessCategory>.from(
              json["BusinessCategories"].map(
                (x) => BusinessCategory.fromJson(x),
              ),
            ),
    );
  }
}

class BusinessCategory {
  final String? id;
  final String? uid;
  final String? slug;
  final String? name;

  BusinessCategory({this.id, this.uid, this.slug, this.name});

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json["id"]?.toString(),
      uid: json["uid"]?.toString(),
      slug: json["slug"]?.toString(),
      name: json["name"]?.toString(),
    );
  }
}
