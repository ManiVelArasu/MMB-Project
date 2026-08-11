import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class feedBackRepository {
  feedBackRepository._();

  static final feedBackRepository instance = feedBackRepository._();

  Future<ApiResult<Map<String, dynamic>>> feedBack({
    required int rating,
    required String message,
    required String appVersion,
    required String platform,
  }) async {
    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.feedBack,
        method: ApiMethod.post,
        body: {
          "rating": rating,
          "message": message,
          "app_version": appVersion,
          "platform": platform,
        },
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );
    return result;
  }
}
