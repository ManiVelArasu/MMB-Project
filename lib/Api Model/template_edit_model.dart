// To parse this JSON data, do
//
//     final templateEdit = templateEditFromJson(jsonString);

import 'dart:convert';

TemplateEdit templateEditFromJson(String str) => TemplateEdit.fromJson(json.decode(str));

String templateEditToJson(TemplateEdit data) => json.encode(data.toJson());

class TemplateEdit {
  final bool success;
  final Data data;

  TemplateEdit({
    required this.success,
    required this.data,
  });

  factory TemplateEdit.fromJson(Map<String, dynamic> json) => TemplateEdit(
    success: json["success"],
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data.toJson(),
  };
}

class Data {
  final String? id;
  final String? uid;
  final String? categoryId;
  final String? languageId;
  final String? name;
  final String? thumbnailS3Key;
  final String? content;
  final String? templateType;
  final String? isPremium;
  final String? trendingScore;
  final String? viewsCount;
  final String? downloadsCount;
  final String? likesCount;
  final String? status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLocked;

  Data({
    required this.id,
    required this.uid,
    required this.categoryId,
    required this.languageId,
    required this.name,
    required this.thumbnailS3Key,
    required this.content,
    required this.templateType,
    required this.isPremium,
    required this.trendingScore,
    required this.viewsCount,
    required this.downloadsCount,
    required this.likesCount,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    categoryId: json["category_id"]?.toString(),
    languageId: json["language_id"]?.toString(),
    name: json["name"]?.toString(),
    thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
    content: json["content"]?.toString(),
    templateType: json["template_type"]?.toString(),
    isPremium: json["is_premium"]?.toString(),
    trendingScore: json["trending_score"]?.toString(),
    viewsCount: json["views_count"]?.toString(),
    downloadsCount: json["downloads_count"]?.toString(),
    likesCount: json["likes_count"]?.toString(),
    status: json["status"]?.toString(),
    createdBy: json["created_by"]?.toString(),
    createdAt:json["created_at"]==null?null: DateTime.parse(json["created_at"]),
    updatedAt:json["updated_at"]==null?null: DateTime.parse(json["updated_at"]),
    isLocked: json["is_locked"]??false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "category_id": categoryId,
    "language_id": languageId,
    "name": name,
    "thumbnail_s3_key": thumbnailS3Key,
    "content": content,
    "template_type": templateType,
    "is_premium": isPremium,
    "trending_score": trendingScore,
    "views_count": viewsCount,
    "downloads_count": downloadsCount,
    "likes_count": likesCount,
    "status": status,
    "created_by": createdBy,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "is_locked": isLocked,
  };
}
