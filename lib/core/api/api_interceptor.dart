import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_endpoints.dart';
import 'api_handler.dart';
import 'enums/refreh_result.dart';

class TokenRefreshInterceptor extends Interceptor {
  final Dio dio;

  bool _isRefreshing = false;
  Future<RefreshResult>? _refreshFuture;

  TokenRefreshInterceptor(this.dio);

  // ============================================================
  // ON ERROR
  // ============================================================

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    // ==========================================================
    // ONLY HANDLE 401
    // ==========================================================

    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final request = err.requestOptions;

    // ==========================================================
    // PREVENT INFINITE RETRY
    // ==========================================================

    if (request.extra['tokenRefreshRetried'] == true) {
      debugPrint(
        '❌ Request still returned 401 after token refresh',
      );

      return handler.next(err);
    }

    // ==========================================================
    // NEVER INTERCEPT REFRESH API ITSELF
    // ==========================================================

    if (request.path.contains(
      ApiEndpoints.refreshToken,
    )) {
      debugPrint(
        '❌ Refresh token API itself returned 401',
      );

      return handler.next(err);
    }

    // ==========================================================
    // GET REFRESH TOKEN
    // ==========================================================

    final prefs =
    await SharedPreferences.getInstance();

    final refreshToken =
    prefs.getString('refresh_token');

    // ==========================================================
    // REFRESH TOKEN MISSING
    // ==========================================================

    if (refreshToken == null ||
        refreshToken.trim().isEmpty) {
      debugPrint(
        '❌ Refresh token missing',
      );

      return handler.next(err);
    }

