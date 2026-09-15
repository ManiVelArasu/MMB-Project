import '../core/api/api_endpoints.dart';
import '../core/api/api_repository.dart';
import '../core/api/enums/api_method.dart';
import '../core/api/models/api_request_config.dart';
import '../core/api/models/api_result.dart';

class UpdateProfileRepository {
  UpdateProfileRepository._();

  static final UpdateProfileRepository instance = UpdateProfileRepository._();

  Future<ApiResult<dynamic>> updateBusinessDetails({
    required String businessUid,
    required String name,
    required String industry,
    required String description,
    required String logoS3Key,
    required String coverS3Key,
    required List<Map<String, dynamic>> brandColors,
    required int watermarkEnabled,
    String? headingFontId,
    String? bodyFontId,
    required String city,
    required String state,
    required String address,
    double? latitude,
    double? longitude,
    required String phone,
    required String whatsapp,
    required String email,
    required String website,
    required Map<String, dynamic> socialLinks,
    required Map<String, dynamic> operatingHours,
  }) {
    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.businessDetail(businessUid),
        method: ApiMethod.patch,

        body: {
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
        },
      ),

      fromJson: (json) => json,
    );
  }
}
