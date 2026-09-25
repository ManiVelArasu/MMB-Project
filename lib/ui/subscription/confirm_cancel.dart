import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmCancellationScreen extends StatelessWidget {
  const ConfirmCancellationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 15,
              color: Colors.red,
            ),
          ),
        ),
        title: const Text(
          "Confirm Cancellation",
          style: TextStyle(
            color: Color(0xFF171A2B),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 8),

            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 38,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Sure you want to cancel?",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Your Premium access continues until 12 Sept 2026.\n"
                  "After that, your plan won't renew and you'll move\n"
                  "to the Free plan.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "💡 Cost was the reason? Switching to Basic keeps\n"
                    "templates & AI tools from just ₹199/mo — no need to\n"
                    "lose everything.",
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "YOU'LL LOSE ACCESS TO",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "❌  1000 Templates & 1000 AI Credits",
                    style: TextStyle(fontSize: 10),
                  ),

                  SizedBox(height: 7),

                  Text(
                    "❌  Watermark-free, HD downloads",
                    style: TextStyle(fontSize: 10),
                  ),

                  SizedBox(height: 7),

                  Text(
                    "❌  5 Brand Series access",
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "KEEP MY PLAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () {
                  // Cancel renewal API here
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "CONFIRM CANCELLATION",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}