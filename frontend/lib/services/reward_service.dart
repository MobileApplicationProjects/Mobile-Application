import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'auth_service.dart';
import '../utils/api_constants.dart';

class RewardService {
  final AuthService _authService = AuthService();

  /// Upload an image file to the backend, returns the public URL
  Future<String> uploadImage(XFile imageFile) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadImageEndpoint}');
    final bytes = await imageFile.readAsBytes();
    
    final mimeType = lookupMimeType(imageFile.name) ?? 'image/jpeg';
    final mimeSplit = mimeType.split('/');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Image upload failed (${response.statusCode})');
    }
  }

  /// Fetch all active rewards from the backend
  Future<List<Map<String, dynamic>>> getRewards() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rewardsEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load rewards: ${response.statusCode}');
    }
  }

  /// Create a new reward (Admin only)
  Future<void> createReward({
    required String partnerName,
    required String title,
    required String description,
    required int costInTokens,
    required int totalStock,
    required String? expiryDate,
    required String? imageUrl,
    bool isDonation = false,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = {
      'partner_name': partnerName,
      'title': title,
      'description': description,
      'cost_in_tokens': costInTokens,
      'total_stock': totalStock,
      'expiry_date': expiryDate,
      'image_url': imageUrl,
      'is_donation': isDonation,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rewardsEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return; // Success
    } else if (response.statusCode == 403) {
      throw Exception('Permission denied: Admin only');
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to create reward');
    }
  }

  /// Redeem a reward
  Future<void> redeemReward(int rewardId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rewardsEndpoint}/redeem'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rewardId': rewardId}),
    );

    if (response.statusCode == 200) {
      return; // Success
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to redeem reward');
    }
  }
}
