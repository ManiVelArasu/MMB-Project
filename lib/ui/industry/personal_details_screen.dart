import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../network/provider/business_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../utils/height_measure.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/title_value_widget.dart';
import 'choose_image_sheet.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customColor = Provider.of<CustomThemeProvider>(context).colors;
    final theme = Theme.of(context).textTheme;
    return Consumer<BusinessProvider>(
      builder: (context, businessProvider, child) {
        if (businessProvider.nameController.text.isEmpty && businessProvider.businessName.isNotEmpty) {
          businessProvider.nameController.text = businessProvider.businessName;
        }
        if (businessProvider.emailController.text.isEmpty && businessProvider.email.isNotEmpty) {
          businessProvider.emailController.text = businessProvider.email;
        }
        if (businessProvider.mobileController.text.isEmpty && businessProvider.mobileNumber.isNotEmpty) {
          businessProvider.mobileController.text = businessProvider.mobileNumber;
        }

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
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: customColor.redColor.withAlpha(25),
                                    border: Border.all(
                                      color: customColor.redColor,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                  color: customColor.redColor.withAlpha(25),
                                  border: Border.all(
                                    color: customColor.redColor,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/create_logo_ic.svg",
                                    ),
                                    height8,
                                    Text(
                                      "Create logo", // "Upload logo" என்பதற்கு பதிலாக "Create logo" என மாற்றப்பட்டுள்ளது
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
                                  // ... existing decoration ...
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    businessProvider.isImageSelected == true
                                        ? businessProvider.originalImage!
                                        : businessProvider.selectedImage ?? businessProvider.originalImage!,
                                    // -----------------------------------
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    // Error handling for corrupted file
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(child: Icon(Icons.error));
                                    },
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

                          // 1. BUSINESS NAME FIELD
                          _buildInputField(
                            title: "Business Name",
                            hintText: "Enter business name",
                            controller: businessProvider.nameController,
                            onChanged: businessProvider.setBusinessName,
                            customColor: customColor,
                            theme: theme,
                          ),
                          height12,

                          // 2. EMAIL ID FIELD
                          _buildInputField(
                            title: "Email Id",
                            hintText: "Enter email id",
                            controller: businessProvider.emailController,
                            onChanged: businessProvider.setEmail,
                            keyboardType: TextInputType.emailAddress,
                            customColor: customColor,
                            theme: theme,
                          ),
                          height12,

                          // 3. CONTACT NUMBER FIELD
                          _buildInputField(
                            title: "Contact Number",
                            hintText: "Enter contact number",
                            controller: businessProvider.mobileController,
                            onChanged: businessProvider.setMobileNumber,
                            keyboardType: TextInputType.phone,
                            customColor: customColor,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ButtonWidget(
                    buttonPress: () {
                      // உங்கள் Continue பட்டன் லாஜிக் இங்கே
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

  // Helper widget to avoid code duplication for Input Fields
  Widget _buildInputField({
    required String title,
    required String hintText,
    required TextEditingController controller,
    required Function(String) onChanged,
    required dynamic customColor,
    required TextTheme theme,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: customColor.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: customColor.baseColor,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller, // கண்ட்ரோலர் இணைக்கப்பட்டுள்ளது
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
