import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:provider/provider.dart' show Provider, Consumer;

import '../../../network/provider/business_provider.dart';
import '../../../network/provider/custom_theme_provider.dart';
import '../../../utils/height_measure.dart';
import '../../../widgets/button_widget.dart';

class BgRemoveSheet extends StatelessWidget {
  final VoidCallback onSuccess;

  const BgRemoveSheet({super.key, required this.onSuccess});

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
                      // 1. Original Image Card
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: () {
                              businessProvider.setImageSelected(
                                true,
                              ); // Original image-ஐத் தேர்ந்தெடுக்கிறது
                            },
                            child: Container(
                              height: 100.h,
                              width: 100.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      businessProvider.isImageSelected == true
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
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  businessProvider
                                      .originalImage!, // இங்கு Original Image தான் இருக்க வேண்டும்
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
                      // 2. Background Removed Image Card
                      Stack(
                        fit: StackFit.passthrough,
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: () {
                              businessProvider.setImageSelected(
                                false,
                              ); // BG Removed image-ஐத் தேர்ந்தெடுக்கிறது
                            },
                            child: Container(
                              height: 100.h,
                              width: 100.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      businessProvider.isImageSelected == false
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
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  businessProvider
                                      .selectedImage!, // இங்கு BG Removed Image இருக்க வேண்டும்
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
                            fit:
                                BoxFit.cover, // cover clips better than contain
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
                            isLoading:
                                businessProvider.isProcessingBackground ||
                                businessProvider.isUploading,
                            buttonPress: () async {
                              print("asdsadsdd");
                              if (businessProvider.isProcessingBackground ||
                                  businessProvider.isUploading) {
                                return;
                              }

                              // STEP 1: Remove Background
                              final removed = await businessProvider
                                  .removeBackground();
                              if (!context.mounted) return; // மிக முக்கியம்

                              if (!removed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      businessProvider.errorMessage ??
                                          "Background removal failed",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // STEP 2: Upload Image
                              final uploaded = await businessProvider
                                  .uploadBgRemovedImage();
                              if (!context.mounted) return; // மிக முக்கியம்

                              if (!uploaded) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      businessProvider.errorMessage ??
                                          "Image upload failed",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // STEP 3: Success -> Close Bottom Sheet only once securely
                              debugPrint(
                                "✅ LOGO UPLOAD SUCCESS → CLOSING SHEET",
                              );

                              // onSuccess காலிபேக் இருந்தால் அதையும் இயக்கலாம்
                              onSuccess();

                              // ஷீட்டை மட்டும் க்ளோஸ் செய்ய (பின்னே செல்லாமல் இருக்க)
                              Navigator.of(context).pop();
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
                    :// 1-வது CONTINUE பட்டன் (originalImage == null இருக்கும் போது)
                ButtonWidget(
                  isLoading: businessProvider.isProcessingBackground || businessProvider.isUploading,
                  buttonPress: () async {
                    if (businessProvider.isProcessingBackground || businessProvider.isUploading) {
                      return;
                    }

                    final removed = await businessProvider.removeBackground();
                    if (!context.mounted) return;

                    if (!removed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(businessProvider.errorMessage ?? "Background removal failed"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final uploaded = await businessProvider.uploadBgRemovedImage();
                    if (!context.mounted) return;

                    if (!uploaded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(businessProvider.errorMessage ?? "Image upload failed"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    debugPrint("✅ LOGO UPLOAD SUCCESS → CLOSING SHEET ONLY");

                    if (!context.mounted) return;

                    // onSuccess-ஐயும் ஷீட் கன்டெக்ஸ்ட்டையும் சரியாக க்ளோஸ் செய்ய
                    Navigator.of(context).pop();
                    onSuccess();
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
