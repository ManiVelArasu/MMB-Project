// ============================================================
// API BASE RESPONSE
// All endpoints return: { status: bool, message: String, object: T }
// ============================================================

class ApiBaseResponse<T> {
  const ApiBaseResponse({
    required this.status,
    required this.message,
    this.object,
  });

  final bool status;
  final String message;
  final T? object;

  factory ApiBaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromObject,
  ) {
    return ApiBaseResponse<T>(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      object: json['object'] != null && fromObject != null
          ? fromObject(json['object'])
          : null,
    );
  }
}
