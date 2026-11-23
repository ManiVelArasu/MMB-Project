import 'dart:io';

import 'package:flutter/material.dart';

import 'brand_profile_resolver.dart';

/// Editable brand info (logo / name / phone / email / website) shared by the
/// frames screen, the preview and the edit sheet.
class BrandForm {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final website = TextEditingController();

  /// Enable / Disable switch of the brand info on the frame.
  bool enabled = true;

  /// Logo picked by the user (null -> profile logo is used).
  File? logo;

  /// A new logo was picked and is not uploaded yet.
  bool logoChanged = false;
  bool isSaving = false;

  // Once the user typed in a field the profile value no longer overwrites it.
  bool nameTouched = false;
  bool phoneTouched = false;
  bool emailTouched = false;
  bool websiteTouched = false;

  /// Values drawn into the frame's `slot:*` objects.
  Map<String, String> get slotTexts => {
        'phone': phone.text.trim(),
        'web': website.text.trim(),
        'email': email.text.trim(),
        'name': name.text.trim(),
      };

  /// Fills the untouched fields from the profile (also when the profile
  /// loads a moment later).
  void syncFromProfile(BrandProfileResolver profile) {
    _fill(website, profile.website, websiteTouched);
    _fill(phone, profile.phone, phoneTouched);
    _fill(name, profile.name, nameTouched);
    _fill(email, profile.email, emailTouched);
  }

  void _fill(TextEditingController c, String value, bool touched) {
    if (!touched && c.text != value) c.text = value;
  }

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    website.dispose();
  }
}
