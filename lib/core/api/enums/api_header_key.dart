/// Standard header key names used across all requests.
enum ApiHeaderKey {
  contentType,
  accept,
  authorization,
  acceptLanguage,
  cacheControl,
}

extension ApiHeaderKeyX on ApiHeaderKey {
  String get value {
    switch (this) {
      case ApiHeaderKey.contentType:
        return 'Content-Type';
      case ApiHeaderKey.accept:
        return 'Accept';
      case ApiHeaderKey.authorization:
        return 'Authorization';
      case ApiHeaderKey.acceptLanguage:
        return 'Accept-Language';
      case ApiHeaderKey.cacheControl:
        return 'Cache-Control';
    }
  }
}
