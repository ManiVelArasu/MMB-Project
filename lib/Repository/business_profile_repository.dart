import '../Api Model/frames_categories.dart';
import '../Api Model/frames_detail_model.dart';
import '../Api Model/frames_model.dart';
import '../Api Model/key_words_model.dart';
import '../Api Model/mine_frames.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class BusinessProfileRepository {
  BusinessProfileRepository._();

  static final BusinessProfileRepository instance =
      BusinessProfileRepository._();

  Future<ApiResult<KeyWordsModel>> industryKeyWords(String industrySlug) {
    return ApiRepository.instance.request<KeyWordsModel>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.industryKeyWords(industrySlug),
        method: ApiMethod.get,
      ),
      fromJson: (json) => KeyWordsModel.fromJson(json),
    );
  }

  Future<ApiResult<FramesData>> frames(String type, {String? category}) {
    return ApiRepository.instance.request<FramesData>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.frames,
        method: ApiMethod.get,
        queryParams: {
          "frame_type": type,
          if (category != null && category.isNotEmpty) "category": category,
        },
      ),
      fromJson: (json) => FramesData.fromJson(json),
    );
  }

  Future<ApiResult<FramesCategories>> framesCategory(String type) {
    return ApiRepository.instance.request<FramesCategories>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.framesCategories,
        method: ApiMethod.get,
        queryParams: {"frame_type": type},
      ),
      fromJson: (json) => FramesCategories.fromJson(json),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> purchaseFrame(String frameUid) {
    return ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: '/frames/$frameUid/purchase',
        method: ApiMethod.post,
      ),
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  Future<ApiResult<MineFrames>> framesMine() {
    return ApiRepository.instance.request<MineFrames>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.framesMine,
        method: ApiMethod.get,
      ),
      fromJson: (json) => MineFrames.fromJson(json),
    );
  }

  Future<ApiResult<FramesDetailScreen>> frameDetail(String frameUid) {
    return ApiRepository.instance.request<FramesDetailScreen>(
      config: ApiRequestConfig(
        endpoint: '/frames/$frameUid',
        method: ApiMethod.get,
      ),
      fromJson: (json) => FramesDetailScreen.fromJson(json),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> updateBusinessFramesDetails({
    required String businessUid,
    required String name,
    required String phone,
    String? email,
    String? website,
    String? logo_s3_key,
  }) {
    return ApiRepository.instance.request<Map<String, dynamic>>(
      config: ApiRequestConfig(
        endpoint: "${ApiEndpoints.Business}/$businessUid",
        method: ApiMethod.patch,
        body: {
          "name": name,
          "phone": phone,
          if (email != null && email.isNotEmpty) "email": email,
          if (website != null && website.isNotEmpty) "website": website,
          if (logo_s3_key != null && logo_s3_key.isNotEmpty)
            "logo_s3_key": logo_s3_key,
        },
      ),
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );
  }
}
