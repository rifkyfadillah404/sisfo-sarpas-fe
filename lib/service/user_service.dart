import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Fetch user data from API using token
  Future<Map<String, dynamic>> fetchUserData(String token) async {
    try {
      print('Fetching user data with token: ${token.substring(0, 10)}...');

      // First try the /user endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API response data: $data');

        if (data['user'] != null) {
          return data['user'];
        } else if (data['id'] != null) {
          // Some APIs return the user object directly
          return data;
        }
      }

      // If the first endpoint fails, try the /me endpoint which is common in Laravel APIs
      final meResponse = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('ME API response status: ${meResponse.statusCode}');

      if (meResponse.statusCode == 200) {
        final data = jsonDecode(meResponse.body);
        print('ME API response data: $data');

        if (data['user'] != null) {
          return data['user'];
        } else if (data['id'] != null) {
          return data;
        }
      }

      // If API calls fail, try to get data from SharedPreferences
      print('API calls failed, falling back to SharedPreferences');
      return await getUserFromPrefs();
    } catch (e) {
      print('Error fetching user data: $e');
      // If there's an error, try to get data from SharedPreferences
      return await getUserFromPrefs();
    }
  }

  // Get user data from SharedPreferences
  Future<Map<String, dynamic>> getUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Get user ID and name from SharedPreferences
    final userId = prefs.getInt('user_id');
    final userName = prefs.getString('user_name');
    final email = prefs.getString('email');

    print('SharedPreferences data:');
    print('- userId: $userId');
    print('- userName: $userName');
    print('- email: $email');

    // If we have data in SharedPreferences, return it
    if (userId != null) {
      final userData = {
        'id': userId,
        'name': userName ?? 'User SISFO',
        'email': email ?? 'user@example.com',
      };
      print('Returning user data from SharedPreferences: $userData');
      return userData;
    }

    // If no data is available, return default values
    print('No user data in SharedPreferences, returning default values');
    return {'id': 0, 'name': 'User SISFO', 'email': 'user@example.com'};
  }
}
