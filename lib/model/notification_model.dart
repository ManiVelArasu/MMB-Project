class NotificationModels {
  final String? uid;
  final String title;
  final String description;
  final String category;
  final String? avatarUrl;
  final DateTime dateTime;
  final bool isRead;

  const NotificationModels({
    this.uid,
    required this.title,
    required this.description,
    required this.category,
    this.avatarUrl,
    required this.dateTime,
    required this.isRead,
  });

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'category': category,
      'avatarUrl': avatarUrl,
      'dateTime': dateTime.toIso8601String(),
      'isRead': isRead,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory NotificationModels.fromMap(
      Map<String, dynamic> map,
      ) {
    return NotificationModels(
      uid: map['uid']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString(),

      dateTime: map['dateTime'] != null
          ? DateTime.parse(
        map['dateTime'].toString(),
      )
          : DateTime.now(),

      isRead: map['isRead'] ?? false,
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  NotificationModels copyWith({
    String? uid,
    String? title,
    String? description,
    String? category,
    String? avatarUrl,
    DateTime? dateTime,
    bool? isRead,
  }) {
    return NotificationModels(
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description:
      description ?? this.description,
      category: category ?? this.category,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateTime: dateTime ?? this.dateTime,
      isRead: isRead ?? this.isRead,
    );
  }
}