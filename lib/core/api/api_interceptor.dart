import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_endpoints.dart';
import 'api_handler.dart';

class TokenRefreshInterceptor extends Interceptor {
  final Dio dio;

  bool _isRefreshing = false;
  Future<bool>? _refreshFuture;

  TokenRefreshInterceptor(this.dio);

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    // Only handle 401
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final request = err.requestOptions;

    // --------------------------------------------------
    // Prevent infinite retry loop
    // --------------------------------------------------
    if (request.extra['tokenRefreshRetried'] == true) {
      debugPrint(
        '❌ Request still returned 401 after token refresh',
      );

      return handler.next(err);
    }

    // --------------------------------------------------
    // Never intercept refresh API itself
    // --------------------------------------------------
    if (request.path.contains(ApiEndpoints.refreshToken)) {
      debugPrint(
        '❌ Refresh token API itself returned 401',
      );

      return handler.next(err);
    }

    final prefs = await SharedPreferences.getInstance();

    final refreshToken =
    prefs.getString('refresh_token');

    // --------------------------------------------------
    // No refresh token
    // --------------------------------------------------
    if (refreshToken == null ||
        refreshToken.trim().isEmpty) {
      debugPrint(
        '❌ Refresh token missing',
      );

      return handler.next(err);
    }

    try {
      bool refreshSuccess;

      // --------------------------------------------------
      // Another request is already refreshing
      // --------------------------------------------------
      if (_isRefreshing &&
          _refreshFuture != null) {
        debugPrint(
          '⏳ Token refresh already running → waiting...',
        );

        refreshSuccess = await _refreshFuture!;
      } else {
        // ------------------------------------------------
        // Start refresh
        // ------------------------------------------------
        _isRefreshing = true;

        final future =
        _performRefresh(refreshToken);

        _refreshFuture = future;

        try {
          refreshSuccess = await future;
        } finally {
          _isRefreshing = false;
          _refreshFuture = null;
        }
      }

      // --------------------------------------------------
      // Refresh failed
      // --------------------------------------------------
      if (!refreshSuccess) {
        debugPrint(
          '❌ Token refresh failed',
        );

        return handler.next(err);
      }

      // --------------------------------------------------
      // Read latest access token
      // --------------------------------------------------
      final latestPrefs =
      await SharedPreferences.getInstance();

      final newAccessToken =
          latestPrefs.getString('access_token') ??
              latestPrefs.getString('auth_token');

      if (newAccessToken == null ||
          newAccessToken.trim().isEmpty) {
        debugPrint(
          '❌ New access token not found',
        );

        return handler.next(err);
      }

      // --------------------------------------------------
      // Update original request
      // --------------------------------------------------
      request.headers['Authorization'] =
      'Bearer $newAccessToken';

      request.extra['tokenRefreshRetried'] = true;

      debugPrint(
        '🔄 Retrying original request with new access token',
      );

      // --------------------------------------------------
      // Retry original request
      // --------------------------------------------------
      final response = await dio.fetch(request);

      debugPrint(
        '✅ Original request succeeded after token refresh',
      );

      return handler.resolve(response);
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Token refresh/retry exception: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return handler.next(err);
    }
  }

  // ======================================================
  // REFRESH TOKEN
  // ======================================================

  Future<bool> _performRefresh(
      String refreshToken,
      ) async {
    try {
      debugPrint('');
      debugPrint(
        '==============================================',
      );
      debugPrint(
        '🔄 ACCESS TOKEN EXPIRED',
      );
      debugPrint(
        '📡 Calling Refresh Token API...',
      );
      debugPrint(
        '==============================================',
      );

      // --------------------------------------------------
      // Separate Dio instance
      // --------------------------------------------------
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout:
          const Duration(seconds: 30),
          sendTimeout:
          const Duration(seconds: 30),
          receiveTimeout:
          const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      // --------------------------------------------------
      // Call refresh API
      // --------------------------------------------------
      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {
          'refresh_token': refreshToken,
        },
      );

      debugPrint(
        '🔑 Refresh API status: ${response.statusCode}',
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        debugPrint(
          '❌ Refresh API failed',
        );

        return false;
      }

      final body = response.data;

      if (body is! Map) {
        debugPrint(
          '❌ Invalid refresh response',
        );

        return false;
      }

      // --------------------------------------------------
      // Extract token data
      // --------------------------------------------------

      final dynamic rawData =
      body['data'];

      final Map<dynamic, dynamic> tokenData =
      rawData is Map
          ? rawData
          : body;

      final dynamic accessToken =
          tokenData['access_token'] ??
              tokenData['accessToken'] ??
              tokenData['token'];

      final dynamic newRefreshToken =
          tokenData['refresh_token'] ??
              tokenData['refreshToken'] ??
              refreshToken;

      if (accessToken == null ||
          accessToken.toString().trim().isEmpty) {
        debugPrint(
          '❌ Refresh API did not return access token',
        );

        return false;
      }

      // --------------------------------------------------
      // Save tokens
      // --------------------------------------------------

      await ApiHandler.instance.setTokens(
        token: accessToken.toString(),
        refreshToken:
        newRefreshToken.toString(),
      );

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        'access_token',
        accessToken.toString(),
      );

      await prefs.setString(
        'auth_token',
        accessToken.toString(),
      );

      await prefs.setString(
        'refresh_token',
        newRefreshToken.toString(),
      );

      debugPrint('');
      debugPrint(
        '==============================================',
      );
      debugPrint(
        '✅ NEW ACCESS TOKEN GENERATED',
      );
      debugPrint(
        '✅ NEW REFRESH TOKEN SAVED',
      );
      debugPrint(
        '==============================================',
      );
      debugPrint('');

      return true;
    } on DioException catch (e) {
      debugPrint(
        '❌ Refresh API DioException',
      );

      debugPrint(
        'Status: ${e.response?.statusCode}',
      );

      debugPrint(
        'Response: ${e.response?.data}',
      );

      return false;
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Refresh API Exception: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  // ======================================================
  // PUBLIC METHOD
  // USE THIS FROM SPLASH / APP START
  // ======================================================

  Future<bool> refreshAccessTokenOnAppStart() async {
    if (_isRefreshing &&
        _refreshFuture != null) {
      return await _refreshFuture!;
    }

    final prefs =
    await SharedPreferences.getInstance();

    final refreshToken =
    prefs.getString('refresh_token');

    if (refreshToken == null ||
        refreshToken.trim().isEmpty) {
      debugPrint(
        '❌ No refresh token on app start',
      );

      return false;
    }

    _isRefreshing = true;

    final future =
    _performRefresh(refreshToken);

    _refreshFuture = future;

    try {
      return await future;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
    }
  }
}