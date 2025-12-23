import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';
import '../apartment/apartment_rooms_screen.dart';
import '../lease/lease_contracts_screen.dart';
import '../lease/contract_history_screen.dart';
import '../inventory/inventories_screen.dart';
import 'property_details_editable_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({Key? key}) : super(key: key);

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final PropertyService _propertyService = PropertyService();
  List<PropertyModel>? _properties;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final buildingId = authProvider.user?.buildingId;

      if (buildingId != null) {
        final properties = await _propertyService.getMyProperties(buildingId);
        setState(() {
          _properties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Biens'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties == null || _properties!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun bien trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vous ne possédez aucun bien dans cet immeuble',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _properties!.length,
                    itemBuilder: (context, index) {
                      final property = _properties![index];
                      return _buildPropertyCard(property);
                    },
                  ),
                ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    final hasOwner = property.owner != null;
    final hasTenant = property.tenant != null;
    final isOccupied = hasTenant || (property.resident != null);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.apartmentLabel ?? 'Appartement ${property.apartmentNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Étage ${property.apartmentFloor} • N°${property.apartmentNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOccupied ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOccupied ? 'Occupé' : 'Libre',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOccupied ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.square_foot,
              '${property.livingAreaSurface} m²',
            ),
            _buildInfoRow(
              Icons.bed_outlined,
              '${property.numberOfBedrooms} chambres',
            ),
            _buildInfoRow(
              Icons.meeting_room_outlined,
              '${property.numberOfRooms} pièces',
            ),
            if (hasTenant) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.person_outline,
                'Locataire: ${property.tenant?.fname} ${property.tenant?.lname}',
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailsEditableScreen(
                            apartmentId: int.parse(property.idApartment!),
                            apartmentLabel: property.apartmentLabel ?? 'Appartement ${property.apartmentNumber}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractHistoryScreen(
                            apartmentId: property.idApartment!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('Contrats'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApartmentRoomsScreen(
                      apartmentId: property.idApartment!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.meeting_room_rounded, size: 18),
              label: const Text('Gérer les pièces'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
