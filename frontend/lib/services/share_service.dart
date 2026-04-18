import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/api_constants.dart';

class ShareService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch the aggregated today summary for the share card
  Future<Map<String, dynamic>> getTodaySummary() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.shareTodayEndpoint}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch today summary');
    }
  }

  /// Log a share event
  Future<void> logShare(String platform, Map<String, dynamic>? data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.shareLogEndpoint}'),
      headers: await _headers(),
      body: jsonEncode({
        'platform': platform,
        'data': data,
      }),
    );

    if (response.statusCode != 201) {
      // Non-critical error, just log it
      print('Failed to log share event: ${response.statusCode}');
    }
  }
}
