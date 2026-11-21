class MineFrames {
  final bool success;
  final List<Datum> data;

  MineFrames({required this.success, required this.data});

  factory MineFrames.fromJson(Map<String, dynamic> json) => MineFrames(
    success: json["success"],
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  final String? id;
  final String? uid;
  final String? userId;
  final String? frameId;
  final String? acquiredVia;
  final String? paymentId;
  final String? status;
  final DateTime? acquiredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Frame? frame;

  Datum({
    required this.id,
    required this.uid,
    required this.userId,
    required this.frameId,
    required this.acquiredVia,
    required this.paymentId,
    required this.status,
    required this.acquiredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.frame,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    userId: json["user_id"]?.toString(),
    frameId: json["frame_id"]?.toString(),
    acquiredVia: json["acquired_via"]?.toString(),
    paymentId: json["payment_id"]?.toString(),
    status: json["status"]?.toString(),
    acquiredAt: json["acquired_at"] == null
        ? null
        : DateTime.parse(json["acquired_at"]),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    frame: json["Frame"] == null ? null : Frame.fromJson(json["Frame"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "user_id": userId,
    "frame_id": frameId,
    "acquired_via": acquiredVia,
    "payment_id": paymentId,
    "status": status,
    "acquired_at": acquiredAt?.toIso8601String(),
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "Frame": frame?.toJson(),
  };
}

class Frame {
  final String? id;
  final String? uid;
  final String? categoryId;
  final String? name;
  final String? description;
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
  final String? thumbnailS3Key;
  final Version? version;
  final List<Language> availableLanguages;
  final List<ESize> availableSizes;

  Frame({
    required this.id,
    required this.uid,
    required this.categoryId,
    required this.name,
    required this.description,
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
    required this.thumbnailS3Key,
    required this.version,
    required this.availableLanguages,
    required this.availableSizes,
  });

  factory Frame.fromJson(Map<String, dynamic> json) => Frame(
    id: json["id"].toString(),
    uid: json["uid"].toString(),
    categoryId: json["category_id"].toString(),
    name: json["name"].toString(),
    description: json["description"].toString(),
    frameType: json["frame_type"].toString(),
    isPremium: json["is_premium"].toString(),
    price: json["price"].toString(),
    strikePrice: json["strike_price"].toString(),
    displayOrder: json["display_order"].toString(),
    status: json["status"].toString(),
    createdBy: json["created_by"].toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    frameCategory: json["FrameCategory"] == null
        ? null
        : FrameCategory.fromJson(json["FrameCategory"]),
    thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
    version: json["version"] == null ? null : Version.fromJson(json["version"]),
    availableLanguages: json["available_languages"] == null
        ? []
        : List<Language>.from(
            json["available_languages"].map((x) => Language.fromJson(x)),
          ),
    availableSizes: json["available_sizes"] == null
        ? []
        : List<ESize>.from(
            json["available_sizes"].map((x) => ESize.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "category_id": categoryId,
    "name": name,
    "description": description,
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
    "thumbnail_s3_key": thumbnailS3Key,
    "version": version?.toJson(),
    "available_languages": List<dynamic>.from(
      availableLanguages.map((x) => x.toJson()),
    ),
    "available_sizes": List<dynamic>.from(
      availableSizes.map((x) => x.toJson()),
    ),
  };
}

class Language {
  final String? id;
  final String? code;
  final String? name;
  final String? nativeName;

  Language({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeName,
  });

  factory Language.fromJson(Map<String, dynamic> json) => Language(
    id: json["id"]?.toString(),
    code: json["code"]?.toString(),
    name: json["name"]?.toString(),
    nativeName: json["native_name"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "code": code,
    "name": name,
    "native_name": nativeName,
  };
}

class ESize {
  final String? id;
  final String? uid;
  final String? slug;
  final String? name;
  final String? width;
  final String? height;
  final String? platform;

  ESize({
    required this.id,
    required this.uid,
    required this.slug,
    required this.name,
    required this.width,
    required this.height,
    required this.platform,
  });

  factory ESize.fromJson(Map<String, dynamic> json) => ESize(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    slug: json["slug"]?.toString(),
    name: json["name"]?.toString(),
    width: json["width"]?.toString(),
    height: json["height"]?.toString(),
    platform: json["platform"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "slug": slug,
    "name": name,
    "width": width,
    "height": height,
    "platform": platform,
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

class Version {
  final String? id;
  final String? uid;
  final String? languageId;
  final String? sizeId;
  final String? thumbnailS3Key;
  final String? assetPrefix;
  final DateTime? updatedAt;
  final Language? language;
  final ESize? templateSize;

  Version({
    required this.id,
    required this.uid,
    required this.languageId,
    required this.sizeId,
    required this.thumbnailS3Key,
    required this.assetPrefix,
    required this.updatedAt,
    required this.language,
    required this.templateSize,
  });

  factory Version.fromJson(Map<String, dynamic> json) => Version(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    languageId: json["language_id"]?.toString(),
    sizeId: json["size_id"]?.toString(),
    thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
    assetPrefix: json["asset_prefix"]?.toString(),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    language: json["Language"] == null
        ? null
        : Language.fromJson(json["Language"]),
    templateSize: json["TemplateSize"] == null
        ? null
        : ESize.fromJson(json["TemplateSize"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "language_id": languageId,
    "size_id": sizeId,
    "thumbnail_s3_key": thumbnailS3Key,
    "asset_prefix": assetPrefix,
    "updated_at": updatedAt?.toIso8601String(),
    "Language": language?.toJson(),
    "TemplateSize": templateSize?.toJson(),
  };
}
