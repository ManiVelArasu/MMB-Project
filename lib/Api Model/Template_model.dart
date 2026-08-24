class TemplatesResponseModel {
  final bool success;
  final List<TemplateModel> data;

  TemplatesResponseModel({
    required this.success,
    required this.data,
  });

  factory TemplatesResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return TemplatesResponseModel(
      success: json['success'] == true,
      data: (json['data'] as List? ?? [])
          .map(
            (e) => TemplateModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}

class TemplateModel {
  final String? id;
  final String? uid;
  final String? categoryId;
  final String? languageId;
  final String? name;
  final String? thumbnailS3Key;
  final String? templateType;
  final String? isPremium;
  final bool? isLocked;

  TemplateModel({
    this.id,
    this.uid,
    this.categoryId,
    this.languageId,
    this.name,
    this.thumbnailS3Key,
    this.templateType,
    this.isPremium,
    this.isLocked,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id']?.toString(),
      uid: json['uid']?.toString(),
      categoryId: json['category_id']?.toString(),
      languageId: json['language_id']?.toString(),
      name: json['name']?.toString(),
      thumbnailS3Key: json['thumbnail_s3_key']?.toString(),
      templateType: json['template_type']?.toString(),
      isPremium: json['is_premium']?.toString(),
      isLocked: json['is_locked'] ?? false,
    );
  }
}