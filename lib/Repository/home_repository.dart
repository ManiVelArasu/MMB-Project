import '../Api Model/Template_model.dart';
import '../Api Model/special_days.dart';
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
    final result = await ApiRepository.instance
        .request<TemplateCategoriesModel>(
          config: ApiRequestConfig(
            endpoint: ApiEndpoints.templateCategory,
            method: ApiMethod.get,
            queryParams: {"tree": "1", "homepage": "1"},
          ),
          fromJson: (json) =>
              TemplateCategoriesModel.fromJson(json as Map<String, dynamic>),
        );
    return result;
  }

  Future<ApiResult<TemplatesResponseModel>> templatesByCategory(
    String categorySlug,
  ) async {
    final result = await ApiRepository.instance.request<TemplatesResponseModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.templates,
        method: ApiMethod.get,
        queryParams: {'category': categorySlug},
      ),
      fromJson: (json) {
        return TemplatesResponseModel.fromJson(json as Map<String, dynamic>);
      },
    );

    return result;
  }

  Future<ApiResult<SpecialDays>> specialDaysApi({
    String? range,
    String? from,
    String? to,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (range != null && range.isNotEmpty) {
      queryParams["range"] = range;
    } else if (from != null &&
        from.isNotEmpty &&
        to != null &&
        to.isNotEmpty) {
      queryParams["from"] = from;
      queryParams["to"] = to;
    }

    final result =
    await ApiRepository.instance.request<SpecialDays>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.specialDays,
        method: ApiMethod.get,
        queryParams: queryParams,
      ),
      fromJson: (json) =>
          SpecialDays.fromJson(
            json as Map<String, dynamic>,
          ),
    );

    return result;
  }
}
