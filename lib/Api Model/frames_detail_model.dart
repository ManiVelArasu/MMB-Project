class FramesDetailScreen {
  final bool success;
  final Data? data;

  FramesDetailScreen({required this.success, required this.data});

  factory FramesDetailScreen.fromJson(Map<String, dynamic> json) =>
      FramesDetailScreen(
        success: json["success"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"success": success, "data": data?.toJson()};
}

class Data {
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
  final bool? owned;
  final bool? isLocked;
  final String? thumbnailUrl;
  final List<Version> versions;
  final String? content;

  Data({
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
    required this.owned,
    required this.isLocked,
    required this.thumbnailUrl,
    required this.versions,
    required this.content,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    categoryId: json["category_id"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
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
    owned: json["owned"] ?? false,
    isLocked: json["is_locked"] ?? false,
    thumbnailUrl: json["thumbnail_url"]?.toString(),
    versions: json["versions"] == null
        ? []
        : List<Version>.from(json["versions"].map((x) => Version.fromJson(x))),
    content: json["content"]?.toString(),
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
    "owned": owned,
    "is_locked": isLocked,
    "thumbnail_url": thumbnailUrl,
    "versions": List<dynamic>.from(versions.map((x) => x.toJson())),
    "content": content,
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
