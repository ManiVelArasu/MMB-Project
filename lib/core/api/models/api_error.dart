import '../enums/api_error_type.dart';

/// Structured error returned by the API handler.
class ApiError {
  const ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.serverData,
  });

  /// Classification of the error.
  final ApiErrorType type;

  /// Human-readable message (shown in toast).
  final String message;

  /// HTTP status code, if available.
  final int? statusCode;

  /// Raw server response body, if available.
  final dynamic serverData;

  @override
  String toString() =>
      'ApiError(type: $type, statusCode: $statusCode, message: $message)';
}
