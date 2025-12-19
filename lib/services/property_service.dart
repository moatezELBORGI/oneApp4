import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class PropertyService {
  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }
  Future<List<PropertyModel>> getMyProperties(String buildingId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/owners/my-properties?buildingId=$buildingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PropertyModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      throw Exception('Error loading properties: $e');
    }
  }
}
