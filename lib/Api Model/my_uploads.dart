class MyUploads {
  final bool? success;
  final List<MyUploadData> data;
  final Meta? meta;

  MyUploads({required this.success, required this.data, required this.meta});

  factory MyUploads.fromJson(Map<String, dynamic> json) => MyUploads(
    success: json["success"] ?? false,
    data: json["data"] == null
        ? []
        : List<MyUploadData>.from(
            json["data"].map((x) => MyUploadData.fromJson(x)),
          ),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta?.toJson(),
  };
}

class MyUploadData {
  final String? uid;
  final String? s3Key;
  final String? slot;
  final String? bytes;
  final String? contentType;
  final String? width;
  final String? height;
  final String? originalFilename;
  final DateTime? createdAt;

  MyUploadData({
    required this.uid,
    required this.s3Key,
    required this.slot,
    required this.bytes,
    required this.contentType,
    required this.width,
    required this.height,
    required this.originalFilename,
    required this.createdAt,
  });

  factory MyUploadData.fromJson(Map<String, dynamic> json) => MyUploadData(
    uid: json["uid"]?.toString(),
    s3Key: json["s3_key"]?.toString(),
    slot: json["slot"]?.toString(),
    bytes: json["bytes"]?.toString(),
    contentType: json["content_type"]?.toString(),
    width: json["width"]?.toString(),
    height: json["height"]?.toString(),
    originalFilename: json["original_filename"]?.toString(),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "s3_key": s3Key,
    "slot": slot,
    "bytes": bytes,
    "content_type": contentType,
    "width": width,
    "height": height,
    "original_filename": originalFilename,
    "created_at": createdAt?.toIso8601String(),
  };
}

class Meta {
  final String? total;

  Meta({required this.total});

  factory Meta.fromJson(Map<String, dynamic> json) =>
      Meta(total: json["total"]?.toString());

  Map<String, dynamic> toJson() => {"total": total};
}
