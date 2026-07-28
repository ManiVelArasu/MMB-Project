import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart'; // Make sure ImagePicker is installed
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:provider/provider.dart';



class ChooseImageSheet extends StatelessWidget {
  const ChooseImageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                height8,
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
                    AppText(
                      "Upload Image",
                      style: theme.bodyLarge!.copyWith(
                        color: customColor.blackColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: SvgPicture.asset("assets/icons/close_ic.svg"),
                    ),
                  ],
                ),
                height12,

                // 1. UPLOAD FROM GALLERY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: InkWell(
                    onTap: () async {

                      await businessProvider.pickImage(
                        context,
                        source: ImageSource.gallery,
                      );
                    },
                    child: Container(
                      height: 110.h,
                      width: screenWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: customColor.redColor.withAlpha(25),
                        border: Border.all(color: customColor.redColor.withAlpha(80)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset("assets/icons/upload_logo_ic.svg"),
                          height8,
                          AppText(
                            "Upload from Gallery",
                            style: theme.bodyMedium!.copyWith(
                              color: customColor.blackColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0.h),
                  child: AppText(
                    "OR",
                    style: theme.bodyMedium!.copyWith(
                      color: customColor.blackColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {

                    await businessProvider.pickImage(
                      context,
                      source: ImageSource.camera,
                    );
                  },
                  child: Container(
                    width: screenWidth * 0.42,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: customColor.blackColor,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset("assets/icons/camera_ic.svg"),
                          width8,
                          AppText(
                            "Take a Photo",
                            style: theme.bodyMedium!.copyWith(
                              color: customColor.whiteColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                height12,
              ],
            ),
          ),
        );
      },
    );
  }
}