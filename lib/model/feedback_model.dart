class FeedbackModel {
  final int rating;
  final String feedback;

  FeedbackModel({
    required this.rating,
    required this.feedback,
  });

  /// Convert object to Map
  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'feedback': feedback,
    };
  }

  /// Convert Map to Object
  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      rating: map['rating'] ?? 0,
      feedback: map['feedback'] ?? '',
    );
  }

  /// Copy Object
  FeedbackModel copyWith({
    int? rating,
    String? feedback,
  }) {
    return FeedbackModel(
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
    );
  }
}