class TemplateSizeModel {
  bool success;
  List<TemplateSize> data;

  TemplateSizeModel({required this.success, required this.data});

  factory TemplateSizeModel.fromJson(Map<String, dynamic> json) =>
      TemplateSizeModel(
        success: json["success"] ?? false,
        data: json["data"] == null
            ? []
            : List<TemplateSize>.from(json["data"].map((x) => TemplateSize.fromJson(x))),
      );

  TemplateSizeModel copyWith({bool? success, List<TemplateSize>? data}) =>
      TemplateSizeModel(
        success: success ?? this.success,
        data: data ?? this.data,
      );
}

class TemplateSize {
  String? id;
  String? uid;
  String? name;
  String? slug;
  String? width;
  String? height;
  String? unit;
  String? platform;
  String? isActive;
  DateTime? createdAt;

  TemplateSize({
    required this.id,
    required this.uid,
    required this.name,
    required this.slug,
    required this.width,
    required this.height,
    required this.unit,
    required this.platform,
    required this.isActive,
    required this.createdAt,
  });

  factory TemplateSize.fromJson(Map<String, dynamic> json) => TemplateSize(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    slug: json["slug"]?.toString(),
    width: json["width"]?.toString(),
    height: json["height"]?.toString(),
    unit: json["unit"]?.toString(),
    platform: json["platform"]?.toString(),
    isActive: json["isActive"]?.toString(),
    createdAt: json["createdAt"] == null
        ? DateTime.now()
        : DateTime.parse(json["createdAt"]),
  );

  TemplateSize copyWith({
    String? id,
    String? uid,
    String? name,
    String? slug,
    String? width,
    String? height,
    String? unit,
    String? platform,
    String? isActive,
    DateTime? createdAt,
  }) => TemplateSize(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    width: width ?? this.width,
    height: height ?? this.height,
    unit: unit ?? this.unit,
    platform: platform ?? this.platform,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}
