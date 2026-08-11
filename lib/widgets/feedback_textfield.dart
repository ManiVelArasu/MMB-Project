import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../network/provider/feedback_provider.dart';

class FeedbackTextField extends StatelessWidget {
  const FeedbackTextField({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FeedbackProvider>(context);

    return TextField(
      controller: provider.feedbackController,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: "Your thoughts",
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
      ),
    );
  }
}
