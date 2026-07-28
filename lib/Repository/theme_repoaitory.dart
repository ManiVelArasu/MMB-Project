import '../Api Model/theme_screen_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class ThemeRepository {
  ThemeRepository._();

  static final ThemeRepository instance = ThemeRepository._();

  Future<ApiResult<ThemeGroupResponse>> industry() {
    return ApiRepository.instance.request<ThemeGroupResponse>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.themes,
        method: ApiMethod.get,
      ),
      fromJson: (json) => ThemeGroupResponse.fromJson(json),
    );
  }
}
