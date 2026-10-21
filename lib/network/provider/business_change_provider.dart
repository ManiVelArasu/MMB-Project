import 'package:flutter/material.dart';
import 'package:mmb_app/network/provider/common_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Repository/business_change_repository.dart';

class BusinessPatchProvider extends ChangeNotifier {
  bool isUploading = false;
  String? errorMessage;

  final CommonProvider commonProvider = CommonProvider.instance;
  Future<Map<String, dynamic>?> businessPatchApi(
    BuildContext context,
    String subIndustry,
    String other,
  ) async {
    isUploading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Saved industry details
      final industrySlug = prefs.getString('saved_category_slug') ?? '';

      final savedUid = prefs.getString('business_uid');
      final businessUid = savedUid?.trim();

      if (businessUid == null || businessUid.isEmpty) {
        errorMessage = 'Business UID not found';
        notifyListeners();
        // return false;
      }

      final savedName = commonProvider.business?.name??'';

      final mobileNumber = prefs.getString('saved_mobile_number') ?? '';

      debugPrint('🏢 Industry Slug: $industrySlug');
      debugPrint('🏢 Industry ID: $businessUid');
      debugPrint('🏢 Business Name: $savedName');
      debugPrint('🏢 Mobile Number: $mobileNumber');
      debugPrint('🏢 Sub Industry: ${subIndustry.trim()}');
      debugPrint('🏢 Custom Sub Industry: ${other.trim()}');

      // Validation
      if (industrySlug.isEmpty) {
        errorMessage = 'Saved industry category not found';
        return null;
      }

      /*if (industryId.isEmpty) {
        errorMessage = 'Saved industry ID not found';
        return null;
      }*/

      if (mobileNumber.isEmpty) {
        errorMessage = 'Saved mobile number not found';
        return null;
      }

      // PATCH API
      final result = await BusinessPatchRepository.instance.businessPatch(
        industrySlug,
        subIndustry.trim(),
        savedName,
        other.trim(),
        businessUid ?? '',
      );

      return await result.when(
        success: (data) async {
          final uid = data['uid']?.toString();

          if (uid == null || uid.isEmpty) {
            errorMessage = 'Business UID not found';
            return null;
          }

          await prefs.setString('business_uid', uid);

          debugPrint('✅ Business PATCH successful');
          debugPrint('🏢 Business UID: $uid');

          if (!context.mounted) return data;

          Navigator.pushNamed(
            context,
            '/BusinessProfileScreen',
          );

          return data;
        },
        failure: (error) {
          errorMessage = error.message;

          debugPrint('❌ Business PATCH failed: ${error.message}');

          return null;
        },
      );
    } catch (e, stackTrace) {
      errorMessage = e.toString();

      debugPrint('❌ businessPatchApi error: $e');
      debugPrint('$stackTrace');

      return null;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}
