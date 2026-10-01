class TemplatedChildren {
  final bool success;
  final List<TemplatedChildrenList> data;

  TemplatedChildren({required this.success, required this.data});

  factory TemplatedChildren.fromJson(Map<String, dynamic> json) =>
      TemplatedChildren(
        success: json["success"],
        data: List<TemplatedChildrenList>.from(
          json["data"].map((x) => TemplatedChildrenList.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class TemplatedChildrenList {
  final String? id;
  final String? uid;
  final String? parentId;
  final String? name;
  final String? slug;
  final String? iconS3Key;
  final String? thumbnailS3Key;
  final String? showInHomepage;
  final String? displayOrder;
  final String? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TemplatedChildrenList> children;

  TemplatedChildrenList({
    required this.id,
    required this.uid,
    required this.parentId,
    required this.name,
    required this.slug,
    required this.iconS3Key,
    required this.thumbnailS3Key,
    required this.showInHomepage,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.children,
  });

  factory TemplatedChildrenList.fromJson(Map<String, dynamic> json) =>
      TemplatedChildrenList(
        id: json["id"]?.toString(),
        uid: json["uid"]?.toString(),
        parentId: json["parent_id"]?.toString(),
        name: json["name"]?.toString(),
        slug: json["slug"]?.toString(),
        iconS3Key: json["icon_s3_key"]?.toString(),
        thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
        showInHomepage: json["show_in_homepage"]?.toString(),
        displayOrder: json["display_order"]?.toString(),
        isActive: json["is_active"]?.toString(),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.tryParse(json["created_at"].toString()),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.tryParse(json["updated_at"].toString()),
        children: json["children"] == null
            ? []
            : List<TemplatedChildrenList>.from(
          json["children"].map((x) => TemplatedChildrenList.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "parent_id": parentId,
    "name": name,
    "slug": slug,
    "icon_s3_key": iconS3Key,
    "thumbnail_s3_key": thumbnailS3Key,
    "show_in_homepage": showInHomepage,
    "display_order": displayOrder,
    "is_active": isActive,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "children": List<dynamic>.from(children.map((x) => x.toJson())),
  };
}
