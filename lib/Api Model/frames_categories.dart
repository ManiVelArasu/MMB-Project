class FramesCategories {
  final bool success;
  final List<Datum> data;

  FramesCategories({required this.success, required this.data});

  factory FramesCategories.fromJson(Map<String, dynamic> json) =>
      FramesCategories(
        success: json["success"],
        data:json["data"]==null?[]: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  final String? id;
  final String? uid;
  final String? name;
  final String? slug;
  final String? displayOrder;

  Datum({
    required this.id,
    required this.uid,
    required this.name,
    required this.slug,
    required this.displayOrder,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"]?.toString(),
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    slug: json["slug"]?.toString(),
    displayOrder: json["display_order"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "name": name,
    "slug": slug,
    "display_order": displayOrder,
  };
}
