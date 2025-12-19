import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lease_contract_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class LeaseContractService {
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

  Future<LeaseContractModel> createContract({
    required String apartmentId,
    required String ownerId,
    required String tenantId,
    required DateTime startDate,
    DateTime? endDate,
    required double initialRentAmount,
    double? depositAmount,
    double? chargesAmount,
    required String regionCode,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/lease-contracts'),
      headers: headers,
      body: jsonEncode({
        'apartmentId': apartmentId,
        'ownerId': ownerId,
        'tenantId': tenantId,
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate?.toIso8601String().split('T')[0],
        'initialRentAmount': initialRentAmount,
        'depositAmount': depositAmount,
        'chargesAmount': chargesAmount,
        'regionCode': regionCode,
      }),
    );

    if (response.statusCode == 200) {
      return LeaseContractModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create contract: ${response.body}');
    }
  }

  Future<List<LeaseContractModel>> getMyContracts() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/lease-contracts/my-contracts'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LeaseContractModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load contracts: ${response.body}');
    }
  }

  Future<LeaseContractModel> getContractById(String contractId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/lease-contracts/$contractId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return LeaseContractModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load contract: ${response.body}');
    }
  }

  Future<LeaseContractModel> signContractByOwner(String contractId, String signatureData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/lease-contracts/$contractId/sign-owner'),
      headers: headers,
      body: jsonEncode({'signatureData': signatureData}),
    );

    if (response.statusCode == 200) {
      return LeaseContractModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to sign contract: ${response.body}');
    }
  }

  Future<LeaseContractModel> signContractByTenant(String contractId, String signatureData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/lease-contracts/$contractId/sign-tenant'),
      headers: headers,
      body: jsonEncode({'signatureData': signatureData}),
    );

    if (response.statusCode == 200) {
      return LeaseContractModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to sign contract: ${response.body}');
    }
  }

  Future<RentIndexationModel> indexRent({
    required String contractId,
    required double indexationRate,
    double? baseIndex,
    double? newIndex,
    String? notes,
  }) async {
    final headers = await _getHeaders();
    final queryParams = {
      'indexationRate': indexationRate.toString(),
      if (baseIndex != null) 'baseIndex': baseIndex.toString(),
      if (newIndex != null) 'newIndex': newIndex.toString(),
      if (notes != null) 'notes': notes,
    };

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/lease-contracts/$contractId/index-rent').replace(queryParameters: queryParams),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return RentIndexationModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to index rent: ${response.body}');
    }
  }

  Future<String> generateContractPdf(String contractId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/lease-contracts/$contractId/generate-pdf'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to generate PDF: ${response.body}');
    }
  }
}
