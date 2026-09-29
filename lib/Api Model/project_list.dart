
class ProjectList {
  final bool success;
  final List<ProjectListModel> data;

  ProjectList({required this.success, required this.data});

  factory ProjectList.fromJson(Map<String, dynamic> json) => ProjectList(
    success: json["success"],
    data: List<ProjectListModel>.from(
      json["data"].map((x) => ProjectListModel.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class ProjectListModel {
  final String? id;
  final String? uid;
  final String? userId;
  final String? businessId;
  final String? templateId;
  final String? parentProjectId;
  final String? sizeId;
  final String? name;
  final String? content;
  final String? thumbnailS3Key;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectListModel({
    required this.id,
    required this.uid,
    required this.userId,
    required this.businessId,
    required this.templateId,
    required this.parentProjectId,
    required this.sizeId,
    required this.name,
    required this.content,
    required this.thumbnailS3Key,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectListModel.fromJson(Map<String, dynamic> json) =>
      ProjectListModel(
        id: json["id"]?.toString(),
        uid: json["uid"]?.toString(),
        userId: json["user_id"]?.toString(),
        businessId: json["business_id"]?.toString(),
        templateId: json["template_id"]?.toString(),
        parentProjectId: json["parent_project_id"]?.toString(),
        sizeId: json["size_id"]?.toString(),
        name: json["name"]?.toString(),
        content: json["content"]?.toString(),
        thumbnailS3Key: json["thumbnail_s3_key"]?.toString(),
        status: json["status"]?.toString(),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "user_id": userId,
    "business_id": businessId,
    "template_id": templateId,
    "parent_project_id": parentProjectId,
    "size_id": sizeId,
    "name": name,
    "content": content,
    "thumbnail_s3_key": thumbnailS3Key,
    "status": status,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
