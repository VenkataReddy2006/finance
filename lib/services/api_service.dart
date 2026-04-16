import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/person.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web, or your Server IP
  static const String baseUrl = 'https://finance-backend-1-d8b7.onrender.com/api';

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // --- Groups ---

  Future<List<Group>> getGroups() async {
    if (_userId == null) return [];
    try {
      final response = await http.get(Uri.parse('$baseUrl/groups/$_userId'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((g) => Group.fromJson(g)).toList();
      }
      throw Exception('Failed to load groups');
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<Group> createGroup(String name, String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'name': name,
          'id': id,
          'orderIndex': 0,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        return Group.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create group');
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<void> deleteGroup(String id) async {
    await http.delete(Uri.parse('$baseUrl/groups/$id'));
  }

  Future<void> updateGroup(Group group) async {
    await http.put(
      Uri.parse('$baseUrl/groups/${group.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(group.toJson()),
    );
  }

  // --- People ---

  Future<List<Person>> getPeople() async {
    if (_userId == null) return [];
    try {
      final response = await http.get(Uri.parse('$baseUrl/people/$_userId'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((p) => Person.fromJson(p)).toList();
      }
      throw Exception('Failed to load people');
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<Person> createPerson(Person person) async {
    final Map<String, dynamic> data = person.toJson();
    data['userId'] = _userId;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/people'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        return Person.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to create person');
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<void> updatePerson(Person person) async {
    await http.put(
      Uri.parse('$baseUrl/people/${person.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(person.toJson()),
    );
  }

  Future<void> deletePerson(String id) async {
    await http.delete(Uri.parse('$baseUrl/people/$id'));
  }

  // --- Payments ---

  Future<void> addPayment(String personId, Map<String, dynamic> payment) async {
    await http.post(
      Uri.parse('$baseUrl/people/$personId/payments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payment),
    );
  }

  Future<void> deletePayment(String personId, String paymentId) async {
    await http.delete(Uri.parse('$baseUrl/people/$personId/payments/$paymentId'));
  }

  // --- Account Mirroring ---

  Future<void> syncUser(String userId, String email, String password, {String? name, String? phoneNumber, String? profileImage}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'email': email,
          'password': password,
          'name': name,
          'phoneNumber': phoneNumber,
          'profileImage': profileImage,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to sync credentials to MongoDB');
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  Future<String> getEmailByPhone(String phoneNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/by-phone/$phoneNumber'))
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['email'];
      }
      throw Exception('No account found with this phone number');
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  // --- Helper for Errors ---
  void _handleApiError(Object e) {
    String errorMsg = e.toString();
    if (errorMsg.contains('TimeoutException') || errorMsg.contains('Future not completed')) {
      debugPrint('API Error: Connection Timed Out. Please check your network or backend server.');
    } else if (errorMsg.contains('Connection refused') || errorMsg.contains('SocketException')) {
      debugPrint('API Error: Server Unreachable at $baseUrl');
    } else {
      debugPrint('API Error: $errorMsg');
    }
  }

  // --- Account Deletion ---

  Future<void> deleteUserData(String userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/$userId'))
          .timeout(const Duration(seconds: 30));
      
      // Treat 404 (Already gone/never existed) or 200 (Success) as OK!
      if (response.statusCode != 200 && response.statusCode != 404) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete cloud data');
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  // --- Signup Verification ---

  Future<void> sendSignupOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-signup-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to send verification code');
    }
  }

  Future<void> verifySignupOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-signup-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'otp': otp}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Invalid or expired OTP');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'))
          .timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      _handleApiError(e);
      return null;
    }
  }

  Future<void> updateProfileImage(String userId, String imageBase64) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'profileImage': imageBase64}),
      ).timeout(const Duration(seconds: 30));
 
      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to update profile image');
      }
    } catch (e) {
      _handleApiError(e);
      rethrow;
    }
  }

  // --- Password Recovery ---

  Future<void> sendForgotPasswordOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-forgot-password-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      String errorMsg = data['error'] ?? 'Failed to send reset code';
      
      if (errorMsg.contains('ETIMEDOUT') || errorMsg.contains('27017') || errorMsg.contains('buffering timed out')) {
        errorMsg = 'Database connection failed. Please ensure your IP is whitelisted in MongoDB Atlas.';
      }
      throw Exception(errorMsg);
    }
  }

  Future<void> verifyForgotPasswordOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-forgot-password-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'otp': otp}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Invalid or expired OTP');
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to reset password');
    }
  }

  Future<void> resetPasswordByPhone(String phoneNumber, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password-phone'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'newPassword': newPassword,
      }),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Failed to reset password');
    }
  }

  Future<void> changePassword(String userId, String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Incorrect old password or system error');
    }
  }
}
