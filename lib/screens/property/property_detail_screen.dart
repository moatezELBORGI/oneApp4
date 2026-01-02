import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/apartment_details_model.dart';
import '../../models/apartment_complete_model.dart';
import '../../models/apartment_room_complete_model.dart';
import '../../services/apartment_details_service.dart';
import '../../services/apartment_management_service.dart';
import '../apartment/edit_apartment_section_screen.dart';
import '../apartment/apartment_rooms_screen.dart';
import '../../widgets/custom_app_bar.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String apartmentId;
  final String apartmentLabel;

  const PropertyDetailScreen({
    Key? key,
    required this.apartmentId,
    required this.apartmentLabel,
  }) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final ApartmentDetailsService _service = ApartmentDetailsService();
  final ApartmentManagementService _managementService = ApartmentManagementService();
  final ImagePicker _picker = ImagePicker();
  ApartmentDetailsModel? _details;
  ApartmentCompleteModel? _completeApartment;
  bool _isLoading = true;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final details = await _service.getApartmentDetails(widget.apartmentId);

      ApartmentCompleteModel? completeApartment;
      try {
        completeApartment = await _managementService.getApartment(widget.apartmentId);
      } catch (e) {
        print('Could not load complete apartment data: $e');
      }

      setState(() {
        _details = details;
        _completeApartment = completeApartment;
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

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _service.uploadPhoto(
        widget.apartmentId,
        File(image.path),
      );

      Navigator.pop(context);
      await _loadDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo téléchargée avec succès')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(int photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deletePhoto(photoId);
      await _loadDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditApartmentScreen(
          apartmentId: widget.apartmentId,
          currentData: _details,
        ),
      ),
    );

    if (result == true) {
      _loadDetails();
    }
  }

  void _navigateToRooms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApartmentRoomsScreen(
          apartmentId: widget.apartmentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apartmentLabel),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.meeting_room_rounded),
            onPressed: _navigateToRooms,
            tooltip: 'Pièces',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
            tooltip: 'Modifier',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
          ? const Center(child: Text('Aucune donnée disponible'))
          : RefreshIndicator(
        onRefresh: _loadDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildPhotoCarousel(),
              _buildAccordionSections(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    final photos = _details?.photos ?? [];

    return Container(
      height: 300,
      color: Colors.grey[200],
      child: Stack(
        children: [
          if (photos.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune photo',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          else
            PageView.builder(
              itemCount: photos.length,
              onPageChanged: (index) {
                setState(() => _currentPhotoIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = photos[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photo.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.7),
                        ),
                        onPressed: () => _deletePhoto(photo.id),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (photos.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: photos.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPhotoIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _showImageSourceDialog,
              child: const Icon(Icons.add_a_photo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSections() {
    return Column(
      children: [
        if (_completeApartment != null && _completeApartment!.rooms.isNotEmpty) ...[
          ..._completeApartment!.rooms.map((room) {
            return _buildRoomAccordionTile(room);
          }).toList(),
          if (_completeApartment!.customFields.isNotEmpty)
            _buildCustomFieldsAccordionTile(),
        ] else ...[
          _buildAccordionTile(
            title: 'Informations Générales',
            icon: Icons.info_outline,
            content: _buildGeneralInfoContent(),
            isInitiallyExpanded: true,
          ),
          _buildAccordionTile(
            title: 'Intérieur',
            icon: Icons.home,
            content: _buildInteriorContent(),
            isInitiallyExpanded: false,
          ),
          _buildAccordionTile(
            title: 'Extérieur',
            icon: Icons.deck,
            content: _buildExteriorContent(),
            isInitiallyExpanded: false,
          ),
          _buildAccordionTile(
            title: 'Installations',
            icon: Icons.build,
            content: _buildInstallationsContent(),
            isInitiallyExpanded: false,
          ),
          _buildAccordionTile(
            title: 'Énergie',
            icon: Icons.bolt,
            content: _buildEnergieContent(),
            isInitiallyExpanded: false,
          ),
        ],
      ],
    );
  }

  Widget _buildAccordionTile({
    required String title,
    required IconData icon,
    required Widget content,
    required bool isInitiallyExpanded,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoContent() {
    final info = _details?.generalInfo;
    if (info == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Nombre de chambres', info.nbChambres?.toString()),
        _buildInfoRow(
            'Nombre de salles de bain', info.nbSalleBain?.toString()),
        _buildInfoRow('Surface', info.surface != null ? '${info.surface} m²' : null),
        _buildInfoRow('Étage', info.etage?.toString()),
      ],
    );
  }

  Widget _buildInteriorContent() {
    final interior = _details?.interior;
    if (interior == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Quartier/Lieu', interior.quartierLieu),
        _buildInfoRow('Surface habitable',
            interior.surfaceHabitable != null ? '${interior.surfaceHabitable} m²' : null),
        _buildInfoRow('Surface salon',
            interior.surfaceSalon != null ? '${interior.surfaceSalon} m²' : null),
        _buildInfoRow('Type de cuisine', interior.typeCuisine),
        _buildInfoRow('Surface cuisine',
            interior.surfaceCuisine != null ? '${interior.surfaceCuisine} m²' : null),
        _buildInfoRow(
            'Nombre salles de douche', interior.nbSalleDouche?.toString()),
        _buildInfoRow('Nombre toilettes', interior.nbToilette?.toString()),
        _buildInfoRow('Cave', interior.cave == true ? 'Oui' : 'Non'),
        _buildInfoRow('Grenier', interior.grenier == true ? 'Oui' : 'Non'),
      ],
    );
  }

  Widget _buildExteriorContent() {
    final exterior = _details?.exterior;
    if (exterior == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Surface terrasse',
            exterior.surfaceTerrasse != null ? '${exterior.surfaceTerrasse} m²' : null),
        _buildInfoRow('Orientation terrasse', exterior.orientationTerrasse),
      ],
    );
  }

  Widget _buildInstallationsContent() {
    final installations = _details?.installations;
    if (installations == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
            'Ascenseur', installations.ascenseur == true ? 'Oui' : 'Non'),
        _buildInfoRow('Accès handicapé',
            installations.accesHandicap == true ? 'Oui' : 'Non'),
        _buildInfoRow(
            'Parlophone', installations.parlophone == true ? 'Oui' : 'Non'),
        _buildInfoRow('Interphone vidéo',
            installations.interphoneVideo == true ? 'Oui' : 'Non'),
        _buildInfoRow('Porte blindée',
            installations.porteBlindee == true ? 'Oui' : 'Non'),
        _buildInfoRow('Piscine', installations.piscine == true ? 'Oui' : 'Non'),
      ],
    );
  }

  Widget _buildEnergieContent() {
    final energie = _details?.energie;
    if (energie == null) {
      return const Text('Aucune information disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Classe énergétique', energie.classeEnergetique),
        _buildInfoRow(
            'Consommation énergie primaire',
            energie.consommationEnergiePrimaire != null
                ? '${energie.consommationEnergiePrimaire} kWh/m²/an'
                : null),
        _buildInfoRow(
            'Consommation théorique totale',
            energie.consommationTheoriqueTotale != null
                ? '${energie.consommationTheoriqueTotale} kWh/an'
                : null),
        _buildInfoRow('Émission CO2',
            energie.emissionCo2 != null ? '${energie.emissionCo2} kg/m²/an' : null),
        _buildInfoRow('Numéro rapport PEB', energie.numeroRapportPeb),
        _buildInfoRow('Type de chauffage', energie.typeChauffage),
        _buildInfoRow(
            'Double vitrage', energie.doubleVitrage == true ? 'Oui' : 'Non'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non renseigné',
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomAccordionTile(ApartmentRoomCompleteModel room) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.meeting_room, color: Colors.blue),
        title: Text(
          room.roomName ?? room.roomType.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(room.roomType.name),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (room.fieldValues.isNotEmpty) ...[
                  const Text(
                    'Caractéristiques',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...room.fieldValues.map((fieldValue) {
                    String value = 'Non renseigné';
                    if (fieldValue.textValue != null) {
                      value = fieldValue.textValue!;
                    } else if (fieldValue.numberValue != null) {
                      value = '${fieldValue.numberValue} m²';
                    } else if (fieldValue.booleanValue != null) {
                      value = fieldValue.booleanValue! ? 'Oui' : 'Non';
                    }
                    return _buildInfoRow(fieldValue.fieldName, value);
                  }).toList(),
                  const SizedBox(height: 16),
                ],
                if (room.equipments.isNotEmpty) ...[
                  const Text(
                    'Équipements',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...room.equipments.map((equipment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (equipment.description != null &&
                                equipment.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                equipment.description!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (equipment.images.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: equipment.images.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: equipment.images[index].imageUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
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
                  const SizedBox(height: 16),
                ],
                if (room.images.isNotEmpty) ...[
                  const Text(
                    'Photos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: room.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: room.images[index].imageUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
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
      ),
    );
  }

  Widget _buildCustomFieldsAccordionTile() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.info_outline, color: Colors.orange),
        title: const Text(
          'Champs spécifiques',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _completeApartment!.customFields.map((field) {
                return _buildInfoRow(field.fieldLabel, field.fieldValue);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
