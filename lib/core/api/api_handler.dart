import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'api_interceptor.dart';
import 'enums/api_content_type.dart';
import 'enums/api_error_type.dart';
import 'enums/api_header_key.dart';
import 'enums/api_header_value.dart';
import 'enums/api_method.dart';
import 'enums/toast_position.dart';
import 'models/api_error.dart';
import 'models/api_request_config.dart';
import 'models/api_result.dart';
import 'models/multipart_file_entry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ApiHandler
// ─────────────────────────────────────────────────────────────────────────────

/// Singleton HTTP handler.
///
/// ### Initialisation (call once in `main`)
/// ```dart
/// ApiHandler.init(
///   baseUrl: 'https://api.example.com',
///   defaultContentType: ApiContentType.json,
///   rethrowExceptions: false,
///   showToastOnError: true,
/// );
/// ```
///
/// ### Setting tokens after authentication
/// ```dart
/// ApiHandler.instance.setTokens(
///   token: 'eyJ...',
///   refreshToken: 'eyJ...',
/// );
/// ```
///
/// ### Making a request (via [ApiRepository])
/// ```dart
/// final result = await ApiRepository.instance.request<Map<String, dynamic>>(
///   config: ApiRequestConfig(
///     endpoint: '/auth/login',
///     method: ApiMethod.post,
///     body: {'username': 'john', 'password': '1234'},
///   ),
/// );
/// ```
class ApiHandler {
  ApiHandler._();

  static ApiHandler? _instance;

  /// Access the singleton after [init] has been called.
  static ApiHandler get instance {
    assert(
      _instance != null,
      'ApiHandler.init() must be called before accessing ApiHandler.instance.',
    );
    return _instance!;
  }

  // ── internal state ──────────────────────────────────────────────────────────

  late Dio _dio;
  String? _token;
  String? _refreshToken;

  // ── configuration ───────────────────────────────────────────────────────────

  late ApiContentType _defaultContentType;
  late int _defaultConnectTimeoutMs;
  late int _defaultReceiveTimeoutMs;

  /// When `true`, exceptions are re-thrown after being logged/toasted.
  /// Can be overridden per-request via [ApiRequestConfig.rethrowException].
  late bool rethrowExceptions;

  /// When `true`, a toast is shown on every error.
  /// Can be overridden per-request via [ApiRequestConfig.showToastOnError].
  late bool showToastOnError;

  /// Default toast position. Can be overridden per-request.
  late ApiToastPosition defaultToastPosition;

  // ── init ────────────────────────────────────────────────────────────────────

