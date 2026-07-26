/// Common header value strings.
enum ApiHeaderValue {
  applicationJson,
  multipartFormData,
  formUrlEncoded,
  noCache,
}

extension ApiHeaderValueX on ApiHeaderValue {
  String get value {
    switch (this) {
      case ApiHeaderValue.applicationJson:
        return 'application/json';
      case ApiHeaderValue.multipartFormData:
        return 'multipart/form-data';
      case ApiHeaderValue.formUrlEncoded:
        return 'application/x-www-form-urlencoded';
      case ApiHeaderValue.noCache:
        return 'no-cache';
    }
  }
}
