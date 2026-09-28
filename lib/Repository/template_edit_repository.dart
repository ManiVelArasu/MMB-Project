import '../Api Model/template_edit_model.dart';
import '../Api Model/templates_view.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class TemplateRepository {
  TemplateRepository._();
  static final TemplateRepository instance = TemplateRepository._();

  Future<ApiResult<TemplateEdit>> getTemplateByUid({required String uid}) {
    final safeUid = Uri.encodeComponent(uid.trim());
    return ApiRepository.instance.request<TemplateEdit>(
      config: ApiRequestConfig(
        endpoint: '/templates/$safeUid',
        method: ApiMethod.get,
      ),
      fromJson: (json) => TemplateEdit.fromJson(json),
    );
  }

  Future<ApiResult<TemplatesList>> templateApi({String? category}) async {
    final Map<String, dynamic> queryParams = {};

    if (category != null && category.trim().isNotEmpty) {
      queryParams["category"] = category.trim();
    }

    return await ApiRepository.instance.request<TemplatesList>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.templates,
        method: ApiMethod.get,
        queryParams: queryParams,
      ),
      fromJson: (json) {
        return TemplatesList.fromJson(json as Map<String, dynamic>);
      },
    );
  }
}
