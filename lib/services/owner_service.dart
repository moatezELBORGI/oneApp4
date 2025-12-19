import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class OwnerService {
   Future<String?> _getToken() async {
    return await StorageService.getToken();
  }
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<User> createOwner({
    required String fname,
    required String lname,
    required String email,
    String? phoneNumber,
    required String buildingId,
    List<String>? apartmentIds,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/owners'),
      headers: headers,
      body: jsonEncode({
        'fname': fname,
        'lname': lname,
        'email': email,
        'phoneNumber': phoneNumber,
        'buildingId': buildingId,
        'apartmentIds': apartmentIds ?? [],
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create owner: ${response.body}');
    }
  }

  Future<List<User>> getOwnersByBuilding(String buildingId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/owners/building/$buildingId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load owners: ${response.body}');
    }
  }

  Future<void> assignApartmentToOwner(String apartmentId, String ownerId) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/owners/assign-apartment?apartmentId=$apartmentId&ownerId=$ownerId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign apartment: ${response.body}');
    }
  }
}
