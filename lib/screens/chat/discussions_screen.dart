import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/building_context_service.dart';
import '../../widgets/building_context_indicator.dart';
import '../../utils/app_theme.dart';
import '../../models/channel_model.dart';
import 'chat_screen.dart';
import 'new_discussion_screen.dart';

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  String? _lastBuildingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForCurrentBuilding();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (_lastBuildingId != currentBuildingId) {
      print('DEBUG: DiscussionsScreen - Building changed from $_lastBuildingId to $currentBuildingId');
      _lastBuildingId = currentBuildingId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentBuildingId != null) {
          _initializeForCurrentBuilding();
        }
      });
    }
  }

  void _initializeForCurrentBuilding() {
    print('DEBUG: DiscussionsScreen - Initializing for current building');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId != null) {
      BuildingContextService.forceRefreshForBuilding(context, currentBuildingId);
    }
  }

  void _loadDiscussions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId == null) {
      print('DEBUG: No building context, skipping discussions load');
      return;
    }

    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
    channelProvider.loadChannels(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Discussions', style: AppTheme.titleStyle),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          const BuildingContextIndicator(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NewDiscussionScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppTheme.primaryColor,
            ),
            tooltip: 'Nouvelle discussion',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<ChannelProvider>(
        builder: (context, channelProvider, child) {
          print('DEBUG: DiscussionsScreen - Consumer rebuild');
          print('DEBUG: isLoading: ${channelProvider.isLoading}');
          print('DEBUG: error: ${channelProvider.error}');
          print('DEBUG: channels count: ${channelProvider.channels.length}');

          if (channelProvider.channels.isNotEmpty && !channelProvider.isLoading) {
            print('DEBUG: We have ${channelProvider.channels.length} channels, displaying them');
          }

          if (channelProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des discussions...',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (channelProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oups ! Une erreur est survenue',
                      style: AppTheme.subtitleStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      channelProvider.error!,
                      style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadDiscussions,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final directChannels = channelProvider.getDirectChannels();

          if (directChannels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aucune discussion',
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Commencez à échanger avec vos voisins\nen démarrant une nouvelle conversation',
                      style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NewDiscussionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text('Nouvelle discussion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadDiscussions(),
            color: AppTheme.primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: directChannels.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade200,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final channel = directChannels[index];
                return _buildDiscussionCard(channel);
              },
            ),
          );
        },
      ),

    );
  }

  Widget _buildDiscussionCard(Channel channel) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isReceivedMessage = channel.lastMessage != null &&
        channel.lastMessage!.senderId != currentUserId;

    final hasUnreadMessage = isReceivedMessage;

    return Material(
      color: hasUnreadMessage
          ? AppTheme.primaryColor.withOpacity(0.05)
          : AppTheme.surfaceColor,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(channel: channel),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar avec badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUnreadMessage
                            ? AppTheme.primaryColor.withOpacity(0.3)
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: hasUnreadMessage
                          ? AppTheme.primaryColor.withOpacity(0.15)
                          : AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: hasUnreadMessage
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                  if (hasUnreadMessage)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.surfaceColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel.name,
                            style: AppTheme.subtitleStyle.copyWith(
                              fontSize: 16,
                              fontWeight: hasUnreadMessage
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (channel.lastMessage != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(channel.lastMessage!.createdAt),
                            style: AppTheme.captionStyle.copyWith(
                              color: hasUnreadMessage
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                              fontWeight: hasUnreadMessage
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel.lastMessage != null
                                ? channel.lastMessage!.content
                                : 'Aucun message',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 14,
                              color: hasUnreadMessage
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontWeight: hasUnreadMessage
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              fontStyle: channel.lastMessage == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Indicateur de navigation
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: hasUnreadMessage
                    ? AppTheme.primaryColor
                    : AppTheme.textLight,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Aujourd'hui - afficher l'heure
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      // Cette semaine - afficher le jour
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dateTime.weekday - 1];
    } else if (difference.inDays < 365) {
      // Cette année - afficher jour/mois
      return '${dateTime.day}/${dateTime.month}';
    } else {
      // Plus ancien - afficher l'année
      return '${dateTime.day}/${dateTime.month}/${dateTime.year.toString().substring(2)}';
    }
  }
}