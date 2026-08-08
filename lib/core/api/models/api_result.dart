import 'api_error.dart';

/// Wraps the outcome of every API call.
///
/// - [data] is non-null on success.
/// - [error] is non-null on failure.
///
/// Both fields are exposed so callers that need the error detail can read it,
/// while callers that only care about success can just check [data].
class ApiResult<T> {
  const ApiResult._({this.data, this.error});

  const ApiResult.success(T data) : this._(data: data);
  const ApiResult.failure(ApiError error) : this._(error: error);

  final T? data;
  final ApiError? error;

  bool get isSuccess => data != null;
  bool get isFailure => error != null;
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiError error) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }
}
