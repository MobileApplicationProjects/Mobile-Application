import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'auth_service.dart';
import '../utils/api_constants.dart';

class LocationService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Start a new tracking session
  Future<String> startSession() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.locationSessionsEndpoint}'),
      headers: await _headers(),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['sessionId'] as String;
    } else {
      throw Exception('Failed to start location session');
    }
  }

  /// Add batch of points to a session
  Future<void> addPoints(String sessionId, List<LatLng> points) async {
    final payload = points.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude,
      'recordedAt': DateTime.now().toIso8601String(),
    }).toList();

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.locationPointsEndpoint(sessionId)}'),
      headers: await _headers(),
      body: jsonEncode({'points': payload}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to upload location points');
    }
  }

  /// End a tracking session
  Future<void> endSession(String sessionId) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.locationEndSessionEndpoint(sessionId)}'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to end location session');
    }
  }

  /// Get latest session with points
  Future<Map<String, dynamic>?> getLatestSession() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.locationLatestSessionEndpoint}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['session'] as Map<String, dynamic>?;
    }
    return null;
  }
}
