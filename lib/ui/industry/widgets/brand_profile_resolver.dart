import 'package:flutter/foundation.dart';
import 'package:mmb_app/network/provider/business_provider.dart';
import 'package:mmb_app/network/provider/businessprofile_provider.dart';
import 'package:mmb_app/network/provider/common_provider.dart';

import 'frame_helpers.dart';

/// Resolves the logged-in user's phone / name / email / website / logo from
/// the providers. When a field name is not known it is searched in the
/// model's json.
///
/// Create one per build: the flattened profile json is built once and reused.
class BrandProfileResolver {
  BrandProfileResolver({required this.profile, required this.business});

  final BusinessProfileProvider profile;
  final BusinessProvider business;

  Map<String, String>? _data;
  static bool _logged = false;
  static String _lastLogoLog = '';

  // ------------------------------------------------------------------
  // VALUES
  // ------------------------------------------------------------------

  String get phone {
    if (profile.savedPhone.isNotEmpty) return profile.savedPhone;
    final fromBusiness = business.mobileNumber.trim();
    if (fromBusiness.isNotEmpty) return fromBusiness;
    return _value(
      const ['mobile', 'phone', 'contact', 'whatsapp'],
      exclude: const ['code', 'country', 'verif', 'otp'],
    );
  }

  String get name {
    final fromBusiness = business.businessName.trim();
    if (fromBusiness.isNotEmpty) return fromBusiness;
    return _value(
      const ['businessname', 'companyname', 'name'],
      exclude: const ['user', 'file', 'logo', 'image'],
    );
  }

  String get email {
    final fromBusiness = business.email.trim();
    if (fromBusiness.isNotEmpty) return fromBusiness;
    return _value(const ['email']);
  }

  String get website {
    if (profile.savedWebsite.isNotEmpty) return profile.savedWebsite;
    return _value(
      const ['website', 'site', 'url'],
      exclude: const ['logo', 'image', 'photo'],
    );
  }

  /// Business account -> business logo, personal account -> profile photo.
  /// The latest uploaded / saved key (BusinessProfileProvider) wins, so the
  /// preview shows a new logo before the profile model refreshes.
  String get imageUrl {
    final common = CommonProvider.instance;
    final isBusiness = common.accountType?.toLowerCase() == 'business';

    dynamic businessModel;
    dynamic me;
    try {
      businessModel = common.business;
    } catch (_) {}
    try {
      me = common.me?.data;
    } catch (_) {}

    final fromBusiness = pick(businessModel, [
          (b) => b.logoUrl,
          (b) => b.logo,
          (b) => b.logoS3Key,
          (b) => b.logoKey,
          (b) => b.businessLogo,
          (b) => b.profileImage,
    ]);
    final fromMe = pick(me, [
          (m) => m.profileImageUrl,
          (m) => m.profileImage,
          (m) => m.profilePicture,
          (m) => m.profileImageS3Key,
          (m) => m.avatar,
          (m) => m.photo,
          (m) => m.imageS3Key,
    ]);

    final savedKey =
    ((isBusiness ? profile.logoS3Key : profile.profileS3Key) ?? '').trim();

    var raw = savedKey.isNotEmpty
        ? savedKey
        : (isBusiness
        ? (fromBusiness.isNotEmpty ? fromBusiness : fromMe)
        : (fromMe.isNotEmpty ? fromMe : fromBusiness));

    // unknown field names -> look through the model's json
    if (raw.isEmpty) {
      raw = _value(
        const ['logo', 'profileimage', 'profilepic', 'photo', 'avatar', 'image'],
        exclude: const ['banner', 'cover', 'width', 'height', 'frame', 'bg'],
      );
    }
    final url = cdnUrl(raw);

    // TEMP DEBUG: logo enga irundhu varudhu-nu paakka. Fix aana pinnaadi remove pannunga.
    if (kDebugMode) {
      final line =
          'LOGO DEBUG isBusiness=$isBusiness accountType=${common.accountType} '
          'savedKey="$savedKey" fromBusiness="$fromBusiness" fromMe="$fromMe" '
          'raw="$raw" url="$url"';
      if (line != _lastLogoLog) {
        _lastLogoLog = line;
        debugPrint(line);
      }
    }
    return url;
  }

  // ------------------------------------------------------------------
  // PROFILE JSON SEARCH
  // ------------------------------------------------------------------

  /// First profile value whose key contains one of [contains] (in order).
  String _value(
      List<String> contains, {
        List<String> exclude = const [],
      }) {
    final data = _profileData();
    for (final c in contains) {
      for (final e in data.entries) {
        if (e.key.contains(c) && !exclude.any((x) => e.key.contains(x))) {
          return e.value;
        }
      }
    }
    return '';
  }

  /// All simple values of the business / user model (via toJson), nested maps
  /// flattened, keys lower-cased without "_" / "-". Business first.
  Map<String, String> _profileData() {
    final cached = _data;
    if (cached != null) return cached;

    final out = <String, String>{};

    void flatten(Map m) {
      m.forEach((k, v) {
        final key = k.toString().toLowerCase().replaceAll(
          RegExp(r'[_\-\s]'),
          '',
        );
        if (v is Map) {
          flatten(v);
        } else if (v != null && v is! List && v.toString().trim().isNotEmpty) {
          out.putIfAbsent(key, () => v.toString().trim());
        }
      });
    }

    void add(dynamic obj) {
      if (obj == null) return;
      try {
        final j = (obj as dynamic).toJson();
        if (j is Map) flatten(j);
      } catch (_) {}
    }

    final common = CommonProvider.instance;
    try {
      add(common.business);
    } catch (_) {}
    try {
      add(common.me?.data);
    } catch (_) {}
    try {
      add(common.me);
    } catch (_) {}

    if (kDebugMode && !_logged) {
      _logged = true;
      debugPrint('PROFILE DATA keys: ${out.keys.toList()}');
    }
    return _data = out;
  }
}