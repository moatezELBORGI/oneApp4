class InventoryModel {
  final String id;
  final String contractId;
  final String type;
  final DateTime inventoryDate;
  final String? electricityMeterNumber;
  final double? electricityDayIndex;
  final double? electricityNightIndex;
  final String? waterMeterNumber;
  final double? waterIndex;
  final String? heatingMeterNumber;
  final double? heatingKwhIndex;
  final double? heatingM3Index;
  final int keysApartment;
  final int keysMailbox;
  final int keysCellar;
  final int accessCards;
  final int parkingRemotes;
  final String status;
  final DateTime? ownerSignedAt;
  final DateTime? tenantSignedAt;
  final String? ownerSignatureData;
  final String? tenantSignatureData;
  final String? pdfUrl;
  final List<InventoryRoomEntryModel> roomEntries;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryModel({
    required this.id,
    required this.contractId,
    required this.type,
    required this.inventoryDate,
    this.electricityMeterNumber,
    this.electricityDayIndex,
    this.electricityNightIndex,
    this.waterMeterNumber,
    this.waterIndex,
    this.heatingMeterNumber,
    this.heatingKwhIndex,
    this.heatingM3Index,
    required this.keysApartment,
    required this.keysMailbox,
    required this.keysCellar,
    required this.accessCards,
    required this.parkingRemotes,
    required this.status,
    this.ownerSignedAt,
    this.tenantSignedAt,
    this.ownerSignatureData,
    this.tenantSignatureData,
    this.pdfUrl,
    this.roomEntries = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'],
      contractId: json['contractId'],
      type: json['type'],
      inventoryDate: DateTime.parse(json['inventoryDate']),
      electricityMeterNumber: json['electricityMeterNumber'],
      electricityDayIndex: json['electricityDayIndex'] != null ? (json['electricityDayIndex'] as num).toDouble() : null,
      electricityNightIndex: json['electricityNightIndex'] != null ? (json['electricityNightIndex'] as num).toDouble() : null,
      waterMeterNumber: json['waterMeterNumber'],
      waterIndex: json['waterIndex'] != null ? (json['waterIndex'] as num).toDouble() : null,
      heatingMeterNumber: json['heatingMeterNumber'],
      heatingKwhIndex: json['heatingKwhIndex'] != null ? (json['heatingKwhIndex'] as num).toDouble() : null,
      heatingM3Index: json['heatingM3Index'] != null ? (json['heatingM3Index'] as num).toDouble() : null,
      keysApartment: json['keysApartment'] ?? 0,
      keysMailbox: json['keysMailbox'] ?? 0,
      keysCellar: json['keysCellar'] ?? 0,
      accessCards: json['accessCards'] ?? 0,
      parkingRemotes: json['parkingRemotes'] ?? 0,
      status: json['status'],
      ownerSignedAt: json['ownerSignedAt'] != null ? DateTime.parse(json['ownerSignedAt']) : null,
      tenantSignedAt: json['tenantSignedAt'] != null ? DateTime.parse(json['tenantSignedAt']) : null,
      ownerSignatureData: json['ownerSignatureData'],
      tenantSignatureData: json['tenantSignatureData'],
      pdfUrl: json['pdfUrl'],
      roomEntries: json['roomEntries'] != null
          ? (json['roomEntries'] as List).map((e) => InventoryRoomEntryModel.fromJson(e)).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'type': type,
      'inventoryDate': inventoryDate.toIso8601String(),
      'electricityMeterNumber': electricityMeterNumber,
      'electricityDayIndex': electricityDayIndex,
      'electricityNightIndex': electricityNightIndex,
      'waterMeterNumber': waterMeterNumber,
      'waterIndex': waterIndex,
      'heatingMeterNumber': heatingMeterNumber,
      'heatingKwhIndex': heatingKwhIndex,
      'heatingM3Index': heatingM3Index,
      'keysApartment': keysApartment,
      'keysMailbox': keysMailbox,
      'keysCellar': keysCellar,
      'accessCards': accessCards,
      'parkingRemotes': parkingRemotes,
      'status': status,
      'ownerSignedAt': ownerSignedAt?.toIso8601String(),
      'tenantSignedAt': tenantSignedAt?.toIso8601String(),
      'ownerSignatureData': ownerSignatureData,
      'tenantSignatureData': tenantSignatureData,
      'pdfUrl': pdfUrl,
    };
  }
}

class InventoryRoomEntryModel {
  final String id;
  final String inventoryId;
  final String? roomId;
  final String? sectionName;
  final String? description;
  final int orderIndex;
  final List<InventoryRoomPhotoModel> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryRoomEntryModel({
    required this.id,
    required this.inventoryId,
    this.roomId,
    this.sectionName,
    this.description,
    required this.orderIndex,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryRoomEntryModel.fromJson(Map<String, dynamic> json) {
    return InventoryRoomEntryModel(
      id: json['id'].toString(),
      inventoryId: json['inventoryId'].toString(),
      roomId: json['roomId']?.toString(),
      sectionName: json['sectionName'],
      description: json['description'],
      orderIndex: json['orderIndex'] ?? 0,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((e) => InventoryRoomPhotoModel.fromJson(e)).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class InventoryRoomPhotoModel {
  final String id;
  final String roomEntryId;
  final String photoUrl;
  final String? caption;
  final int orderIndex;
  final DateTime createdAt;

  InventoryRoomPhotoModel({
    required this.id,
    required this.roomEntryId,
    required this.photoUrl,
    this.caption,
    required this.orderIndex,
    required this.createdAt,
  });

  factory InventoryRoomPhotoModel.fromJson(Map<String, dynamic> json) {
    return InventoryRoomPhotoModel(
      id: json['id'].toString(),
      roomEntryId: json['roomEntryId'].toString(),
      photoUrl: json['photoUrl'],
      caption: json['caption'],
      orderIndex: json['orderIndex'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
