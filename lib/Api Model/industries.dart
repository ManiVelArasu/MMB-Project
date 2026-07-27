// 1. TOP LEVEL RESPONSE MODEL
class IndustryResponse {
  IndustryResponse({
    required this.success,
    required this.data,
  });

  factory IndustryResponse.fromJson(Map<String, dynamic> json) =>
      IndustryResponse(
        success: json['success'] ?? false,
        data: json['data'] == null
            ? []
            : List<Industries>.from(
            json['data'].map((x) => Industries.fromJson(x))),
      );

  bool success;
  List<Industries> data;

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Industries {
  Industries({
    required this.id,
    required this.uid,
    required this.parentId,
    required this.name,
    required this.slug,
    required this.iconS3Key,
    required this.thumbnailS3Key,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Industries.fromJson(Map<String, dynamic> json) {
    return Industries(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      parentId: json['parent_id']?.toString(),
      name: json['name']?.toString(),
      slug: json['slug']?.toString(),
      iconS3Key: json['icon_s3_key']?.toString(),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      displayOrder: json['display_order']?.toString(),
      isActive: json['is_active']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }

  String? id;
  String? uid;
  String? parentId;
  String? name;
  String? slug;
  String? iconS3Key;
  String? thumbnailS3Key;
  String? displayOrder;
  String? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'parent_id': parentId,
    'name': name,
    'slug': slug,
    'icon_s3_key': iconS3Key,
    'thumbnail_s3_key': thumbnailS3Key,
    'display_order': displayOrder,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}