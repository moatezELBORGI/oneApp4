import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/apartment_complete_model.dart';
import '../models/room_type_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApartmentManagementService {

  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }

  Future<List<RoomTypeModel>> getSystemRoomTypes() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/apartment-management/room-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => RoomTypeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch room types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch room types: $e');
    }
  }

  Future<List<RoomTypeModel>> getRoomTypes(String buildingId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/apartment-management/room-types/$buildingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => RoomTypeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch room types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch room types: $e');
    }
  }

  Future<ApartmentCompleteModel> createApartment(
      Map<String, dynamic> apartmentData,
      ) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/apartment-management/apartments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(apartmentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentCompleteModel.fromJson(data);
      } else {
        throw Exception('Failed to create apartment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create apartment: $e');
    }
  }

  Future<ApartmentCompleteModel> getApartment(String apartmentId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/apartment-management/apartments/$apartmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentCompleteModel.fromJson(data);
      } else {
        throw Exception('Failed to fetch apartment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch apartment: $e');
    }
  }

  Future<ApartmentCompleteModel> updateRooms(
      String apartmentId,
      List<Map<String, dynamic>> rooms,
      ) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/apartment-management/apartments/$apartmentId/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(rooms),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentCompleteModel.fromJson(data);
      } else {
        throw Exception('Failed to update rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update rooms: $e');
    }
  }

  Future<ApartmentCompleteModel> updateCustomFields(
      String apartmentId,
      List<Map<String, dynamic>> customFields,
      ) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/apartment-management/apartments/$apartmentId/custom-fields'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(customFields),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ApartmentCompleteModel.fromJson(data);
      } else {
        throw Exception('Failed to update custom fields: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update custom fields: $e');
    }
  }
}
