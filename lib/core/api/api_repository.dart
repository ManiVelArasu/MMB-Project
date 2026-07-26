import 'api_handler.dart';
import 'models/api_request_config.dart';
import 'models/api_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ApiRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Single entry-point for all API calls in the application.
///
/// Every feature repository should call [ApiRepository.instance.request] and
/// pass an [ApiRequestConfig] describing the call.
///
/// ### Example
/// ```dart
/// class AuthRepository {
///   Future<ApiResult<UserModel>> login(String username, String password) {
///     return ApiRepository.instance.request<UserModel>(
///       config: ApiRequestConfig(
///         endpoint: '/auth/login',
///         method: ApiMethod.post,
///         body: {'username': username, 'password': password},
///       ),
///       fromJson: UserModel.fromJson,
///     );
///   }
/// }
/// ```
class ApiRepository {
  ApiRepository._();

  static final ApiRepository instance = ApiRepository._();

  /// Executes the request described by [config].
  ///
  /// [fromJson] converts the raw response body to [T].
  /// If omitted, the raw `dynamic` value is cast to [T] directly.
  ///
  /// Returns [ApiResult.success] with [T] on success, or
  /// [ApiResult.failure] with an [ApiError] on any error.
  Future<ApiResult<T>> request<T>({
    required ApiRequestConfig config,
    T Function(dynamic json)? fromJson,
  }) {
    return ApiHandler.instance.request<T>(
      config: config,
      fromJson: fromJson,
    );
  }
}
