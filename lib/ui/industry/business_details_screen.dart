import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../component/custom_widget.dart';
import '../../network/provider/business_provider.dart';
import '../../network/provider/custom_theme_provider.dart';
import '../../network/provider/common_provider.dart';
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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMeAndSavedData();
    });
  }

  // ============================================================
  // LOAD ME API
  // ============================================================

  Future<void> _loadMeAndSavedData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingMe = true;
        });
      }

      // --------------------------------------------------------
      // GET ME API
      // --------------------------------------------------------

      final bool meSuccess =
      await CommonProvider.instance.loadMe(
        forceRefresh: true,
      );

      if (!mounted) return;

      if (!meSuccess) {
        debugPrint(
          "❌ ME API failed: "
              "${CommonProvider.instance.meError}",
        );

        setState(() {
          _isLoadingMe = false;
        });

        return;
      }

      // --------------------------------------------------------
      // ACCOUNT TYPE
      // --------------------------------------------------------

      final String? accountType =
      CommonProvider.instance.accountType
          ?.trim()
          .toLowerCase();

      debugPrint("======================================");
      debugPrint("✅ ME API SUCCESS");
      debugPrint("ACCOUNT TYPE = $accountType");
      debugPrint(
        "IS PERSONAL = ${accountType == 'personal'}",
      );
      debugPrint(
        "IS BUSINESS = ${accountType == 'business'}",
      );
      debugPrint("======================================");

      // --------------------------------------------------------
      // LOAD SAVED BUSINESS DATA
      // --------------------------------------------------------

      await context
          .read<BusinessProvider>()
          .loadSavedData();

      if (!mounted) return;

      setState(() {
        _isLoadingMe = false;
      });
    } catch (e, stackTrace) {
      debugPrint("❌ Load ME error: $e");
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoadingMe = false;
      });
    }
  }

  // ============================================================
  // CONTINUE
  // ============================================================

  Future<void> _onContinue({
    required BusinessProvider businessProvider,
    required bool isPersonal,
    required bool isBusiness,
  }) async {
    if (businessProvider.isUploading) {
      return;
    }

    // ==========================================================
    // INVALID ACCOUNT TYPE
    // ==========================================================

    if (!isPersonal && !isBusiness) {
      debugPrint(
        "❌ Invalid account type: "
            "${CommonProvider.instance.accountType}",
      );

      return;
    }

    try {
      // ========================================================
      // PERSONAL
      // ========================================================

      if (isPersonal) {
        debugPrint("======================================");
        debugPrint("🚀 UPDATE PERSONAL DETAILS");
        debugPrint("======================================");

        final bool success =
        await businessProvider.updatePersonalDetails(
          context,
        );

        if (!success) {
          debugPrint(
            "❌ Personal details update failed",
          );

          return;
        }

        debugPrint(
          "✅ Personal details updated successfully",
        );
      }

      // ========================================================
      // BUSINESS
      // ========================================================

      if (isBusiness) {
        debugPrint("======================================");
        debugPrint("🚀 UPDATE BUSINESS DETAILS");
        debugPrint("Business UID: ${widget.businessUid}");
        debugPrint("======================================");

        final bool success =
        await businessProvider.updateBusinessDetails(
          context,
          widget.businessUid,
        );

        if (!success) {
          debugPrint(
            "❌ Business details update failed",
          );

          return;
        }

        debugPrint(
          "✅ Business details updated successfully",
        );
      }

      // ========================================================
      // SAVE CONTINUE
      // ONLY AFTER API SUCCESS
      // ========================================================

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setBool(
        'continue',
        true,
      );

      debugPrint(
        "✅ continue = ${prefs.getBool('continue')}",
      );

      // ========================================================
      // NAVIGATION
      // ========================================================

      if (!context.mounted) return;

      Navigator.pushReplacementNamed(
        context,
        "/CustomBottomNavScreen",
      );
    } catch (e, stackTrace) {
      debugPrint(
        "❌ Continue error: $e",
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final customColor =
        context.watch<CustomThemeProvider>().colors;

    final theme =
        Theme.of(context).textTheme;

    final businessProvider =
    context.watch<BusinessProvider>();

    final commonProvider =
    context.watch<CommonProvider>();

    // ==========================================================
    // ACCOUNT TYPE FROM ME API
    // ==========================================================

    final String? accountType =
    commonProvider.me?.data.accountType
        ?.trim()
        .toLowerCase();

    final bool isPersonal =
        accountType == 'personal';

    final bool isBusiness =
        accountType == 'business';

    debugPrint("======================================");
    debugPrint("ACCOUNT TYPE = $accountType");
    debugPrint(
      "IS PERSONAL = $isPersonal",
    );
    debugPrint(
      "IS BUSINESS = $isBusiness",
    );
    debugPrint("======================================");

    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoadingMe ||
        commonProvider.isMeLoading) {
      return Scaffold(
        backgroundColor:
        customColor.whiteColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      customColor.whiteColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              Navigator.pop(context),
          icon: SvgPicture.asset(
            "assets/icons/back_icon.svg",
          ),
        ),
        backgroundColor:
        customColor.whiteColor,
        surfaceTintColor:
        customColor.whiteColor,
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child:
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // TITLE
                      // ==================================================

                      const TitleValueWidget(
                        title:
                        "Business Details",
                        subTitle:
                        "Add your business details to personalize your templates, branding, and AI recommendations.",
                      ),

                      // ==================================================
                      // LOGO TITLE
                      // ==================================================

                      AppText(
                        "Business Logo (Optional)",
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==================================================
                      // IMAGE SECTION
                      // ==================================================

                      businessProvider
                          .selectedImage ==
                          null &&
                          businessProvider
                              .originalImage ==
                              null
                          ? Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .start,
                            children: [
                              // ======================================
                              // UPLOAD LOGO
                              // ======================================

                              InkWell(
                                onTap: () =>
                                    uploadImageSheet(
                                      context,
                                      businessProvider,
                                    ),
                                child:
                                Container(
                                  height:
                                  120.h,
                                  width:
                                  120.w,
                                  decoration:
                                  BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(
                                      16,
                                    ),
                                    color: customColor
                                        .redColor
                                        .withAlpha(
                                      25,
                                    ),
                                    border:
                                    Border.all(
                                      color: businessProvider
                                          .imageError !=
                                          null
                                          ? Colors
                                          .red
                                          : customColor
                                          .redColor,
                                    ),
                                  ),
                                  child:
                                  Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                    children: [
                                      SvgPicture
                                          .asset(
                                        "assets/icons/upload_logo_ic.svg",
                                      ),

                                      height8,

                                      AppText(
                                        "Upload logo",
                                        style: theme
                                            .bodyMedium!
                                            .copyWith(
                                          color:
                                          customColor.blackColor,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ======================================
                              // OR
                              // ======================================

                              Padding(
                                padding:
                                EdgeInsets.symmetric(
                                  horizontal:
                                  12.0.h,
                                ),
                                child:
                                AppText(
                                  "OR",
                                  style: theme
                                      .bodyMedium!
                                      .copyWith(
                                    color:
                                    customColor.blackColor,
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),
                              ),

                              // ======================================
                              // PERSONAL
                              // FROM LIBRARY
                              // ======================================

                              if (isPersonal)
                                InkWell(
                                  onTap: () {
                                    debugPrint(
                                      "📚 From Library clicked",
                                    );

                                    // உங்கள் existing
                                    // From Library action
                                    // இங்கே வைக்கலாம்.
                                  },
                                  child:
                                  Container(
                                    height:
                                    120.h,
                                    width:
                                    130.w,
                                    padding:
                                    const EdgeInsets
                                        .all(
                                      16,
                                    ),
                                    decoration:
                                    BoxDecoration(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        16,
                                      ),
                                      color: customColor
                                          .redColor
                                          .withAlpha(
                                        25,
                                      ),
                                      border:
                                      Border.all(
                                        color:
                                        customColor.redColor,
                                      ),
                                    ),
                                    child:
                                    Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        SvgPicture
                                            .asset(
                                          "assets/icons/create_logo_ic.svg",
                                        ),

                                        height8,

                                        AppText(
                                          "From Library",
                                          style: theme
                                              .bodyMedium!
                                              .copyWith(
                                            color:
                                            customColor.blackColor,
                                            fontWeight:
                                            FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // ======================================
                              // BUSINESS
                              // CREATE WITH AI
                              // ======================================

                              if (isBusiness)
                                InkWell(
                                  onTap: () {
                                    debugPrint(
                                      "🤖 Create with AI clicked",
                                    );
                                  },
                                  child:
                                  Container(
                                    height:
                                    120.h,
                                    width:
                                    130.w,
                                    padding:
                                    const EdgeInsets
                                        .all(
                                      16,
                                    ),
                                    decoration:
                                    BoxDecoration(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        16,
                                      ),
                                      color: customColor
                                          .redColor
                                          .withAlpha(
                                        25,
                                      ),
                                      border:
                                      Border.all(
                                        color:
                                        customColor.redColor,
                                      ),
                                    ),
                                    child:
                                    Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        SvgPicture
                                            .asset(
                                          "assets/icons/create_logo_ic.svg",
                                        ),

                                        height8,

                                        AppText(
                                          "Create with AI",
                                          style: theme
                                              .bodyMedium!
                                              .copyWith(
                                            color:
                                            customColor.blackColor,
                                            fontWeight:
                                            FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // ==========================================
                          // IMAGE ERROR
                          // ==========================================

                          if (businessProvider
                              .imageError !=
                              null)
                            Padding(
                              padding:
                              EdgeInsets.only(
                                top: 6.h,
                                left: 4.w,
                              ),
                              child:
                              AppText(
                                businessProvider
                                    .imageError!,
                                style:
                                TextStyle(
                                  color:
                                  Colors.red,
                                  fontSize:
                                  12.sp,
                                ),
                              ),
                            ),
                        ],
                      )
                          : Stack(
                        clipBehavior:
                        Clip.none,
                        children: [
                          // ==========================================
                          // SELECTED IMAGE
                          // ==========================================

                          Container(
                            height:
                            100.h,
                            width:
                            100.w,
                            decoration:
                            BoxDecoration(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                              border:
                              Border.all(
                                color: businessProvider
                                    .isImageSelected ==
                                    false
                                    ? customColor
                                    .redColor
                                    : customColor
                                    .greyColor
                                    .withAlpha(
                                  50,
                                ),
                                width:
                                2.w,
                              ),
                            ),
                            child:
                            ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                              child:
                              Builder(
                                builder:
                                    (context) {
                                  final imageFile =
                                  businessProvider
                                      .isImageSelected ==
                                      true
                                      ? businessProvider
                                      .originalImage
                                      : (businessProvider
                                      .selectedImage ??
                                      businessProvider
                                          .originalImage);

                                  if (imageFile !=
                                      null) {
                                    return Image
                                        .file(
                                      imageFile,
                                      fit: BoxFit
                                          .cover,
                                      width: double
                                          .infinity,
                                      height: double
                                          .infinity,
                                    );
                                  }

                                  return const Center(
                                    child:
                                    Icon(
                                      Icons
                                          .image_not_supported,
                                      color: Colors
                                          .grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // ==========================================
                          // REMOVE
                          // ==========================================

                          Positioned(
                            top: -8,
                            right: -8,
                            child:
                            InkWell(
                              onTap: () =>
                                  businessProvider
                                      .clearImage(),
                              child:
                              SvgPicture
                                  .asset(
                                "assets/icons/remove_ic.svg",
                                height:
                                30,
                                width:
                                30,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ====================================================
                      // BUSINESS NAME
                      // ====================================================

                      height12,

                      _buildCustomInputField(
                        title:
                        "Business Name",
                        hintText:
                        "Enter business name",
                        controller:
                        businessProvider
                            .nameController,
                        customColor:
                        customColor,
                        theme: theme,
                        onChanged:
                        businessProvider
                            .setBusinessName,
                        errorMessage:
                        businessProvider
                            .nameError,
                      ),

                      // ====================================================
                      // EMAIL
                      // ====================================================

                      height12,

                      _buildCustomInputField(
                        title:
                        "Email Id",
                        hintText:
                        "Enter email id",
                        controller:
                        businessProvider
                            .emailController,
                        keyboardType:
                        TextInputType
                            .emailAddress,
                        customColor:
                        customColor,
                        theme: theme,
                        onChanged:
                        businessProvider
                            .setEmail,
                        errorMessage:
                        businessProvider
                            .emailError,
                      ),

                      // ====================================================
                      // PHONE
                      // ====================================================

                      height12,

                      _buildCustomInputField(
                        title:
                        "Contact Number",
                        hintText:
                        "Enter contact number",
                        controller:
                        businessProvider
                            .mobileController,
                        keyboardType:
                        TextInputType.phone,
                        customColor:
                        customColor,
                        theme: theme,
                        onChanged:
                        businessProvider
                            .setMobileNumber,
                        errorMessage:
                        businessProvider
                            .mobileError,
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================================
              // CONTINUE BUTTON
              // ==========================================================

              const SizedBox(
                height: 15,
              ),

              ButtonWidget(
                isLoading:
                businessProvider.isUploading,

                buttonPress: () async {
                  await _onContinue(
                    businessProvider:
                    businessProvider,
                    isPersonal:
                    isPersonal,
                    isBusiness:
                    isBusiness,
                  );
                },

                title: "CONTINUE",

                textStyle:
                theme.titleLarge!
                    .copyWith(
                  color:
                  customColor.whiteColor,
                  fontWeight:
                  FontWeight.w700,
                ),

                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  color:
                  customColor.redColor,
                ),

                height: 54.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOM INPUT
  // ============================================================

  Widget _buildCustomInputField({
    required String title,
    required String hintText,
    required dynamic customColor,
    required TextTheme theme,
    required Function(String) onChanged,
    required String? errorMessage,
    required TextEditingController controller,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: errorMessage != null
                  ? Colors.red
                  : customColor
                  .borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                style: theme
                    .bodySmall!
                    .copyWith(
                  fontWeight:
                  FontWeight.w600,
                  color: customColor
                      .baseColor,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              TextFormField(
                controller:
                controller,
                keyboardType:
                keyboardType,
                onChanged:
                onChanged,
                decoration:
                InputDecoration(
                  hintText:
                  hintText,
                  hintStyle: theme
                      .bodyMedium!
                      .copyWith(
                    fontWeight:
                    FontWeight.w400,
                    color: customColor
                        .greyColor
                        .withAlpha(
                      50,
                    ),
                  ),
                  border:
                  InputBorder.none,
                  isDense: true,
                  contentPadding:
                  EdgeInsets.zero,
                ),
                style: theme
                    .bodyMedium!
                    .copyWith(
                  fontWeight:
                  FontWeight.w400,
                  color: customColor
                      .baseColor,
                ),
              ),
            ],
          ),
        ),

        if (errorMessage != null)
          Padding(
            padding:
            EdgeInsets.only(
              top: 4.h,
              left: 4.w,
            ),
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

// ================================================================
// UPLOAD IMAGE SHEET
// ================================================================

void uploadImageSheet(
    BuildContext context,
    BusinessProvider businessProvider,
    ) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return ChangeNotifierProvider
          .value(
        value: businessProvider,
        child: Container(
          decoration:
          const BoxDecoration(
            borderRadius:
            BorderRadius.only(
              topRight:
              Radius.circular(30),
              bottomRight:
              Radius.circular(30),
            ),
          ),
          child:
          const ChooseImageSheet(),
        ),
      );
    },
  );
}