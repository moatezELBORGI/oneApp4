import 'package:dio/dio.dart';
import '../models/apartment_complete_model.dart';
import '../models/room_type_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class ApartmentManagementService {
  final ApiService _apiService;

  ApartmentManagementService(this._apiService);

  Future<List<RoomTypeModel>> getSystemRoomTypes() async {
    try {
      final response = await _apiService.dio.get(
        '$baseUrl/apartment-management/room-types',
      );

      final List<dynamic> data = response.data;
      return data.map((json) => RoomTypeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch room types: $e');
    }
  }

  Future<List<RoomTypeModel>> getRoomTypes(int buildingId) async {
    try {
      final response = await _apiService.dio.get(
        '$baseUrl/apartment-management/room-types/$buildingId',
      );

      final List<dynamic> data = response.data;
      return data.map((json) => RoomTypeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch room types: $e');
    }
  }

  Future<ApartmentCompleteModel> createApartment(
    Map<String, dynamic> apartmentData,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '$baseUrl/apartment-management/apartments',
        data: apartmentData,
      );

      return ApartmentCompleteModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create apartment: $e');
    }
  }

  Future<ApartmentCompleteModel> getApartment(int apartmentId) async {
    try {
      final response = await _apiService.dio.get(
        '$baseUrl/apartment-management/apartments/$apartmentId',
      );

      return ApartmentCompleteModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch apartment: $e');
    }
  }

  Future<ApartmentCompleteModel> updateRooms(
    int apartmentId,
    List<Map<String, dynamic>> rooms,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '$baseUrl/apartment-management/apartments/$apartmentId/rooms',
        data: rooms,
      );

      return ApartmentCompleteModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update rooms: $e');
    }
  }

  Future<ApartmentCompleteModel> updateCustomFields(
    int apartmentId,
    List<Map<String, dynamic>> customFields,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '$baseUrl/apartment-management/apartments/$apartmentId/custom-fields',
        data: customFields,
      );

      return ApartmentCompleteModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update custom fields: $e');
    }
  }
}
