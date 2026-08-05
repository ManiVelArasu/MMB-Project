import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../network/provider/feedback_provider.dart';

class EmojiRating extends StatelessWidget {
  const EmojiRating({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FeedbackProvider>(context);

    final List<String> emojis = [
      "😡",
      "🙁",
      "😐",
      "😊",
      "🤩",
    ];


    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        emojis.length,
            (index) {
          final bool isSelected =
              provider.selectedEmoji == index;

          return GestureDetector(
            onTap: () {
              provider.selectEmoji(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFEAEA)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE53935)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  emojis[index],
                  style: const TextStyle(
                    fontSize: 32,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}