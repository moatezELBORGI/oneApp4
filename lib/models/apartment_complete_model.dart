import 'apartment_room_complete_model.dart';

class ApartmentCompleteModel {
  final String id;
  final String? propertyName;
  final String number;
  final int floor;
  final String? ownerId;
  final String? ownerName;
  final String buildingId;
  final String? buildingName;
  final List<ApartmentRoomCompleteModel> rooms;
  final List<ApartmentCustomFieldModel> customFields;

  ApartmentCompleteModel({
    required this.id,
    this.propertyName,
    required this.number,
    required this.floor,
    this.ownerId,
    this.ownerName,
    required this.buildingId,
    this.buildingName,
    this.rooms = const [],
    this.customFields = const [],
  });

  factory ApartmentCompleteModel.fromJson(Map<String, dynamic> json) {
    return ApartmentCompleteModel(
      id: json['id'],
      propertyName: json['propertyName'],
      number: json['number'],
      floor: json['floor'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      buildingId: json['buildingId'],
      buildingName: json['buildingName'],
      rooms: (json['rooms'] as List?)
              ?.map((e) => ApartmentRoomCompleteModel.fromJson(e))
              .toList() ??
          [],
      customFields: (json['customFields'] as List?)
              ?.map((e) => ApartmentCustomFieldModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (propertyName != null) 'propertyName': propertyName,
      'number': number,
      'floor': floor,
      if (ownerId != null) 'ownerId': ownerId,
      if (ownerName != null) 'ownerName': ownerName,
      'buildingId': buildingId,
      if (buildingName != null) 'buildingName': buildingName,
      'rooms': rooms.map((e) => e.toJson()).toList(),
      'customFields': customFields.map((e) => e.toJson()).toList(),
    };
  }
}

class ApartmentCustomFieldModel {
  final int? id;
  final int? apartmentId;
  final String fieldLabel;
  final String fieldValue;
  final int displayOrder;
  final bool isSystemField;

  ApartmentCustomFieldModel({
    this.id,
    this.apartmentId,
    required this.fieldLabel,
    required this.fieldValue,
    this.displayOrder = 0,
    this.isSystemField = false,
  });

  factory ApartmentCustomFieldModel.fromJson(Map<String, dynamic> json) {
    return ApartmentCustomFieldModel(
      id: json['id'],
      apartmentId: json['apartmentId'],
      fieldLabel: json['fieldLabel'],
      fieldValue: json['fieldValue'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      isSystemField: json['isSystemField'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (apartmentId != null) 'apartmentId': apartmentId,
      'fieldLabel': fieldLabel,
      'fieldValue': fieldValue,
      'displayOrder': displayOrder,
      'isSystemField': isSystemField,
    };
  }
}
