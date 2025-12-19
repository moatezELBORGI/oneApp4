import 'user_model.dart';

class PropertyModel {
  final String? id;
  final String? idApartment;
  final String? apartmentLabel;
  final String? apartmentNumber;
  final int? apartmentFloor;
  final int? floor;
  final double? livingAreaSurface;
  final int? numberOfRooms;
  final int? numberOfBedrooms;
  final bool? haveBalconyOrTerrace;
  final bool? isFurnished;
  final String? buildingId;
  final User? resident;
  final User? owner;
  final User? tenant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PropertyModel({
    this.id,
    this.idApartment,
    this.apartmentLabel,
    this.apartmentNumber,
    this.apartmentFloor,
    this.floor,
    this.livingAreaSurface,
    this.numberOfRooms,
    this.numberOfBedrooms,
    this.haveBalconyOrTerrace,
    this.isFurnished,
    this.buildingId,
    this.resident,
    this.owner,
    this.tenant,
    this.createdAt,
    this.updatedAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'],
      idApartment: json['idApartment'],
      apartmentLabel: json['apartmentLabel'],
      apartmentNumber: json['apartmentNumber'],
      apartmentFloor: json['apartmentFloor'],
      floor: json['floor'],
      livingAreaSurface: json['livingAreaSurface']?.toDouble(),
      numberOfRooms: json['numberOfRooms'],
      numberOfBedrooms: json['numberOfBedrooms'],
      haveBalconyOrTerrace: json['haveBalconyOrTerrace'],
      isFurnished: json['isFurnished'],
      buildingId: json['buildingId'],
      resident: json['resident'] != null ? User.fromJson(json['resident']) : null,
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      tenant: json['tenant'] != null ? User.fromJson(json['tenant']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idApartment': idApartment,
      'apartmentLabel': apartmentLabel,
      'apartmentNumber': apartmentNumber,
      'apartmentFloor': apartmentFloor,
      'floor': floor,
      'livingAreaSurface': livingAreaSurface,
      'numberOfRooms': numberOfRooms,
      'numberOfBedrooms': numberOfBedrooms,
      'haveBalconyOrTerrace': haveBalconyOrTerrace,
      'isFurnished': isFurnished,
      'buildingId': buildingId,
      'resident': resident?.toJson(),
      'owner': owner?.toJson(),
      'tenant': tenant?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
