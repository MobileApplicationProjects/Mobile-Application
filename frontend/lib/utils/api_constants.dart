class ApiConstants {
  // ============================================================
  // ⚡ เปลี่ยนเป็น true เมื่อ Deploy ขึ้น Render แล้ว
  // ⚡ เปลี่ยนเป็น false เมื่อต้องการทดสอบกับเครื่องตัวเอง
  // ============================================================
  static const bool _useProduction = false;

  // 👇 ใส่ URL ที่ได้จาก Render ตรงนี้ (ไม่ต้องมี /api ต่อท้าย)
  static const String _productionHost = 'https://gao-api.onrender.com';

  static String get baseUrl {
    // Use Render hosted backend for all platforms
    return 'https://gao-api.onrender.com/api';
  }

  // Auth endpoints
  static const String loginEndpoint = '/account/login';
  static const String registerEndpoint = '/account/register';
  static const String profileEndpoint = '/account/profile';

  // Rewards endpoints
  static const String rewardsEndpoint = '/rewards';

  // Challenges endpoints
  static const String challengesEndpoint = '/challenges';

  // Rooms endpoints
  static const String roomsEndpoint = '/rooms';

  // Upload endpoints
  static const String uploadImageEndpoint = '/uploads/image';

  // Health endpoints
  static const String healthSyncEndpoint = '/health/sync';
  static const String healthMetricsEndpoint = '/health/metrics';
  static const String healthYearlyMetricsEndpoint = '/health/metrics/yearly';
  static const String healthStreakEndpoint = '/health/metrics/streak';

  // Location endpoints
  static const String locationSessionsEndpoint = '/location/sessions';
  static const String locationLatestSessionEndpoint = '/location/sessions/latest';
  static String locationPointsEndpoint(String sessionId) => '/location/sessions/$sessionId/points';
  static String locationEndSessionEndpoint(String sessionId) => '/location/sessions/$sessionId/end';

  // Share endpoints
  static const String shareTodayEndpoint = '/share/today';
  static const String shareLogEndpoint = '/share/log';
}
