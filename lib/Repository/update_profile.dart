import '../Api Model/business_model.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class UpdateProfileRepository {
  UpdateProfileRepository._();

  static final UpdateProfileRepository instance = UpdateProfileRepository._();

  Future<ApiResult<BusinessApiModel>> updateBusiness({
    required String businessUid,
    String? name,
    String? industry,
    String? description,
    String? logoS3Key,
    String? coverS3Key,
    List<dynamic>? brandColors,
    int? watermarkEnabled,
    String? headingFontId,
    String? bodyFontId,
    String? city,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? whatsapp,
    String? email,
    String? website,
    Map<String, dynamic>? socialLinks,
    Map<String, dynamic>? operatingHours,
  }) async {
    final Map<String, dynamic> payload = {
      "name": name,
      "industry": industry,
      "description": description,
      "logo_s3_key": logoS3Key,
      "cover_s3_key": coverS3Key,
      "brand_colors": brandColors,
      "watermark_enabled": watermarkEnabled,
      "heading_font_id": headingFontId,
      "body_font_id": bodyFontId,
      "city": city,
      "state": state,
      "address": address,
      "latitude": latitude,
      "longitude": longitude,
      "phone": phone,
      "whatsapp": whatsapp,
      "email": email,
      "website": website,
      "social_links": socialLinks,
      "operating_hours": operatingHours,
    };

    // Remove null values
    payload.removeWhere((key, value) => value == null);

    // Remove empty strings
    payload.removeWhere(
      (key, value) => value is String && value.trim().isEmpty,
    );

    return ApiRepository.instance.request<BusinessApiModel>(
      config: ApiRequestConfig(
        endpoint: "${ApiEndpoints.Business}/$businessUid",
        method: ApiMethod.patch,
        body: payload,
      ),
      fromJson: (json) {
        // API response may return:
        // { success: true, data: {...} }

        if (json["data"] is Map<String, dynamic>) {
          return BusinessApiModel.fromJson(json["data"]);
        }

        return BusinessApiModel.fromJson(json);
      },
    );
  }
}
