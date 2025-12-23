import 'room_type_model.dart';

class ApartmentRoomCompleteModel {
  final String id;
  final String apartmentId;
  final String? roomName;
  final RoomTypeModel roomType;
  final List<RoomFieldValueModel> fieldValues;
  final List<RoomEquipmentModel> equipments;
  final List<RoomImageModel> images;

  ApartmentRoomCompleteModel({
    required this.id,
    required this.apartmentId,
    this.roomName,
    required this.roomType,
    this.fieldValues = const [],
    this.equipments = const [],
    this.images = const [],
  });

  factory ApartmentRoomCompleteModel.fromJson(Map<String, dynamic> json) {
    return ApartmentRoomCompleteModel(
      id: json['id']?.toString() ?? '',
      apartmentId: json['apartmentId']?.toString() ?? '',
      roomName: json['roomName']?.toString(),
      roomType: RoomTypeModel.fromJson(json['roomType']),
      fieldValues: (json['fieldValues'] as List?)
              ?.map((e) => RoomFieldValueModel.fromJson(e))
              .toList() ??
          [],
      equipments: (json['equipments'] as List?)
              ?.map((e) => RoomEquipmentModel.fromJson(e))
              .toList() ??
          [],
      images: (json['images'] as List?)
              ?.map((e) => RoomImageModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'roomName': roomName,
      'roomType': roomType.toJson(),
      'fieldValues': fieldValues.map((e) => e.toJson()).toList(),
      'equipments': equipments.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}

class RoomFieldValueModel {
  final int? id;
  final int? apartmentRoomId;
  final int fieldDefinitionId;
  final String fieldName;
  final String? textValue;
  final double? numberValue;
  final bool? booleanValue;

  RoomFieldValueModel({
    this.id,
    this.apartmentRoomId,
    required this.fieldDefinitionId,
    required this.fieldName,
    this.textValue,
    this.numberValue,
    this.booleanValue,
  });

  factory RoomFieldValueModel.fromJson(Map<String, dynamic> json) {
    return RoomFieldValueModel(
      id: json['id'],
      apartmentRoomId: json['apartmentRoomId'],
      fieldDefinitionId: json['fieldDefinitionId'],
      fieldName: json['fieldName'],
      textValue: json['textValue'],
      numberValue: json['numberValue']?.toDouble(),
      booleanValue: json['booleanValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (apartmentRoomId != null) 'apartmentRoomId': apartmentRoomId,
      'fieldDefinitionId': fieldDefinitionId,
      'fieldName': fieldName,
      if (textValue != null) 'textValue': textValue,
      if (numberValue != null) 'numberValue': numberValue,
      if (booleanValue != null) 'booleanValue': booleanValue,
    };
  }
}

class RoomEquipmentModel {
  final int? id;
  final int? apartmentRoomId;
  final String name;
  final String? description;
  final List<RoomImageModel> images;

  RoomEquipmentModel({
    this.id,
    this.apartmentRoomId,
    required this.name,
    this.description,
    this.images = const [],
  });

  factory RoomEquipmentModel.fromJson(Map<String, dynamic> json) {
    return RoomEquipmentModel(
      id: json['id'],
      apartmentRoomId: json['apartmentRoomId'],
      name: json['name'],
      description: json['description'],
      images: (json['images'] as List?)
              ?.map((e) => RoomImageModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (apartmentRoomId != null) 'apartmentRoomId': apartmentRoomId,
      'name': name,
      if (description != null) 'description': description,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}

class RoomImageModel {
  final int? id;
  final int? apartmentRoomId;
  final int? equipmentId;
  final String imageUrl;
  final int displayOrder;

  RoomImageModel({
    this.id,
    this.apartmentRoomId,
    this.equipmentId,
    required this.imageUrl,
    this.displayOrder = 0,
  });

  factory RoomImageModel.fromJson(Map<String, dynamic> json) {
    return RoomImageModel(
      id: json['id'],
      apartmentRoomId: json['apartmentRoomId'],
      equipmentId: json['equipmentId'],
      imageUrl: json['imageUrl'],
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (apartmentRoomId != null) 'apartmentRoomId': apartmentRoomId,
      if (equipmentId != null) 'equipmentId': equipmentId,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
    };
  }
}
