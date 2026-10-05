import '../Api Model/payment_history.dart';
import '../Api Model/plan_usage.dart';
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

  Future<ApiResult<dynamic>> subscription({required int planBillingOptionId}) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.subscription,
        method: ApiMethod.post,
        body: {"plan_billing_option_id": planBillingOptionId},
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> getMySubscription() {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: '${ApiEndpoints.subscription}/me',
        method: ApiMethod.get,
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<PaymentHistory>> paymentHistory() {
    return ApiRepository.instance.request<PaymentHistory>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.subscriptionPayment,
        method: ApiMethod.get,
      ),
      fromJson: (json) => PaymentHistory.fromJson(json),
    );
  }

  Future<ApiResult<PlanUsage>> planUsage() {
    return ApiRepository.instance.request<PlanUsage>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.planUsage,
        method: ApiMethod.get,
      ),
      fromJson: (json) => PlanUsage.fromJson(json),
    );
  }
}
