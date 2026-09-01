import '../Api Model/industries.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class IndustryDropdown {
  IndustryDropdown._();

  static final IndustryDropdown instance = IndustryDropdown._();

  Future<ApiResult<IndustryResponse>> industry() {
    return ApiRepository.instance.request<IndustryResponse>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.industries,
        method: ApiMethod.get,
      ),
      fromJson: (json) =>
          IndustryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResult<IndustryResponse>> industryView({String? parentSlug}) {
    return ApiRepository.instance.request<IndustryResponse>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.industries,
        method: ApiMethod.get,
        queryParams: {
          if (parentSlug != null && parentSlug.trim().isNotEmpty)
            'parent': parentSlug.trim(),
        },
      ),
      fromJson: (json) =>
          IndustryResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
