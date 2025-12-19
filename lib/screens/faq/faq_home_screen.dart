import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgi/models/faq_topic.dart';
import 'package:mgi/services/building_context_service.dart';
import 'package:mgi/providers/claim_provider.dart';
import 'faq_topic_detail_screen.dart';

class FAQHomeScreen extends StatefulWidget {
  const FAQHomeScreen({super.key});

  @override
  State<FAQHomeScreen> createState() => _FAQHomeScreenState();
}

class _FAQHomeScreenState extends State<FAQHomeScreen> {
  @override
  void initState() {
    super.initState();

    final provider = Provider.of<ClaimProvider>(context, listen: false);
    final buildingId = BuildingContextService().currentBuildingId;

    provider.fetchFaqTopics(buildingId!); // ⬅️ auto load
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClaimProvider>(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("FAQ & Assistance"),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            // -----------------------------------------------------------
            // Header
            // -----------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.primary.withOpacity(0.08),
              ),
              child: Row(
                children: [
                  Icon(Icons.support_agent_rounded,
                      color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Besoin d’aide ? Sélectionnez une catégorie.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------
            // Provider UI States
            // -----------------------------------------------------------

            if (provider.isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.errorMessage != null)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Erreur pendant le chargement."),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        final id =
                            BuildingContextService().currentBuildingId;
                        provider.fetchFaqTopics(id!);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Réessayer"),
                    ),
                  ],
                ),
              )
            else if (provider.topics.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text("Aucune FAQ trouvée pour ce bâtiment."),
                  ),
                )
              else
              // -----------------------------------------------------------
              // Grid of Topics
              // -----------------------------------------------------------
                Expanded(
                  child: GridView.builder(
                    itemCount: provider.topics.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (context, index) {
                      final topic = provider.topics[index];
                      return _CompactTopicButton(
                        topic: topic,
                        index: index,
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration:
                              const Duration(milliseconds: 250),
                              pageBuilder: (_, animation, __) => FadeTransition(
                                opacity: animation,
                                child: FAQTopicDetailScreen(topic: topic),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================================
// Compact Topic Button
// =============================================================================================

class _CompactTopicButton extends StatelessWidget {
  final FAQTopic topic;
  final int index;
  final VoidCallback onTap;

  const _CompactTopicButton({
    required this.topic,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.9, end: 1),
      duration: Duration(milliseconds: 250 + index * 70),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.30),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                // ICON circle
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    topic.icon,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),

                // TEXT
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${topic.questions.length} questions",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary.withOpacity(0.70),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
