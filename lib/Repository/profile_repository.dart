import '../Api Model/language_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  Future<ApiResult<LanguageModel>> getLanguage() {
    return ApiRepository.instance.request<LanguageModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.language,
        method: ApiMethod.get,
      ),
      fromJson: (json) => LanguageModel.fromJson(json),
    );
  }
}
