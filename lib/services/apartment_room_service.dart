import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/apartment_room_model.dart';
import '../models/room_type_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import '../widgets/equipment_selector_widget.dart';

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

  Future<void> uploadRoomImage(String roomId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/apartment-rooms/$roomId/upload-image'),
      );
      final token = await _getToken();

      request.headers['Authorization'] = 'Bearer $token';

      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      final mimeType = _getMimeType(imageFile.path);

      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> deleteRoomImage(int imageId) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/apartment-rooms/images/$imageId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      throw Exception('Error deleting image: $e');
    }
  }

  Future<List<RoomTypeModel>> getAllRoomTypes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/apartment-rooms/room-types'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => RoomTypeModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load room types: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching room types: $e');
    }
  }

  Future<String> createRoomWithEquipments({
    required String apartmentId,
    required String roomName,
    required String roomTypeId,
    List<SelectedEquipment>? equipments,
  }) async {
    try {
      final headers = await _getHeaders();

      final equipmentsData = equipments?.map((eq) {
        return {
          'name': eq.template.name,
          'description': eq.template.description,
        };
      }).toList() ?? [];

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/apartment-rooms/with-equipments'),
        headers: headers,
        body: jsonEncode({
          'apartmentId': apartmentId,
          'roomName': roomName,
          'roomTypeId': roomTypeId,
          'equipments': equipmentsData,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final roomId = responseData['id']?.toString() ?? '';

        if (equipments != null && equipments.isNotEmpty) {
          for (var i = 0; i < equipments.length; i++) {
            final equipment = equipments[i];
            final equipmentId = responseData['equipments']?[i]?['id']?.toString();

            if (equipment.images.isNotEmpty && equipmentId != null) {
              for (var image in equipment.images) {
                await _uploadEquipmentImage(equipmentId, image);
              }
            }
          }
        }

        return roomId;
      } else {
        throw Exception('Failed to create room: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating room with equipments: $e');
    }
  }

  Future<void> _uploadEquipmentImage(String equipmentId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/apartment-rooms/equipments/$equipmentId/upload-image'),
      );
      final token = await _getToken();

      request.headers['Authorization'] = 'Bearer $token';

      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      final mimeType = _getMimeType(imageFile.path);

      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload equipment image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading equipment image: $e');
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
