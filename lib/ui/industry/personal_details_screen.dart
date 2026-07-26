import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';

import 'choose_image_sheet.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset("assets/icons/back_icon.svg"),
            ),
            backgroundColor: customColor.whiteColor,
            surfaceTintColor: customColor.whiteColor,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TitleValueWidget(
                            title: "Personal Details",
                            subTitle:
                            "Please provide your personal details to help us personalize your experience.",
                          ),

                          businessProvider.selectedImage == null &&
                              businessProvider.originalImage == null
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.start,

                            children: [
                              InkWell(
                                onTap: () {
                                  uploadImageSheet(context);
                                },
                                child: Container(
                                  height: 120.h,
                                  width: 120.w,
                                  // padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      16,
                                    ),
                                    color: customColor.redColor.withAlpha(
                                      25,
                                    ),
                                    border: Border.all(
                                      color: customColor.redColor,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/upload_logo_ic.svg",
                                      ),
                                      height8,
                                      Text(
                                        "Upload logo",
                                        style: theme.bodyMedium!.copyWith(
                                          color: customColor.blackColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.0.h,
                                ),
                                child: Text(
                                  "OR",
                                  style: theme.bodyMedium!.copyWith(
                                    color: customColor.blackColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                height: 120.h,
                                width: 120.w,

                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: customColor.redColor.withAlpha(
                                    25,
                                  ),
                                  border: Border.all(
                                    color: customColor.redColor,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/create_logo_ic.svg",
                                    ),
                                    height8,
                                    Text(
                                      "Upload logo",
                                      style: theme.bodyMedium!.copyWith(
                                        color: customColor.blackColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                              : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 100.h,
                                width: 100.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                    businessProvider
                                        .isImageSelected ==
                                        false
                                        ? customColor.redColor
                                        : customColor.greyColor.withAlpha(
                                      50,
                                    ),
                                    width: 2.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.1,
                                      ),
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
                                    businessProvider.isImageSelected ==
                                        true
                                        ? businessProvider.originalImage!
                                        : businessProvider.selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: InkWell(
                                  onTap: () {
                                    businessProvider.clearImage();
                                  },

                                  child: SvgPicture.asset(
                                    "assets/icons/remove_ic.svg",
                                    height: 30,
                                    width: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          height12,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: customColor.borderColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Business Name",
                                  style: theme.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: customColor.baseColor,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                TextFormField(
                                  keyboardType: TextInputType.text,
                                  onChanged: businessProvider.setBusinessName,
                                  decoration: InputDecoration(
                                    hintText: "Enter business name",
                                    hintStyle: theme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: customColor.greyColor.withAlpha(
                                        50,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: theme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: customColor.baseColor,
                                  ),
                                ),

                                // Validation error
                                // if (authProvider.mobileError != null)
                                //   Padding(
                                //     padding: const EdgeInsets.only(top: 4),
                                //     child: Text(
                                //       authProvider.mobileError!,
                                //       style: TextStyle(
                                //         color: Colors.red,
                                //         fontSize: 12.sp,
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                          ),
                          height12,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: customColor.borderColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email Id",
                                  style: theme.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: customColor.baseColor,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                TextFormField(
                                  keyboardType: TextInputType.text,
                                  onChanged: businessProvider.setEmail,
                                  decoration: InputDecoration(
                                    hintText: "Enter email id",
                                    hintStyle: theme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: customColor.greyColor.withAlpha(
                                        50,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: theme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: customColor.baseColor,
                                  ),
                                ),

                                // Validation error
                                // if (authProvider.mobileError != null)
                                //   Padding(
                                //     padding: const EdgeInsets.only(top: 4),
                                //     child: Text(
                                //       authProvider.mobileError!,
                                //       style: TextStyle(
                                //         color: Colors.red,
                                //         fontSize: 12.sp,
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                          ),
                          height12,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: customColor.borderColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Contact Number",
                                  style: theme.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: customColor.baseColor,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                TextFormField(
                                  keyboardType: TextInputType.text,
                                  onChanged: businessProvider.setMobileNumber,
                                  decoration: InputDecoration(
                                    hintText: "Enter contact number",
                                    hintStyle: theme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: customColor.greyColor.withAlpha(
                                        50,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: theme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: customColor.baseColor,
                                  ),
                                ),

                                // Validation error
                                // if (authProvider.mobileError != null)
                                //   Padding(
                                //     padding: const EdgeInsets.only(top: 4),
                                //     child: Text(
                                //       authProvider.mobileError!,
                                //       style: TextStyle(
                                //         color: Colors.red,
                                //         fontSize: 12.sp,
                                //       ),
                                //     ),
                                //   ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ButtonWidget(
                    buttonPress: () {

                    },
                    title: "CONTINUE",
                    textStyle: theme.titleLarge!.copyWith(
                      color: customColor.whiteColor,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: customColor.redColor,
                    ),
                    height: 54.h,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void uploadImageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: ChooseImageSheet(),
      );
    },
  );
}
