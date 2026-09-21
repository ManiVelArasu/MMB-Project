import 'package:mmb_app/Api%20Model/business_model.dart';

import '../Api Model/key_words_model.dart';
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

  Future<ApiResult<dynamic>> updateMe({required String accountType}) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.user,
        method: ApiMethod.patch,
        body: {"account_type": accountType},
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<BusinessModel>> businessApi() {
    return ApiRepository.instance.request<BusinessModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.Business,
        method: ApiMethod.get,
      ),
      fromJson: (json) => BusinessModel.fromJson(json),
    );
  }
  Future<ApiResult<KeyWordsModel>> keyWords() {
    return ApiRepository.instance.request<KeyWordsModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.keyWords,
        method: ApiMethod.get,
      ),
      fromJson: (json) => KeyWordsModel.fromJson(json),
    );
  }
}
