import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';

import 'brand_form.dart';
import 'frame_helpers.dart';

/// "Update Business Info" bottom sheet: logo / name / mobile / email /
/// website. Every change calls [onChanged] (the screen's setState), so the
/// frame preview behind the sheet updates while typing.
Future<void> showBrandEditSheet(
  BuildContext context, {
  required BrandForm form,
  required Widget Function() logoPreview,
  required Future<void> Function() onPickLogo,
  required Future<bool> Function() onSave,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (_) => _BrandEditSheet(
      form: form,
      logoPreview: logoPreview,
      onPickLogo: onPickLogo,
      onSave: onSave,
      onChanged: onChanged,
    ),
  );
}

class _BrandEditSheet extends StatefulWidget {
  const _BrandEditSheet({
    required this.form,
    required this.logoPreview,
    required this.onPickLogo,
    required this.onSave,
    required this.onChanged,
  });

  final BrandForm form;
  final Widget Function() logoPreview;
  final Future<void> Function() onPickLogo;
  final Future<bool> Function() onSave;
  final VoidCallback onChanged;

  @override
  State<_BrandEditSheet> createState() => _BrandEditSheetState();
}

class _BrandEditSheetState extends State<_BrandEditSheet> {
  BrandForm get _form => widget.form;

  Future<void> _pickLogo() async {
    await widget.onPickLogo();
    if (mounted) setState(() {}); // refresh the logo preview in the sheet
  }

  Future<void> _save() async {
    final ok = await widget.onSave();
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandle(),
                SizedBox(height: 12.h),
                _buildHeader(),
                SizedBox(height: 16.h),
                _buildLogoRow(),
                SizedBox(height: 14.h),
                _buildField(
                  label: 'Business Name',
                  controller: _form.name,
                  onEdited: () => _form.nameTouched = true,
                ),
                _buildField(
                  label: 'Mobile Number',
                  controller: _form.phone,
                  keyboardType: TextInputType.phone,
                  onEdited: () => _form.phoneTouched = true,
                ),
                _buildField(
                  label: 'Email',
                  controller: _form.email,
                  keyboardType: TextInputType.emailAddress,
                  onEdited: () => _form.emailTouched = true,
                ),
                _buildField(
                  label: 'Website',
                  controller: _form.website,
                  keyboardType: TextInputType.url,
                  onEdited: () => _form.websiteTouched = true,
                  isLast: true,
                ),
                SizedBox(height: 16.h),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        height: 5.h,
        width: 80.w,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AppText(
          'Update Business Info',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(4.r),
            decoration: const BoxDecoration(
              color: kBrandRedTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, color: kBrandRed, size: 18.sp),
          ),
        ),
      ],
    );
  }

  /// Current logo  OR  upload a new one.
  Widget _buildLogoRow() {
    return Row(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(child: widget.logoPreview()),
        ),
        SizedBox(width: 14.w),
        AppText(
          'OR',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(width: 14.w),
        InkWell(
          onTap: _pickLogo,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE3E3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_rounded, color: kBrandRed, size: 22.sp),
                SizedBox(height: 6.h),
                AppText(
                  'Upload logo',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onEdited,
    TextInputType? keyboardType,
    bool isLast = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) {
          onEdited();
          widget.onChanged();
        },
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 12.h,
          ),
          border: border,
          enabledBorder: border,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _save,
        style: brandButtonStyle(
          radius: 12.r,
          padding: EdgeInsets.symmetric(vertical: 14.h),
        ),
        child: AppText(
          'UPDATE BUSINESS DETAILS',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ========================================================================
// REMOVE BACKGROUND DIALOG
// ========================================================================

/// true -> REMOVE BG, false -> KEEP IT ORIGINAL, null -> dismissed.
Future<bool?> showRemoveBackgroundDialog(BuildContext context, File preview) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Image.file(preview, fit: BoxFit.contain),
            ),
            SizedBox(height: 14.h),
            AppText(
              'Remove Background?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              'Would you like to remove background from your logo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: brandButtonStyle(radius: 8.r),
                    child: AppText(
                      'REMOVE BG',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: AppText(
                      'KEEP IT ORIGINAL',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
