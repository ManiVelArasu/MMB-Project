import '../Api Model/key_words_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class BusinessProfileRepository {
  BusinessProfileRepository._();

  static final BusinessProfileRepository instance =
      BusinessProfileRepository._();

  Future<ApiResult<KeyWordsModel>> industryKeyWords(String industrySlug) {
    return ApiRepository.instance.request<KeyWordsModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.industryKeyWords(industrySlug),
        method: ApiMethod.get,
      ),
      fromJson: (json) => KeyWordsModel.fromJson(json),
    );
  }
}
