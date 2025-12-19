class ChatResponse {
  final String type;        // "faq" ou "llm"
  final String answer;
  final double score;
  final String? question;

  ChatResponse({
    required this.type,
    required this.answer,
    required this.score,
    this.question,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      type: json["type"] ?? "llm",
      answer: json["answer"] ?? "",
      score: (json["score"] ?? 0).toDouble(),
      question: json["question"],
    );
  }
}
