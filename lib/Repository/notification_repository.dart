import '../Api Model/notification_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  Future<ApiResult<NotificationModel>> getNotification() {
    return ApiRepository.instance.request<NotificationModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.notification,
        method: ApiMethod.get,
      ),
      fromJson: (json) => NotificationModel.fromJson(json),
    );
  }
}
