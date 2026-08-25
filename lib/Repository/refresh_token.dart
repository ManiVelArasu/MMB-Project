import 'package:dio/dio.dart';
import 'package:project_mmb/core/api/api_endpoints.dart';

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

      if (response.statusCode == 200) {
        final data = response.data;

        final accessToken = data['access_token'] ?? data['accessToken'];

        final newRefreshToken =
            data['refresh_token'] ?? data['refreshToken'] ?? refreshToken;

        if (accessToken == null || accessToken.toString().isEmpty) {
          return null;
        }

        return RefreshTokenResponse(
          accessToken: accessToken.toString(),
          refreshToken: newRefreshToken.toString(),
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  RefreshTokenResponse({required this.accessToken, required this.refreshToken});
}
