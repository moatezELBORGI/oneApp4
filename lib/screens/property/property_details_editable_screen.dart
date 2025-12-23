import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/apartment_complete_model.dart';
import '../../models/apartment_room_complete_model.dart';
import '../../services/apartment_management_service.dart';
import '../../services/apartment_room_service.dart';
import '../../utils/app_theme.dart';

class PropertyDetailsEditableScreen extends StatefulWidget {
  final String apartmentId;
  final String? apartmentLabel;

  const PropertyDetailsEditableScreen({
    Key? key,
    required this.apartmentId,
    this.apartmentLabel,
  }) : super(key: key);

  @override
  State<PropertyDetailsEditableScreen> createState() =>
      _PropertyDetailsEditableScreenState();
}

class _PropertyDetailsEditableScreenState
    extends State<PropertyDetailsEditableScreen> {
  final ApartmentManagementService _managementService =
      ApartmentManagementService();
  final ApartmentRoomService _roomService = ApartmentRoomService();
  final ImagePicker _picker = ImagePicker();

  ApartmentCompleteModel? _apartment;
  bool _isLoading = true;

  final _propertyNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();

  List<Map<String, TextEditingController>> _customFieldControllers = [];
  Map<String, Map<String, TextEditingController>> _roomFieldControllers = {};

  @override
  void initState() {
    super.initState();
    _loadApartmentData();
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _numberController.dispose();
    _floorController.dispose();
    for (var controllerMap in _customFieldControllers) {
      controllerMap.values.forEach((controller) => controller.dispose());
    }
    _roomFieldControllers.forEach((key, controllers) {
      controllers.values.forEach((controller) => controller.dispose());
    });
    super.dispose();
  }

  Future<void> _loadApartmentData() async {
    setState(() => _isLoading = true);
    try {
      final apartment =
          await _managementService.getApartment(widget.apartmentId);

      _propertyNameController.text = apartment.propertyName ?? '';
      _numberController.text = apartment.number;
      _floorController.text = apartment.floor.toString();

      _customFieldControllers = apartment.customFields.map((field) {
        return {
          'label': TextEditingController(text: field.fieldLabel),
          'value': TextEditingController(text: field.fieldValue),
          'id': TextEditingController(text: field.id?.toString() ?? ''),
        };
      }).toList();

      _roomFieldControllers = {};
      for (var room in apartment.rooms) {
        _roomFieldControllers[room.id] = {
          'roomName': TextEditingController(text: room.roomName ?? ''),
        };
      }

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

  Future<void> _saveBasicInfo() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _loadApartmentData();

      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Informations sauvegardées avec succès')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _saveCustomFields() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final customFieldsData = _customFieldControllers
          .asMap()
          .entries
          .map((entry) => {
                'id': entry.value['id']!.text.isNotEmpty
                    ? int.parse(entry.value['id']!.text)
                    : null,
                'fieldLabel': entry.value['label']!.text,
                'fieldValue': entry.value['value']!.text,
                'displayOrder': entry.key,
              })
          .toList();

      await _managementService.updateCustomFields(
        widget.apartmentId,
        customFieldsData,
      );

      await _loadApartmentData();

      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Champs sauvegardés avec succès')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _uploadRoomImage(String roomId) async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajouter une photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

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

      await _roomService.uploadRoomImage(roomId, File(image.path));

      Navigator.pop(context);
      await _loadApartmentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo ajoutée avec succès')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteRoomImage(int imageId) async {
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
      await _roomService.deleteRoomImage(imageId);
      await _loadApartmentData();

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

  Future<void> _addCustomField() async {
    setState(() {
      _customFieldControllers.add({
        'label': TextEditingController(),
        'value': TextEditingController(),
        'id': TextEditingController(),
      });
    });
  }

  Future<void> _removeCustomField(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le champ'),
        content:
            const Text('Êtes-vous sûr de vouloir supprimer ce champ personnalisé?'),
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

    setState(() {
      _customFieldControllers[index].values.forEach((c) => c.dispose());
      _customFieldControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.apartmentLabel ?? 'Détails du bien'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apartment == null
              ? const Center(child: Text('Aucune donnée disponible'))
              : RefreshIndicator(
                  onRefresh: _loadApartmentData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildBasicInfoAccordion(),
                        if (_apartment!.rooms.isNotEmpty)
                          _buildRoomsAccordion(),
                        _buildCustomFieldsAccordion(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBasicInfoAccordion() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
        title: const Text(
          'Informations de base',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _propertyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la propriété',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _floorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Étage',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stairs),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveBasicInfo,
                  icon: const Icon(Icons.save),
                  label: const Text('Sauvegarder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsAccordion() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.meeting_room, color: Colors.blue),
        title: const Text(
          'Pièces',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${_apartment!.rooms.length} pièce(s)'),
        children: _apartment!.rooms.map((room) {
          return _buildRoomCard(room);
        }).toList(),
      ),
    );
  }

  Widget _buildRoomCard(ApartmentRoomCompleteModel room) {
    final roomControllers = _roomFieldControllers[room.id];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: ExpansionTile(
        leading: const Icon(Icons.room_preferences, size: 20),
        title: Text(
          room.roomName ?? room.roomType.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(room.roomType.name),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (roomControllers != null) ...[
                  TextFormField(
                    controller: roomControllers['roomName'],
                    decoration: const InputDecoration(
                      labelText: 'Nom de la pièce',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              fieldValue.fieldName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: Text(value),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 24),
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
                                          imageUrl:
                                              equipment.images[index].imageUrl,
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
                  const Divider(height: 24),
                ],
                if (room.images.isNotEmpty) ...[
                  const Text(
                    'Photos de la pièce',
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
                        final image = room.images[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: image.imageUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () => _deleteRoomImage(image.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _uploadRoomImage(room.id),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Ajouter une photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldsAccordion() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.extension, color: Colors.orange),
        title: const Text(
          'Autres champs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${_customFieldControllers.length} champ(s) personnalisé(s)'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._customFieldControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controllers = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Champ ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeCustomField(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controllers['label'],
                            decoration: const InputDecoration(
                              labelText: 'Label',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controllers['value'],
                            decoration: const InputDecoration(
                              labelText: 'Valeur',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addCustomField,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un champ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveCustomFields,
                  icon: const Icon(Icons.save),
                  label: const Text('Sauvegarder les champs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
