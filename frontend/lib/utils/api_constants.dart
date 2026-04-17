

class ApiConstants {
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

  // Upload endpoints
  static const String uploadImageEndpoint = '/uploads/image';

  // Health endpoints
  static const String healthSyncEndpoint = '/health/sync';
  static const String healthMetricsEndpoint = '/health/metrics';
  static const String healthYearlyMetricsEndpoint = '/health/metrics/yearly';
}
