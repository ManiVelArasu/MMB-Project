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
  }) async {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.project,
        method: ApiMethod.post,
        body: {'name': name, 'content': content},
      ),
      fromJson: (json) => json,
    );
  }

  Future<ApiResult<dynamic>> updateProject({
    required String projectUid,
    required String name,
    required String content,
  }) async {
    final uid = projectUid.trim();
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: '${ApiEndpoints.project}/$uid',
        method: ApiMethod.patch,
        body: {'name': name, 'content': content},
      ),
      fromJson: (json) => json,
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
