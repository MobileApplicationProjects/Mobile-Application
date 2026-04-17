import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'auth_service.dart';

class RoomService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createRoom({
    required String name,
    required int durationDays,
    required List<String> invites,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.roomsEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'duration_days': durationDays,
        'invites': invites,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create room');
    }
  }

  Future<List<dynamic>> listRooms() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.roomsEndpoint}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['rooms'] ?? [];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to list rooms');
    }
  }

  Future<void> acceptInvite(String roomId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.roomsEndpoint}/$roomId/accept'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to accept invite');
    }
  }

  Future<Map<String, dynamic>> getLeaderboard(String roomId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.roomsEndpoint}/$roomId/leaderboard'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to get leaderboard');
    }
  }
}
