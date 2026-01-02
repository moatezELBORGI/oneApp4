import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/claim_provider.dart';
import '../../services/building_context_service.dart';
import '../../widgets/custom_app_bar.dart';

class ChatbotScreen extends StatefulWidget {
  final String topicName;

  const ChatbotScreen({
    super.key,
    required this.topicName,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  String? get buildingId => BuildingContextService().currentBuildingId;

  @override
  void initState() {
    super.initState();
    _addBotIntroMessage();
  }

  void _addBotIntroMessage() {
    _messages.add(
      _ChatMessage(
        sender: MessageSender.bot,
        text:
        "Bonjour 👋\nJe peux vous aider sur le sujet : « ${widget.topicName} ».\nPosez-moi votre question ou choisissez une suggestion.",
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(sender: MessageSender.user, text: text.trim()),
      );
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final claimProvider = Provider.of<ClaimProvider>(context, listen: false);

      // Vérifier que buildingId existe
      if (buildingId == null) {
        throw Exception("Building ID non disponible");
      }

      final response = await claimProvider.sendChat(
        text.trim(),
        buildingId!,
      );

      setState(() {
        // Afficher la réponse du bot
        String botMessage = response.answer;

        // Ajouter des informations supplémentaires si c'est une réponse FAQ
        if (response.type == 'faq' && response.question != null) {
          botMessage = "📌 ${response.question}\n\n$botMessage";
        }

        _messages.add(
          _ChatMessage(
            sender: MessageSender.bot,
            text: botMessage,
            isFaqMatch: response.type == 'faq',
            confidence: response.score,
          ),
        );
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      print("❌ Erreur chat: $e"); // Debug
      setState(() {
        _messages.add(
          _ChatMessage(
            sender: MessageSender.bot,
            text: "Désolé, une erreur s'est produite. Veuillez réessayer.\n\nDétails: ${e.toString()}",
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final suggestions = [
      "M'expliquer les règles",
      "Comment faire une demande ?",
      "Quels sont les délais ?",
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.support_agent_rounded, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Assistant virtuel",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    widget.topicName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggestions
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => _SuggestionCard(
                text: suggestions[index],
                onTap: () => _sendMessage(suggestions[index]),
              ),
            ),
          ),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const _TypingIndicator();
                }

                final msg = _messages[index];
                final isUser = msg.sender == MessageSender.user;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _ChatBubble(
                      message: msg.text,
                      isUser: isUser,
                      isFaqMatch: msg.isFaqMatch,
                      confidence: msg.confidence,
                    ),
                  ),
                );
              },
            ),
          ),

          // Input zone
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Écrire un message...",
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
//       INTERNAL MODELS
// ===============================

enum MessageSender { user, bot }

class _ChatMessage {
  final MessageSender sender;
  final String text;
  final bool isFaqMatch;
  final double? confidence;

  _ChatMessage({
    required this.sender,
    required this.text,
    this.isFaqMatch = false,
    this.confidence,
  });
}

// ===============================
//       UI COMPONENTS
// ===============================

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isFaqMatch;
  final double? confidence;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    this.isFaqMatch = false,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = isUser
        ? colorScheme.primary
        : colorScheme.surfaceVariant.withOpacity(0.9);
    final textColor = isUser ? Colors.white : theme.textTheme.bodyMedium?.color;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Text(message,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
          ),
          // Badge FAQ optionnel
          if (!isUser && isFaqMatch)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 12, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      "FAQ",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionCard({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surfaceVariant.withOpacity(0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(text,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(color: color),
            const SizedBox(width: 4),
            _Dot(color: color),
            const SizedBox(width: 4),
            _Dot(color: color),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _anim = Tween<double>(begin: 4, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: _anim.value,
        height: _anim.value,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}