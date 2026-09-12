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
  ) async {
    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessUpdate,
        method: ApiMethod.post,
        body: {
          'industry': industrySlug,
          'sub_industry': subIndustry,
          'name': name,
        },
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
  }) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessDetail(businessUid),
        method: ApiMethod.patch,
        body: {"name": name, "email": email, "phone": phone},
      ),
      fromJson: (json) => json,
    );
  }
}
