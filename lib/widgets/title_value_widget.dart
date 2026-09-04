import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:provider/provider.dart';

import '../network/provider/custom_theme_provider.dart';
import '../utils/height_measure.dart';

class TitleValueWidget extends StatelessWidget {
  final String title;
  final String subTitle;
  final Color? titleColor;    // 👈 Optional Title Color
  final Color? subTitleColor; // 👈 Optional Subtitle Color

  const TitleValueWidget({
    super.key,
    required this.title,
    required this.subTitle,
    this.titleColor,
    this.subTitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final customColor = context.watch<CustomThemeProvider>().colors;
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.headlineLarge!.copyWith(
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            color: titleColor ?? customColor.blackColor,
          ),
        ),
        height12,

        // Subtitle
        Text(
          subTitle,
          style: theme.titleMedium!.copyWith(
            color: subTitleColor ?? customColor.textColor,
          ),
        ),
        height12,
      ],
    );
  }
}
