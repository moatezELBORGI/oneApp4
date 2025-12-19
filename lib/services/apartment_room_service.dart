import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/apartment_room_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApartmentRoomService {
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

  Future<ApartmentRoomModel> createRoom({
    required String apartmentId,
    required String roomName,
    String? roomType,
    String? description,
    int orderIndex = 0,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/apartment-rooms'),
      headers: headers,
      body: jsonEncode({
        'apartmentId': apartmentId,
        'roomName': roomName,
        'roomType': roomType,
        'description': description,
        'orderIndex': orderIndex,
      }),
    );

    if (response.statusCode == 200) {
      return ApartmentRoomModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create room: ${response.body}');
    }
  }

  Future<List<ApartmentRoomModel>> getRoomsByApartment(String apartmentId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/apartment-rooms/apartment/$apartmentId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ApartmentRoomModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load rooms: ${response.body}');
    }
  }

  Future<ApartmentRoomModel> updateRoom(String roomId, ApartmentRoomModel room) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/apartment-rooms/$roomId'),
      headers: headers,
      body: jsonEncode(room.toJson()),
    );

    if (response.statusCode == 200) {
      return ApartmentRoomModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update room: ${response.body}');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${Constants.baseUrl}/apartment-rooms/$roomId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete room: ${response.body}');
    }
  }

  Future<ApartmentRoomPhotoModel> addPhotoToRoom({
    required String roomId,
    required String photoUrl,
    String? caption,
    int orderIndex = 0,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/apartment-rooms/$roomId/photos?photoUrl=$photoUrl&caption=$caption&orderIndex=$orderIndex'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return ApartmentRoomPhotoModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add photo: ${response.body}');
    }
  }
}
