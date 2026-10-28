class FramesData {
  final bool? success;
  final List<FramesList> data;
  final Meta? meta;

  FramesData({required this.success, required this.data, required this.meta});

  factory FramesData.fromJson(Map<String, dynamic> json) => FramesData(
    success: json["success"] ?? false,
    data: json["data"] == null
        ? []
        : List<FramesList>.from(
            json["data"].map((x) => FramesList.fromJson(x)),
          ),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta?.toJson(),
  };
}

class FramesList {
  final String? id;
  final String? uid;
  final String? categoryId;
  final String? name;
  final String? description;
  final String? thumbnailS3Key;
  final String? frameType;
  final String? isPremium;
  final String? price;
  final String? strikePrice;
  final String? displayOrder;
  final String? status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final FrameCategory? frameCategory;
  final bool? owned;
  final bool? isLocked;

  FramesList({
    required this.id,
    required this.uid,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.thumbnailS3Key,
    required this.frameType,
    required this.isPremium,
    required this.price,
    required this.strikePrice,
    required this.displayOrder,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.frameCategory,
    required this.owned,
    required this.isLocked,
  });

  factory FramesList.fromJson(Map<String, dynamic> json) => FramesList(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    categoryId: json["category_id"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
    thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
    frameType: json["frame_type"]?.toString(),
    isPremium: json["is_premium"]?.toString(),
    price: json["price"]?.toString(),
    strikePrice: json["strike_price"]?.toString(),
    displayOrder: json["display_order"]?.toString(),
    status: json["status"]?.toString(),
    createdBy: json["created_by"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    frameCategory: json["FrameCategory"] == null
        ? null
        : FrameCategory.fromJson(json["FrameCategory"]),
    owned: json["owned"] ?? false,
    isLocked: json["is_locked"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "category_id": categoryId,
    "name": name,
    "description": description,
    "thumbnail_s3_key": thumbnailS3Key,
    "frame_type": frameType,
    "is_premium": isPremium,
    "price": price,
    "strike_price": strikePrice,
    "display_order": displayOrder,
    "status": status,
    "created_by": createdBy,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "FrameCategory": frameCategory?.toJson(),
    "owned": owned,
    "is_locked": isLocked,
  };
}

class FrameCategory {
  final String? id;
  final String? uid;
  final String? name;
  final String? slug;

  FrameCategory({
    required this.id,
    required this.uid,
    required this.name,
    required this.slug,
  });

  factory FrameCategory.fromJson(Map<String, dynamic> json) => FrameCategory(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    slug: json["slug"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "name": name,
    "slug": slug,
  };
}

class Meta {
  final String? total;

  Meta({required this.total});

  factory Meta.fromJson(Map<String, dynamic> json) =>
      Meta(total: json["total"]?.toString());

  Map<String, dynamic> toJson() => {"total": total};
}
