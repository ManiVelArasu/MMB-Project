/// Content-type options for API requests.
enum ApiContentType {
  /// application/json
  json,

  /// multipart/form-data  (file uploads, mixed fields)
  multipart,

  /// application/x-www-form-urlencoded
  formUrlEncoded,
}
