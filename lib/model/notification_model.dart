class NotificationModel {
  final String title;
  final String description;
  final String category;
  final String? avatarUrl;
  final DateTime dateTime;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.description,
    required this.category,
    this.avatarUrl,
    required this.dateTime,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'avatarUrl': avatarUrl,
      'dateTime': dateTime.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      avatarUrl: map['avatarUrl'],
      dateTime: DateTime.parse(map['dateTime']),
      isRead: map['isRead'] ?? false,











      
    );
  }

  NotificationModel copyWith({
    String? title,
    String? description,
    String? category,
    String? avatarUrl,
    DateTime? dateTime,
    bool? isRead,
  }) {
    return NotificationModel(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateTime: dateTime ?? this.dateTime,
      isRead: isRead ?? this.isRead,
    );
  }
}
