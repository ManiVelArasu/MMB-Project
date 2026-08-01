class SupportTicketModel {
  final String ticketId;
  final String status;
  final String title;
  final String description;
  final DateTime dateTime;

  SupportTicketModel({
    required this.ticketId,
    required this.status,
    required this.title,
    required this.description,
    required this.dateTime,
  });

  SupportTicketModel copyWith({
    String? ticketId,
    String? status,
    String? title,
    String? description,
    DateTime? dateTime,
  }) {
    return SupportTicketModel(
      ticketId: ticketId ?? this.ticketId,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}