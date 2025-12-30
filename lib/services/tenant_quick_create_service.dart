import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'storage_service.dart';

class TenantQuickCreateService {
  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }

  Future<Map<String, dynamic>> createTenantQuick({
    required String fname,
    required String lname,
    required String email,
    required String phoneNumber,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/residents/tenant-quick'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fname': fname,
        'lname': lname,
        'email': email,
        'phoneNumber': phoneNumber,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception(errorBody);
    }
  }
}
