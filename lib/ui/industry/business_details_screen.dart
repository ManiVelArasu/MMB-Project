import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../component/custom_widget.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/common_provider.dart';
import '../../network/provider/plan_provider.dart';
import '../../utils/height_measure.dart';
import '../../widgets/button_widget.dart';
import '../../widgets/title_value_widget.dart';
import 'choose_image_sheet.dart';


class BusinessDetailsScreen extends StatefulWidget {
  final String businessUid;

  const BusinessDetailsScreen({
    super.key,
    required this.businessUid,
  });

  @override
  State<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState
    extends State<BusinessDetailsScreen> {
  bool _isLoadingMe = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMeAndSavedData();
    });
  }

  Future<void> _loadMeAndSavedData() async {
    try {
      if (mounted) {
        setState(() => _isLoadingMe = true);
      }

      final bool meSuccess =
      await CommonProvider.instance.loadMe(
        forceRefresh: true,
      );

      if (!mounted) return;

      if (!meSuccess) {
        debugPrint(
          "ME API failed: ${CommonProvider.instance.meError}",
        );

        setState(() => _isLoadingMe = false);
        return;
      }

      final String? accountType =
      CommonProvider.instance.accountType
          ?.trim()
          .toLowerCase();

      debugPrint("ACCOUNT TYPE = $accountType");

      await context.read<BusinessProvider>().loadSavedData();

      if (!mounted) return;

      // Check stale image after saved data loading.
      final provider = context.read<BusinessProvider>();
      _validateSavedImage(provider);

      setState(() => _isLoadingMe = false);
    } catch (e, stackTrace) {
      debugPrint("Load ME error: $e");
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _isLoadingMe = false);
    }
  }

  bool _isValidImage(File? file) {
    if (file == null) return false;

    try {
      return file.existsSync();
    } catch (e) {
      debugPrint("Image validation error: $e");
      return false;
    }
  }

  void _validateSavedImage(BusinessProvider provider) {
    final selected = provider.selectedImage;
    final original = provider.originalImage;

    final selectedValid = _isValidImage(selected);
    final originalValid = _isValidImage(original);

    if (!selectedValid && !originalValid) {
      provider.clearImage();
    }
  }

  File? _getValidImage(BusinessProvider provider) {
    final File? imageFile =
    provider.isImageSelected == true
        ? provider.originalImage
        : (provider.selectedImage ??
        provider.originalImage);

    if (_isValidImage(imageFile)) {
      return imageFile;
    }

    return null;
  }

  Future<void> _onContinue({
    required BusinessProvider businessProvider,
    required bool isPersonal,
    required bool isBusiness,
  }) async {
    if (businessProvider.isUploading) return;

    if (businessProvider.nameController.text.trim().isEmpty) {
      businessProvider.setBusinessName("");
    }

    if (!businessProvider.validateForm()) {
      setState(() {});
      debugPrint("Form validation failed");
      return;
    }

    if (!isPersonal && !isBusiness) {
      debugPrint(
        "Invalid account type: "
            "${CommonProvider.instance.accountType}",
      );
      return;
    }

    try {
      if (isPersonal) {
        final bool success =
        await businessProvider.updatePersonalDetails(
          context,
        );

        if (!success) return;
      }

      if (isBusiness) {
        String businessUid = widget.businessUid.trim();

        if (businessUid.isEmpty) {
          final prefs =
          await SharedPreferences.getInstance();

          businessUid =
              prefs.getString('business_uid')?.trim() ?? '';
        }

        final bool success =
        await businessProvider.updateBusinessDetails(
          context,
          businessUid,
        );

        if (!success) {
          debugPrint(
            "Business update failed: "
                "${businessProvider.errorMessage}",
          );
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('continue', true);

      final bool showSkip =
          prefs.getBool('showSkip') ?? false;

      if (!context.mounted) return;

      final planProvider = context.read<PlanProvider>();

      await planProvider.fetchMySubscription();

      if (!context.mounted) return;

      final bool hasActivePlan =
          planProvider.activePlanUid != null &&
              planProvider.activePlanUid!.isNotEmpty;

      if (hasActivePlan || showSkip) {
        Navigator.pushReplacementNamed(
          context,
          "/CustomBottomNavScreen",
        );
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        "/PlansAndPricingScreen",
        arguments: {"showSkip": true},
      );
    } catch (e, stackTrace) {
      debugPrint("Continue error: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColor =
        context.watch<CustomThemeProvider>().colors;

    final theme = Theme.of(context).textTheme;

    final businessProvider =
    context.watch<BusinessProvider>();

    final commonProvider =
    context.watch<CommonProvider>();

    final String? accountType =
    commonProvider.me?.data.accountType
        ?.trim()
        .toLowerCase();

    final bool isPersonal = accountType == 'personal';
    final bool isBusiness = accountType == 'business';

    if (_isLoadingMe || commonProvider.isMeLoading) {
      return Scaffold(
        backgroundColor: customColor.whiteColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Important: Always validate the actual file before Image.file.
    final File? validImage =
    _getValidImage(businessProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: customColor.whiteColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          if (isPersonal)
                            TitleValueWidget(
                              title: "Personal Details",
                              subTitle:
                              "Please provide the details to help us personalize your experience.",
                            ),

                          if (isBusiness)
                            TitleValueWidget(
                              title: "Business Details",
                              subTitle:
                              "Add your business details to discover relevant templates and personalized AI recommendations.",
                            ),

                          const SizedBox(height: 10),

                          // =====================================
                          // IMAGE SECTION
                          // =====================================

                          if (validImage == null)
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        uploadImageSheet(
                                          context,
                                          businessProvider,
                                        );
                                      },
                                      child: Container(
                                        height: 120.h,
                                        width: 120.w,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(16),
                                          color: customColor.redColor
                                              .withAlpha(25),
                                          border: Border.all(
                                            color: businessProvider
                                                .imageError !=
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
                                              style: theme.bodyMedium!
                                                  .copyWith(
                                                color: customColor.blackColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding:
                                      EdgeInsets.symmetric(
                                        horizontal: 12.0.h,
                                      ),
                                      child: AppText(
                                        "OR",
                                        style: theme.bodyMedium!
                                            .copyWith(
                                          color: customColor.blackColor,
                                          fontSize:
                                          AppFontSize.fontSize13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    if (isPersonal)
                                      InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            "/ProfilePictureScreen",
                                          );
                                        },
                                        child: Container(
                                          height: 120.h,
                                          width: 120.w,
                                          padding:
                                          const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(16),
                                            color: customColor.redColor
                                                .withAlpha(25),
                                            border: Border.all(
                                              color:
                                              customColor.redColor,
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
                                                "From Library",
                                                style: theme.bodyMedium!
                                                    .copyWith(
                                                  color: customColor
                                                      .blackColor,
                                                  fontSize: AppFontSize
                                                      .fontSize13,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    if (isBusiness)
                                      InkWell(
                                        onTap: () {
                                          debugPrint(
                                            "Create with AI clicked",
                                          );
                                        },
                                        child: Container(
                                          height: 120.h,
                                          width: 120.w,
                                          padding:
                                          const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(16),
                                            color: customColor.redColor
                                                .withAlpha(25),
                                            border: Border.all(
                                              color:
                                              customColor.redColor,
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
                                                "Create with AI",
                                                style: TextStyle(
                                                  color: customColor
                                                      .blackColor,
                                                  fontSize: AppFontSize
                                                      .fontSize13,
                                                  fontWeight:
                                                  FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
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
                          else
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 100.h,
                                  width: 100.w,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    border: Border.all(
                                      color: businessProvider
                                          .isImageSelected ==
                                          false
                                          ? customColor.redColor
                                          : customColor.greyColor
                                          .withAlpha(50),
                                      width: 2.w,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    child: Image.file(
                                      validImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        debugPrint(
                                          "Image render error: $error",
                                        );

                                        return const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        );
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

                          // =====================================
                          // BUSINESS NAME
                          // =====================================

                          height12,

                          if (isBusiness)
                            _buildCustomInputField(
                              title: "Business Name",
                              hintText: "Enter business name",
                              controller:
                              businessProvider.nameController,
                              customColor: customColor,
                              theme: theme,
                              onChanged:
                              businessProvider.setBusinessName,
                              errorMessage:
                              businessProvider.nameError,
                            ),

                          if (isPersonal)
                            _buildCustomInputField(
                              title: "Name",
                              hintText: "Enter Your name",
                              controller:
                              businessProvider.nameController,
                              customColor: customColor,
                              theme: theme,
                              onChanged:
                              businessProvider.setBusinessName,
                              errorMessage:
                              businessProvider.nameError,
                            ),

                          // =====================================
                          // EMAIL
                          // =====================================

                          height12,

                          _buildCustomInputField(
                            title: "Email Id",
                            hintText: "Enter email id",
                            controller:
                            businessProvider.emailController,
                            keyboardType:
                            TextInputType.emailAddress,
                            customColor: customColor,
                            theme: theme,
                            onChanged: businessProvider.setEmail,
                            errorMessage:
                            businessProvider.emailError,
                          ),

                          // =====================================
                          // PHONE
                          // =====================================

                          height12,

                          _buildCustomInputField(
                            title: "Contact Number",
                            hintText: "Enter contact number",
                            controller:
                            businessProvider.mobileController,
                            keyboardType: TextInputType.phone,
                            customColor: customColor,
                            theme: theme,
                            editable: false,
                            onChanged:
                            businessProvider.setMobileNumber,
                            errorMessage:
                            businessProvider.mobileError,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                ButtonWidget(
                  isLoading: businessProvider.isUploading,
                  buttonPress: () async {
                    await _onContinue(
                      businessProvider: businessProvider,
                      isPersonal: isPersonal,
                      isBusiness: isBusiness,
                    );
                  },
                  title: "CONTINUE",
                  textStyle: TextStyle(
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
      ),
    );
  }

  // =====================================
  // CUSTOM INPUT
  // =====================================

  Widget _buildCustomInputField({
    required String title,
    required String hintText,
    required dynamic customColor,
    required TextTheme theme,
    required Function(String) onChanged,
    required String? errorMessage,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool editable = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: editable
                ? Colors.transparent
                : Colors.grey.shade100,
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
                  fontWeight: FontWeight.w500,
                  fontSize: AppFontSize.fontSize13,
                  color: customColor.baseColor,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                onChanged: editable ? onChanged : null,
                readOnly: !editable,
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
                  color: editable
                      ? customColor.baseColor
                      : Colors.grey.shade600,
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
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================
// UPLOAD IMAGE SHEET
// =============================================

void uploadImageSheet(
    BuildContext context,
    BusinessProvider businessProvider,
    ) {
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

