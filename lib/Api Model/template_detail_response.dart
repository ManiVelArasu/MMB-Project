class TemplateDetailResponse {
  final int? id;
  final String? uid;
  final int? categoryId;
  final int? languageId;
  final String? name;
  final String? thumbnailS3Key;
  final String? content;

  const TemplateDetailResponse({
    this.id,
    this.uid,
    this.categoryId,
    this.languageId,
    this.name,
    this.thumbnailS3Key,
    this.content,
  });

  factory TemplateDetailResponse.fromJson(dynamic json) {
    final root = json is Map<String, dynamic>
        ? json
        : Map<String, dynamic>.from(json as Map);
    final rawData = root['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : root;

    return TemplateDetailResponse(
      id: _toInt(data['id']),
      uid: data['uid']?.toString(),
      categoryId: _toInt(data['category_id']),
      languageId: _toInt(data['language_id']),
      name: data['name']?.toString(),
      thumbnailS3Key: data['thumbnail_s3_key']?.toString(),
      content: data['content']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
