import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';


import '../core/api/api_endpoints.dart';

class RefreshRepository {
  final Dio dio;

  RefreshRepository(this.dio);

  Future<RefreshTokenResponse?> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint('🔄 Refresh API Status: ${response.statusCode}');

      debugPrint('🔄 Refresh API Success: ${response.data['success']}');

      if (response.statusCode != 200) {
        return null;
      }

      final responseBody = response.data;

      if (responseBody is! Map) {
        debugPrint('❌ Invalid refresh response');
        return null;
      }

      final data = responseBody['data'];

      if (data is! Map) {
        debugPrint('❌ Refresh data is missing');
        return null;
      }

      final accessToken = data['access_token'] ?? data['accessToken'];

      final newRefreshToken =
          data['refresh_token'] ?? data['refreshToken'] ?? refreshToken;

      if (accessToken == null || accessToken.toString().isEmpty) {
        debugPrint('❌ New access token missing');
        return null;
      }

      debugPrint('✅ New access token received');
      debugPrint('✅ New refresh token received');

      return RefreshTokenResponse(
        accessToken: accessToken.toString(),
        refreshToken: newRefreshToken.toString(),
      );
    } on DioException catch (e) {
      debugPrint('❌ Refresh API Status: ${e.response?.statusCode}');

      debugPrint('❌ Refresh API Response: ${e.response?.data}');

      return null;
    } catch (e) {
      debugPrint('❌ Refresh Exception: $e');

      return null;
    }
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  RefreshTokenResponse({required this.accessToken, required this.refreshToken});
}
