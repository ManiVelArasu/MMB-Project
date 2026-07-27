import 'dart:convert';

TemplateCategoriesModel templateCategoriesModelFromJson(String str) =>
    TemplateCategoriesModel.fromJson(json.decode(str));

String templateCategoriesModelToJson(TemplateCategoriesModel data) =>
    json.encode(data.toJson());

class TemplateCategoriesModel {
  final bool? success;
  final List<TemplateCategories>? data;

  TemplateCategoriesModel({
    this.success,
    this.data,
  });

  TemplateCategoriesModel copyWith({
    bool? success,
    List<TemplateCategories>? data,
  }) =>
      TemplateCategoriesModel(
        success: success ?? this.success,
        data: data ?? this.data,
      );

  // 🚨 INTHA factory constructor missing-a irundhadhaala dhaan error vandhuchu
  factory TemplateCategoriesModel.fromJson(Map<String, dynamic> json) =>
      TemplateCategoriesModel(
        success: json["success"] as bool?,
        data: json["data"] == null
            ? []
            : List<TemplateCategories>.from(
          (json["data"] as List)
              .map((x) => TemplateCategories.fromJson(x as Map<String, dynamic>)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class TemplateCategories {
  final String? id;
  final String? uid;
  final String? parentId;
  final String? name;
  final String? slug;
  final String? iconS3Key;
  final String? thumbnailS3Key;
  final String? showInHomepage;
  final String? displayOrder;
  final String? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TemplateCategories({
    this.id,
    this.uid,
    this.parentId,
    this.name,
    this.slug,
    this.iconS3Key,
    this.thumbnailS3Key,
    this.showInHomepage,
    this.displayOrder,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  TemplateCategories copyWith({
    String? id,
    String? uid,
    String? parentId,
    String? name,
    String? slug,
    String? iconS3Key,
    String? thumbnailS3Key,
    String? showInHomepage,
    String? displayOrder,
    String? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TemplateCategories(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        parentId: parentId ?? this.parentId,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        iconS3Key: iconS3Key ?? this.iconS3Key,
        thumbnailS3Key: thumbnailS3Key ?? this.thumbnailS3Key,
        showInHomepage: showInHomepage ?? this.showInHomepage,
        displayOrder: displayOrder ?? this.displayOrder,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory TemplateCategories.fromJson(Map<String, dynamic> json) =>
      TemplateCategories(
        id: json["id"]?.toString(),
        uid: json["uid"]?.toString(),
        parentId: json["parent_id"]?.toString(),
        name: json["name"]?.toString(),
        slug: json["slug"]?.toString(),
        iconS3Key: json["icon_s3_key"]?.toString(),
        thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
        showInHomepage: json["show_in_homepage"]?.toString(),
        displayOrder: json["display_order"]?.toString(),
        isActive: json["is_active"]?.toString(),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.tryParse(json["created_at"].toString()),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.tryParse(json["updated_at"].toString()),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "parent_id": parentId,
    "name": name,
    "slug": slug,
    "icon_s3_key": iconS3Key,
    "thumbnail_s3_key": thumbnailS3Key,
    "show_in_homepage": showInHomepage,
    "display_order": displayOrder,
    "is_active": isActive,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}