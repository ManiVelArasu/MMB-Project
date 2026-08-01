import 'package:flutter/material.dart';
import '../../model/support_ticket_model.dart';

class SupportProvider extends ChangeNotifier {
  final List<SupportTicketModel> _tickets = [
    SupportTicketModel(
      ticketId: "#23564",
      status: "Open",
      title: "Your custom post ticket",
      description:
      "Your issue has been resolved. Let us know if you need any further assistance.",
      dateTime: DateTime(2025, 9, 14, 15, 10),
    ),
    SupportTicketModel(
      ticketId: "#23564",
      status: "Closed",
      title: "Your custom post ticket",
      description:
      "Your issue has been resolved. Let us know if you need any further assistance.",
      dateTime: DateTime(2025, 9, 12, 6, 13),
    ),
  ];

  /// Get all tickets
  List<SupportTicketModel> get tickets => _tickets;

  /// Add Ticket
  void addTicket(SupportTicketModel ticket) {
    _tickets.add(ticket);
    notifyListeners();
  }

  /// Delete Ticket
  void deleteTicket(int index) {
    _tickets.removeAt(index);
    notifyListeners();
  }

  /// Open Ticket
  void openTicket(int index) {
    _tickets[index] = _tickets[index].copyWith(status: "Open");
    notifyListeners();
  }

  /// Close Ticket
  void closeTicket(int index) {
    _tickets[index] = _tickets[index].copyWith(status: "Closed");
    notifyListeners();
  }

  /// Open Tickets
  List<SupportTicketModel> get openTickets =>
      _tickets.where((ticket) => ticket.status == "Open").toList();

  /// Closed Tickets
  List<SupportTicketModel> get closedTickets =>
      _tickets.where((ticket) => ticket.status == "Closed").toList();
}