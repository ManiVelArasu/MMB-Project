import 'dart:typed_data';
import 'package:flutter/cupertino.dart';

import '../Api Model/project_list.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class ProjectRepository {
  ProjectRepository._();
  static final ProjectRepository instance = ProjectRepository._();

  Future<ApiResult<dynamic>> createProject({
    required String name,
    required String content,
    int? templateId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'content': content,
    };

    if (templateId != null) {
      body['template_id'] = templateId; // int, not String
    }

    debugPrint('CREATE PROJECT BODY: $body');

    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.project,
        method: ApiMethod.post,
        body: body,
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> updateProject({
    required String projectUid,
    required String name,
    required String content,
    String? thumbnailBase64,
    String? thumbnailS3Key,
  }) async {
    final uid = projectUid.trim();

    if (uid.isEmpty) {
      throw ArgumentError('Project UID cannot be empty');
    }

    final body = <String, dynamic>{
      'name': name.trim().isEmpty ? 'Untitled design' : name.trim(),
      'content': content,
    };

    // Send thumbnail only when actual image Base64 is available.
    if (thumbnailBase64 != null &&
        thumbnailBase64.trim().isNotEmpty) {
      final thumbnail = thumbnailBase64.trim();

      body['thumbnail'] = thumbnail.startsWith('data:image/')
          ? thumbnail
          : 'data:image/jpeg;base64,$thumbnail';
    }
    // Do not send thumbnailS3Key as the thumbnail image.
    // The backend can retain the existing S3 key if supported.

    debugPrint('📤 UPDATE PROJECT UID: $uid');
    debugPrint('📤 UPDATE PROJECT BODY KEYS: ${body.keys.toList()}');
    debugPrint('📤 THUMBNAIL INCLUDED: ${body.containsKey('thumbnail')}');
    debugPrint('📤 UPDATE PROJECT CONTENT LENGTH: ${content.length}');

    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: '${ApiEndpoints.project}/$uid',
        method: ApiMethod.patch,
        body: body,
      ),
      fromJson: (json) {
        debugPrint('📥 UPDATE PROJECT RESPONSE: $json');
        return json;
      },
    );
  }


  Future<ApiResult<Map<String, dynamic>>> exportProject({
    required String projectUid,
    String? s3Key,
  }) async {
    final body = <String, dynamic>{
      'export_type': 'download',
      'platform': 'direct',
    };

    if (s3Key != null && s3Key.trim().isNotEmpty) {
      body['s3_key'] = s3Key.trim();
    }

    return ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: '${ApiEndpoints.project}/$projectUid/exports',
        method: ApiMethod.post,
        body: body,
      ),
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return json;
        }

        throw Exception('Invalid export response');
      },
    );
  }

  Future<ApiResult<ProjectList>> getProject() async {
    return ApiRepository.instance.request<ProjectList>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.project,
        method: ApiMethod.get,
      ),
      fromJson: (json) {
        debugPrint('📥 PROJECT LIST RESPONSE: $json');

        if (json is Map<String, dynamic>) {
          return ProjectList.fromJson(json);
        }

        throw Exception('Invalid project list response: ${json.runtimeType}');
      },
    );
  }
}
