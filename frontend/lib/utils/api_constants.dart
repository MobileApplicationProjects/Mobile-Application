import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // ============================================================
  // ⚡ เปลี่ยนเป็น true เมื่อ Deploy ขึ้น Render แล้ว
  // ⚡ เปลี่ยนเป็น false เมื่อต้องการทดสอบกับเครื่องตัวเอง
  // ============================================================
  static const bool _useProduction = false;

  // 👇 ใส่ URL ที่ได้จาก Render ตรงนี้ (ไม่ต้องมี /api ต่อท้าย)
  static const String _productionHost = 'https://YOUR-APP-NAME.onrender.com';

  static String get baseUrl {
    // Production mode: ใช้ URL ของ Render
    if (_useProduction) {
      return '$_productionHost/api';
    }

    // Development mode: ใช้ localhost ตามเดิม
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

  // Rooms endpoints
  static const String roomsEndpoint = '/rooms';

  // Upload endpoints
  static const String uploadImageEndpoint = '/uploads/image';

  // Health endpoints
  static const String healthSyncEndpoint = '/health/sync';
  static const String healthMetricsEndpoint = '/health/metrics';
  static const String healthYearlyMetricsEndpoint = '/health/metrics/yearly';
  static const String healthStreakEndpoint = '/health/metrics/streak';
}
