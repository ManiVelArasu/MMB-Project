import 'package:flutter/material.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:provider/provider.dart';

class TitleValueWidget extends StatelessWidget {
  final String title;
  final String subTitle;
  const TitleValueWidget({super.key, required this.title, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    final customColor = context.watch<CustomThemeProvider>().colors;
    final theme = Theme.of(context).textTheme;
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: theme.headlineLarge!.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: customColor.blackColor,
          ),
        ),
        height12,

        // Subtitle
        Text(
          subTitle,
          style: theme.titleMedium!.copyWith(color: customColor.textColor),
        ),
        height12,

      ],
    );
  }
}
