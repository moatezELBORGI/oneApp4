import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/building_context_service.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';
import '../../widgets/custom_app_bar.dart';

class NewDiscussionScreen extends StatefulWidget {
  const NewDiscussionScreen({super.key});

  @override
  State<NewDiscussionScreen> createState() => _NewDiscussionScreenState();
}

class _NewDiscussionScreenState extends State<NewDiscussionScreen> {
  final _searchController = TextEditingController();
  List<User> _filteredResidents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBuildingResidents();
    });
  }

  void _loadBuildingResidents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

    final currentBuildingId = authProvider.user?.buildingId;
    print('DEBUG: Loading residents for current building: $currentBuildingId');

    if (currentBuildingId != null) {
      BuildingContextService().setBuildingContext(currentBuildingId);
      channelProvider.clearBuildingResidents();

      await channelProvider.loadBuildingResidents(currentBuildingId);
      print(channelProvider.buildingResidents.length);

      setState(() {
        _filteredResidents = channelProvider.buildingResidents
            .where((resident) => resident.id != authProvider.user?.id)
            .where((resident) => resident.buildingId == currentBuildingId || resident.buildingId == null)
            .toList();
        print('DEBUG: Filtered to ${_filteredResidents.length} residents for building $currentBuildingId (excluding current user)');
        for (var resident in _filteredResidents) {
          print('DEBUG: Resident: ${resident.fullName} (ID: ${resident.id}, Building: ${resident.buildingId})');
        }
      });
    } else {
      print('DEBUG: No current building ID found for user');
      setState(() {
        _filteredResidents = [];
      });
    }
  }

  void _filterResidents(String query) {
    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentBuildingId = authProvider.user?.buildingId;

    setState(() {
      if (query.isEmpty) {
        _filteredResidents = channelProvider.buildingResidents
            .where((resident) => resident.id != authProvider.user?.id)
            .where((resident) => resident.buildingId == currentBuildingId || resident.buildingId == null)
            .toList();
      } else {
        _filteredResidents = channelProvider.buildingResidents
            .where((resident) =>
        resident.id != authProvider.user?.id &&
            (resident.buildingId == currentBuildingId || resident.buildingId == null) &&
            resident.fullName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _startDiscussion(User resident) async {
    final channelProvider = Provider.of<ChannelProvider>(context, listen: false);

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    final channel = await channelProvider.getOrCreateDirectChannel(resident.id);

    if (mounted) {
      Navigator.of(context).pop(); // Fermer le dialogue de chargement

      if (channel != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(channel: channel),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouvelle discussion', style: AppTheme.titleStyle),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar avec meilleur design
          Container(
            color: AppTheme.surfaceColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionnez un résident',
                  style: AppTheme.captionStyle.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  style: AppTheme.bodyStyle,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom...',
                    hintStyle: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterResidents('');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: _filterResidents,
                ),
              ],
            ),
          ),

          // Compteur de résidents
          if (_filteredResidents.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredResidents.length} résident${_filteredResidents.length > 1 ? 's' : ''} disponible${_filteredResidents.length > 1 ? 's' : ''}',
                style: AppTheme.captionStyle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Residents List
          Expanded(
            child: Consumer<ChannelProvider>(
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
                          'Chargement des résidents...',
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
                            onPressed: _loadBuildingResidents,
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

                if (_filteredResidents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchController.text.isEmpty
                                  ? Icons.people_outline
                                  : Icons.search_off,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Aucun résident disponible'
                                : 'Aucun résultat',
                            style: AppTheme.subtitleStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Il n\'y a pas encore de résidents dans votre immeuble'
                                : 'Aucun résident ne correspond à "${_searchController.text}"',
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
                  itemCount: _filteredResidents.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final resident = _filteredResidents[index];
                    return _buildResidentTile(resident);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentTile(User resident) {
    return Material(
      color: AppTheme.surfaceColor,
      child: InkWell(
        onTap: () => _startDiscussion(resident),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar avec indicateur en ligne
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor,
                      child: resident.picture != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.network(
                          resident.picture!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              resident.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            );
                          },
                        ),
                      )
                          : Text(
                        resident.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Informations du résident
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident.fullName,
                      style: AppTheme.subtitleStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Appartement ${resident.apartmentId ?? 'Non assigné'}',
                          style: AppTheme.captionStyle.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bouton d'action
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}