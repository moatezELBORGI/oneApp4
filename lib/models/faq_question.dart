class FAQQuestion {
  final String question;
  final String answer;

  FAQQuestion(this.question, this.answer);

  factory FAQQuestion.fromJson(Map<String, dynamic> json) {
    return FAQQuestion(
      json['question'] as String,
      json['answer'] as String,
    );
  }
}