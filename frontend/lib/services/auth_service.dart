import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_constants.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';

  /// Check if user is already logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Save token
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
      }
      
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Sign in failed');
    }
  }

  /// Sign up with user details
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String gender,
    required double weight,
    required double height,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'weight': weight,
        'height': height,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      
      // Save token if immediate login is expected
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
      }
      
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Sign up failed');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  /// Request password reset
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    // This is a placeholder as the backend doesn't have this API yet.
    await Future.delayed(const Duration(seconds: 1));

    return {
      'success': true,
      'message': 'Password reset link logic pending backend implementation.',
    };
  }

  /// Upload image then save URL as avatar for the logged-in user
  Future<String> uploadAndSetAvatar(XFile imageFile) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    // Step 1: Upload image file
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

    final streamed = await request.send();
    final uploadResponse = await http.Response.fromStream(streamed);
    if (uploadResponse.statusCode != 200) {
      throw Exception('Image upload failed');
    }
    final uploadData = jsonDecode(uploadResponse.body);
    final avatarUrl = uploadData['url'] as String;

    // Step 2: Save URL to user profile
    final saveResponse = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/account/avatar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'avatarUrl': avatarUrl}),
    );
    if (saveResponse.statusCode != 200) {
      throw Exception('Failed to save avatar URL');
    }

    return avatarUrl;
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  /// Fetches token history transactions
  Future<List<dynamic>> fetchTransactions() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/account/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to fetch transactions: ${response.statusCode}');
    }
  }
}
