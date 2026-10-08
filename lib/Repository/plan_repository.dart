import '../Api Model/ai_pack_data.dart';
import '../Api Model/ai_top_up_model.dart';
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

  Future<ApiResult<dynamic>> cancelPlan() {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.cancelPlan,
        method: ApiMethod.post,
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> verify({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.verify,
        method: ApiMethod.post,
        body: {
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        },
      ),
      fromJson: (json) => json,
    );
  }
  Future<ApiResult<AiPackPaymentData>> quota(String quotaId) {
    return ApiRepository.instance.request<AiPackPaymentData>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.quota(quotaId),
        method: ApiMethod.post,
      ),
      fromJson: (json) {
        final data = json["data"];

        if (data is Map<String, dynamic>) {
          return AiPackPaymentData.fromJson(data);
        }

        throw Exception("AI Pack payment data not found");
      },
    );
  }

  Future<ApiResult<dynamic>> invoice(String InvoiceId) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.invoice(InvoiceId),
        method: ApiMethod.get,
        queryParams: {"type": "invoice"},
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> receipt(String InvoiceId) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.invoice(InvoiceId),
        method: ApiMethod.get,
        queryParams: {"type": "receipt"},
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<AiTopUpData>> AiTopUpCredit() {
    return ApiRepository.instance.request<AiTopUpData>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.aiPlan,
        method: ApiMethod.get,
        queryParams: {"feature": "ai_credits"},
      ),
      fromJson: (json) =>
          AiTopUpData.fromJson(Map<String, dynamic>.from(json["data"].first)),
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
