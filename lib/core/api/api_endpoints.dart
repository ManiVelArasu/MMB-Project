// ============================================================
// API ENDPOINTS
// Single source of truth for every endpoint path in the app.
// Usage: ApiEndpoints.login, ApiEndpoints.getMember(1), etc.
// ============================================================

class ApiEndpoints {
  ApiEndpoints._(); // no instances

  // ── Base URL Config ────────────────────────────────────────
  static const String baseUrl =
      'https://lightslategray-llama-976293.hostingersite.com/api/v1';

  // ── Asset Categories ──────────────────────────────────────
  static const String assetCategories = '/asset-categories';

  static const String industries = '/industries';

  static const String plan = '/plans';

  static const String templateSize = '/template-sizes';
  static const String themes = '/brand-series?preview_variants=4';
  static String themesDetail(String varientId) => '/variants/$varientId';

  static const String templateCategory = '/template-categories';
  static const String templates = '/templates';

  static const String cdnImageUrl =
      'https://temp-m2b-assets.s3.ap-south-1.amazonaws.com';

  // ── Auth ──────────────────────────────────────────────────
  static const String login = '/auth/send-otp';

  static const String verifyOtp = '/auth/verify-otp';

  ///refresh token
  static const String refreshToken = '/auth/refresh';

  static const String feedBack = '/feedback';

  static const String fileUpload = '/uploads/presign';

  static const String logout = '/auth/logout';

  static const String businessUpdate = '/businesses';

  static const String user = '/users/me';

  static const String language = '/languages';

  static const String notification = '/notifications';
}
