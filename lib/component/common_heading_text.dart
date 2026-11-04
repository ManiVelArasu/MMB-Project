import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/theme/app.fonts.dart';
import 'custom_widget.dart';

class CommonHeadingText extends StatelessWidget {
  final String title;

  const CommonHeadingText(
      this.title, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return AppText(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: AppFontSize.fontSize18,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}