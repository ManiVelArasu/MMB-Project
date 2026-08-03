import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:project_mmb/component/custom_widget.dart';
import 'package:project_mmb/network/provider/business_provider.dart';
import 'package:project_mmb/network/provider/custom_theme_provider.dart';
import 'package:project_mmb/ui/industry/choose_image_sheet.dart';
import 'package:project_mmb/utils/height_measure.dart';
import 'package:project_mmb/widgets/button_widget.dart';
import 'package:project_mmb/widgets/title_value_widget.dart';
import 'package:provider/provider.dart';

class BusinessDetailsScreen extends StatelessWidget {
  const BusinessDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customColor = context.watch<CustomThemeProvider>().colors;
    final theme = Theme.of(context).textTheme;
    final businessProvider = context
        .watch<BusinessProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
                      const TitleValueWidget(
                        title: "Business Details",
                        subTitle:
                            "Please provide your business details to help us personalize your experience.",
                      ),

                      businessProvider.selectedImage == null &&
                              businessProvider.originalImage == null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => uploadImageSheet(
                                        context,
                                        businessProvider,
                                      ),
                                      child: Container(
                                        height: 120.h,
                                        width: 120.w,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          color: customColor.redColor.withAlpha(
                                            25,
                                          ),
                                          border: Border.all(
                                            color:
                                                businessProvider.imageError !=
                                                    null
                                                ? Colors.red
                                                : customColor.redColor,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              "assets/icons/upload_logo_ic.svg",
                                            ),
                                            height8,
                                            AppText(
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
                                      child: AppText(
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
                                      padding: const EdgeInsets.all(16),
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
                                        children: [
                                          SvgPicture.asset(
                                            "assets/icons/create_logo_ic.svg",
                                          ),
                                          height8,
                                          AppText(
                                            "Create logo",
                                            style: theme.bodyMedium!.copyWith(
                                              color: customColor.blackColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (businessProvider.imageError != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 6.h,
                                      left: 4.w,
                                    ),
                                    child: AppText(
                                      businessProvider.imageError!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12.sp,
                                      ),
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
                                          businessProvider.isImageSelected ==
                                              false
                                          ? customColor.redColor
                                          : customColor.greyColor.withAlpha(50),
                                      width: 2.w,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Builder(
                                      builder: (context) {
                                        final imageFile =
                                            businessProvider.selectedImage ??
                                            businessProvider.originalImage;
                                        if (imageFile != null) {
                                          return Image.file(
                                            imageFile,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          );
                                        } else {
                                          return const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: InkWell(
                                    onTap: () => businessProvider.clearImage(),
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

                      // 1. BUSINESS NAME FIELD
                      _buildCustomInputField(
                        title: "Business Name",
                        hintText: "Enter business name",
                        customColor: customColor,
                        theme: theme,
                        onChanged: businessProvider.setBusinessName,
                        errorMessage: businessProvider.nameError,
                      ),

                      height12,

                      // 2. EMAIL ID FIELD
                      _buildCustomInputField(
                        title: "Email Id",
                        hintText: "Enter email id",
                        keyboardType: TextInputType.emailAddress,
                        customColor: customColor,
                        theme: theme,
                        onChanged: businessProvider.setEmail,
                        errorMessage: businessProvider.emailError,
                      ),

                      height12,

                      // 3. CONTACT NUMBER FIELD
                      _buildCustomInputField(
                        title: "Contact Number",
                        hintText: "Enter contact number",
                        keyboardType: TextInputType.phone,
                        customColor: customColor,
                        theme: theme,
                        onChanged: businessProvider.setMobileNumber,
                        errorMessage: businessProvider.mobileError,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              // CONTINUE BUTTON
              ButtonWidget(
                buttonPress: () {
                  // FORM VALIDATION CHECK
                  if (businessProvider.validateForm()) {
                    // 🚀 Since BusinessProvider is global, the saved image, name, email & mobile
                    // can now be accessed in any other screen (like /BusinessFrameScreen) using context.watch<BusinessProvider>()
                    Navigator.pushNamed(context, "/CustomBottomNavScreen");
                  }
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
  }

  Widget _buildCustomInputField({
    required String title,
    required String hintText,
    required dynamic customColor,
    required TextTheme theme,
    required Function(String) onChanged,
    required String? errorMessage,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorMessage != null
                  ? Colors.red
                  : customColor.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                style: theme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: customColor.baseColor,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                keyboardType: keyboardType,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: theme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    color: customColor.greyColor.withAlpha(50),
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
            ],
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: AppText(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }
}

void uploadImageSheet(BuildContext context, BusinessProvider businessProvider) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return ChangeNotifierProvider.value(
        value: businessProvider,
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: const ChooseImageSheet(),
        ),
      );
    },
  );
}
