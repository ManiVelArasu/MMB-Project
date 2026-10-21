import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class BusinessPatchRepository {
  BusinessPatchRepository._();

  static final BusinessPatchRepository instance = BusinessPatchRepository._();
  Future<ApiResult<Map<String, dynamic>>> businessPatch(
      String industrySlug,
      String subIndustry,
      String name,
      String other,
      String industryId,
      ) async {
    final Map<String, dynamic> body = {
      'industry': industrySlug,
      'name': name,
    };

    final cleanSubIndustry = subIndustry.trim();
    final cleanOther = other.trim();

    if (cleanOther.isNotEmpty) {
      body['custom_sub_industry'] = cleanOther;
    } else if (cleanSubIndustry.isNotEmpty) {
      body['sub_industry'] = cleanSubIndustry;
    }



    return ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessDetail(industryId),
        method: ApiMethod.patch,
        body: body,
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );
  }
}
