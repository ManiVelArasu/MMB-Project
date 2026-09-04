import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../component/appbar_widget.dart';
import '../../component/custom_searchbar.dart';
import '../../component/custom_widget.dart';
import '../../network/provider/edit_photo_provider.dart';
import '../../utils/theme/app.colors.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditPhotoProvider(),
      child: Consumer<EditPhotoProvider>(
        builder: (context, provider, child) {
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
                      suffixAsset: "assets/images/search.png",
                      borderColor: AppColors.searchBorderColor,
                      onChanged: (query) {},
                    ),

                    SizedBox(height: 24.h),

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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 85.h,
                          width: 85.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: const Color(0xFFFFECEE),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              size: 40.sp,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6.h,
                          right: -6.w,
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
                      ],
                    ),

                    SizedBox(height: 20.h),

                    _buildCustomInputField(
                      label: "Business Name",
                      controller: provider.businessNameController,
                    ),
                    _buildCustomInputField(
                      label: "Email ID",
                      controller: provider.emailController,
                    ),
                    _buildCustomInputField(
                      label: "Contact Number",
                      controller: provider.contactController,
                    ),

                    SizedBox(height: 16.h),

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

                    if (provider.isMoreInfoExpanded) ...[
                      SizedBox(height: 12.h),
                      _buildCustomInputField(
                        label: "Contact Number",
                        controller: provider.altContactController,
                      ),
                      _buildCustomInputField(
                        label: "Website",
                        controller: provider.websiteController,
                      ),
                    ],

                    SizedBox(height: 16.h),
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

                    if (provider.isSocialExpanded) ...[
                      SizedBox(height: 12.h),
                      _buildCustomInputField(
                        label: "Facebook",
                        controller: provider.facebookController,
                      ),
                      _buildCustomInputField(
                        label: "Instagram",
                        controller: provider.instagramController,
                      ),
                      _buildCustomInputField(
                        label: "x (Twitter)",
                        controller: provider.twitterController,
                      ),
                      _buildCustomInputField(
                        label: "YouTube",
                        controller: provider.youtubeController,
                      ),
                      _buildCustomInputField(
                        label: "LinkedIn",
                        controller: provider.linkedinController,
                      ),
                    ],

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomInputField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
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
