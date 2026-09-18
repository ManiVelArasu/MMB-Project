import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_endpoints.dart';
import 'api_handler.dart';

/// Refreshes an expired access token and retries the failed request.
///
/// A single refresh is shared by concurrent 401 responses so several API
/// calls cannot trigger several refresh-token requests at the same time.
class TokenRefreshInterceptor extends Interceptor {
  final Dio dio;

  bool _isRefreshing = false;
  Future<void>? _refreshFuture;

  TokenRefreshInterceptor(this.dio);

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Never refresh the same request more than once.
    if (err.requestOptions.extra['tokenRefreshRetried'] == true) {
      return handler.next(err);
    }

    // Never try to refresh the refresh-token request itself.
    if (err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
      return handler.next(err);
    }

    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    try {
      if (_isRefreshing && _refreshFuture != null) {
        await _refreshFuture;
      } else {
        _isRefreshing = true;
        final future = _performRefresh(refreshToken);
        _refreshFuture = future;

        try {
          await future;
        } finally {
          _refreshFuture = null;
          _isRefreshing = false;
        }
      }

      // Read the token again after refresh. Do not use the stale value that
      // was read before _performRefresh().
      final latestPrefs = await SharedPreferences.getInstance();
      final newAccessToken = latestPrefs.getString('auth_token');

      if (newAccessToken == null || newAccessToken.isEmpty) {
        return handler.next(err);
      }

      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      // Retry through the same Dio instance, but mark it so a broken refresh
      // cannot recursively trigger refresh forever.
      requestOptions.extra['tokenRefreshRetried'] = true;

      final response = await dio.fetch(requestOptions);
      return handler.resolve(response);
    } catch (e, stackTrace) {
      debugPrint('❌ Token refresh failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _refreshFuture = null;
      _isRefreshing = false;
      return handler.next(err);
    }
  }

  Future<void> _performRefresh(String refreshToken) async {
    // Separate Dio: refresh API itself must not pass through this interceptor.
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final response = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Refresh API failed: ${response.statusCode}');
    }

    final body = response.data;
    if (body is! Map) {
      throw Exception('Invalid refresh response');
    }

    final data = body['data'];
    final Map<dynamic, dynamic> tokenData =
    data is Map ? data : body;

    final newAccessToken =
        tokenData['access_token'] ??
            tokenData['accessToken'] ??
            tokenData['token'];

    final newRefreshToken =
        tokenData['refresh_token'] ??
            tokenData['refreshToken'] ??
            refreshToken;

    if (newAccessToken == null || newAccessToken.toString().isEmpty) {
      throw Exception('Refresh API did not return access token');
    }

    // Save BOTH tokens. If backend does not rotate the refresh token, the
    // old refresh token is retained.
    await ApiHandler.instance.setTokens(
      token: newAccessToken.toString(),
      refreshToken: newRefreshToken.toString(),
    );

    debugPrint('✅ Access token refreshed');
    debugPrint('✅ Refresh token saved');
  }
}
