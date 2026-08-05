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

  static const String cdnImageUrl =
      'https://temp-m2b-assets.s3.ap-south-1.amazonaws.com';

  // ── Auth ──────────────────────────────────────────────────
  static const String login = '/login/mobile/authenticate';

  // ── Member ────────────────────────────────────────────────
  static String getMember(String memberId) => '/member/getmember/$memberId';
  static const String addMember = '/member/addmember';

  static String updateMember(String memberId) => '/member/mobile/$memberId';
  static String changeProfileImage(String memberId) =>
      '/member/$memberId/profile-photo';

  // ── Plans ─────────────────────────────────────────────────
  static String getPlans(String gymId) => '/planmaster/plan/$gymId/active';

  // ── Attendance ────────────────────────────────────────────
  static const String markAttendance = '/attendance/mark';

  // ── Member Workouts ───────────────────────────────────────
  static String getMemberWorkouts(String gymId, String memberId, String date) =>
      '/member-workouts/get-by-gymid/$gymId/$memberId/$date';

  static const String dashboard = '/dashboard/mobiledashboard';

  // ── Diet Log ──────────────────────────────────────────────
  static String getWeeklyDietCompliance(String memberId, String weekNumber) =>
      '/member-diet-log/weekly-compliance/$memberId/$weekNumber';

  // ── Trainer ──────────────────────────────────────────────
  static String getTrainer(String memberId, String gymId) =>
      '/trainer/gettrainer/$gymId/$memberId';
}
