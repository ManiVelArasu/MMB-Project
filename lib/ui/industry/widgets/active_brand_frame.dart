import 'dart:io';

import 'package:flutter/foundation.dart';

/// The purchased brand frame the user selected on the Business Frames screen.
/// The template edit screen reads it and draws the frame as an overlay.
///
/// Business Frames screen  -> ActiveBrandFrame.instance.update(...)
/// Template edit screen    -> ListenableBuilder(listenable: ActiveBrandFrame.instance)
///
/// Lives in memory (one app session). Save `contentJson` / `enabled` to
/// SharedPreferences too if it must survive an app restart.
class ActiveBrandFrame extends ChangeNotifier {
  ActiveBrandFrame._();
  static final ActiveBrandFrame instance = ActiveBrandFrame._();

  String? uid;

  /// `content` (Fabric JSON string) of frames/{uid}.
  String? contentJson;

  /// Enable / Disable switch of the Business Frames screen.
  bool enabled = true;

  /// Values drawn into the slots: phone / web / email / name.
  Map<String, String> slotTexts = const {};

  /// Picked logo (file) or profile / business logo (url).
  File? logoFile;
  String logoUrl = '';

  /// Overlay is drawn only for a purchased frame that is switched on.
  bool get isActive =>
      enabled && contentJson != null && contentJson!.trim().isNotEmpty;

  void update({
    required String? uid,
    required String? contentJson,
    required bool enabled,
    required Map<String, String> slotTexts,
    required File? logoFile,
    required String logoUrl,
  }) {
    final same = this.uid == uid &&
        this.contentJson == contentJson &&
        this.enabled == enabled &&
        mapEquals(this.slotTexts, slotTexts) &&
        this.logoFile?.path == logoFile?.path &&
        this.logoUrl == logoUrl;
    if (same) return;

    this.uid = uid;
    this.contentJson = contentJson;
    this.enabled = enabled;
    this.slotTexts = Map<String, String>.from(slotTexts);
    this.logoFile = logoFile;
    this.logoUrl = logoUrl;
    notifyListeners();
  }

  void clear() {
    uid = null;
    contentJson = null;
    slotTexts = const {};
    logoFile = null;
    logoUrl = '';
    notifyListeners();
  }
}