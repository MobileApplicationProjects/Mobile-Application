import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'auth_service.dart';

class ChallengeService {
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getChallenges() async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.challengesEndpoint}');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load challenges: ${response.body}');
    }
  }

  Future<void> createChallenge(Map<String, dynamic> challengeData) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.challengesEndpoint}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(challengeData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create challenge: ${response.body}');
    }
  }

  Future<void> updateChallenge(int id, Map<String, dynamic> challengeData) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.challengesEndpoint}/$id');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(challengeData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update challenge: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getLatestChallenge() async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.challengesEndpoint}/latest');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception('Failed to load latest challenge: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> claimChallenge(int id) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.challengesEndpoint}/claim/$id');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to claim challenge: ${response.body}');
    }
  }
}
