import '../enums/api_content_type.dart';
import '../enums/api_method.dart';
import '../enums/toast_position.dart';

/// Configuration object passed to [ApiRepository.request].
///
/// Every field that is `null` falls back to the global default set during
/// [ApiHandler.init].
class ApiRequestConfig {
  const ApiRequestConfig({
    required this.endpoint,
    required this.method,
    this.body,
    this.queryParams,
    this.extraHeaders,
    this.contentType,
    this.connectTimeoutMs,
    this.receiveTimeoutMs,
    this.rethrowException,
    this.showToastOnError,
    this.toastPosition,
  });

  /// Path appended to the base URL (e.g. `/auth/login`).
  final String endpoint;

  /// HTTP verb.
  final ApiMethod method;

  /// Request body.
  ///   - For [ApiContentType.json]           → `Map<String, dynamic>`
  ///   - For [ApiContentType.multipart]      → `Map<String, dynamic>` where
  ///     file values are `MultipartFileEntry` instances.
  ///   - For [ApiContentType.formUrlEncoded] → `Map<String, dynamic>`
  final dynamic body;

  /// URL query parameters.
  final Map<String, dynamic>? queryParams;

  /// Headers merged on top of the global defaults for this request only.
  final Map<String, String>? extraHeaders;

  /// Overrides the global content-type for this request.
  final ApiContentType? contentType;

  /// Overrides the global connect timeout (milliseconds).
  final int? connectTimeoutMs;

  /// Overrides the global receive timeout (milliseconds).
  final int? receiveTimeoutMs;

  /// When `true`, exceptions bubble up instead of being swallowed.
  /// Overrides the global [ApiHandler.rethrowExceptions] flag.
  final bool? rethrowException;

  /// Whether to show a toast on error. Overrides the global default.
  final bool? showToastOnError;

  /// Toast position for this request. Overrides the global default.
  final ApiToastPosition? toastPosition;
}
