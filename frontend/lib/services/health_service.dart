import 'dart:convert';
import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';
import '../utils/api_constants.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  // In health package version 13+, HealthFactory is renamed to Health
  final Health health = Health();
  final AuthService _authService = AuthService();

  final types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
  ];

  final permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<bool> authorize() async {
    await Permission.activityRecognition.request();
    bool? hasPermissions = await health.hasPermissions(
      types,
      permissions: permissions,
    );
    if (hasPermissions != true) {
      return await health.requestAuthorization(types, permissions: permissions);
    }
    return true;
  }

  Future<Map<String, dynamic>> fetchTodayMetrics() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    int steps = 0;
    double calories = 0.0;
    double distance = 0.0;

    try {
      bool authorized = await authorize();
      if (!authorized) {
        return {'steps': 0, 'calories': 0.0, 'distance': 0.0};
      }

      int? stepsData = await health.getTotalStepsInInterval(midnight, now);
      steps = stepsData ?? 0;

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.DISTANCE_WALKING_RUNNING,
        ],
      );

      for (var point in healthData) {
        if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          calories += double.tryParse(point.value.toString()) ?? 0.0;
        } else if (point.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
          distance += double.tryParse(point.value.toString()) ?? 0.0;
        }
      }

      return {'steps': steps, 'calories': calories, 'distance': distance};
    } catch (e) {
      print('Exception in fetchTodayMetrics: $e');
      return {'steps': 0, 'calories': 0.0, 'distance': 0.0};
    }
  }

  /// Pushes today's metrics to the backend
  Future<void> syncToday() async {
    try {
      final metrics = await fetchTodayMetrics();
      final token = await _authService.getToken();
      if (token == null) return;

      final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
      
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthSyncEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'date': dateStr,
          'steps': metrics['steps'],
          'calories': metrics['calories'],
          'distance': metrics['distance'],
        }),
      );
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  /// Fetches last 7 days metrics
  Future<List<Map<String, dynamic>>> fetchWeeklyMetrics() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 6));
      final dateFormat = DateFormat('dd/MM/yyyy');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthMetricsEndpoint}?startDate=${dateFormat.format(start)}&endDate=${dateFormat.format(now)}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Fetch weekly failed: $e');
      return [];
    }
  }

  /// Fetches yearly stats for heatmap
  Future<Map<String, int>> fetchYearlyMetrics(int year) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return {};

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthYearlyMetricsEndpoint}?year=$year'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((key, value) => MapEntry(key, value as int));
      }
      return {};
    } catch (e) {
      print('Fetch yearly failed: $e');
      return {};
    }
  }
}
