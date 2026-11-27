import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mmb_app/component/custom_widget.dart';
import 'package:mmb_app/utils/theme/app.colors.dart';
import 'package:mmb_app/utils/theme/app.fonts.dart';
import 'package:mmb_app/widgets/button_widget.dart';

import 'brand_form.dart';
import 'brand_slot.dart';
import 'frame_content.dart';
import 'frame_helpers.dart';

Future<void> showBrandEditSheet(
    BuildContext context, {
      required BrandForm form,
      required BrandSlots values,
      Set<String>? slots,
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
      values: values,
      slots: slots,
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
    required this.values,
    required this.slots,
    required this.logoPreview,
    required this.onPickLogo,
    required this.onSave,
    required this.onChanged,
  });

  final BrandForm form;
  final BrandSlots values;

  /// Slots of the selected frame. null -> frame without `content`.
  final Set<String>? slots;
  final Widget Function() logoPreview;
  final Future<void> Function() onPickLogo;
  final Future<bool> Function() onSave;
  final VoidCallback onChanged;

  @override
  State<_BrandEditSheet> createState() => _BrandEditSheetState();
}

class _BrandEditSheetState extends State<_BrandEditSheet> {
  static const _defaultKeys = ['logo', 'name', 'phone', 'email', 'web'];

  static const _socialLabels = {
    'facebook': 'Facebook',
    'instagram': 'Instagram',
    'twitter': 'Twitter',
    'youtube': 'YouTube',
    'linkedin': 'LinkedIn',
  };

  BrandForm get _form => widget.form;

  bool _has(String key) =>
      widget.slots?.contains(key) ?? _defaultKeys.contains(key);

  List<String> get _otherSlots => (widget.slots ?? const <String>{})
      .where(
        (k) =>
    !_defaultKeys.contains(k) && !FrameContent.socialKeys.contains(k),
  )
      .toList();

  bool _isSaving = false;
  bool _isUploading = false;

  bool get _isBusy => _isSaving || _isUploading;

  Future<void> _pickLogo() async {
    if (_isBusy) return;
    setState(() => _isUploading = true);
    try {
      await widget.onPickLogo(); // pick + upload
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (_isBusy) return;
    setState(() => _isSaving = true);
    var ok = false;
    try {
      ok = await widget.onSave();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    // sheet may already be closed with the X button
    if (ok && mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Navigator.pop(context);
    }
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
                if (_has('logo')) ...[
                  _buildLogoRow(),
                  SizedBox(height: 14.h),
                ],
                if (_has('name'))
                  _buildField(
                    label: 'Business Name',
                    controller: _form.name,
                    onEdited: () => _form.nameTouched = true,
                  ),
                if (_has('phone'))
                  _buildField(
                    label: 'Mobile Number',
                    controller: _form.phone,
                    keyboardType: TextInputType.phone,
                    onEdited: () => _form.phoneTouched = true,
                  ),
                if (_has('email'))
                  _buildField(
                    label: 'Email',
                    controller: _form.email,
                    keyboardType: TextInputType.emailAddress,
                    onEdited: () => _form.emailTouched = true,
                  ),
                if (_has('web'))
                  _buildField(
                    label: 'Website',
                    controller: _form.website,
                    keyboardType: TextInputType.url,
                    onEdited: () => _form.websiteTouched = true,
                  ),
                for (final key in _otherSlots.where((k) => k.isNotEmpty))
                  _buildField(
                    label: '${key[0].toUpperCase()}${key.substring(1)}',
                    controller: widget.values.field(key),
                    onEdited: () {},
                  ),
                for (final key in FrameContent.socialKeys)
                  if (_has(key)) _buildCheckbox(key),
                SizedBox(height: 4.h),
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
          'Update Frame Info',
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
                if (_isUploading)
                  ButtonLoader(color: kBrandRed)
                else
                  Icon(Icons.upload_rounded, color: kBrandRed, size: 22.sp),
                SizedBox(height: 6.h),
                AppText(
                  _isUploading ? 'Uploading...' : 'Upload logo',
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

  Widget _buildCheckbox(String key) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: kBrandRed,
      title: AppText(
        _socialLabels[key] ?? key,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      value: !widget.values.hidden.contains(key),
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            widget.values.hidden.remove(key);
          } else {
            widget.values.hidden.add(key);
          }
        });
        widget.onChanged();
      },
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onEdited,
    TextInputType? keyboardType,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
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
      height: 46.h,
      child: ElevatedButton(
        // stays enabled while saving so the button keeps its red colour
        // (_save ignores the extra taps)
        onPressed: _save,
        style: brandButtonStyle(radius: 12.r),
        child: _isSaving
            ? const ButtonLoader(label: 'UPDATING...')
            : AppText(
          'UPDATE FRAME',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Small spinner (with optional text) shown inside buttons.
class ButtonLoader extends StatelessWidget {
  const ButtonLoader({super.key, this.label, this.color = Colors.white});

  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18.r,
          height: 18.r,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        if (label != null) ...[
          SizedBox(width: 10.w),
          AppText(
            label!,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

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
            AppText(
              'Would you like to remove background from your logo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    buttonPress: () => Navigator.pop(ctx, true),
                    title: 'REMOVE BG',
                    buttonColor: AppColors.appRed,
                    textStyle: TextStyle(
                      fontSize: AppFontSize.fontSize10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.appWhite,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                Expanded(
                  child: ButtonWidget(
                    buttonPress: () => Navigator.pop(ctx, false),
                    title: 'KEEP IT ORIGINAL',
                    buttonColor: AppColors.appRed,
                    textStyle: TextStyle(
                      fontSize: AppFontSize.fontSize10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.appWhite,
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