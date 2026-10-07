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

  Future<ApiResult<dynamic>> updateBusinessDetails({
    required String businessUid,
    required String name,
    required String email,
    required String phone,
    required String logo_s3_key,
  }) {
    final Map<String, dynamic> body = {
      "name": name,
      "phone": phone,
      "logo_s3_key": logo_s3_key,
    };

    // Email entered only → send email
    if (email.trim().isNotEmpty) {
      body["email"] = email.trim();
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
