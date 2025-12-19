import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mgi/services/storage_service.dart';
import '../utils/constants.dart';

class LeaseContractEnhancedService {
  Future<String?> _getToken() async {
    return await StorageService.getToken();
  }

  Future<List<Map<String, dynamic>>> getContractsByApartmentWithInventoryStatus(String apartmentId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/lease-contracts-enhanced/apartment/$apartmentId/with-inventory-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load contracts');
      }
    } catch (e) {
      throw Exception('Error loading contracts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStandardArticles(String regionCode) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/lease-contracts-enhanced/standard-articles?regionCode=$regionCode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load standard articles');
      }
    } catch (e) {
      throw Exception('Error loading standard articles: $e');
    }
  }

  Future<bool> canTerminateContract(String contractId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/lease-contracts-enhanced/$contractId/can-terminate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as bool;
      } else {
        throw Exception('Failed to check termination status');
      }
    } catch (e) {
      throw Exception('Error checking termination status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBuildingMembers(String buildingId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/admin/buildings/$buildingId/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load building members');
      }
    } catch (e) {
      throw Exception('Error loading building members: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNonResidentUsers({String? search}) async {
    try {
      final token = await _getToken();
      final uri = search != null && search.isNotEmpty
          ? Uri.parse('${Constants.baseUrl}/lease-contracts-enhanced/non-resident-users?search=$search')
          : Uri.parse('${Constants.baseUrl}/lease-contracts-enhanced/non-resident-users');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load non-resident users');
      }
    } catch (e) {
      throw Exception('Error loading non-resident users: $e');
    }
  }
}
