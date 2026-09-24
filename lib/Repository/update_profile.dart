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

  Future<ApiResult<dynamic>> updatePersonal({
    String? name,
    String? industry,
    String? description,
    String? profile_photo_s3_key,
    String? coverS3Key,
    String? city,
    String? state,
    String? address,
    double? latitude,
    double? longitude,
    String? whatsapp,
    String? email,
    String? website,
  }) async {
    final Map<String, dynamic> payload = {};

    // Add only if value is available
    if (name != null && name.trim().isNotEmpty) {
      payload["name"] = name.trim();
    }

    if (industry != null && industry.trim().isNotEmpty) {
      payload["industry"] = industry.trim();
    }

    if (description != null && description.trim().isNotEmpty) {
      payload["description"] = description.trim();
    }

    if (profile_photo_s3_key != null &&
        profile_photo_s3_key.trim().isNotEmpty) {
      payload["profile_photo_s3_key"] =
          profile_photo_s3_key.trim();
    }

    if (coverS3Key != null &&
        coverS3Key.trim().isNotEmpty) {
      payload["cover_s3_key"] = coverS3Key.trim();
    }

    if (city != null && city.trim().isNotEmpty) {
      payload["city"] = city.trim();
    }

    if (state != null && state.trim().isNotEmpty) {
      payload["state"] = state.trim();
    }

    if (address != null && address.trim().isNotEmpty) {
      payload["address"] = address.trim();
    }

    if (latitude != null) {
      payload["latitude"] = latitude;
    }

    if (longitude != null) {
      payload["longitude"] = longitude;
    }

    if (whatsapp != null && whatsapp.trim().isNotEmpty) {
      payload["whatsapp"] = whatsapp.trim();
    }

    if (email != null && email.trim().isNotEmpty) {
      payload["email"] = email.trim();
    }

    if (website != null && website.trim().isNotEmpty) {
      payload["website"] = website.trim();
    }

    return ApiRepository.instance.request<dynamic>(
      config: ApiRequestConfig(
        endpoint: ApiEndpoints.user,
        method: ApiMethod.patch,
        body: payload,
      ),
      fromJson: (json) {
        return json;
      },
    );
  }
}
