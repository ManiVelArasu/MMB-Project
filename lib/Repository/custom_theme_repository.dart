import '../Api Model/template_size_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class CustomThemeRepository {
  CustomThemeRepository._();

  static final CustomThemeRepository instance = CustomThemeRepository._();

  Future<ApiResult<TemplateSizeModel>> industry() {
    return ApiRepository.instance.request<TemplateSizeModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.templateSize,
        method: ApiMethod.get,
      ),
      fromJson: (json) => TemplateSizeModel.fromJson(json),
    );
  }
}
