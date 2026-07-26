import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:provider/provider.dart' show Provider, Consumer;

class BgRemoveSheet extends StatelessWidget {
  const BgRemoveSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              color: customColor.whiteColor,
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
                      onPressed: () => Navigator.pop(context),
                      icon: SvgPicture.asset("assets/icons/close_ic.svg"),
                    ),
                  ],
                ),
          
                height12,
                if (businessProvider.originalImage != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
          
                        children: [
                          InkWell(
                            onTap: () {
                              businessProvider.setImageSelected(true);
                            },
                            child: Container(
                              height: 100.h,
                              width: 100.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: businessProvider.isImageSelected == true
                                      ? customColor.redColor
                                      : customColor.greyColor.withAlpha(50),
                                  width: 2.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                // Clip image to container border
                                borderRadius: BorderRadius.circular(10),
                                // Slightly smaller than container
                                child: Image.file(
                                  businessProvider.originalImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ),
                          businessProvider.isImageSelected == true
                              ? Positioned(
                                  top: -8,
                                  left: -8,
                                  child: SvgPicture.asset(
                                    "assets/icons/check_ic.svg",
                                    height: 30,
                                    width: 30,
                                  ),
                                )
                              : SizedBox.shrink(),
                        ],
                      ),
                      width12,
                      Stack(
                        fit: StackFit.passthrough,
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: () {
                              businessProvider.setImageSelected(false);
                            },
                            child: Container(
                              height: 100.h,
                              width: 100.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: businessProvider.isImageSelected == false
                                      ? customColor.redColor
                                      : customColor.greyColor.withAlpha(50),
                                  width: 2.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                // Clip image to container border
                                borderRadius: BorderRadius.circular(10),
                                // Slightly smaller than container
                                child: Image.file(
                                  businessProvider.selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ),
          
                          businessProvider.isImageSelected == false
                              ? Positioned(
                                  top: -8,
                                  left: -8,
                                  child: SvgPicture.asset(
                                    "assets/icons/check_ic.svg",
                                    height: 30,
                                    width: 30,
                                  ),
                                )
                              : SizedBox.shrink(),
                        ],
                      ),
                    ],
                  )
                else
                  businessProvider.isProcessingBackground
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: customColor.baseColor,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.hardEdge,
                          child: Image.file(
                            businessProvider.selectedImage!,
                            fit: BoxFit.cover, // cover clips better than contain
                            height: 100.h,
                            width: 100.w,
                          ),
                        ),
                height12,
                Text(
                  businessProvider.originalImage == null
                      ? "Remove Background?"
                      : "Select Logo",
                  style: theme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: customColor.blackColor,
                  ),
                ),
                height12,
                businessProvider.originalImage == null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ButtonWidget(
                            buttonPress: () {},
                            title: "NO",
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Color(0xffE0E0E0),
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
                              businessProvider.removeBackground();
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
                      )
                    : ButtonWidget(
                        buttonPress: () {
                          if (businessProvider.originalImage == null) {
                            businessProvider.removeBackground();
                          } else {
                            Navigator.pushNamed(
                              context,
                              "/BusinessDetailsScreen",
                            );
                          }
                        },
                        title: "CONTINUE",
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: customColor.redColor,
                        ),
                        height: 40.h,
                        width: 150.w,
          
                        textStyle: theme.bodyLarge!.copyWith(
                          color: customColor.whiteColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
