class SpecialDays {
  final bool? success;
  final List<Datum> data;
  final Meta? meta;

  SpecialDays({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory SpecialDays.fromJson(Map<String, dynamic> json) {
    return SpecialDays(
      success: json["success"] ?? false,
      data: json["data"] == null
          ? []
          : List<Datum>.from(
        (json["data"] as List).map(
              (x) => Datum.fromJson(
            x as Map<String, dynamic>,
          ),
        ),
      ),
      meta: json["meta"] == null
          ? null
          : Meta.fromJson(
        json["meta"] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "data": data.map((x) => x.toJson()).toList(),
      "meta": meta?.toJson(),
    };
  }
}

class Datum {
  final String? id;
  final String? uid;
  final String? name;
  final String? description;
  final String? thumbnailS3Key;
  final String? bannerS3Key;
  final String? type;
  final String? eventDate;
  final String? fullDate;
  final String? isRecurring;
  final String? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<Template> templates;

  final DateTime occursOn;

  Datum({
    required this.id,
    required this.uid,
    required this.name,
    required this.description,
    required this.thumbnailS3Key,
    required this.bannerS3Key,
    required this.type,
    required this.eventDate,
    required this.fullDate,
    required this.isRecurring,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.templates,
    required this.occursOn,
  });

  factory Datum.fromJson(Map<String, dynamic> json) {
    return Datum(
      id: json["id"]?.toString(),
      uid: json["uid"]?.toString(),
      name: json["name"]?.toString(),
      description: json["description"]?.toString(),

      thumbnailS3Key:
      json["thumbnail_s3_key"]?.toString(),

      bannerS3Key:
      json["banner_s3_key"]?.toString(),

      type: json["type"]?.toString(),

      eventDate:
      json["event_date"]?.toString(),

      fullDate:
      json["full_date"]?.toString(),

      isRecurring:
      json["is_recurring"]?.toString(),

      isActive:
      json["is_active"]?.toString(),

      createdAt: json["created_at"] == null
          ? null
          : DateTime.tryParse(
        json["created_at"].toString(),
      ),

      updatedAt: json["updated_at"] == null
          ? null
          : DateTime.tryParse(
        json["updated_at"].toString(),
      ),

      // IMPORTANT
      // API:
      // "Templates": [...]
      templates: json["Templates"] == null
          ? []
          : List<Template>.from(
        (json["Templates"] as List).map(
              (x) => Template.fromJson(
            x as Map<String, dynamic>,
          ),
        ),
      ),

      occursOn: DateTime.parse(
        json["occurs_on"].toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uid": uid,
      "name": name,
      "description": description,
      "thumbnail_s3_key": thumbnailS3Key,
      "banner_s3_key": bannerS3Key,
      "type": type,
      "event_date": eventDate,
      "full_date": fullDate,
      "is_recurring": isRecurring,
      "is_active": isActive,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),

      "Templates": templates
          .map((x) => x.toJson())
          .toList(),

      "occurs_on":
      "${occursOn.year.toString().padLeft(4, '0')}-"
          "${occursOn.month.toString().padLeft(2, '0')}-"
          "${occursOn.day.toString().padLeft(2, '0')}",
    };
  }
}

class Template {
  final String? id;
  final String? uid;
  final String? categoryId;
  final String? languageId;
  final String? name;
  final String? thumbnailS3Key;
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

  Template({
    required this.id,
    required this.uid,
    required this.categoryId,
    required this.languageId,
    required this.name,
    required this.thumbnailS3Key,
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

  factory Template.fromJson(
      Map<String, dynamic> json,
      ) {
    return Template(
      id: json["id"]?.toString(),

      uid: json["uid"]?.toString(),

      categoryId:
      json["category_id"]?.toString(),

      languageId:
      json["language_id"]?.toString(),

      name:
      json["name"]?.toString(),

      thumbnailS3Key:
      json["thumbnail_s3_key"]?.toString(),

      templateType:
      json["template_type"]?.toString(),

      isPremium:
      json["is_premium"]?.toString(),

      trendingScore:
      json["trending_score"]?.toString(),

      viewsCount:
      json["views_count"]?.toString(),

      downloadsCount:
      json["downloads_count"]?.toString(),

      likesCount:
      json["likes_count"]?.toString(),

      status:
      json["status"]?.toString(),

      createdBy:
      json["created_by"]?.toString(),

      createdAt: json["created_at"] == null
          ? null
          : DateTime.tryParse(
        json["created_at"].toString(),
      ),

      updatedAt: json["updated_at"] == null
          ? null
          : DateTime.tryParse(
        json["updated_at"].toString(),
      ),

      isLocked:
      json["is_locked"] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uid": uid,
      "category_id": categoryId,
      "language_id": languageId,
      "name": name,
      "thumbnail_s3_key": thumbnailS3Key,
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
}

class Meta {
  final Range? range;

  Meta({
    required this.range,
  });

  factory Meta.fromJson(
      Map<String, dynamic> json,
      ) {
    return Meta(
      range: json["range"] == null
          ? null
          : Range.fromJson(
        json["range"] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "range": range?.toJson(),
    };
  }
}

class Range {
  final DateTime from;
  final DateTime to;

  Range({
    required this.from,
    required this.to,
  });

  factory Range.fromJson(
      Map<String, dynamic> json,
      ) {
    return Range(
      from: DateTime.parse(
        json["from"].toString(),
      ),
      to: DateTime.parse(
        json["to"].toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "from":
      "${from.year.toString().padLeft(4, '0')}-"
          "${from.month.toString().padLeft(2, '0')}-"
          "${from.day.toString().padLeft(2, '0')}",

      "to":
      "${to.year.toString().padLeft(4, '0')}-"
          "${to.month.toString().padLeft(2, '0')}-"
          "${to.day.toString().padLeft(2, '0')}",
    };
  }
}