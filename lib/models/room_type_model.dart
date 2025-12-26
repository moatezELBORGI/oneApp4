class RoomTypeModel {
  final int id;
  final String name;
  final int? buildingId;
  final List<RoomTypeFieldDefinitionModel> fieldDefinitions;

  RoomTypeModel({
    required this.id,
    required this.name,
    this.buildingId,
    this.fieldDefinitions = const [],
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id'],
      name: json['name'],
      buildingId: json['buildingId'],
      fieldDefinitions: (json['fieldDefinitions'] as List?)
          ?.map((e) => RoomTypeFieldDefinitionModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'buildingId': buildingId,
      'fieldDefinitions': fieldDefinitions.map((e) => e.toJson()).toList(),
    };
  }
}

class RoomTypeFieldDefinitionModel {
  final int id;
  final int roomTypeId;
  final String fieldName;
  final String fieldType;
  final bool isRequired;
  final int displayOrder;

  String get fieldLabel => fieldName;

  RoomTypeFieldDefinitionModel({
    required this.id,
    required this.roomTypeId,
    required this.fieldName,
    required this.fieldType,
    required this.isRequired,
    required this.displayOrder,
  });

  factory RoomTypeFieldDefinitionModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeFieldDefinitionModel(
      id: json['id'],
      roomTypeId: json['roomTypeId'],
      fieldName: json['fieldName'],
      fieldType: json['fieldType'],
      isRequired: json['isRequired'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomTypeId': roomTypeId,
      'fieldName': fieldName,
      'fieldType': fieldType,
      'isRequired': isRequired,
      'displayOrder': displayOrder,
    };
  }
}
