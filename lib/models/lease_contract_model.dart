class LeaseContractModel {
  final String id;
  final String apartmentId;
  final String ownerId;
  final String ownerName;
  final String tenantId;
  final String tenantName;
  final DateTime startDate;
  final DateTime? endDate;
  final double initialRentAmount;
  final double currentRentAmount;
  final double? depositAmount;
  final double? chargesAmount;
  final String regionCode;
  final String status;
  final DateTime? ownerSignedAt;
  final DateTime? tenantSignedAt;
  final String? ownerSignatureData;
  final String? tenantSignatureData;
  final String? pdfUrl;
  final List<RentIndexationModel> indexations;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaseContractModel({
    required this.id,
    required this.apartmentId,
    required this.ownerId,
    required this.ownerName,
    required this.tenantId,
    required this.tenantName,
    required this.startDate,
    this.endDate,
    required this.initialRentAmount,
    required this.currentRentAmount,
    this.depositAmount,
    this.chargesAmount,
    required this.regionCode,
    required this.status,
    this.ownerSignedAt,
    this.tenantSignedAt,
    this.ownerSignatureData,
    this.tenantSignatureData,
    this.pdfUrl,
    this.indexations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaseContractModel.fromJson(Map<String, dynamic> json) {
    return LeaseContractModel(
      id: json['id'],
      apartmentId: json['apartmentId'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName']  ,
      tenantId: json['tenantId'],
      tenantName: json['tenantName']  ,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      initialRentAmount: (json['initialRentAmount'] as num).toDouble(),
      currentRentAmount: (json['currentRentAmount'] as num).toDouble(),
      depositAmount: json['depositAmount'] != null ? (json['depositAmount'] as num).toDouble() : null,
      chargesAmount: json['chargesAmount'] != null ? (json['chargesAmount'] as num).toDouble() : null,
      regionCode: json['regionCode'],
      status: json['status'],
      ownerSignedAt: json['ownerSignedAt'] != null ? DateTime.parse(json['ownerSignedAt']) : null,
      tenantSignedAt: json['tenantSignedAt'] != null ? DateTime.parse(json['tenantSignedAt']) : null,
      ownerSignatureData: json['ownerSignatureData'],
      tenantSignatureData: json['tenantSignatureData'],
      pdfUrl: json['pdfUrl'],
      indexations: json['indexations'] != null
          ? (json['indexations'] as List).map((i) => RentIndexationModel.fromJson(i)).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'ownerId': ownerId,
      'tenantId': tenantId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'initialRentAmount': initialRentAmount,
      'currentRentAmount': currentRentAmount,
      'depositAmount': depositAmount,
      'chargesAmount': chargesAmount,
      'regionCode': regionCode,
      'status': status,
      'ownerSignedAt': ownerSignedAt?.toIso8601String(),
      'tenantSignedAt': tenantSignedAt?.toIso8601String(),
      'ownerSignatureData': ownerSignatureData,
      'tenantSignatureData': tenantSignatureData,
      'pdfUrl': pdfUrl,
    };
  }
}

class RentIndexationModel {
  final String id;
  final String contractId;
  final DateTime indexationDate;
  final double previousAmount;
  final double newAmount;
  final double indexationRate;
  final double? baseIndex;
  final double? newIndex;
  final String? notes;
  final DateTime createdAt;

  RentIndexationModel({
    required this.id,
    required this.contractId,
    required this.indexationDate,
    required this.previousAmount,
    required this.newAmount,
    required this.indexationRate,
    this.baseIndex,
    this.newIndex,
    this.notes,
    required this.createdAt,
  });

  factory RentIndexationModel.fromJson(Map<String, dynamic> json) {
    return RentIndexationModel(
      id: json['id'],
      contractId: json['contractId'],
      indexationDate: DateTime.parse(json['indexationDate']),
      previousAmount: (json['previousAmount'] as num).toDouble(),
      newAmount: (json['newAmount'] as num).toDouble(),
      indexationRate: (json['indexationRate'] as num).toDouble(),
      baseIndex: json['baseIndex'] != null ? (json['baseIndex'] as num).toDouble() : null,
      newIndex: json['newIndex'] != null ? (json['newIndex'] as num).toDouble() : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
