import 'package:flutter/material.dart';

import 'brand_form.dart';

/// Values that depend on the slots of the selected frame's `content`.
class BrandSlots {
  /// Social slots unticked in the edit sheet (hidden in the frame).
  final Set<String> hidden = {};

  /// Text slots other than name / phone / email / web (eg. address).
  final Map<String, TextEditingController> extra = {};

  TextEditingController field(String key) =>
      extra.putIfAbsent(key, () => TextEditingController());

  /// All text values drawn inside the frame.
  Map<String, String> texts(BrandForm form) => {
    ...form.slotTexts,
    'name': form.name.text.trim(),
    for (final e in extra.entries) e.key: e.value.text.trim(),
  };

  void dispose() {
    for (final c in extra.values) {
      c.dispose();
    }
  }
}