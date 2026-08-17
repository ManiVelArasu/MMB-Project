import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChangePlanScreen extends StatelessWidget {
  const ChangePlanScreen({super.key});

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
          "Change Plan",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("CURRENT PLAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Premium", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("All basic brand generation tools", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const Text("₹499/mo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text("UPGRADE TO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Elite", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text("₹999/mo", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text("• 3,000 AI Credits + Business Listing", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calculation info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Prorated difference", style: TextStyle(color: Colors.grey)),
                      Text("₹500", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Charged today", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("₹500", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Upgrade Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {Navigator.pushNamed(context, "/UsageScreen");},
                child: const Text("PAY DIFFERENCE & UPGRADE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                "Downgrades take effect from your next billing cycle instead of charging you today.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}