import 'dart:math';

import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class AiRepository {
  AiRepository._();

  static final AiRepository instance = AiRepository._();

  /// GET ai/operations (list of AI tools and their credit cost)
  Future<ApiResult<dynamic>> operations() => _get('/ai/operations');

  /// GET uploads?slot=media_library&limit=20
  Future<ApiResult<dynamic>> mediaLibrary() => _get(
    '/uploads',
    query: {"slot": "media_library", "limit": 20},
  );

  /// POST ai/operations/ai_bg_remover  -> 202 + job id
  /// The API requires an `Idempotency-Key` header (unique per request).
  Future<ApiResult<dynamic>> removeBackground(String uploadUid) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: '/ai/operations/ai_bg_remover',
        method: ApiMethod.post,
        extraHeaders: {"Idempotency-Key": _uuidV4()},
        body: {"image": uploadUid}, // GUID of the upload
      ),
      fromJson: (json) => json,
    );
  }

  /// GET ai/jobs/{jobId}
  Future<ApiResult<dynamic>> job(String jobId) => _get('/ai/jobs/$jobId');

  /// Random UUID v4, eg. "3f2b8c1e-9a4d-4e7b-b1c2-5d6e7f8a9b0c".
  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<ApiResult<dynamic>> _get(
      String endpoint, {
        Map<String, dynamic>? query,
      }) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: endpoint,
        method: ApiMethod.get,
        queryParams: query,
      ),
      fromJson: (json) => json,
    );
  }
}