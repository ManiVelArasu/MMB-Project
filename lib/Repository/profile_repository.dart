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

  Future<ApiResult<dynamic>> accountDeactivate() {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.accountDeactivate,
        method: ApiMethod.post,
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> accountLanguage({
    required List<String> languages,
    bool notifyPush = true,
    bool notifyEmail = false,
    bool notifyWhatsapp = true,
  }) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: "${ApiEndpoints.user}/preferences",
        method: ApiMethod.patch,
        body: {
          "languages": languages,
          "notify_push": notifyPush,
          "notify_email": notifyEmail,
          "notify_whatsapp": notifyWhatsapp,
        },
      ),
      fromJson: (json) => json,
    );
  }
}
