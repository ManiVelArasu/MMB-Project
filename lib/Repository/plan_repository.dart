import '../Api Model/plans_type.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class PlanRepository {
  PlanRepository._();

  static final PlanRepository instance = PlanRepository._();

  Future<ApiResult<PlanResponse>> industry() {
    return ApiRepository.instance.request<PlanResponse>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.plan,
        method: ApiMethod.get,
      ),
      fromJson: (json) => PlanResponse.fromJson(json),
    );
  }
}
