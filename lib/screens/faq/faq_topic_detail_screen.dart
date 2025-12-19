import 'package:flutter/material.dart';
import 'package:mgi/models/faq_question.dart';
import 'package:mgi/models/faq_topic.dart';

import '../../services/building_context_service.dart';
import 'chatbot_screen.dart';

class FAQTopicDetailScreen extends StatelessWidget {
  final FAQTopic topic;

  const FAQTopicDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buildingId = BuildingContextService().currentBuildingId;

    final colorScheme = theme.colorScheme;
    final questions = topic.questions.isNotEmpty
        ? topic.questions
        : [
      FAQQuestion("Aucune question définie", "Ce sujet n'a pas encore de FAQ configurée."),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(topic.name),
      ),
      body: Column(
        children: [
          // Header stylé
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: colorScheme.primary.withOpacity(0.08),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      topic.icon,
                      color: colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Voici les questions les plus fréquentes sur ce sujet.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des FAQ
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final q = questions[index];
                return _FAQExpansionItem(question: q);
              },
            ),
          ),

          // Bouton Chatbot
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.chat_rounded),
                label: const Text(
                  "Parler au chatbot",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatbotScreen(topicName: topic.name),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _FAQExpansionItem extends StatelessWidget {
  final FAQQuestion question;

  const _FAQExpansionItem({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Icon(
            Icons.help_outline_rounded,
            color: colorScheme.primary,
          ),
          title: Text(
            question.question,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                question.answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
