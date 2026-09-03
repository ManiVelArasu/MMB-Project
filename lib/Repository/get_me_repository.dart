import '../Api Model/me_api.dart';
import '../Api Model/template_size_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class GetMeRepository {
  GetMeRepository._();

  static final GetMeRepository instance = GetMeRepository._();

  Future<ApiResult<Language>> getMe() {
    return ApiRepository.instance.request<Language>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.user,
        method: ApiMethod.get,
      ),
      fromJson: (json) => Language.fromJson(json),
    );
  }
}
