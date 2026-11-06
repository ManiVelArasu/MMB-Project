import 'package:flutter/foundation.dart';

import '../Api Model/Template_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

/// Template detail screen-ku thevaiyana APIs
///  1. GET templates/{uid}                          → single template
///  2. GET templates?category={id}&limit=9&offset=0 → same category templates
class TemplateDetailRepository {
  TemplateDetailRepository._();

  static final TemplateDetailRepository instance = TemplateDetailRepository._();

  /// GET templates/{templateUid}
  Future<ApiResult<TemplateModel>> templateByUid(String templateUid) {
    return ApiRepository.instance.request<TemplateModel>(
      config: ApiRequestConfig(
        endpoint: '${ApiEndpoints.templates}/$templateUid',
        method: ApiMethod.get,
      ),
      fromJson: (json) {
        debugPrint('📥 TEMPLATE BY UID RESPONSE: $json');

        final map = json as Map<String, dynamic>;

        // { success, data: {...template} }  (or the template itself)
        final data = map['data'];

        if (data is Map<String, dynamic>) {
          return TemplateModel.fromJson(data);
        }

        return TemplateModel.fromJson(map);
      },
    );
  }

  /// GET templates?category={categoryId}&limit=9&offset=0
  Future<ApiResult<TemplatesResponseModel>> templatesByCategoryId(
      int categoryId, {
        int limit = 9,
        int offset = 0,
      }) {
    return ApiRepository.instance.request<TemplatesResponseModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.templates,
        method: ApiMethod.get,
        queryParams: {
          'category': categoryId,
          'limit': limit,
          'offset': offset,
        },
      ),
      fromJson: (json) =>
          TemplatesResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }
}