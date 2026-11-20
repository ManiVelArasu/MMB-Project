import 'package:flutter/foundation.dart';

import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class SearchProfileRepository {
  SearchProfileRepository._();

  static final SearchProfileRepository instance = SearchProfileRepository._();

  // Relative to the API base (…/api/v1). Change if your ApiEndpoints
  // already has constants for these.
  static const String _templates = 'templates';
  static const String _suggestions = 'templates/suggestions';

  /// GET /templates/suggestions?q=
  Future<ApiResult<dynamic>> suggestions(String query, {int limit = 8}) {
    final endpoint =
        '/$_suggestions?q=${Uri.encodeQueryComponent(query)}&limit=$limit';

    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(endpoint: endpoint, method: ApiMethod.get),
      fromJson: (json) => json,
    );
  }

  /// GET /templates?q=&limit=&offset=
  Future<ApiResult<dynamic>> search(
      String query, {
        int limit = 30,
        int offset = 0,
        String? tags,
        String? templateType,
        String? language,
        String? size,
      }) {
    final params = <String, String>{
      'q': query,
      'limit': '$limit',
      'offset': '$offset',
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (templateType != null && templateType.isNotEmpty)
        'template_type': templateType,
      if (language != null && language.isNotEmpty) 'language': language,
      if (size != null && size.isNotEmpty) 'size': size,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final endpoint = '/$_templates?$queryString';

    debugPrint('🔍 SEARCH: $endpoint');

    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(endpoint: endpoint, method: ApiMethod.get),
      fromJson: (json) => json,
    );
  }
}
