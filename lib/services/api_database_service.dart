import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// A service class for saving and retrieving user data using a REST API
/// This is an example implementation showing how to communicate with a custom backend
class ApiDatabaseService {
  // Replace this with your actual API base URL
  final String _baseUrl = 'https://your-backend-api.com/api';
  
  // Get an API key or token (could be from secure storage or environment)
  Future<String> _getApiKey() async {
    // In a real implementation, you might get this from secure storage
    return 'YOUR_API_KEY';
  }
  
  // Headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final apiKey = await _getApiKey();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }
  
  // Save user data to external API
  Future<bool> saveUserData(User user, {String? fullName}) async {
    try {
      final headers = await _getHeaders();
      final userData = {
        'userId': user.uid,
        'name': fullName ?? user.displayName ?? 'User',
        'email': user.email,
        'photoUrl': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'authProvider': user.providerData.isNotEmpty 
            ? user.providerData[0].providerId 
            : 'firebase',
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: headers,
        body: jsonEncode(userData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('User data saved successfully to external API');
        return true;
      } else {
        print('Failed to save user data to API: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving user data to API: $e');
      return false;
    }
  }
  
  // Update user data in external API
  Future<bool> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: headers,
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        print('User data updated successfully in external API');
        return true;
      } else {
        print('Failed to update user data in API: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating user data in API: $e');
      return false;
    }
  }
  
  // Get user data from external API
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get user data from API: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user data from API: $e');
      return null;
    }
  }
  
  // Delete user data from external API
  Future<bool> deleteUserData(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('User data deleted successfully from external API');
        return true;
      } else {
        print('Failed to delete user data from API: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting user data from API: $e');
      return false;
    }
  }
} 