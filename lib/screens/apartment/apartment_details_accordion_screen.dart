import 'package:flutter/material.dart';
import '../../models/apartment_complete_model.dart';
import '../../services/apartment_management_service.dart';
import '../../services/api_service.dart';

class ApartmentDetailsAccordionScreen extends StatefulWidget {
  final int apartmentId;

  const ApartmentDetailsAccordionScreen({
    Key? key,
    required this.apartmentId,
  }) : super(key: key);

  @override
  State<ApartmentDetailsAccordionScreen> createState() =>
      _ApartmentDetailsAccordionScreenState();
}

class _ApartmentDetailsAccordionScreenState
    extends State<ApartmentDetailsAccordionScreen> {
  final _apiService = ApiService();
  late final ApartmentManagementService _apartmentService;

  ApartmentCompleteModel? _apartment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apartmentService = ApartmentManagementService(_apiService);
    _loadApartment();
  }

  Future<void> _loadApartment() async {
    try {
      final apartment = await _apartmentService.getApartment(widget.apartmentId);
      setState(() {
        _apartment = apartment;
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Mon appartement'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apartment == null
              ? const Center(child: Text('Aucune donnée disponible'))
              : RefreshIndicator(
                  onRefresh: _loadApartment,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildBasicInfoCard(),
                          const SizedBox(height: 16),
                          if (_apartment!.rooms.isNotEmpty) ...[
                            _buildRoomsSection(),
                            const SizedBox(height: 16),
                          ],
                          if (_apartment!.customFields.isNotEmpty)
                            _buildCustomFieldsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apartment,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _apartment!.propertyName ?? 'Appartement ${_apartment!.number}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Étage ${_apartment!.floor}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations générales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Numéro', _apartment!.number),
            _buildInfoRow('Étage', _apartment!.floor.toString()),
            if (_apartment!.ownerName != null)
              _buildInfoRow('Propriétaire', _apartment!.ownerName!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsSection() {
    return Card(
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.meeting_room,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pièces',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _apartment!.rooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = _apartment!.rooms[index];
                return ExpansionTile(
                  title: Text(
                    room.roomName ?? room.roomType.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    room.roomType.name,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (room.fieldValues.isNotEmpty) ...[
                            const Text(
                              'Caractéristiques',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...room.fieldValues.map((fieldValue) {
                              String value = '';
                              if (fieldValue.textValue != null) {
                                value = fieldValue.textValue!;
                              } else if (fieldValue.numberValue != null) {
                                value = '${fieldValue.numberValue} m²';
                              } else if (fieldValue.booleanValue != null) {
                                value = fieldValue.booleanValue! ? 'Oui' : 'Non';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        fieldValue.fieldName,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          if (room.equipments.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Équipements',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...room.equipments.map((equipment) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.grey[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        equipment.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (equipment.description != null &&
                                          equipment.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          equipment.description!,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                      if (equipment.images.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 80,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: equipment.images.length,
                                            separatorBuilder: (context, index) =>
                                                const SizedBox(width: 8),
                                            itemBuilder: (context, index) {
                                              return GestureDetector(
                                                onTap: () =>
                                                    _showImageDialog(equipment.images[index].imageUrl),
                                                child: Container(
                                                  width: 80,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(8),
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                        equipment.images[index].imageUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          if (room.images.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Photos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: room.images.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _showImageDialog(room.images[index].imageUrl),
                                    child: Container(
                                      width: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            room.images[index].imageUrl,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFieldsSection() {
    return Card(
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Informations spécifiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: _apartment!.customFields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            field.fieldLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            field.fieldValue,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
