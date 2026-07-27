import '../Api Model/templatecategories.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class HomeRepository {
  HomeRepository._();

  static final HomeRepository instance = HomeRepository._();

  Future<ApiResult<TemplateCategoriesModel>> templateCategory() async {
    final result = await ApiRepository.instance.request<TemplateCategoriesModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.templateCategory,
        method: ApiMethod.get,
      ),
      fromJson: (json) =>
          TemplateCategoriesModel.fromJson(json as Map<String, dynamic>),
    );
    return result;
  }
}
