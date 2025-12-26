import 'package:flutter/material.dart';
import '../../models/room_type_model.dart';
import '../../models/apartment_room_complete_model.dart';
import '../../models/apartment_complete_model.dart';
import '../../services/apartment_management_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/equipment_selector_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateApartmentWizardScreen extends StatefulWidget {
  final String buildingId;
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

final ApiService _apiService = ApiService();

class _CreateApartmentWizardScreenState
    extends State<CreateApartmentWizardScreen> with SingleTickerProviderStateMixin {
  late final ApartmentManagementService _apartmentService;
  final _storageService = StorageService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  bool _isLoading = false;

  final _propertyNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  String? _selectedOwnerId;

  List<RoomTypeModel> _roomTypes = [];
  List<CreateRoomData> _rooms = [];

  final _surfaceController = TextEditingController();

  List<CustomFieldData> _customFields = [
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
        _showErrorSnackBar('Erreur lors du chargement des types de pièces');
      }
    }
  }

  Future<String> _uploadImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName = 'apartment_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final url = await _apiService.uploadFile(file, fileName);
      final pictureurl = url['url'];
      return pictureurl;
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

      final apartmentData = {
        'propertyName': _propertyNameController.text,
        'number': _numberController.text,
        'floor': int.parse(_floorController.text),
        'surface': _surfaceController.text.isNotEmpty ? double.tryParse(_surfaceController.text) : null,
        'ownerId': _selectedOwnerId,
        'buildingId': widget.buildingId,
        'rooms': roomsData,
        'customFields': customFieldsData,
      };

      await _apartmentService.createApartment(apartmentData);

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Appartement créé avec succès');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la création: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nouvel appartement'),
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
              'Création en cours...',
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
                color: (isCompleted ? Colors.green : Theme.of(context).primaryColor)
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Étage maximum: ${widget.maxFloors}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Propriétaire',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: Icon(Icons.person),
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
                  Icon(Icons.meeting_room_outlined, size: 72, color: Colors.grey[400]),
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
                    label: const Text('Ajouter la première pièce'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      room.roomType.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Supprimer la pièce'),
                            content: const Text('Êtes-vous sûr de vouloir supprimer cette pièce ?'),
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    children: [
                      _buildRoomForm(room),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showAddRoomDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Ajouter une autre pièce'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
            ],
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

  Widget _buildFieldInput(CreateRoomData room, RoomTypeFieldDefinitionModel fieldDef) {
    if (fieldDef.fieldType == 'NUMBER') {
      return TextField(
        decoration: InputDecoration(
          labelText: fieldDef.fieldName + (fieldDef.isRequired ? ' *' : ''),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixText: fieldDef.fieldName == 'Surface' ? 'm²' : null,
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          setState(() {
            room.fieldValues[fieldDef.id] = value;
          });
        },
      );
    } else if (fieldDef.fieldType == 'BOOLEAN') {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          title: Text(fieldDef.fieldName),
          value: room.fieldValues[fieldDef.id] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              room.fieldValues[fieldDef.id] = value;
            });
          },
        ),
      );
    } else if (fieldDef.fieldType == 'IMAGE_LIST') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                fieldDef.fieldName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...room.imageUrls.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(entry.value),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
              InkWell(
                onTap: () => _pickImage(room),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[400]),
                      const SizedBox(height: 4),
                      Text('Ajouter', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (fieldDef.fieldType == 'EQUIPMENT_LIST') {
      return EquipmentSelectorWidget(
        roomTypeId: room.roomType.id,
        onEquipmentsChanged: (equipments) {
          setState(() {
            room.selectedEquipments = equipments;
          });
        },
        initialEquipments: room.selectedEquipments,
      );
    }
    return TextField(
      decoration: InputDecoration(
        labelText: fieldDef.fieldName + (fieldDef.isRequired ? ' *' : ''),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Ajoutez des informations supplémentaires',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.square_foot, size: 22, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Surface totale',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _surfaceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Surface (m²)',
                    suffixText: 'm²',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._customFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (field.icon != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Theme.of(context).primaryColor.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(field.icon, size: 22, color: Theme.of(context).primaryColor),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          field.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (!field.isSystemField)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                          onPressed: () {
                            setState(() {
                              _customFields.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Valeur',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
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
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Ajouter un champ personnalisé'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _onStepCancel,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Précédent'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey[400]!, width: 2),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: _currentStep < 2
                  ? ElevatedButton.icon(
                onPressed: _onStepContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Suivant'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              )
                  : ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.check_circle),
                label: const Text('Créer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_propertyNameController.text.isEmpty ||
          _numberController.text.isEmpty ||
          _floorController.text.isEmpty) {
        _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
        return;
      }

      final floor = int.tryParse(_floorController.text);
      if (floor == null || floor > widget.maxFloors || floor < 0) {
        _showErrorSnackBar('L\'étage doit être entre 0 et ${widget.maxFloors}');
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _showAddRoomDialog() async {
    RoomTypeModel? selectedRoomType;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.meeting_room, color: Colors.blue[700]),
            ),
            const SizedBox(width: 12),
            const Text('Ajouter une pièce'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<RoomTypeModel>(
              decoration: InputDecoration(
                labelText: 'Type de pièce',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (selectedRoomType != null) {
                setState(() {
                  _rooms.add(CreateRoomData(roomType: selectedRoomType!));
                });
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Veuillez sélectionner un type de pièce');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_box, color: Colors.blue[700]),
            ),
            const SizedBox(width: 12),
            const Text('Nouveau champ'),
          ],
        ),
        content: TextField(
          controller: labelController,
          decoration: InputDecoration(
            labelText: 'Libellé du champ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
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
              } else {
                _showErrorSnackBar('Veuillez entrer un libellé');
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
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
        _showSuccessSnackBar('Image ajoutée avec succès');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur lors de l\'upload: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _numberController.dispose();
    _floorController.dispose();
    _surfaceController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class CreateRoomData {
  final RoomTypeModel roomType;
  String? customName;
  Map<int, dynamic> fieldValues = {};
  List<EquipmentData> equipments = [];
  List<SelectedEquipment> selectedEquipments = [];
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
  final IconData? icon;

  CustomFieldData({
    required this.label,
    required this.value,
    required this.isSystemField,
    this.icon,
  });
}