import 'package:flutter/material.dart';
import '../../models/room_type_model.dart';
import '../../models/apartment_complete_model.dart';
import '../../models/apartment_room_complete_model.dart';
import '../../services/apartment_management_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/equipment_selector_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditApartmentWizardScreen extends StatefulWidget {
  final String apartmentId;
  final String buildingId;

  const EditApartmentWizardScreen({
    Key? key,
    required this.apartmentId,
    required this.buildingId,
  }) : super(key: key);

  @override
  State<EditApartmentWizardScreen> createState() =>
      _EditApartmentWizardScreenState();
}

final ApiService _apiService = ApiService();

class _EditApartmentWizardScreenState extends State<EditApartmentWizardScreen>
    with SingleTickerProviderStateMixin {
  late final ApartmentManagementService _apartmentService;
  final _storageService = StorageService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final _propertyNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  final _surfaceController = TextEditingController();
  String? _selectedOwnerId;

  List<RoomTypeModel> _roomTypes = [];
  List<EditRoomData> _rooms = [];
  List<CustomFieldData> _customFields = [];

  ApartmentCompleteModel? _originalApartment;

  @override
  void initState() {
    super.initState();
    _apartmentService = ApartmentManagementService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
    _loadApartmentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _propertyNameController.dispose();
    _numberController.dispose();
    _floorController.dispose();
    _surfaceController.dispose();
    super.dispose();
  }

  Future<void> _loadApartmentData() async {
    setState(() => _isLoading = true);
    try {
      final apartment = await _apartmentService.getApartment(widget.apartmentId);
      final roomTypes = await _apartmentService.getRoomTypes(widget.buildingId);

      _propertyNameController.text = apartment.propertyName ?? '';
      _numberController.text = apartment.number;
      _floorController.text = apartment.floor.toString();
      _selectedOwnerId = apartment.ownerId;

      _rooms = apartment.rooms.map((room) {
        final editRoom = EditRoomData(
          roomId: room.id,
          roomType: roomTypes.firstWhere((rt) => rt.id == room.roomType.id),
          customName: room.roomName,
        );

        for (var fieldValue in room.fieldValues) {
          if (fieldValue.textValue != null) {
            editRoom.fieldValues[fieldValue.fieldDefinitionId] = fieldValue.textValue;
          } else if (fieldValue.numberValue != null) {
            editRoom.fieldValues[fieldValue.fieldDefinitionId] = fieldValue.numberValue;
          } else if (fieldValue.booleanValue != null) {
            editRoom.fieldValues[fieldValue.fieldDefinitionId] = fieldValue.booleanValue;
          }
        }

        for (var equipment in room.equipments) {
          editRoom.equipments.add(EquipmentData(
            name: equipment.name,
            description: equipment.description ?? '',
            imageUrls: equipment.images.map((img) => img.imageUrl).toList(),
          ));
        }

        editRoom.imageUrls = room.images.map((img) => img.imageUrl).toList();

        return editRoom;
      }).toList();

      _customFields = apartment.customFields.map((field) {
        return CustomFieldData(
          label: field.fieldLabel,
          value: field.fieldValue,
          isSystemField: field.isSystemField,
        );
      }).toList();

      if (_customFields.isEmpty) {
        _customFields = [
          CustomFieldData(
            label: 'Consommation énergie',
            value: '',
            isSystemField: true,
            icon: Icons.bolt,
          ),
          CustomFieldData(
            label: 'Émission CO2',
            value: '',
            isSystemField: true,
            icon: Icons.eco,
          ),
          CustomFieldData(
            label: 'Numéro rapport CPEB',
            value: '',
            isSystemField: true,
            icon: Icons.description,
          ),
        ];
      }

      setState(() {
        _originalApartment = apartment;
        _roomTypes = roomTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Erreur lors du chargement: ${e.toString()}');
      }
    }
  }

  Future<String> _uploadImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName =
          'apartment_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final url = await _apiService.uploadFile(file, fileName);
      final pictureurl = url['url'];
      return pictureurl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSaving = true);

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

        for (var selectedEquipment in room.selectedEquipments) {
          final List<String> uploadedImageUrls = [];
          for (var imageFile in selectedEquipment.images) {
            try {
              final xFile = XFile(imageFile.path);
              final url = await _uploadImage(xFile);
              uploadedImageUrls.add(url);
            } catch (e) {
              print('Failed to upload equipment image: $e');
            }
          }

          equipmentsData.add({
            'name': selectedEquipment.template.name,
            'description': selectedEquipment.template.description,
            'imageUrls': uploadedImageUrls,
          });
        }

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

      final basicInfoData = {
        'propertyName': _propertyNameController.text,
        'number': _numberController.text,
        'floor': int.parse(_floorController.text),
        'surface': _surfaceController.text.isNotEmpty
            ? double.tryParse(_surfaceController.text)
            : null,
      };

      await _apartmentService.updateBasicInfo(widget.apartmentId, basicInfoData);
      await _apartmentService.updateRooms(widget.apartmentId, roomsData);
      await _apartmentService.updateCustomFields(
          widget.apartmentId, customFieldsData);

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Appartement modifié avec succès');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la modification: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddRoomDialog() async {
    final selectedRoomType = await showDialog<RoomTypeModel>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sélectionner le type de pièce'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _roomTypes.length,
            itemBuilder: (context, index) {
              final roomType = _roomTypes[index];
              return ListTile(
                leading: const Icon(Icons.meeting_room),
                title: Text(roomType.name),
                onTap: () => Navigator.pop(context, roomType),
              );
            },
          ),
        ),
      ),
    );

    if (selectedRoomType != null) {
      setState(() {
        _rooms.add(EditRoomData(
          roomType: selectedRoomType,
          roomId: null,
        ));
      });
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Modifier l\'appartement'),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : _isSaving
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sauvegarde en cours...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildCurrentStepContent(),
              ),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProgressStep(0, 'Informations', Icons.info_outline),
          Expanded(child: _buildProgressLine(0)),
          _buildProgressStep(1, 'Pièces', Icons.meeting_room),
          Expanded(child: _buildProgressLine(1)),
          _buildProgressStep(2, 'Champs', Icons.checklist),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isActive
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            boxShadow: isActive
                ? [
              BoxShadow(
                color: (isCompleted
                    ? Colors.green
                    : Theme.of(context).primaryColor)
                    .withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ]
                : [],
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? (isCompleted ? Colors.green : Theme.of(context).primaryColor)
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 30, left: 8, right: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: [
        _buildBasicInfoStep(),
        _buildRoomsStep(),
        _buildCustomFieldsStep(),
      ][_currentStep],
    );
  }

  Widget _buildBasicInfoStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home, color: Colors.blue[700], size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Détails de l\'appartement',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Nom du bien',
            controller: _propertyNameController,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Numéro',
                  controller: _numberController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Étage',
                  controller: _floorController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Surface (m²)',
            controller: _surfaceController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_rooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 2),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.meeting_room_outlined,
                      size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'Aucune pièce ajoutée',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez par ajouter des pièces',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddRoomDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Ajouter une pièce'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[50]!, Colors.green[100]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_rooms.length} pièce${_rooms.length > 1 ? 's' : ''} ajoutée${_rooms.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ..._rooms.asMap().entries.map((entry) {
                final index = entry.key;
                final room = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(20),
                    childrenPadding: const EdgeInsets.all(20),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      room.customName ?? room.roomType.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(room.roomType.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('Supprimer la pièce'),
                            content: const Text(
                                'Êtes-vous sûr de vouloir supprimer cette pièce ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _rooms.removeAt(index);
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final controller = TextEditingController(text: room.customName ?? '');
                              controller.addListener(() {
                                room.customName = controller.text.isEmpty ? null : controller.text;
                              });
                              return CustomTextField(
                                label: 'Nom personnalisé (optionnel)',
                                controller: controller,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          if (room.roomType.fieldDefinitions.isNotEmpty) ...[
                            Text(
                              'Caractéristiques',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...room.roomType.fieldDefinitions.map((fieldDef) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildFieldInput(room, fieldDef),
                              );
                            }).toList(),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Équipements',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (room.equipments.isNotEmpty) ...[
                            Text(
                              'Équipements existants',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...room.equipments.map((equipment) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.inventory_2_outlined),
                                  title: Text(equipment.name),
                                  subtitle: equipment.description.isNotEmpty
                                      ? Text(equipment.description)
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        room.equipments.remove(equipment);
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                          ],
                          EquipmentSelectorWidget(
                            roomTypeId: room.roomType.id,
                            onEquipmentsChanged: (equipments) {
                              setState(() {
                                room.selectedEquipments = equipments;
                              });
                            },
                            initialEquipments: room.selectedEquipments,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddRoomDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Ajouter une autre pièce'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFieldInput(EditRoomData room, RoomTypeFieldDefinitionModel fieldDef) {
    if (fieldDef.fieldType == 'TEXT') {
      final controller = TextEditingController(
        text: room.fieldValues[fieldDef.id]?.toString() ?? '',
      );
      controller.addListener(() {
        room.fieldValues[fieldDef.id] = controller.text;
      });
      return CustomTextField(
        label: fieldDef.fieldLabel,
        controller: controller,
      );
    } else if (fieldDef.fieldType == 'NUMBER') {
      final controller = TextEditingController(
        text: room.fieldValues[fieldDef.id]?.toString() ?? '',
      );
      controller.addListener(() {
        room.fieldValues[fieldDef.id] = double.tryParse(controller.text);
      });
      return CustomTextField(
        label: fieldDef.fieldLabel,
        controller: controller,
        keyboardType: TextInputType.number,
      );
    } else if (fieldDef.fieldType == 'BOOLEAN') {
      return CheckboxListTile(
        title: Text(fieldDef.fieldLabel),
        value: room.fieldValues[fieldDef.id] as bool? ?? false,
        onChanged: (value) {
          setState(() {
            room.fieldValues[fieldDef.id] = value ?? false;
          });
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCustomFieldsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                    Icon(Icons.extension, color: Colors.orange[700], size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Champs personnalisés',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ..._customFields.map((field) {
                final index = _customFields.indexOf(field);
                final controller = TextEditingController(text: field.value);
                controller.addListener(() {
                  field.value = controller.text;
                });
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      if (field.icon != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(field.icon, size: 20),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: field.label,
                          controller: controller,
                        ),
                      ),
                      if (!field.isSystemField)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _customFields.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _customFields.add(CustomFieldData(
                      label: 'Nouveau champ',
                      value: '',
                      isSystemField: false,
                    ));
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un champ'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                  _animationController.forward(from: 0);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentStep < 2) {
                  setState(() {
                    _currentStep++;
                  });
                  _animationController.forward(from: 0);
                } else {
                  _handleSubmit();
                }
              },
              icon: Icon(_currentStep < 2 ? Icons.arrow_forward : Icons.save),
              label: Text(_currentStep < 2 ? 'Suivant' : 'Enregistrer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditRoomData {
  final String? roomId;
  final RoomTypeModel roomType;
  String? customName;
  Map<int, dynamic> fieldValues = {};
  List<EquipmentData> equipments = [];
  List<SelectedEquipment> selectedEquipments = [];
  List<String> imageUrls = [];

  EditRoomData({
    this.roomId,
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
    this.imageUrls = const [],
  });
}

class CustomFieldData {
  final String label;
  String value;
  final bool isSystemField;
  final IconData? icon;

  CustomFieldData({
    required this.label,
    required this.value,
    required this.isSystemField,
    this.icon,
  });
}
