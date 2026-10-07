import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:provider/provider.dart' show Provider, Consumer, ReadContext;

import '../../../network/provider/business_provider.dart';
import '../../../network/provider/custom_theme_provider.dart';
import '../../../utils/height_measure.dart';
import '../../../widgets/button_widget.dart';

class BgRemoveSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const BgRemoveSheet({super.key, required this.onSuccess});

  @override
  State<BgRemoveSheet> createState() => _BgRemoveSheetState();
}

class _BgRemoveSheetState extends State<BgRemoveSheet> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBackgroundRemoval();
    });
  }

  Future<void> _startBackgroundRemoval() async {
    if (_started || !mounted) return;
    _started = true;

    final provider = context.read<BusinessProvider>();

    if (provider.originalImage == null ||
        provider.bgRemovedImage != null ||
        provider.isProcessingBackground) {
      return;
    }

    await provider.removeBackground();
  }

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
                    children: [
                      Expanded(
                        child: _buildImageCard(
                          context: context,
                          image: businessProvider.originalImage,
                          title: "Normal",
                          selected: businessProvider.isImageSelected,
                          enabled: businessProvider.originalImage != null,
                          onTap: () {
                            businessProvider.setImageSelected(true);
                          },
                          customColor: customColor,
                          theme: theme,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildImageCard(
                          context: context,
                          image: businessProvider.bgRemovedImage,
                          title: "BG Removed",
                          selected: !businessProvider.isImageSelected &&
                              businessProvider.bgRemovedImage != null,
                          enabled: businessProvider.bgRemovedImage != null,
                          isProcessing:
                          businessProvider.isProcessingBackground,
                          onTap: businessProvider.bgRemovedImage == null
                              ? null
                              : () {
                            businessProvider.setImageSelected(false);
                          },
                          customColor: customColor,
                          theme: theme,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
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
                ButtonWidget(
                  isLoading: businessProvider.isUploading,
                  buttonPress: () async {
                    if (businessProvider.isUploading) {
                      return;
                    }

                    // IMPORTANT: Upload exactly the image selected by the user.
                    // Do NOT call removeBackground() here.
                    final uploaded =
                    await businessProvider.uploadCurrentImage();

                    if (!context.mounted) return;

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

                    debugPrint(
                      "✅ SELECTED IMAGE UPLOAD SUCCESS: "
                          "${businessProvider.selectedImage?.path}",
                    );

                    widget.onSuccess();
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard({
    required BuildContext context,
    required File? image,
    required String title,
    required bool selected,
    required bool enabled,
    required VoidCallback? onTap,
    required dynamic customColor,
    required TextTheme theme,
    bool isProcessing = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 110.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? customColor.redColor
                        : customColor.greyColor.withAlpha(80),
                    width: selected ? 2.5.w : 1.5.w,
                  ),
                  color: customColor.whiteColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: isProcessing
                      ? Center(
                    child: SizedBox(
                      height: 28.h,
                      width: 28.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: customColor.redColor,
                      ),
                    ),
                  )
                      : image != null
                      ? Image.file(
                    image,
                    fit: title == "BG Removed"
                        ? BoxFit.contain
                        : BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                      : Center(
                    child: Text(
                      "Processing...",
                      style: theme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: -8,
                left: -8,
                child: SvgPicture.asset(
                  "assets/icons/check_ic.svg",
                  height: 30,
                  width: 30,
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          title,
          style: theme.bodySmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: customColor.blackColor,
          ),
        ),
      ],
    );
  }

}

