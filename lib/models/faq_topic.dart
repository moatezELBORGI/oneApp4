import 'package:flutter/material.dart';
import 'package:mgi/models/faq_question.dart';

class FAQTopic {
  final String name;
  final IconData icon;
  final List<FAQQuestion> questions;

  FAQTopic(this.name, this.icon, {this.questions = const []});

  factory FAQTopic.fromJson(Map<String, dynamic> json) {
    final iconName = json['icon'] as String?;
    return FAQTopic(
      json['name'] as String,
      _iconFromString(iconName),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => FAQQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
/// mapping "apartment_rounded" -> Icons.apartment_rounded, etc.
IconData _iconFromString(String? name) {
  switch (name) {
    case 'apartment_rounded':
      return Icons.apartment_rounded;
    case 'payments_rounded':
      return Icons.payments_rounded;
    case 'build_rounded':
      return Icons.build_rounded;
    case 'description_rounded':
      return Icons.description_rounded;
    case 'groups_rounded':
      return Icons.groups_rounded;
    case 'help_outline_rounded':
      return Icons.help_outline_rounded;
    default:
      return Icons.help_outline_rounded; // fallback
  }
}