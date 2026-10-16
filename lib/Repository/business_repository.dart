import 'package:flutter/cupertino.dart';

import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class BusinessRepository {
  BusinessRepository._();

  static final BusinessRepository instance = BusinessRepository._();
  Future<ApiResult<Map<String, dynamic>>> businessUpdate(
    String industrySlug,
    String subIndustry,
    String name,
    String other,
  ) async {
    final Map<String, dynamic> body = {'industry': industrySlug, 'name': name};

    final cleanSubIndustry = subIndustry.trim();
    final cleanOther = other.trim();

    // ============================================================
    // OTHER SELECTED
    // custom_sub_industry ONLY
    // ============================================================

    if (cleanOther.isNotEmpty) {
      body['custom_sub_industry'] = cleanOther;
    }
    // ============================================================
    // NORMAL SUB INDUSTRY SELECTED
    // sub_industry ONLY
    // ============================================================
    else if (cleanSubIndustry.isNotEmpty) {
      body['sub_industry'] = cleanSubIndustry;
    }

    debugPrint('📤 FINAL BUSINESS BODY: $body');

    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessUpdate,
        method: ApiMethod.post,
        body: body,
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );

    return result;
  }

  Future<ApiResult<Map<String, dynamic>>> skipBusinessUpdate(
    String industrySlug,
    String name,
  ) async {
    final Map<String, dynamic> body = {'industry': industrySlug, 'name': name};

    debugPrint('⏭️ SKIP REQUEST BODY: $body');

    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessUpdate,
        method: ApiMethod.post,
        body: body,
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );

    return result;
  }

  Future<ApiResult<Map<String, dynamic>>> fromLibrary(String category) async {
    final Map<String, dynamic> body = {'category': 'profile_pics'};

    debugPrint('⏭️ SKIP REQUEST BODY: $body');

    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.asset(category),
        method: ApiMethod.get,
        body: body,
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );

    return result;
  }

  Future<ApiResult<dynamic>> updateBusinessDetails({
    required String businessUid,
    required String name,
    required String email,
    required String phone,
    String? logo_s3_key,
  }) {
    final Map<String, dynamic> body = {
      "name": name.trim(),
      "phone": phone.trim(),
    };

    // Email இருந்தால் மட்டும் அனுப்பவும்.
    if (email.trim().isNotEmpty) {
      body["email"] = email.trim();
    }

    // New, valid image key இருந்தால் மட்டும் அனுப்பவும்.
    final logoKey = logo_s3_key?.trim();

    if (logoKey != null && logoKey.isNotEmpty) {
      body["logo_s3_key"] = logoKey;
    }

    debugPrint("📤 BUSINESS DETAILS BODY: $body");

    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessDetail(businessUid),
        method: ApiMethod.patch,
        body: body,
      ),
      fromJson: (json) => json,
    );
  }
}
