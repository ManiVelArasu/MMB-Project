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
        body: {"name": name, "content": content},
      ),
      fromJson: (json) {
        return json;
      },
    );
  }
}
