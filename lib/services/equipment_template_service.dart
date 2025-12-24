import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipment_template_model.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EquipmentTemplateService {
  static const String baseUrl = '${Constants.baseUrl}/equipment-templates';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<EquipmentTemplateModel>> getAllTemplates() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => EquipmentTemplateModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load equipment templates');
      }
    } catch (e) {
      throw Exception('Error fetching equipment templates: $e');
    }
  }

  Future<List<EquipmentTemplateModel>> getTemplatesByRoomType(int roomTypeId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/room-type/$roomTypeId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => EquipmentTemplateModel.fromJson(json)).toList();
      } else {
        // Log message clair pour erreur HTTP
        print('❌ Error: Failed to load equipment templates for room type $roomTypeId. Status code: ${response.statusCode}');
        throw Exception('Failed to load equipment templates for room type $roomTypeId');
      }
    } catch (e) {
      // Log message clair pour erreur générale
      print('❌ Exception caught while fetching equipment templates for room type $roomTypeId: $e');
      throw Exception('Error fetching equipment templates for room type $roomTypeId');
    }
  }

  Future<EquipmentTemplateModel> createTemplate(EquipmentTemplateModel template) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(template.toJson()),
      );

      if (response.statusCode == 200) {
        return EquipmentTemplateModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to create equipment template');
      }
    } catch (e) {
      throw Exception('Error creating equipment template: $e');
    }
  }

  Future<EquipmentTemplateModel> updateTemplate(String id, EquipmentTemplateModel template) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(template.toJson()),
      );

      if (response.statusCode == 200) {
        return EquipmentTemplateModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to update equipment template');
      }
    } catch (e) {
      throw Exception('Error updating equipment template: $e');
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete equipment template');
      }
    } catch (e) {
      throw Exception('Error deleting equipment template: $e');
    }
  }
}
