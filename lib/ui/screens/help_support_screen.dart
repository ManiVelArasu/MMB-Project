import 'package:flutter/material.dart';
import 'package:project_mmb/widgets/support_ticket_card.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_widget.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/support_provider.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupportProvider(),
      child: Consumer<SupportProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.white,

            appBar: const CustomAppBar(
              title: "Help & Support",
              showRightIcon: false,
            ),

            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  /// Support Text
                  const Center(
                    child: AppText(
                      "Our support team is available Monday to Saturday,\n10 AM – 7 PM to assist you with any queries.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),

                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Chat Support Card
                      Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Chat Support",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),

                                SizedBox(height: 6),
                                Text(
                                  "Get instant help through live chat. Our support team is ready to assist you with your queries.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),


                  const SizedBox(height: 24),

                  /// Email
                  const AppText(
                    "Write to us",
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),

                  const SizedBox(height: 4),

                  const AppText(
                    "support@makemybrand.com",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Heading
                  const AppText(
                    "Support Tickets",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Ticket List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = provider.tickets[index];

                      return SupportTicketCard(ticket: ticket,);

                    },

                 ),
                ],
              ),

          ),
          );
        },
      ),
    );
  }
}