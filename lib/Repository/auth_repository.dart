import '../Api Model/login_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  Future<ApiResult<OtpResponseModel>> sendOtp(
    String phone,
    String purpose,
  ) async {
    final result = await ApiRepository.instance.request<OtpResponseModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.login,
        method: ApiMethod.post,

        body: {"phone": phone, "purpose": purpose},
      ),
      fromJson: (json) =>
          OtpResponseModel.fromJson(json['data'] as Map<String, dynamic>),
    );
    return result;
  }

  Future<ApiResult<Map<String, dynamic>>> verifyOtp(
    String phone,
    String purpose,
    String otp,
    String clientMnemonic,
  ) async {
    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.verifyOtp,
        method: ApiMethod.post,
        body: {
          "phone": phone,
          "purpose": purpose,
          "otp": otp,
          "client_mnemonic": clientMnemonic,
        },
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );
    return result;
  }

  Future<ApiResult<Map<String, dynamic>>> logout() async {
    final result = await ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.logout,
        method: ApiMethod.post,
      ),
      fromJson: (json) => json['data'] as Map<String, dynamic>,
    );
    return result;
  }
}