    try {
      RefreshResult refreshResult;

      // ========================================================
      // ANOTHER REQUEST ALREADY REFRESHING
      // ========================================================

      if (_isRefreshing &&
          _refreshFuture != null) {
        debugPrint(
          '⏳ Token refresh already running → waiting...',
        );

        refreshResult = await _refreshFuture!;
      } else {
        // ======================================================
        // START TOKEN REFRESH
        // ======================================================

        _isRefreshing = true;

        final Future<RefreshResult> future =
        _performRefresh(refreshToken);

        _refreshFuture = future;

        try {
          refreshResult = await future;
        } finally {
          _isRefreshing = false;
          _refreshFuture = null;
        }
      }

      // ========================================================
      // REFRESH RESULT
      // ========================================================

      debugPrint(
        '🔑 Token refresh result: $refreshResult',
      );

      // ========================================================
      // REFRESH SUCCESS
      // ========================================================

      if (refreshResult ==
          RefreshResult.success) {
        debugPrint(
          '✅ Token refresh successful',
        );
      }

      // ========================================================
      // NETWORK ERROR
      // ========================================================

      else if (refreshResult ==
          RefreshResult.networkError) {
        debugPrint(
          '🌐 Refresh API network error',
        );

        debugPrint(
          '⚠️ Keeping existing session/tokens',
        );

        // IMPORTANT:
        // Do NOT clear tokens.
        // Do NOT logout.
        // Do NOT navigate to LoginScreen.

        return handler.next(err);
      }

      // ========================================================
      // INVALID REFRESH TOKEN
      // ========================================================

      else if (refreshResult ==
          RefreshResult.invalidRefreshToken) {
        debugPrint(
          '🔐 Refresh token is invalid/expired',
        );

        // IMPORTANT:
        // Do not clear session directly here.
        // Let the authentication/session layer decide.

        return handler.next(err);
      }

      // ========================================================
      // OTHER REFRESH FAILURE
      // ========================================================

      else {
        debugPrint(
          '⚠️ Token refresh failed',
        );

        // Keep existing tokens.
        // Do not logout because of unknown/network errors.

        return handler.next(err);
      }

      // ========================================================
      // GET NEW ACCESS TOKEN
      // ========================================================

      final latestPrefs =
      await SharedPreferences.getInstance();

      final String? newAccessToken =
          latestPrefs.getString('access_token') ??
              latestPrefs.getString('auth_token');

      if (newAccessToken == null ||
          newAccessToken.trim().isEmpty) {
        debugPrint(
          '❌ New access token not found after refresh',
        );

        return handler.next(err);
      }

      // ========================================================
      // UPDATE ORIGINAL REQUEST
      // ========================================================

      request.headers['Authorization'] =
      'Bearer $newAccessToken';

      request.extra['tokenRefreshRetried'] = true;

      debugPrint(
        '🔄 Retrying original request with new access token',
      );

      // ========================================================
      // RETRY ORIGINAL REQUEST
      // ========================================================

      final Response response =
      await dio.fetch(request);

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

      // IMPORTANT:
      // Never clear session because of network/
      // connection/timeout exceptions.

      return handler.next(err);
    }
  }

  // ============================================================
  // PERFORM REFRESH
  // ============================================================

  Future<RefreshResult> _performRefresh(
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

      // ========================================================
      // SEPARATE DIO
      // ========================================================

      final Dio refreshDio = Dio(
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

      // ========================================================
      // REFRESH API
      // ========================================================

      final Response response =
      await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {
          'refresh_token': refreshToken,
        },
      );

      debugPrint(
        '🔑 Refresh API status: ${response.statusCode}',
      );

      debugPrint(
        '🔑 Refresh API response: ${response.data}',
      );

      // ========================================================
      // INVALID REFRESH TOKEN
      // ========================================================

      if (response.statusCode == 401 ||
          response.statusCode == 403) {
        debugPrint(
          '❌ REFRESH TOKEN INVALID / EXPIRED',
        );

        return RefreshResult.invalidRefreshToken;
      }

      // ========================================================
      // OTHER HTTP FAILURE
      // ========================================================

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        debugPrint(
          '❌ Refresh API failed: '
              '${response.statusCode}',
        );

        return RefreshResult.failed;
      }

      // ========================================================
      // VALIDATE RESPONSE
      // ========================================================

      final dynamic body = response.data;

      if (body is! Map) {
        debugPrint(
          '❌ Invalid refresh response',
        );

        return RefreshResult.failed;
      }

      // ========================================================
      // TOKEN DATA
      // ========================================================

      final dynamic rawData =
      body['data'];

      final Map<dynamic, dynamic> tokenData =
      rawData is Map
          ? rawData
          : body;

      // ========================================================
      // ACCESS TOKEN
      // ========================================================

      final dynamic accessToken =
          tokenData['access_token'] ??
              tokenData['accessToken'] ??
              tokenData['token'];

      // ========================================================
      // REFRESH TOKEN
      // ========================================================

      final dynamic newRefreshToken =
          tokenData['refresh_token'] ??
              tokenData['refreshToken'] ??
              refreshToken;

      // ========================================================
      // ACCESS TOKEN VALIDATION
      // ========================================================

      if (accessToken == null ||
          accessToken.toString().trim().isEmpty) {
        debugPrint(
          '❌ Refresh API did not return access token',
        );

        return RefreshResult.failed;
      }

      // ========================================================
      // SAVE TOKENS TO API HANDLER
      // ========================================================

      await ApiHandler.instance.setTokens(
        token: accessToken.toString(),
        refreshToken:
        newRefreshToken.toString(),
      );

      // ========================================================
      // SAVE TOKENS TO SHARED PREFERENCES
      // ========================================================

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

      // ========================================================
      // SUCCESS LOG
      // ========================================================

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

      return RefreshResult.success;
    } on DioException catch (e) {
      // ========================================================
      // DIO ERROR
      // ========================================================

      debugPrint(
        '❌ Refresh API DioException',
      );

      debugPrint(
        'Type: ${e.type}',
      );

      debugPrint(
        'Status: ${e.response?.statusCode}',
      );

      debugPrint(
        'Response: ${e.response?.data}',
      );

      // ========================================================
      // NO RESPONSE
      // ========================================================
      //
      // Means request did not get a server response.
      //
      // Examples:
      // - No internet
      // - DNS failure
      // - Failed host lookup
      // - Connection refused
      // - Timeout
      // ========================================================

      if (e.response == null) {
        debugPrint(
          '🌐 REFRESH API NETWORK ERROR',
        );

        debugPrint(
          '⚠️ KEEPING EXISTING SESSION',
        );

        return RefreshResult.networkError;
      }

      // ========================================================
      // INVALID REFRESH TOKEN
      // ========================================================

      if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        debugPrint(
          '❌ REFRESH TOKEN INVALID / EXPIRED',
        );

        return RefreshResult.invalidRefreshToken;
      }

      // ========================================================
      // OTHER SERVER ERROR
      // ========================================================

      debugPrint(
        '⚠️ REFRESH API SERVER ERROR',
      );

      return RefreshResult.failed;
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Refresh API Exception: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      // Do not clear session.

      return RefreshResult.failed;
    }
  }

  // ============================================================
  // REFRESH ACCESS TOKEN ON APP START
  // ============================================================

  Future<RefreshResult>
  refreshAccessTokenOnAppStart() async {
    // ==========================================================
    // ALREADY REFRESHING
    // ==========================================================

    if (_isRefreshing &&
        _refreshFuture != null) {
      debugPrint(
        '⏳ Startup refresh already running → waiting...',
      );

      return await _refreshFuture!;
    }

    // ==========================================================
    // GET REFRESH TOKEN
    // ==========================================================

    final prefs =
    await SharedPreferences.getInstance();

    final String? refreshToken =
    prefs.getString('refresh_token');

    // ==========================================================
    // NO REFRESH TOKEN
    // ==========================================================

    if (refreshToken == null ||
        refreshToken.trim().isEmpty) {
      debugPrint(
        '❌ No refresh token on app start',
      );

      return RefreshResult.invalidRefreshToken;
    }

    // ==========================================================
    // START REFRESH
    // ==========================================================

    _isRefreshing = true;

    final Future<RefreshResult> future =
    _performRefresh(refreshToken);

    _refreshFuture = future;

    try {
      final RefreshResult result =
      await future;

      debugPrint(
        '🔑 Startup refresh result: $result',
      );

      return result;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
    }
  }
}