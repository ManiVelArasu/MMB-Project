import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../network/provider/business_provider.dart';
import '../../../network/provider/custom_theme_provider.dart';
import '../../../utils/height_measure.dart';
import '../../../widgets/button_widget.dart';

class RemoveBackgroundQuestionSheet extends StatelessWidget {
  const RemoveBackgroundQuestionSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final customColor =
        Provider.of<CustomThemeProvider>(context).colors;

    final theme = Theme.of(context).textTheme;

    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: customColor.whiteColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    height: 4.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: customColor.greyColor.withAlpha(50),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Text(
                      "Upload Image",
                      style: theme.bodyLarge!.copyWith(
                        color: customColor.blackColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: SvgPicture.asset(
                        "assets/icons/close_ic.svg",
                      ),
                    ),
                  ],
                ),

                height12,

                if (businessProvider.selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      businessProvider.selectedImage!,
                      height: 100.h,
                      width: 100.w,
                      fit: BoxFit.cover,
                    ),
                  ),

                height12,

                Text(
                  "Remove Background?",
                  style: theme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: customColor.blackColor,
                  ),
                ),

                height12,

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ButtonWidget(
                      buttonPress: () {
                        // NO
                        Navigator.pop(context, false);
                      },
                      title: "NO",
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xffE0E0E0),
                      ),
                      height: 40.h,
                      width: 100.w,
                      textStyle: theme.bodyLarge!.copyWith(
                        color: customColor.blackColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    width12,

                    ButtonWidget(
                      buttonPress: () {
                        // YES
                        Navigator.pop(context, true);
                      },
                      title: "YES",
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: customColor.redColor,
                      ),
                      height: 40.h,
                      width: 100.w,
                      textStyle: theme.bodyLarge!.copyWith(
                        color: customColor.whiteColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}