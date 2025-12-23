import 'package:flutter/material.dart';
import '../../models/room_type_model.dart';
import '../../services/apartment_room_service.dart';
import '../../widgets/equipment_selector_widget.dart';

class AddRoomScreen extends StatefulWidget {
  final String apartmentId;

  const AddRoomScreen({Key? key, required this.apartmentId}) : super(key: key);

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final ApartmentRoomService _roomService = ApartmentRoomService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _roomNameController = TextEditingController();
  RoomTypeModel? _selectedRoomType;
  List<RoomTypeModel> _roomTypes = [];
  List<SelectedEquipment> _selectedEquipments = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomTypes() async {
    setState(() => _isLoading = true);
    try {
      final roomTypes = await _roomService.getAllRoomTypes();
      setState(() {
        _roomTypes = roomTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  bool get _shouldShowEquipmentSelector {
    if (_selectedRoomType == null) return false;
    final roomTypeName = _selectedRoomType!.name.toLowerCase();
    return roomTypeName.contains('cuisine') ||
           roomTypeName.contains('kitchen') ||
           roomTypeName.contains('salle d\'eau') ||
           roomTypeName.contains('salle de bain') ||
           roomTypeName.contains('bathroom');
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un type de pièce')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final roomId = await _roomService.createRoomWithEquipments(
        apartmentId: widget.apartmentId,
        roomName: _roomNameController.text,
        roomTypeId: _selectedRoomType!.id,
        equipments: _selectedEquipments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pièce créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une pièce'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations générales',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _roomNameController,
                              decoration: InputDecoration(
                                labelText: 'Nom de la pièce *',
                                hintText: 'Ex: Cuisine principale, Chambre 1...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.label),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<RoomTypeModel>(
                              value: _selectedRoomType,
                              decoration: InputDecoration(
                                labelText: 'Type de pièce *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.category),
                              ),
                              items: _roomTypes.map((roomType) {
                                return DropdownMenuItem(
                                  value: roomType,
                                  child: Text(roomType.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRoomType = value;
                                  _selectedEquipments = [];
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Veuillez sélectionner un type';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_shouldShowEquipmentSelector && _selectedRoomType != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: EquipmentSelectorWidget(
                            roomTypeId: _selectedRoomType!.id,
                            onEquipmentsChanged: (equipments) {
                              setState(() {
                                _selectedEquipments = equipments;
                              });
                            },
                            initialEquipments: _selectedEquipments,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveRoom,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Créer la pièce',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
