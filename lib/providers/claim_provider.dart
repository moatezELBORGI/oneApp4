import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mgi/models/faq_topic.dart';
import 'package:mgi/services/api_service.dart';
import '../models/chat_request.dart';
import '../models/chat_response.dart';
import '../models/claim_model.dart';
import '../services/claim_service.dart';

class ClaimProvider with ChangeNotifier {
  final ClaimService _claimService = ClaimService();
  final ApiService _ApiService = ApiService();
  List<FAQTopic> _topics = [];
  List<FAQTopic> get topics => _topics;
  ChatResponse? lastResponse;
  List<ClaimModel> _claims = [];
  ClaimModel? _selectedClaim;
  bool _isLoading = false;
  String? _errorMessage;
  bool isTyping = false;

  List<ClaimModel> get claims => _claims;
  ClaimModel? get selectedClaim => _selectedClaim;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  Future<ChatResponse> sendChat(String message, String buildingId) async {
    isTyping = true;
    notifyListeners();

    try {
      final req = ChatRequest(message: message, buildingId: buildingId);
      lastResponse = await _ApiService.sendMessageChatbot(req);
      return lastResponse!;
    } finally {
      isTyping = false;
      notifyListeners();
    }
  }
  Future<void> loadClaims(String buildingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _claims = await _claimService.getClaimsByBuilding(buildingId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> fetchFaqTopics(String buildingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _ApiService.fetchFaqTopics(buildingId);
      _topics = result;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadClaimById(int claimId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedClaim = await _claimService.getClaimById(claimId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createClaim({
    required String apartmentId,
    required List<String> claimTypes,
    required String cause,
    required String description,
    String? insuranceCompany,
    String? insurancePolicyNumber,
    List<String>? affectedApartmentIds,
    List<File>? photos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newClaim = await _claimService.createClaim(
        apartmentId: apartmentId,
        claimTypes: claimTypes,
        cause: cause,
        description: description,
        insuranceCompany: insuranceCompany,
        insurancePolicyNumber: insurancePolicyNumber,
        affectedApartmentIds: affectedApartmentIds,
        photos: photos,
      );

      _claims.insert(0, newClaim);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClaimStatus(int claimId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedClaim = await _claimService.updateClaimStatus(claimId, status);

      final index = _claims.indexWhere((c) => c.id == claimId);
      if (index != -1) {
        _claims[index] = updatedClaim;
      }

      if (_selectedClaim?.id == claimId) {
        _selectedClaim = updatedClaim;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClaim(int claimId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _claimService.deleteClaim(claimId);
      _claims.removeWhere((c) => c.id == claimId);

      if (_selectedClaim?.id == claimId) {
        _selectedClaim = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedClaim() {
    _selectedClaim = null;
    notifyListeners();
  }
}
