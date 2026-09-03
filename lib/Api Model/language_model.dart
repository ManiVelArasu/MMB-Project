class LanguageModel {
  final bool success;
  final List<LanguageItem> data;

  LanguageModel({
    required this.success,
    required this.data,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      success: json['success'] == true,
      data: (json['data'] as List? ?? [])
          .map(
            (e) => LanguageItem.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}

class LanguageItem {
  final int id;
  final String uid;
  final String code;
  final String name;
  final String nativeName;
  final int displayOrder;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;

  LanguageItem({
    required this.id,
    required this.uid,
    required this.code,
    required this.name,
    required this.nativeName,
    required this.displayOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory LanguageItem.fromJson(Map<String, dynamic> json) {
    return LanguageItem(
      id: json['id'] ?? 0,
      uid: json['uid'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nativeName: json['native_name'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}