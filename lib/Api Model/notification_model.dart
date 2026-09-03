// To parse this JSON data, do
//
//     final notification = notificationFromJson(jsonString);

import 'dart:convert';

NotificationModel notificationFromJson(String str) =>
    NotificationModel.fromJson(json.decode(str));

String notificationToJson(NotificationModel data) => json.encode(data.toJson());

class NotificationModel {
  final bool success;
  final List<NotificationList> data;
  final Meta? meta;

  NotificationModel({required this.success, required this.data, required this.meta});

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    success: json["success"],
    data: json["data"] == null
        ? []
        : List<NotificationList>.from(
            json["data"].map((x) => NotificationList.fromJson(x)),
          ),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta?.toJson(),
  };
}

class NotificationList {
  final String? uid;
  final String? title;
  final String? body;
  final String? ctaLabel;
  final String? ctaAction;
  final String? ctaParams;
  final String? imageS3Key;
  final String? priority;
  final bool? isDismissible;
  final bool? isRead;
  final String? readAt;
  final DateTime? createdAt;
  final Category? category;

  NotificationList({
    required this.uid,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaAction,
    required this.ctaParams,
    required this.imageS3Key,
    required this.priority,
    required this.isDismissible,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
    required this.category,
  });

  factory NotificationList.fromJson(Map<String, dynamic> json) =>
      NotificationList(
        uid: json["uid"]?.toString(),
        title: json["title"]?.toString(),
        body: json["body"]?.toString(),
        ctaLabel: json["cta_label"]?.toString(),
        ctaAction: json["cta_action"]?.toString(),
        ctaParams: json["cta_params"]?.toString(),
        imageS3Key: json["image_s3_key"]?.toString(),
        priority: json["priority"]?.toString(),
        isDismissible: json["is_dismissible"] ?? false,
        isRead: json["is_read"] ?? false,
        readAt: json["read_at"]?.toString(),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        category: json["category"] == null
            ? null
            : Category.fromJson(json["category"]),
      );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "title": title,
    "body": body,
    "cta_label": ctaLabel,
    "cta_action": ctaAction,
    "cta_params": ctaParams,
    "image_s3_key": imageS3Key,
    "priority": priority,
    "is_dismissible": isDismissible,
    "is_read": isRead,
    "read_at": readAt,
    "created_at": createdAt?.toIso8601String(),
    "category": category?.toJson(),
  };
}

class Category {
  final String? uid;
  final String? name;
  final String? slug;

  Category({required this.uid, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    slug: json["slug"]?.toString(),
  );

  Map<String, dynamic> toJson() => {"uid": uid, "name": name, "slug": slug};
}

class Meta {
  final String? total;

  Meta({required this.total});

  factory Meta.fromJson(Map<String, dynamic> json) =>
      Meta(total: json["total"]?.toString());

  Map<String, dynamic> toJson() => {"total": total};
}
