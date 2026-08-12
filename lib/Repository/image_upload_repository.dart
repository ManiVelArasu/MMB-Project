import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_error_type.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_error.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class MediaUploadRepository {
  MediaUploadRepository._();

  static final MediaUploadRepository instance = MediaUploadRepository._();
  Future<ApiResult<Map<String, dynamic>>> uploadImageAndConfirm({
    required File imageFile,
    required String filename,
    required int width,
    required int height,
  }) async {
    try {
      final dio = Dio();
      final initResult = await ApiRepository.instance
          .request<Map<String, dynamic>>(
            config: ApiRequestConfig(
              endpoint: ApiEndpoints.fileUpload,
              method: ApiMethod.post,
              body: {
                "target": {"slot": "media_library"},
                "filename": filename,
                "content_type": "image/jpeg",
              },
            ),
            fromJson: (json) => json['data'] as Map<String, dynamic>,
          );

      String? uploadUrl;
      String? uploadKey;
      Map<String, dynamic>? requiredHeaders;

      final initSuccess = initResult.when(
        success: (data) {
          uploadUrl = data['upload_url'];
          uploadKey = data['key'];
          requiredHeaders = data['required_headers'];
          return true;
        },
        failure: (error) {
          debugPrint("Presign API Failed: ${error.message}");
          return false;
        },
      );

      if (!initSuccess || uploadUrl == null || uploadKey == null) {
        return ApiResult.failure(
          ApiError(
            message: "Failed to get presign URL from server",
            type: ApiErrorType.unknown,
          ),
        );
      }

      final bytes = await imageFile.readAsBytes();
      final Map<String, dynamic> s3Headers = {
        Headers.contentLengthHeader: bytes.length,
        ...?requiredHeaders,
      };

      final s3Response = await dio.put(
        uploadUrl!,
        data: Stream.fromIterable([bytes]),
        options: Options(headers: s3Headers, contentType: 'image/jpeg'),
      );

      if (s3Response.statusCode != 200 && s3Response.statusCode != 204) {
        return ApiResult.failure(
          ApiError(
            message:
                "S3 Upload failed with status code: ${s3Response.statusCode}",
            type: ApiErrorType.unknown,
          ),
        );
      }

      debugPrint("✅ S3 Upload Successful!");
      final confirmResult = await ApiRepository.instance
          .request<Map<String, dynamic>>(
            config: ApiRequestConfig(
              endpoint: "/uploads/confirm",
              method: ApiMethod.post,
              body: {
                "uploads": [
                  {
                    "key": uploadKey,
                    "width": width,
                    "height": height,
                    "filename": filename,
                  },
                ],
              },
            ),
            fromJson: (json) => json['data'] as Map<String, dynamic>,
          );

      return confirmResult;
    } catch (e) {
      debugPrint("Exception in uploadImageAndConfirm: $e");
      return ApiResult.failure(
        ApiError(message: e.toString(), type: ApiErrorType.unknown),
      );
    }
  }
}
