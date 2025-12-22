import 'package:flutter/material.dart';
import '../../models/room_type_model.dart';
import '../../models/apartment_room_complete_model.dart';
import '../../models/apartment_complete_model.dart';
import '../../services/apartment_management_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateApartmentWizardScreen extends StatefulWidget {
  final int buildingId;
  final int maxFloors;
  final List<Map<String, dynamic>> owners;

  const CreateApartmentWizardScreen({
    Key? key,
    required this.buildingId,
    required this.maxFloors,
    required this.owners,
  }) : super(key: key);

  @override
  State<CreateApartmentWizardScreen> createState() =>
      _CreateApartmentWizardScreenState();
}

class _CreateApartmentWizardScreenState
    extends State<CreateApartmentWizardScreen> {
  final _apiService = ApiService();
  late final ApartmentManagementService _apartmentService;
  final _storageService = StorageService();

  int _currentStep = 0;
  bool _isLoading = false;

  final _propertyNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  String? _selectedOwnerId;

  List<RoomTypeModel> _roomTypes = [];
  List<CreateRoomData> _rooms = [];

  List<CustomFieldData> _customFields = [
    CustomFieldData(
      label: 'Consommation énergie',
      value: '',
      isSystemField: true,
    ),
    CustomFieldData(
      label: 'Émission CO2',
      value: '',
      isSystemField: true,
    ),
    CustomFieldData(
      label: 'Numéro rapport CPEB',
      value: '',
      isSystemField: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _apartmentService = ApartmentManagementService(_apiService);
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    try {
      final roomTypes = await _apartmentService.getRoomTypes(widget.buildingId);
      setState(() {
        _roomTypes = roomTypes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<String> _uploadImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName = 'apartment_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final url = await _storageService.uploadFile(file, fileName);
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> roomsData = [];
      for (var room in _rooms) {
        final List<Map<String, dynamic>> fieldValues = [];
        room.fieldValues.forEach((fieldDefId, value) {
          if (value != null) {
            final fieldDef = room.roomType.fieldDefinitions
                .firstWhere((fd) => fd.id == fieldDefId);

            if (fieldDef.fieldType == 'TEXT') {
              fieldValues.add({
                'fieldDefinitionId': fieldDefId,
                'textValue': value.toString(),
              });
            } else if (fieldDef.fieldType == 'NUMBER') {
              fieldValues.add({
                'fieldDefinitionId': fieldDefId,
                'numberValue': double.tryParse(value.toString()) ?? 0.0,
              });
            } else if (fieldDef.fieldType == 'BOOLEAN') {
              fieldValues.add({
                'fieldDefinitionId': fieldDefId,
                'booleanValue': value as bool,
              });
            }
          }
        });

        final List<Map<String, dynamic>> equipmentsData = [];
        for (var equipment in room.equipments) {
          equipmentsData.add({
            'name': equipment.name,
            'description': equipment.description,
            'imageUrls': equipment.imageUrls,
          });
        }

        roomsData.add({
          'roomTypeId': room.roomType.id,
          'roomName': room.customName,
          'fieldValues': fieldValues,
          'equipments': equipmentsData,
          'imageUrls': room.imageUrls,
        });
      }

      final List<Map<String, dynamic>> customFieldsData = _customFields
          .where((cf) => cf.value.isNotEmpty)
          .map((cf) => {
                'fieldLabel': cf.label,
                'fieldValue': cf.value,
                'isSystemField': cf.isSystemField,
              })
          .toList();

      final apartmentData = {
        'propertyName': _propertyNameController.text,
        'number': _numberController.text,
        'floor': int.parse(_floorController.text),
        'ownerId': _selectedOwnerId,
        'buildingId': widget.buildingId,
        'rooms': roomsData,
        'customFields': customFieldsData,
      };

      await _apartmentService.createApartment(apartmentData);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appartement créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un appartement'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                ),
              ),
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Row(
                      children: [
                        if (_currentStep < 2)
                          Expanded(
                            child: CustomButton(
                              text: 'Suivant',
                              onPressed: details.onStepContinue,
                            ),
                          ),
                        if (_currentStep == 2)
                          Expanded(
                            child: CustomButton(
                              text: 'Créer l\'appartement',
                              onPressed: _handleSubmit,
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (_currentStep > 0)
                          Expanded(
                            child: CustomButton(
                              text: 'Retour',
                              onPressed: details.onStepCancel,
                              variant: ButtonVariant.outlined,
                            ),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Informations de base'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: _buildBasicInfoStep(),
                  ),
                  Step(
                    title: const Text('Pièces'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: _buildRoomsStep(),
                  ),
                  Step(
                    title: const Text('Champs spécifiques'),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    content: _buildCustomFieldsStep(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Nom du bien',
          controller: _propertyNameController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Numéro',
          controller: _numberController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Étage',
          controller: _floorController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Text(
          'Maximum: ${widget.maxFloors} étages',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Propriétaire',
            border: OutlineInputBorder(),
          ),
          value: _selectedOwnerId,
          items: widget.owners.map((owner) {
            return DropdownMenuItem<String>(
              value: owner['id'],
              child: Text(owner['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedOwnerId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRoomsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_rooms.isEmpty)
          const Text(
            'Aucune pièce ajoutée. Cliquez sur le bouton + pour ajouter une pièce.',
            style: TextStyle(color: Colors.grey),
          ),
        ..._rooms.asMap().entries.map((entry) {
          final index = entry.key;
          final room = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.roomType.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _rooms.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRoomForm(room),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showAddRoomDialog,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une pièce'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomForm(CreateRoomData room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var fieldDef in room.roomType.fieldDefinitions)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildFieldInput(room, fieldDef),
          ),
      ],
    );
  }

  Widget _buildFieldInput(
    CreateRoomData room,
    RoomTypeFieldDefinitionModel fieldDef,
  ) {
    if (fieldDef.fieldType == 'NUMBER') {
      return TextField(
        decoration: InputDecoration(
          labelText: fieldDef.fieldName + (fieldDef.isRequired ? ' *' : ''),
          border: const OutlineInputBorder(),
          suffixText: fieldDef.fieldName == 'Surface' ? 'm²' : null,
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          setState(() {
            room.fieldValues[fieldDef.id] = value;
          });
        },
      );
    } else if (fieldDef.fieldType == 'BOOLEAN') {
      return SwitchListTile(
        title: Text(fieldDef.fieldName),
        value: room.fieldValues[fieldDef.id] as bool? ?? false,
        onChanged: (value) {
          setState(() {
            room.fieldValues[fieldDef.id] = value;
          });
        },
      );
    } else if (fieldDef.fieldType == 'IMAGE_LIST') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fieldDef.fieldName),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...room.imageUrls.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(entry.value),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            room.imageUrls.removeAt(entry.key);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
              InkWell(
                onTap: () => _pickImage(room),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Icon(Icons.add_photo_alternate),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (fieldDef.fieldType == 'EQUIPMENT_LIST') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fieldDef.fieldName),
          const SizedBox(height: 8),
          ...room.equipments.asMap().entries.map((entry) {
            final index = entry.key;
            final equipment = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(equipment.name)),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              room.equipments.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    if (equipment.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: equipment.imageUrls.map((url) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          OutlinedButton.icon(
            onPressed: () => _showAddEquipmentDialog(room),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un équipement'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      );
    }
    return TextField(
      decoration: InputDecoration(
        labelText: fieldDef.fieldName + (fieldDef.isRequired ? ' *' : ''),
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          room.fieldValues[fieldDef.id] = value;
        });
      },
    );
  }

  Widget _buildCustomFieldsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._customFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!field.isSystemField)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _customFields.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Valeur',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        field.value = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showAddCustomFieldDialog,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un champ'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_propertyNameController.text.isEmpty ||
          _numberController.text.isEmpty ||
          _floorController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires'),
          ),
        );
        return;
      }

      final floor = int.tryParse(_floorController.text);
      if (floor == null || floor > widget.maxFloors || floor < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'L\'étage doit être entre 0 et ${widget.maxFloors}',
            ),
          ),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _showAddRoomDialog() async {
    RoomTypeModel? selectedRoomType;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une pièce'),
        content: DropdownButtonFormField<RoomTypeModel>(
          decoration: const InputDecoration(
            labelText: 'Type de pièce',
            border: OutlineInputBorder(),
          ),
          items: _roomTypes.map((roomType) {
            return DropdownMenuItem(
              value: roomType,
              child: Text(roomType.name),
            );
          }).toList(),
          onChanged: (value) {
            selectedRoomType = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (selectedRoomType != null) {
                setState(() {
                  _rooms.add(CreateRoomData(roomType: selectedRoomType!));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEquipmentDialog(CreateRoomData room) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un équipement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  room.equipments.add(
                    EquipmentData(
                      name: nameController.text,
                      description: descController.text,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustomFieldDialog() async {
    final labelController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un champ personnalisé'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            labelText: 'Libellé',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (labelController.text.isNotEmpty) {
                setState(() {
                  _customFields.add(
                    CustomFieldData(
                      label: labelController.text,
                      value: '',
                      isSystemField: false,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(CreateRoomData room) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final url = await _uploadImage(image);
        setState(() {
          room.imageUrls.add(url);
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
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _numberController.dispose();
    _floorController.dispose();
    super.dispose();
  }
}

class CreateRoomData {
  final RoomTypeModel roomType;
  String? customName;
  Map<int, dynamic> fieldValues = {};
  List<EquipmentData> equipments = [];
  List<String> imageUrls = [];

  CreateRoomData({
    required this.roomType,
    this.customName,
  });
}

class EquipmentData {
  final String name;
  final String description;
  List<String> imageUrls = [];

  EquipmentData({
    required this.name,
    required this.description,
  });
}

class CustomFieldData {
  final String label;
  String value;
  final bool isSystemField;

  CustomFieldData({
    required this.label,
    required this.value,
    required this.isSystemField,
  });
}
