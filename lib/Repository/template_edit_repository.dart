
import '../Api Model/template_edit_model.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';


class TemplateRepository {
  TemplateRepository._();
  static final TemplateRepository instance = TemplateRepository._();

  Future<ApiResult<TemplateEdit>> getTemplateByUid({
    required String uid,
  }) {
    final safeUid = Uri.encodeComponent(uid.trim());
    return ApiRepository.instance.request<TemplateEdit>(
      config: ApiRequestConfig(
        endpoint: '/templates/$safeUid',
        method: ApiMethod.get,
      ),
      fromJson: (json) => TemplateEdit.fromJson(json),
    );
  }
}
