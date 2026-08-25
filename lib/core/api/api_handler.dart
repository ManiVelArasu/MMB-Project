import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiHandler {
  ApiHandler._();

  static ApiHandler? _instance;

  static ApiHandler get instance {
    assert(
      _instance != null,
      'ApiHandler.init() must be called before accessing ApiHandler.instance.',
    );
    return _instance!;
  }

  late Dio _dio;
  String? _token;
  String? _refreshToken;

  late ApiContentType _defaultContentType;
  late int _defaultConnectTimeoutMs;
  late int _defaultReceiveTimeoutMs;

  late bool rethrowExceptions;
  late bool showToastOnError;
  late ApiToastPosition defaultToastPosition;

  static void init({
    required String baseUrl,
    ApiContentType defaultContentType = ApiContentType.json,
    int connectTimeoutMs = 30000,
    int receiveTimeoutMs = 30000,
    bool rethrowExceptions = false,
    bool showToastOnError = true,
    ApiToastPosition defaultToastPosition = ApiToastPosition.bottom,
    Map<String, String> extraDefaultHeaders = const {},
    Interceptor? interceptor,
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
          ApiHeaderKey.accept.value:
          ApiHeaderValue.applicationJson.value,
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

    _instance!._dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (
            DioException error,
            ErrorInterceptorHandler handler,
            ) async {
          // Only handle 401
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          // Don't refresh the refresh request itself
          if (error.requestOptions.path.contains('/auth/refresh')) {
            return handler.next(error);
          }

          try {
            final prefs =
            await SharedPreferences.getInstance();

            final refreshToken =
            prefs.getString('refresh_token');

            if (refreshToken == null ||
                refreshToken.isEmpty) {
              return handler.next(error);
            }

            debugPrint(
              '🔄 Access token expired. Refreshing...',
            );
            final refreshDio = Dio(
              BaseOptions(
                baseUrl: _instance!._dio.options.baseUrl,
                connectTimeout:
                const Duration(seconds: 30),
                receiveTimeout:
                const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

            final refreshResponse = await refreshDio.post(
              '/auth/refresh',
              data: {
                'refresh_token': refreshToken,
              },
            );

            if (refreshResponse.statusCode != 200 &&
                refreshResponse.statusCode != 201) {
              debugPrint(
                '❌ Refresh failed: '
                    '${refreshResponse.statusCode}',
              );

              return handler.next(error);
            }

            final data = refreshResponse.data;

            final newAccessToken =
                data['access_token'] ??
                    data['accessToken'] ??
                    data['token'];

            final newRefreshToken =
                data['refresh_token'] ??
                    data['refreshToken'];

            if (newAccessToken == null ||
                newAccessToken.toString().isEmpty) {
              debugPrint(
                '❌ Refresh response has no access token',
              );

              return handler.next(error);
            }

            // If backend rotates refresh token,
            // use the new one.
            final String finalRefreshToken =
            newRefreshToken != null &&
                newRefreshToken
                    .toString()
                    .isNotEmpty
                ? newRefreshToken.toString()
                : refreshToken;

            // Save BOTH tokens.
            await _instance!.setTokens(
              token: newAccessToken.toString(),
              refreshToken: finalRefreshToken,
            );

            debugPrint(
              '✅ New access token saved',
            );

            debugPrint(
              '✅ New refresh token saved',
            );

            // Retry original request
            final requestOptions =
                error.requestOptions;

            requestOptions.headers['Authorization'] =
            'Bearer ${newAccessToken.toString()}';

            final retryResponse =
            await _instance!._dio.fetch(
              requestOptions,
            );

            return handler.resolve(retryResponse);
          } catch (e, stackTrace) {
            debugPrint(
              '❌ Refresh token failed: $e',
            );
            debugPrintStack(
              stackTrace: stackTrace,
            );

            return handler.next(error);
          }
        },
      ),
    );

    // Add your custom interceptor AFTER refresh interceptor.
    if (interceptor != null) {
      _instance!._dio.interceptors.add(interceptor);
    }
  }

  String get baseUrl => _dio.options.baseUrl;

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  Future<void> setTokens({required String token, String? refreshToken}) async {
    _token = token;
    _refreshToken = refreshToken;
    print("dsdfsdfsdf${token}");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print("auth_token${token}");
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
  }

  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  Future<ApiResult<T>> request<T>({
    required ApiRequestConfig config,
    T Function(dynamic json)? fromJson,
  }) async {
    final shouldRethrow = config.rethrowException ?? rethrowExceptions;
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
    if (_token != null) {
      headers[ApiHeaderKey.authorization.value] = 'Bearer $_token';
    }
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

  Future<dynamic> _buildBody(dynamic body, ApiContentType contentType) async {
    if (body == null) return null;
    return body;
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
        return ApiResult.success(raw as T);
      } catch (e) {
        return ApiResult.failure(
          ApiError(
            type: ApiErrorType.parseError,
            message: 'Failed to parse response: $e',
            statusCode: statusCode,
            serverData: response.data,
          ),
        );
      }
    }
    return ApiResult.failure(
      ApiError(
        type: ApiErrorType.serverError,
        message:
            _extractServerMessage(response.data) ??
            'Server error ($statusCode)',
        statusCode: statusCode,
        serverData: response.data,
      ),
    );
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
          message:
              _extractServerMessage(e.response?.data) ??
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
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      // 1. சாதாரண கீ-க்களை செக் செய்வது
      for (final key in const [
        'message',
        'error',
        'detail',
        'msg',
        'description',
      ]) {
        final val = data[key];
        if (val is String && val.isNotEmpty) return val;

        // 🚀 2. 'error' ஒரு ம্যাপ-ஆக (Nested Map) இருந்தால் அதனுள் உள்ள 'message'-ஐ எடுப்பது
        if (key == 'error' && val is Map) {
          final nestedMsg = val['message'];
          if (nestedMsg is String && nestedMsg.isNotEmpty) return nestedMsg;
        }
      }
    }
    return null;
  }

  void _showToast(String message, ApiToastPosition position) {
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
  }
}
