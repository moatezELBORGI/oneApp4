import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../models/inventory_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class InventoryService {
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

  Future<InventoryModel> createInventory({
    required String contractId,
    required String type,
    required DateTime inventoryDate,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/inventories'),
      headers: headers,
      body: jsonEncode({
        'contractId': contractId,
        'type': type,
        'inventoryDate': inventoryDate.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode == 200) {
      return InventoryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create inventory: ${response.body}');
    }
  }

  Future<InventoryModel> getInventoryById(String inventoryId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return InventoryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load inventory: ${response.body}');
    }
  }

  Future<List<InventoryModel>> getInventoriesByContract(String contractId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/inventories/contract/$contractId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InventoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load inventories: ${response.body}');
    }
  }

  Future<InventoryModel> updateInventory(String inventoryId, InventoryModel inventory) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId'),
      headers: headers,
      body: jsonEncode(inventory.toJson()),
    );

    if (response.statusCode == 200) {
      return InventoryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update inventory: ${response.body}');
    }
  }

  Future<InventoryModel> signInventoryByOwner(String inventoryId, String signatureData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId/sign-owner'),
      headers: headers,
      body: jsonEncode({'signatureData': signatureData}),
    );

    if (response.statusCode == 200) {
      return InventoryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to sign inventory: ${response.body}');
    }
  }

  Future<InventoryModel> signInventoryByTenant(String inventoryId, String signatureData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId/sign-tenant'),
      headers: headers,
      body: jsonEncode({'signatureData': signatureData}),
    );

    if (response.statusCode == 200) {
      return InventoryModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to sign inventory: ${response.body}');
    }
  }

  Future<void> updateRoomEntry(
    String inventoryId,
    String roomEntryId,
    String description,
  ) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId/rooms/$roomEntryId'),
      headers: headers,
      body: jsonEncode({'description': description}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update room entry: ${response.body}');
    }
  }

  Future<void> uploadRoomPhoto(
    String inventoryId,
    String roomEntryId,
    File file,
  ) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId/rooms/$roomEntryId/photos'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final mimeTypeParts = mimeType.split('/');

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
    ));

    final response = await request.send();
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to upload photo: $responseBody');
    }
  }

  Future<List<InventoryRoomPhotoModel>> getRoomPhotos(
    String inventoryId,
    String roomEntryId,
  ) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId/rooms/$roomEntryId/photos'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InventoryRoomPhotoModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load room photos: ${response.body}');
    }
  }

  Future<void> deleteRoomPhoto(
    String inventoryId,
    String roomEntryId,
    String photoId,
  ) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${Constants.baseUrl}/inventories/$inventoryId/rooms/$roomEntryId/photos/$photoId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete photo: ${response.body}');
    }
  }
}
