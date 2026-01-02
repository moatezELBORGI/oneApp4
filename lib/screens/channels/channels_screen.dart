import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/building_context_service.dart';
import '../../utils/app_theme.dart';
import '../../models/channel_model.dart';
import '../../widgets/building_context_indicator.dart';
import '../chat/chat_screen.dart';
import 'create_channel_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _lastBuildingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      print('DEBUG: ChannelsScreen - Building changed from $_lastBuildingId to $currentBuildingId');
      _lastBuildingId = currentBuildingId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentBuildingId != null) {
          _initializeForCurrentBuilding();
        }
      });
    }
  }

  void _initializeForCurrentBuilding() {
    print('DEBUG: ChannelsScreen - Initializing for current building');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId != null) {
      BuildingContextService.forceRefreshForBuilding(context, currentBuildingId);
    }
  }

  void _loadChannels() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    if (currentBuildingId == null) {
      print('DEBUG: No building context, skipping channels load');
      return;
    }

    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
    channelProvider.loadChannels(refresh: true);
  }

  void _handleCreateChannel() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user?.role == 'BUILDING_ADMIN' ||
        user?.role == 'GROUP_ADMIN' ||
        user?.role == 'SUPER_ADMIN') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateChannelScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Seuls les administrateurs peuvent créer des canaux',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Canaux', style: AppTheme.titleStyle),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          const BuildingContextIndicator(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _handleCreateChannel,
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.primaryColor,
            ),
            tooltip: 'Créer un canal',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surfaceColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: AppTheme.subtitleStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTheme.subtitleStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Tous'),
                Tab(text: 'Groupes'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllChannels(),
          _buildGroupChannels(),
        ],
      ),
    );
  }

  Widget _buildAllChannels() {
    return Consumer<ChannelProvider>(
      builder: (context, channelProvider, child) {
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
                  'Chargement des canaux...',
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
                    onPressed: _loadChannels,
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

        final channels = channelProvider.channels;

        if (channels.isEmpty) {
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
                      Icons.forum_outlined,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun canal disponible',
                    style: AppTheme.titleStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Créez votre premier canal pour\ncommencer à communiquer',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _handleCreateChannel,
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text('Créer un canal'),
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
          onRefresh: () async => _loadChannels(),
          color: AppTheme.primaryColor,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: channels.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade200,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final channel = channels[index];
              return _buildChannelCard(channel);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupChannels() {
    return Consumer<ChannelProvider>(
      builder: (context, channelProvider, child) {
        final groupChannels = channelProvider.getGroupChannels();

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
                  'Chargement des groupes...',
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (groupChannels.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun groupe',
                    style: AppTheme.titleStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Les canaux de groupe apparaîtront ici',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groupChannels.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade200,
            indent: 72,
          ),
          itemBuilder: (context, index) {
            return _buildChannelCard(groupChannels[index]);
          },
        );
      },
    );
  }

  Widget _buildChannelCard(Channel channel) {
    final channelColor = _getChannelColor(channel.type);
    final channelIcon = _getChannelIcon(channel.type);

    return Material(
      color: AppTheme.surfaceColor,
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
              // Avatar avec icône de type
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      channelColor.withOpacity(0.2),
                      channelColor.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: channelColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    channelIcon,
                    color: channelColor,
                    size: 26,
                  ),
                ),
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
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  channel.name,
                                  style: AppTheme.subtitleStyle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (channel.isPrivate) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (channel.lastMessage != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(channel.lastMessage!.createdAt),
                            style: AppTheme.captionStyle.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description ou dernier message
                    if (channel.description != null && channel.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          channel.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),

                    // Membres
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${channel.memberCount} membre${channel.memberCount > 1 ? 's' : ''}',
                          style: AppTheme.captionStyle.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: channelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getChannelTypeLabel(channel.type),
                            style: AppTheme.captionStyle.copyWith(
                              fontSize: 11,
                              color: channelColor,
                              fontWeight: FontWeight.w600,
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
                color: AppTheme.textLight,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getChannelIcon(String type) {
    switch (type) {
      case 'GROUP':
        return Icons.group;
      case 'BUILDING':
        return Icons.apartment;
      case 'PUBLIC':
        return Icons.public;
      default:
        return Icons.tag;
    }
  }

  Color _getChannelColor(String type) {
    switch (type) {
      case 'GROUP':
        return AppTheme.accentColor;
      case 'BUILDING':
        return AppTheme.warningColor;
      case 'PUBLIC':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getChannelTypeLabel(String type) {
    switch (type) {
      case 'GROUP':
        return 'Groupe';
      case 'BUILDING':
        return 'Immeuble';
      case 'PUBLIC':
        return 'Public';
      default:
        return 'Canal';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dateTime.weekday - 1];
    } else if (difference.inDays < 365) {
      return '${dateTime.day}/${dateTime.month}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year.toString().substring(2)}';
    }
  }
}