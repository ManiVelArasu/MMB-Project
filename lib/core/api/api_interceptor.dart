import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_mmb/core/api/api_handler.dart';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_mmb/core/api/api_endpoints.dart';

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

    // Refresh API itself failed.
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

        _refreshFuture = _performRefresh(refreshToken);

        await _refreshFuture;

        _refreshFuture = null;
        _isRefreshing = false;
      }

      final newAccessToken =
      prefs.getString('auth_token');

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        return handler.next(err);
      }

      final requestOptions = err.requestOptions;

      requestOptions.headers['Authorization'] =
      'Bearer $newAccessToken';

      final response = await dio.fetch(requestOptions);

      return handler.resolve(response);
    } catch (e) {
      _refreshFuture = null;
      _isRefreshing = false;

      return handler.next(err);
    }
  }

  Future<void> _performRefresh(String refreshToken) async {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    final response = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {
        'refresh_token': refreshToken,
      },
    );

    final data = response.data;

    final newAccessToken =
        data['access_token'] ??
            data['accessToken'];

    final newRefreshToken =
        data['refresh_token'] ??
            data['refreshToken'];

    if (newAccessToken == null ||
        newAccessToken.toString().isEmpty) {
      throw Exception('Refresh API did not return access token');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'auth_token',
      newAccessToken.toString(),
    );

    // IMPORTANT:
    // If backend rotates refresh token,
    // save the NEW refresh token.
    if (newRefreshToken != null &&
        newRefreshToken.toString().isNotEmpty) {
      await prefs.setString(
        'refresh_token',
        newRefreshToken.toString(),
      );
    }

    debugPrint('✅ Access token refreshed');
    debugPrint('✅ Refresh token updated');
  }
}