  /// Initialise the singleton. Call this once inside `main()` before
  /// `runApp()`.
  ///
  /// [extraDefaultHeaders] are merged with the built-in defaults on every
  /// request.
  static void init({
    required String baseUrl,
    ApiContentType defaultContentType = ApiContentType.json,
    int connectTimeoutMs = 30000,
    int receiveTimeoutMs = 30000,
    bool rethrowExceptions = false,
    bool showToastOnError = true,
    ApiToastPosition defaultToastPosition = ApiToastPosition.bottom,
    Map<String, String> extraDefaultHeaders = const {},
    Interceptor? interceptor
  }) {
    _instance = ApiHandler._();
    _instance!._defaultContentType = defaultContentType;
    _instance!._defaultConnectTimeoutMs = connectTimeoutMs;
    _instance!._defaultReceiveTimeoutMs = receiveTimeoutMs;
    _instance!.rethrowExceptions = rethrowExceptions;
    _instance!.showToastOnError = showToastOnError;
    _instance!.defaultToastPosition = defaultToastPosition;

    _instance!._dio = Dio(

      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: receiveTimeoutMs),

        headers: {
          ApiHeaderKey.accept.value: ApiHeaderValue.applicationJson.value,
          ...extraDefaultHeaders,
        },
      ),
    );

    if (kDebugMode) {
      _instance!._dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
    if(interceptor!=null){
      _instance!._dio.interceptors.add(interceptor);
    }

  }

  // ── base url management ─────────────────────────────────────────────────────

  /// Returns the current base URL being used by Dio.
  String get baseUrl => _dio.options.baseUrl;

  /// Swap the base URL at runtime (useful during development).
  /// Preserves all other Dio options and interceptors.
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  // ── token management ────────────────────────────────────────────────────────

  /// Store the auth token and refresh token after a successful login.
  void setTokens({required String token, String? refreshToken}) {
    _token = token;
    _refreshToken = refreshToken;
  }

  /// Clear tokens on logout.
  void clearTokens() {
    _token = null;
    _refreshToken = null;
  }

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  // ── core request ────────────────────────────────────────────────────────────

  /// Execute an HTTP request described by [config].
  ///
  /// Returns [ApiResult.success] with the parsed [T] on success, or
  /// [ApiResult.failure] on any error.
  ///
  /// If [T] is `void` / you don't need the body, pass `<void>` and ignore
  /// [ApiResult.data].
  Future<ApiResult<T>> request<T>({
    required ApiRequestConfig config,
    T Function(dynamic json)? fromJson,
  }) async {
    final shouldRethrow =
        config.rethrowException ?? rethrowExceptions;
    final shouldToast = config.showToastOnError ?? showToastOnError;
    final toastPos = config.toastPosition ?? defaultToastPosition;

    try {
      final response = await _executeRequest(config);
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      final apiError = _mapDioError(e);
      if (shouldToast) _showToast(apiError.message, toastPos);
      if (shouldRethrow) rethrow;
      return ApiResult.failure(apiError);
    } catch (e) {
      final apiError = ApiError(
        type: ApiErrorType.unknown,
        message: e.toString(),
      );
      if (shouldToast) _showToast(apiError.message, toastPos);
      if (shouldRethrow) rethrow;
      return ApiResult.failure(apiError);
    }
  }

  // ── private helpers ─────────────────────────────────────────────────────────

  Future<Response<dynamic>> _executeRequest(ApiRequestConfig config) async {
    final contentType = config.contentType ?? _defaultContentType;
    final headers = _buildHeaders(contentType, config.extraHeaders);

    final options = Options(
      headers: headers,
      contentType: _contentTypeString(contentType),
      sendTimeout: config.connectTimeoutMs != null
          ? Duration(milliseconds: config.connectTimeoutMs!)
          : Duration(milliseconds: _defaultConnectTimeoutMs),
      receiveTimeout: config.receiveTimeoutMs != null
          ? Duration(milliseconds: config.receiveTimeoutMs!)
          : Duration(milliseconds: _defaultReceiveTimeoutMs),
    );

    final data = await _buildBody(config.body, contentType);

    switch (config.method) {
      case ApiMethod.get:
        return _dio.get(
          config.endpoint,
          queryParameters: config.queryParams,
          options: options,
        );
      case ApiMethod.post:
        return _dio.post(
          config.endpoint,
          data: data,
          queryParameters: config.queryParams,
          options: options,
        );
      case ApiMethod.put:
        return _dio.put(
          config.endpoint,
          data: data,
          queryParameters: config.queryParams,
          options: options,
        );
      case ApiMethod.patch:
        return _dio.patch(
          config.endpoint,
          data: data,
          queryParameters: config.queryParams,
          options: options,
        );
      case ApiMethod.delete:
        return _dio.delete(
          config.endpoint,
          data: data,
          queryParameters: config.queryParams,
          options: options,
        );
    }
  }

  Map<String, String> _buildHeaders(
    ApiContentType contentType,
    Map<String, String>? extra,
  ) {
    final headers = <String, String>{};

    // Authorization
    if (_token != null) {
      headers[ApiHeaderKey.authorization.value] = 'Bearer $_token';
    }

    // Merge caller-supplied extras
    if (extra != null) headers.addAll(extra);

    return headers;
  }

  String _contentTypeString(ApiContentType type) {
    switch (type) {
      case ApiContentType.json:
        return ApiHeaderValue.applicationJson.value;
      case ApiContentType.multipart:
        return ApiHeaderValue.multipartFormData.value;
      case ApiContentType.formUrlEncoded:
        return ApiHeaderValue.formUrlEncoded.value;
    }
  }

  Future<dynamic> _buildBody(
    dynamic body,
    ApiContentType contentType,
  ) async {
    if (body == null) return null;

    switch (contentType) {
      case ApiContentType.json:
        return body; // dio serialises Map → JSON automatically

      case ApiContentType.formUrlEncoded:
        return body; // dio handles Map → form-encoded automatically

      case ApiContentType.multipart:
        if (body is! Map<String, dynamic>) return body;
        final formData = <String, dynamic>{};
        for (final entry in body.entries) {
          if (entry.value is MultipartFileEntry) {
            formData[entry.key] =
                await _toMultipartFile(entry.value as MultipartFileEntry);
          } else if (entry.value is List) {
            // Support list of files or plain values
            final list = <dynamic>[];
            for (final item in entry.value as List) {
              if (item is MultipartFileEntry) {
                list.add(await _toMultipartFile(item));
              } else {
                list.add(item);
              }
            }
            formData[entry.key] = list;
          } else {
            formData[entry.key] = entry.value;
          }
        }
        return FormData.fromMap(formData);
    }
  }

  Future<MultipartFile> _toMultipartFile(MultipartFileEntry entry) async {
    if (entry.filePath != null) {
      return MultipartFile.fromFile(
        entry.filePath!,
        filename: entry.filename,
        contentType: entry.contentType != null
            ? DioMediaType.parse(entry.contentType!)
            : null,
      );
    }
    // bytes path
    return MultipartFile.fromBytes(
      entry.bytes!,
      filename: entry.filename,
      contentType: entry.contentType != null
          ? DioMediaType.parse(entry.contentType!)
          : null,
    );
  }

  ApiResult<T> _parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic json)? fromJson,
  ) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final raw = response.data;
        if (fromJson != null) {
          return ApiResult.success(fromJson(raw));
        }
        // Caller wants the raw dynamic / already typed
        return ApiResult.success(raw as T);
      } catch (e) {
        final err = ApiError(
          type: ApiErrorType.parseError,
          message: 'Failed to parse response: $e',
          statusCode: statusCode,
          serverData: response.data,
        );
        return ApiResult.failure(err);
      }
    }

    // Non-2xx treated as server error
    final err = ApiError(
      type: ApiErrorType.serverError,
      message: _extractServerMessage(response.data) ??
          'Server error ($statusCode)',
      statusCode: statusCode,
      serverData: response.data,
    );
    return ApiResult.failure(err);
  }

  ApiError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError(
          type: ApiErrorType.timeout,
          message: 'Request timed out. Please try again.',
          statusCode: e.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return ApiError(
          type: ApiErrorType.connectionError,
          message: e.error is SocketException
              ? 'No internet connection.'
              : 'Connection error. Please check your network.',
          statusCode: e.response?.statusCode,
        );

      case DioExceptionType.cancel:
        return ApiError(
          type: ApiErrorType.cancelled,
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return ApiError(
          type: ApiErrorType.serverError,
          message: _extractServerMessage(e.response?.data) ??
              'Server error (${statusCode ?? 'unknown'})',
          statusCode: statusCode,
          serverData: e.response?.data,
        );

      case DioExceptionType.badCertificate:
        return ApiError(
          type: ApiErrorType.connectionError,
          message: 'SSL certificate error.',
          statusCode: e.response?.statusCode,
        );

      case DioExceptionType.unknown:
        return ApiError(
          type: ApiErrorType.unknown,
          message: e.message ?? 'An unexpected error occurred.',
          statusCode: e.response?.statusCode,
          serverData: e.response?.data,
        );
      case DioExceptionType.transformTimeout:
        return ApiError(
          type: ApiErrorType.unknown,
          message: e.message ?? 'An unexpected error occurred.',
          statusCode: e.response?.statusCode,
          serverData: e.response?.data,
        );
    }
  }

  /// Tries common server error message fields.
  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      for (final key in const [
        'message',
        'error',
        'detail',
        'msg',
        'description',
      ]) {
        final val = data[key];
        if (val is String && val.isNotEmpty) return val;
      }
    }
    return null;
  }

  void _showToast(String message, ApiToastPosition position) {
    Toast gravity;
    switch (position) {
      case ApiToastPosition.top:
        gravity = Toast.LENGTH_SHORT;
        break;
      case ApiToastPosition.center:
      case ApiToastPosition.bottom:
        gravity = Toast.LENGTH_SHORT;
        break;
    }

    ToastGravity toastGravity;
    switch (position) {
      case ApiToastPosition.top:
        toastGravity = ToastGravity.TOP;
        break;
      case ApiToastPosition.center:
        toastGravity = ToastGravity.CENTER;
        break;
      case ApiToastPosition.bottom:
        toastGravity = ToastGravity.BOTTOM;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: gravity,
      gravity: toastGravity,
      timeInSecForIosWeb: 3,
    );
  }
}
