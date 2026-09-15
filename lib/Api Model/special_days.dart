class SpecialDays {
  final bool? success;
  final List<Datum> data;
  final Meta? meta;

  SpecialDays({required this.success, required this.data, required this.meta});

  factory SpecialDays.fromJson(Map<String, dynamic> json) => SpecialDays(
    success: json["success"] ?? false,
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta?.toJson(),
  };
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
  final List<dynamic> templates;
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

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    description: json["description"]?.toString(),
    thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
    bannerS3Key: json["banner_s3_key"]?.toString(),
    type: json["type"]?.toString(),
    eventDate: json["event_date"]?.toString(),
    fullDate: json["full_date"]?.toString(),
    isRecurring: json["is_recurring"]?.toString(),
    isActive: json["is_active"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    templates: json["Templates"] == null
        ? []
        : List<dynamic>.from(json["Templates"].map((x) => x)),
    occursOn:  DateTime.parse(json["occurs_on"]),
  );

  Map<String, dynamic> toJson() => {
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
    "Templates": List<dynamic>.from(templates.map((x) => x)),
    "occurs_on":
        "${occursOn?.year.toString().padLeft(4, '0')}-${occursOn?.month.toString().padLeft(2, '0')}-${occursOn?.day.toString().padLeft(2, '0')}",
  };
}

class Meta {
  final Range? range;

  Meta({required this.range});

  factory Meta.fromJson(Map<String, dynamic> json) =>
      Meta(range: json["range"] == null ? null : Range.fromJson(json["range"]));

  Map<String, dynamic> toJson() => {"range": range?.toJson()};
}

class Range {
  final DateTime from;
  final DateTime to;

  Range({required this.from, required this.to});

  factory Range.fromJson(Map<String, dynamic> json) =>
      Range(from: DateTime.parse(json["from"]), to: DateTime.parse(json["to"]));

  Map<String, dynamic> toJson() => {
    "from":
        "${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}",
    "to":
        "${to.year.toString().padLeft(4, '0')}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}",
  };
}
