/// Classifies the origin / kind of an API error.
enum ApiErrorType {
  /// HTTP 4xx / 5xx response from the server.
  serverError,

  /// No internet or host unreachable.
  connectionError,

  /// Request timed out.
  timeout,

  /// Response could not be parsed / decoded.
  parseError,

  /// Request was cancelled.
  cancelled,

  /// Any other Dart/Flutter exception.
  unknown,
}
