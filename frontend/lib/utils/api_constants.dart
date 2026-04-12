import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api'; // iOS Simulator
    }
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
