import '../Api Model/notification_model.dart';
import '../Api Model/un_read_count.dart';
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

  Future<ApiResult<dynamic>> notificationReadAll() {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.notificationReadAll,
        method: ApiMethod.patch,
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<UnReadCount>> notificationUnReadCount() {
    return ApiRepository.instance.request<UnReadCount>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.unReadCount,
        method: ApiMethod.get,
      ),
      fromJson: (json) => UnReadCount.fromJson(json),
    );
  }

  Future<ApiResult<dynamic>> notificationReadOne(String notificationUid) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.notificationReadOne(notificationUid),
        method: ApiMethod.patch,
      ),
      fromJson: (json) => json,
    );
  }
}
