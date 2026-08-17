import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class BusinessRepository {
  BusinessRepository._();

  static final BusinessRepository instance = BusinessRepository._();

  Future<ApiResult<Map<String, dynamic>>> businessUpdate(
    String name,
    String phone,
    String email,
  ) async {
    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessUpdate,
        method: ApiMethod.post,
        body: {"name": name, "phone": phone, "email": email},
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );
    return result;
  }
}
