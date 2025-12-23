class EquipmentTemplateModel {
  final String id;
  final String name;
  final String roomTypeId;
  final String? description;
  final int displayOrder;
  final bool isActive;

  EquipmentTemplateModel({
    required this.id,
    required this.name,
    required this.roomTypeId,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory EquipmentTemplateModel.fromJson(Map<String, dynamic> json) {
    return EquipmentTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      roomTypeId: json['roomTypeId']?.toString() ?? '',
      description: json['description']?.toString(),
      displayOrder: json['displayOrder'] is int
          ? json['displayOrder']
          : int.tryParse(json['displayOrder']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roomTypeId': roomTypeId,
      if (description != null) 'description': description,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}
