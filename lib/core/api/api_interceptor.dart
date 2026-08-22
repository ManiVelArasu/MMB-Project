import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_mmb/core/api/api_handler.dart';

class TokenRefreshInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<void Function(String token)> _tokenSubscribers = [];
  static const String refreshTokenEndpoint =
      '/auth/refresh'; // Ungaloda endpoint

  TokenRefreshInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ApiHandler.instance.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final currentRefreshToken = ApiHandler.instance.refreshToken;

      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        debugPrint("❌ Refresh Token missing. Logging out...");
        _logoutAndRedirect();
        return super.onError(err, handler);
      }
      if (_isRefreshing) {
        _tokenSubscribers.add((newToken) async {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          try {
            final response = await dio.fetch(err.requestOptions);
            handler.resolve(response);
          } catch (e) {
            handler.reject(
              e is DioException
                  ? e
                  : DioException(requestOptions: err.requestOptions, error: e),
            );
          }
        });
        return;
      }

      _isRefreshing = true;

      try {
        final response = await dio.post(
          refreshTokenEndpoint,
          data: {'refresh_token': currentRefreshToken},
          options: Options(headers: {}),
        );

        final responseData = response.data;
        final bool isSuccess =
            response.statusCode == 200 &&
            (responseData['success'] == true ||
                responseData['status'] == true ||
                response.statusCode == 201);

        if (isSuccess) {
          final dataMap = responseData['data'] ?? responseData;

          final newAccessToken = dataMap['access_token'] ?? dataMap['token'];
          final newRefreshToken = dataMap['refresh_token'];

          if (newAccessToken != null) {
            await ApiHandler.instance.setTokens(
              token: newAccessToken,
              refreshToken: newRefreshToken ?? currentRefreshToken,
            );

            _isRefreshing = false;

            for (var subscriber in _tokenSubscribers) {
              subscriber(newAccessToken);
            }
            _tokenSubscribers.clear();

            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        }

        _isRefreshing = false;
        _logoutAndRedirect();
        return super.onError(err, handler);
      } catch (e) {
        debugPrint("❌ Token Refresh Exception: $e");
        _isRefreshing = false;
        _tokenSubscribers.clear();
        _logoutAndRedirect();
        return super.onError(err, handler);
      }
    }

    super.onError(err, handler);
  }

  void _logoutAndRedirect() {
    ApiHandler.instance.clearTokens();
  }
}
