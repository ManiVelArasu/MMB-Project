
import 'dart:convert';

KeyWordsModel keyWordsModelFromJson(String str) => KeyWordsModel.fromJson(json.decode(str));

String keyWordsModelToJson(KeyWordsModel data) => json.encode(data.toJson());

class KeyWordsModel {
  final bool success;
  final List<KeyWordsData> data;

  KeyWordsModel({
    required this.success,
    required this.data,
  });

  factory KeyWordsModel.fromJson(Map<String, dynamic> json) => KeyWordsModel(
    success: json["success"],
    data: List<KeyWordsData>.from(json["data"].map((x) => KeyWordsData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class KeyWordsData {
  final String? id;
  final String? name;
  final String? slug;
  final DateTime? createdAt;

  KeyWordsData({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
  });

  factory KeyWordsData.fromJson(Map<String, dynamic> json) => KeyWordsData(
    id: json["id"]?.toString(),
    name: json["name"]?.toString(),
    slug: json["slug"]?.toString(),
    createdAt:json["created_at"]==null?null: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "slug": slug,
    "created_at": createdAt?.toIso8601String(),
  };
}

