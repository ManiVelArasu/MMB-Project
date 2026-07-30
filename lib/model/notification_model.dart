class NotificationModel {
  final String title;
  final String description;
  final DateTime dateTime;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.description,
    required this.dateTime,
    this.isRead = false,
  });

  // Convert object to Map (Useful for API/Database)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Convert Map to Object
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      isRead: map['isRead'] ?? false,
    );
  }

  // Copy object with updated values
  NotificationModel copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isRead,
  }) {
    return NotificationModel(
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isRead: isRead ?? this.isRead,
    );
  }
}