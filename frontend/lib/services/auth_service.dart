/// AuthService - Ready for API integration
/// Replace the mock implementations with actual API calls when the backend is ready.
class AuthService {
  // TODO: Replace with your actual API base URL
  // ignore: unused_field
  static const String _baseUrl = 'https://your-api-url.com/api';

  /// Sign in with email and password
  /// Returns a Map with user data on success, throws on failure
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    // TODO: Replace with actual API call
    // Example:
    // final response = await http.post(
    //   Uri.parse('$_baseUrl/auth/signin'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'email': email,
    //     'password': password,
    //   }),
    // );
    //
    // if (response.statusCode == 200) {
    //   return jsonDecode(response.body);
    // } else {
    //   throw Exception('Sign in failed: ${response.body}');
    // }

    // Mock: Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock: Simulate successful login
    if (email.isNotEmpty && password.isNotEmpty) {
      return {
        'success': true,
        'user': {
          'id': '1',
          'email': email,
          'firstName': 'User',
          'lastName': 'Test',
        },
        'token': 'mock_jwt_token_here',
      };
    } else {
      throw Exception('Email and password are required');
    }
  }

  /// Sign up with user details
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    required double weight,
    required double height,
    required String password,
  }) async {
    // TODO: Replace with actual API call
    // Example:
    // final response = await http.post(
    //   Uri.parse('$_baseUrl/auth/signup'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'email': email,
    //     'firstName': firstName,
    //     'lastName': lastName,
    //     'gender': gender,
    //     'weight': weight,
    //     'height': height,
    //     'password': password,
    //   }),
    // );
    //
    // if (response.statusCode == 201) {
    //   return jsonDecode(response.body);
    // } else {
    //   throw Exception('Sign up failed: ${response.body}');
    // }

    // Mock: Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true,
      'message': 'Account created successfully',
      'user': {
        'id': '1',
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      },
    };
  }

  /// Request password reset
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true,
      'message': 'Password reset link sent to $email',
    };
  }
}
