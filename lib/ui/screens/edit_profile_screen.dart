import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_widget.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';

import '../../network/provider/edit_photo_provider.dart';
import '../../network/provider/common_provider.dart';
import '../../utils/theme/app.colors.dart';
import '../../core/api/api_endpoints.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditPhotoProvider(),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  bool _getMeInitialized = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CommonProvider.instance.loadBusiness(
        forceRefresh: true,
      );
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final commonProvider = context.watch<CommonProvider>();
    final me = commonProvider.me;
    final business = commonProvider.business;

    if (!_getMeInitialized && (me != null || business != null)) {
      _getMeInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final provider = context.read<EditPhotoProvider>();

        if (business != null) {
          await provider.setBusinessApiData(business);
        } else if (me != null) {
          provider.setGetMeData(me);
        }
      });
    }
  }

  Future<void> _saveBusiness() async {
    final provider = context.read<EditPhotoProvider>();

    final success = await provider.saveBusinessDetails();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Business details updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.saveError ?? "Failed to update business details",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditPhotoProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: CustomAppBar(title: "Edit Photo", showRightIcon: false),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              AppText(
                "Find business category that matches your Products/Services",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 10.h),

              CustomSearchBar(
                hintText: "Find your Industry",

                prefixAsset: "assets/images/search.png",

                suffixAsset: "assets/images/mic.png",

                borderColor: AppColors.searchBorderColor,

                onChanged: (query) {
                  provider.industryController.text = query;
                },
              ),

              SizedBox(height: 24.h),

              // =================================================
              // BUSINESS DETAILS
              // =================================================
              AppText(
                "Business Details",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 4.h),

              AppText(
                "Please provide your business details to help us personalize your experience.",
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 16.h),

              // =================================================
              // LOGO
              // =================================================
              _buildLogoSection(provider),

              SizedBox(height: 20.h),

              // =================================================
              // BASIC FIELDS
              // =================================================
              _buildCustomInputField(
                label: "Business Name",
                controller: provider.businessNameController,
              ),

              _buildCustomInputField(
                label: "Industry",
                controller: provider.industryController,
                edit: false

              ),

              _buildCustomInputField(
                label: "Description",
                controller: provider.descriptionController,
                maxLines: 3,
              ),

              _buildCustomInputField(
                label: "Email ID",
                controller: provider.emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              _buildCustomInputField(
                label: "Contact Number",
                controller: provider.contactController,
                keyboardType: TextInputType.phone,
              ),

              _buildCustomInputField(
                label: "WhatsApp",
                controller: provider.whatsappController,
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: 8.h),

              // =================================================
              // MORE BUSINESS INFO
              // =================================================
              GestureDetector(
                onTap: provider.toggleMoreInfo,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    AppText(
                      "More Business Info",
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    Icon(
                      provider.isMoreInfoExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,

                      color: Colors.black87,

                      size: 24.sp,
                    ),
                  ],
                ),
              ),

              // =================================================
              // MORE INFO FIELDS
              // =================================================
              if (provider.isMoreInfoExpanded) ...[
                SizedBox(height: 12.h),

                _buildCustomInputField(
                  label: "Alternate Contact Number",
                  controller: provider.altContactController,
                  keyboardType: TextInputType.phone,
                ),

                _buildCustomInputField(
                  label: "Website",
                  controller: provider.websiteController,
                  keyboardType: TextInputType.url,
                ),

                _buildCustomInputField(
                  label: "City",
                  controller: provider.cityController,
                ),

                _buildCustomInputField(
                  label: "State",
                  controller: provider.stateController,
                ),

                _buildCustomInputField(
                  label: "Address",
                  controller: provider.addressController,
                  maxLines: 3,
                ),

                _buildCustomInputField(
                  label: "Latitude",
                  controller: provider.latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),

                _buildCustomInputField(
                  label: "Longitude",
                  controller: provider.longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ],

              SizedBox(height: 16.h),

              // =================================================
              // SOCIAL
              // =================================================
              GestureDetector(
                onTap: provider.toggleSocial,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    AppText(
                      "Social",
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    Icon(
                      provider.isSocialExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,

                      color: Colors.black87,

                      size: 24.sp,
                    ),
                  ],
                ),
              ),

              // =================================================
              // SOCIAL FIELDS
              // =================================================
              if (provider.isSocialExpanded) ...[
                SizedBox(height: 12.h),

                _buildCustomInputField(
                  label: "Facebook",
                  controller: provider.facebookController,
                  keyboardType: TextInputType.url,
                ),

                _buildCustomInputField(
                  label: "Instagram",
                  controller: provider.instagramController,
                  keyboardType: TextInputType.url,
                ),

                _buildCustomInputField(
                  label: "X (Twitter)",
                  controller: provider.twitterController,
                  keyboardType: TextInputType.url,
                ),

                _buildCustomInputField(
                  label: "YouTube",
                  controller: provider.youtubeController,
                  keyboardType: TextInputType.url,
                ),

                _buildCustomInputField(
                  label: "LinkedIn",
                  controller: provider.linkedinController,
                  keyboardType: TextInputType.url,
                ),
              ],

              SizedBox(height: 20.h),

              // =================================================
              // SAVE BUTTON
              // =================================================
              SizedBox(
                width: double.infinity,

                height: 52.h,

                child: ElevatedButton(
                  onPressed: provider.isSaving || provider.isUploadingImage
                      ? null
                      : _saveBusiness,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),

                    foregroundColor: Colors.white,

                    disabledBackgroundColor: Colors.grey.shade400,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),

                  child:
                      // =================================================
                      // SAVING
                      // =================================================
                      provider.isSaving
                      ? SizedBox(
                          height: 22.h,
                          width: 22.w,

                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,

                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      // =================================================
                      // IMAGE UPLOADING
                      // =================================================
                      : provider.isUploadingImage
                      ? Text(
                          "Uploading Logo...",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      // =================================================
                      // NORMAL
                      // =================================================
                      : Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(EditPhotoProvider provider) {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        GestureDetector(
          onTap: provider.isUploadingImage ? null : provider.pickAndUploadImage,

          child: Container(
            height: 85.h,
            width: 85.w,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFFFECEE), width: 1.5),
            ),

            child: Center(
              child: provider.isUploadingImage
                  ? SizedBox(
                      height: 24.h,
                      width: 24.w,
                      child: const CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : provider.selectedImage != null &&
                        provider.selectedImage!.existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: Image.file(
                        provider.selectedImage!,
                        width: 50.w,
                        height: 50.w,
                        fit: BoxFit.cover,
                      ),
                    )
                  : provider.logoS3Key.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: Image.network(
                        getS3ImageUrl(provider.logoS3Key),
                        width: 50.w,
                        height: 50.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Image.asset(
                            "assets/images/BName.png",
                            width: 50.w,
                            height: 50.w,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    )
                  : Image.asset(
                      "assets/images/BName.png",
                      width: 50.w,
                      height: 50.w,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),

        // =====================================================
        // CLOSE ICON
        // =====================================================
        Positioned(
          top: -6.h,
          right: -6.w,

          child: GestureDetector(
            onTap: provider.isUploadingImage
                ? null
                : provider.removeSelectedImage,

            child: Container(
              height: 22.h,
              width: 22.w,

              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.close_rounded,

                color: Colors.white,

                size: 14.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CUSTOM INPUT
  // =========================================================

  Widget _buildCustomInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool edit = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: edit ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: edit
              ? Colors.grey.shade200
              : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 2.h),

          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: !edit,
            enabled: edit,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: edit
                  ? Colors.black87
                  : Colors.grey.shade600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

String getS3ImageUrl(String key) {
  return "${ApiEndpoints.cdnImageUrl}/$key";
}
