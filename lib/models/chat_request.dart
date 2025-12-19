class ChatRequest {
  final String message;
  final String buildingId;

  ChatRequest({required this.message, required this.buildingId});

  Map<String, dynamic> toJson() => {
    "message": message,
    "buildingId": buildingId,
  };
}
