import 'package:flutter/material.dart';
import '../component/status_widget.dart';
import '../model/support_ticket_model.dart';
import '../utils/theme/app.colors.dart';

class SupportTicketCard extends StatelessWidget {
  final SupportTicketModel ticket;

  const SupportTicketCard({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Ticket ID, Status and Date
          Row(
            children: [
              Text(
                ticket.ticketId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(width: 8),

              StatusWidget(
                status:ticket.status,
                backgroundColor:ticket.status=="Open"? Color(0xFF1F2937):AppColors.lightGreen,
                textStyle:  TextStyle(
                  color: ticket.status=="Open"? AppColors.appRed:AppColors.lightRed,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                "${ticket.dateTime.day}/${ticket.dateTime.month}/${ticket.dateTime.year}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// Ticket Title
          Text(
            ticket.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          /// Description
          Text(
            ticket.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}