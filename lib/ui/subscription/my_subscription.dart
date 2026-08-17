import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MySubscriptionScreen extends StatelessWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Subscription",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Premium Active Card with Progress Circle/Indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFECEE), Color(0xFFF3E8FF)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text("Premium", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            SizedBox(width: 8),
                            ContainerChip(text: "ACTIVE", color: Colors.green),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text("Your plan will automatically renew next month.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  // Circular Day count representation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 65,
                        height: 65,
                        child: CircularProgressIndicator(value: 0.75, color: Colors.red, strokeWidth: 6),
                      ),
                      Column(
                        children: const [
                          Text("17", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Days", style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subscription Info Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Renews on", style: TextStyle(color: Colors.grey)),
                      Text("12 Sept 2026", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Auto Renewal", style: TextStyle(color: Colors.grey)),
                      Text("ON", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Payment Method", style: TextStyle(color: Colors.grey)),
                      Text("Razorpay • UPI", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Action Buttons
            _buildActionButton("MANAGE PLAN", Colors.red, Colors.white, () {Navigator.pushNamed(context, "/ChangePlanScreen");}),
            const SizedBox(height: 10),
            _buildActionButton("DOWNLOAD INVOICE", Colors.white, Colors.black12 ?? Colors.black87, () {}),
            const SizedBox(height: 10),
            _buildActionButton("BILLING HISTORY", Colors.white, Colors.black87, () {}),
            const SizedBox(height: 10),
            _buildActionButton("CANCEL RENEWAL", Colors.white, Colors.black87, () {}),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, Color bgColor, Color textColor, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: BorderSide(color: bgColor == Colors.white ? Colors.grey.shade300 : Colors.transparent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class ContainerChip extends StatelessWidget {
  final String text;
  final Color color;
  const ContainerChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}