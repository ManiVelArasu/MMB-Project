import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_error_type.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_error.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class MediaUploadRepository {
  MediaUploadRepository._();

  static final MediaUploadRepository instance =
  MediaUploadRepository._();

  Future<ApiResult<Map<String, dynamic>>> uploadImageAndConfirm({
    required File imageFile,
    required String filename,
    required int width,
    required int height,
    required String slot,
  }) async {
    try {
      final dio = Dio();

      // ============================================================
      // 1. PRESIGN
      // ============================================================
      final extension = filename.split('.').last.toLowerCase();

      final contentType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => '',
      };

      if (contentType.isEmpty) {
        return ApiResult.failure(
          ApiError(
            message: 'Unsupported image format: .$extension',
            type: ApiErrorType.unknown,
          ),
        );
      }

      // Normalize image bytes so the uploaded bytes match the filename and
      // content type expected by the presign/confirm APIs.
      final originalBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(originalBytes);

      if (decodedImage == null) {
        return ApiResult.failure(
          ApiError(
            message: 'Selected file is not a valid image.',
            type: ApiErrorType.unknown,
          ),
        );
      }

      late final List<int> uploadBytes;
      switch (extension) {
        case 'png':
          uploadBytes = img.encodePng(decodedImage);
          break;
        case 'jpg':
        case 'jpeg':
          uploadBytes = img.encodeJpg(decodedImage, quality: 95);
          break;
        case 'webp':
          final isWebP = originalBytes.length >= 12 &&
              String.fromCharCodes(originalBytes.sublist(0, 4)) == 'RIFF' &&
              String.fromCharCodes(originalBytes.sublist(8, 12)) == 'WEBP';
          if (!isWebP) {
            return ApiResult.failure(
              ApiError(
                message: 'The selected file is not actually a WebP image. '
                    'Use a .png or .jpg filename, or convert it to WebP first.',
                type: ApiErrorType.unknown,
              ),
            );
          }
          uploadBytes = originalBytes;
          break;
      }

      final uploadWidth = decodedImage.width;
      final uploadHeight = decodedImage.height;

      debugPrint("======================================");
      debugPrint("🚀 MEDIA UPLOAD");
      debugPrint("Slot     : $slot");
      debugPrint("Filename : $filename");
      debugPrint("======================================");

      final initResult =
      await ApiRepository.instance.request<Map<String, dynamic>>(
        config: ApiRequestConfig(
          endpoint: ApiEndpoints.fileUpload,
          method: ApiMethod.post,
          body: {
            "target": {
              "slot": slot,
            },
            "filename": filename,
            "content_type": contentType,
          },
        ),
        fromJson: (json) {
          return Map<String, dynamic>.from(
            json['data'] as Map,
          );
        },
      );

      String? uploadUrl;
      String? uploadKey;
      Map<String, dynamic>? requiredHeaders;

      final initSuccess = initResult.when(
        success: (data) {
          uploadUrl = data['upload_url']?.toString();
          uploadKey = data['key']?.toString();

          final headers = data['required_headers'];

          if (headers is Map) {
            requiredHeaders =
            Map<String, dynamic>.from(headers);
          }

          debugPrint("✅ Upload slot: $slot");
          debugPrint("✅ Upload key: $uploadKey");

          return true;
        },
        failure: (error) {
          debugPrint(
            "❌ Presign API Failed: ${error.message}",
          );

          return false;
        },
      );

      if (!initSuccess ||
          uploadUrl == null ||
          uploadUrl!.isEmpty ||
          uploadKey == null ||
          uploadKey!.isEmpty) {
        return ApiResult.failure(
          ApiError(
            message: "Failed to get presign URL from server",
            type: ApiErrorType.unknown,
          ),
        );
      }

      // ============================================================
      // 2. S3 UPLOAD
      // ============================================================

      final bytes = uploadBytes;

      final Map<String, dynamic> s3Headers = {
        Headers.contentLengthHeader: bytes.length,
        ...?requiredHeaders,
      };

      final s3Response = await dio.put(
        uploadUrl!,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: s3Headers,
          contentType: contentType,
        ),
      );

      if (s3Response.statusCode != 200 &&
          s3Response.statusCode != 204) {
        debugPrint(
          "❌ S3 Upload failed: ${s3Response.statusCode}",
        );

        return ApiResult.failure(
          ApiError(
            message:
            "S3 Upload failed with status code: "
                "${s3Response.statusCode}",
            type: ApiErrorType.unknown,
          ),
        );
      }

      debugPrint("✅ S3 Upload Successful!");
      debugPrint("✅ S3 Key: $uploadKey");

      // ============================================================
      // 3. CONFIRM
      // ============================================================

      final confirmResult =
      await ApiRepository.instance.request<Map<String, dynamic>>(
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
        fromJson: (json) {
          return Map<String, dynamic>.from(
            json['data'] as Map,
          );
        },
      );

      confirmResult.when(
        success: (data) {
          debugPrint("======================================");
          debugPrint("✅ UPLOAD CONFIRMED");
          debugPrint("Slot : $slot");
          debugPrint("Key  : $uploadKey");
          debugPrint("======================================");
        },
        failure: (error) {
          debugPrint(
            "❌ Upload confirmation failed: ${error.message}",
          );
        },
      );

      return confirmResult;
    } catch (e, stackTrace) {
      debugPrint(
        "❌ Exception in uploadImageAndConfirm: $e",
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return ApiResult.failure(
        ApiError(
          message: e.toString(),
          type: ApiErrorType.unknown,
        ),
      );
    }
  }
}