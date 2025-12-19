class ApartmentRoomModel {
  final String id;
  final String apartmentId;
  final String roomName;
  final String? roomType;
  final String? description;
  final int orderIndex;
  final List<ApartmentRoomPhotoModel> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApartmentRoomModel({
    required this.id,
    required this.apartmentId,
    required this.roomName,
    this.roomType,
    this.description,
    required this.orderIndex,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApartmentRoomModel.fromJson(Map<String, dynamic> json) {
    return ApartmentRoomModel(
      id: json['id'],
      apartmentId: json['apartmentId'],
      roomName: json['roomName'],
      roomType: json['roomType'],
      description: json['description'],
      orderIndex: json['orderIndex'] ?? 0,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((e) => ApartmentRoomPhotoModel.fromJson(e)).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'roomName': roomName,
      'roomType': roomType,
      'description': description,
      'orderIndex': orderIndex,
    };
  }
}

class ApartmentRoomPhotoModel {
  final String id;
  final String roomId;
  final String photoUrl;
  final String? caption;
  final int orderIndex;
  final DateTime createdAt;

  ApartmentRoomPhotoModel({
    required this.id,
    required this.roomId,
    required this.photoUrl,
    this.caption,
    required this.orderIndex,
    required this.createdAt,
  });

  factory ApartmentRoomPhotoModel.fromJson(Map<String, dynamic> json) {
    return ApartmentRoomPhotoModel(
      id: json['id'],
      roomId: json['roomId'],
      photoUrl: json['photoUrl'],
      caption: json['caption'],
      orderIndex: json['orderIndex'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
