import 'dart:convert';

UnReadCount unReadCountFromJson(String str) =>
    UnReadCount.fromJson(json.decode(str));

String unReadCountToJson(UnReadCount data) => json.encode(data.toJson());

class UnReadCount {
  final bool? success;
  final unRead? data;

  UnReadCount({required this.success, required this.data});

  factory UnReadCount.fromJson(Map<String, dynamic> json) => UnReadCount(
    success: json["success"] ?? false,
    data: json["data"] == null ? null : unRead.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {"success": success, "data": data?.toJson()};
}

class unRead {
  final String? unreadCount;
  final List<ByCategory> byCategory;

  unRead({required this.unreadCount, required this.byCategory});

  factory unRead.fromJson(Map<String, dynamic> json) => unRead(
    unreadCount: json["unread_count"]?.toString(),
    byCategory: json["by_category"] == null
        ? []
        : List<ByCategory>.from(
            json["by_category"].map((x) => ByCategory.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "unread_count": unreadCount,
    "by_category": List<dynamic>.from(byCategory.map((x) => x.toJson())),
  };
}

class ByCategory {
  final String? uid;
  final String? name;
  final String? slug;
  final String? count;

  ByCategory({
    required this.uid,
    required this.name,
    required this.slug,
    required this.count,
  });

  factory ByCategory.fromJson(Map<String, dynamic> json) => ByCategory(
    uid: json["uid"]?.toString(),
    name: json["name"]?.toString(),
    slug: json["slug"]?.toString(),
    count: json["count"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "name": name,
    "slug": slug,
    "count": count,
  };
}
