import 'dart:convert';

BusinessModel businessModelFromJson(String str) =>
    BusinessModel.fromJson(json.decode(str));

String businessModelToJson(BusinessModel data) => json.encode(data.toJson());

class BusinessModel {
  final bool? success;
  final List<BusinessApiModel> data;

  BusinessModel({required this.success, required this.data});

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
    success: json["success"] ?? false,
    data: json["data"] == null
        ? []
        : List<BusinessApiModel>.from(json["data"].map((x) => BusinessApiModel.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class BusinessApiModel {
  final String? brandColors;
  final String? socialLinks;
  final String? operatingHours;
  final String? id;
  final String? uid;
  final String? userId;
  final String? categoryId;
  final String? name;
  final String? description;
  final String? logoS3Key;
  final String? coverS3Key;
  final String? watermarkEnabled;
  final String? headingFontId;
  final String? bodyFontId;
  final String? activeFrameId;
  final String? latitude;
  final String? longitude;
  final String? geohash;
  final String? address;
  final String? city;
  final String? state;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String? ratingAvg;
  final String? ratingCount;
  final String? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final BusinessCategory? businessCategory;
  final List<dynamic> tags;
  final String? headingFont;
  final String? bodyFont;
  final bool watermarkAllowed;
  final bool watermarkActive;

  BusinessApiModel({
    required this.brandColors,
    required this.socialLinks,
    required this.operatingHours,
    required this.id,
    required this.uid,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.logoS3Key,
    required this.coverS3Key,
    required this.watermarkEnabled,
    required this.headingFontId,
    required this.bodyFontId,
    required this.activeFrameId,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.address,
    required this.city,
    required this.state,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.website,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.businessCategory,
    required this.tags,
    required this.headingFont,
    required this.bodyFont,
    required this.watermarkAllowed,
    required this.watermarkActive,
  });

  factory BusinessApiModel.fromJson(Map<String, dynamic> json) => BusinessApiModel(
    brandColors: json["brand_colors"]?.toString(),
    socialLinks: json["social_links"]?.toString(),
    operatingHours: json["operating_hours"]?.toString(),
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    userId: json["user_id"]?.toString(),
    categoryId: json["category_id"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
    logoS3Key: json["logo_s3_key"]?.toString(),
    coverS3Key: json["cover_s3_key"]?.toString(),
    watermarkEnabled: json["watermark_enabled"]?.toString(),
    headingFontId: json["heading_font_id"]?.toString(),
    bodyFontId: json["body_font_id"]?.toString(),
    activeFrameId: json["active_frame_id"]?.toString(),
    latitude: json["latitude"]?.toString(),
    longitude: json["longitude"]?.toString(),
    geohash: json["geohash"]?.toString(),
    address: json["address"]?.toString(),
    city: json["city"]?.toString(),
    state: json["state"]?.toString(),
    phone: json["phone"]?.toString(),
    whatsapp: json["whatsapp"]?.toString(),
    email: json["email"]?.toString(),
    website: json["website"]?.toString(),
    ratingAvg: json["rating_avg"]?.toString(),
    ratingCount: json["rating_count"]?.toString(),
    isActive: json["is_active"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    businessCategory: json["updated_at"] == null
        ? null
        : BusinessCategory.fromJson(json["BusinessCategory"]),
    tags: json["Tags"] == null
        ? []
        : List<dynamic>.from(json["Tags"].map((x) => x)),
    headingFont: json["headingFont"]?.toString(),
    bodyFont: json["bodyFont"]?.toString(),
    watermarkAllowed: json["watermark_allowed"] ?? false,
    watermarkActive: json["watermark_active"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "brand_colors": brandColors,
    "social_links": socialLinks,
    "operating_hours": operatingHours,
    "id": id,
    "uid": uid,
    "user_id": userId,
    "category_id": categoryId,
    "name": name,
    "description": description,
    "logo_s3_key": logoS3Key,
    "cover_s3_key": coverS3Key,
    "watermark_enabled": watermarkEnabled,
    "heading_font_id": headingFontId,
    "body_font_id": bodyFontId,
    "active_frame_id": activeFrameId,
    "latitude": latitude,
    "longitude": longitude,
    "geohash": geohash,
    "address": address,
    "city": city,
    "state": state,
    "phone": phone,
    "whatsapp": whatsapp,
    "email": email,
    "website": website,
    "rating_avg": ratingAvg,
    "rating_count": ratingCount,
    "is_active": isActive,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "BusinessCategory": businessCategory?.toJson(),
    "Tags": List<dynamic>.from(tags.map((x) => x)),
    "headingFont": headingFont,
    "bodyFont": bodyFont,
    "watermark_allowed": watermarkAllowed,
    "watermark_active": watermarkActive,
  };
}

class BusinessCategory {
  final String? id;
  final String? uid;
  final String? slug;
  final String? name;
  final String? parentId;
  final String? status;
  final String? isActive;
  final BusinessCategory? parent;

  BusinessCategory({
    required this.id,
    required this.uid,
    required this.slug,
    required this.name,
    required this.parentId,
    required this.status,
    required this.isActive,
    this.parent,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) =>
      BusinessCategory(
        id: json["id"]?.toString(),
        uid: json["uid"]?.toString(),
        slug: json["slug"]?.toString(),
        name: json["name"]?.toString(),
        parentId: json["parent_id"]?.toString(),
        status: json["status"]?.toString(),
        isActive: json["is_active"]?.toString(),
        parent: json["parent"] == null
            ? null
            : BusinessCategory.fromJson(json["parent"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "slug": slug,
    "name": name,
    "parent_id": parentId,
    "status": status,
    "is_active": isActive,
    "parent": parent?.toJson(),
  };
}
