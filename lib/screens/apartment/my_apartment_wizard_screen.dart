import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/apartment_complete_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/apartment_management_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../claims/claims_screen.dart';

class MyApartmentWizardScreen extends StatefulWidget {
  final String apartmentId;

  const MyApartmentWizardScreen({
    Key? key,
    required this.apartmentId,
  }) : super(key: key);

  @override
  State<MyApartmentWizardScreen> createState() => _MyApartmentWizardScreenState();
}

class _MyApartmentWizardScreenState extends State<MyApartmentWizardScreen>
    with SingleTickerProviderStateMixin {
  late final ApartmentManagementService _apartmentService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  bool _isLoading = true;
  ApartmentCompleteModel? _apartment;

  final _propertyNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _floorController = TextEditingController();
  final _surfaceController = TextEditingController();

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
    _loadApartment();
  }

  Future<void> _loadApartment() async {
    setState(() => _isLoading = true);
    try {
      final apartment = await _apartmentService.getApartment(widget.apartmentId);
      setState(() {
        _apartment = apartment;
        _propertyNameController.text = apartment.propertyName ?? '';
        _numberController.text = apartment.number;
        _floorController.text = apartment.floor.toString();

        final surfaceField = apartment.customFields.firstWhere(
              (field) => field.fieldLabel == 'Surface totale',
          orElse: () => ApartmentCustomFieldModel(
            fieldLabel: 'Surface totale',
            fieldValue: '',
          ),
        );
        _surfaceController.text = surfaceField.fieldValue;

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
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Mon Appartement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.warning_amber_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClaimsScreen()),
            );
          },
          tooltip: 'Sinistres',
        ),
      ],
    );
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),

          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text(
                      'Chargement...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
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
            ),
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
            enabled: false,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Numéro',
                  controller: _numberController,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Étage',
                  controller: _floorController,
                  enabled: false,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (_apartment?.ownerName != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Propriétaire',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _apartment!.ownerName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomsStep() {
    if (_apartment == null || _apartment!.rooms.isEmpty) {
      return Container(
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
                'Aucune pièce enregistrée',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contactez votre administrateur',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  '${_apartment!.rooms.length} pièce${_apartment!.rooms.length > 1 ? 's' : ''} enregistrée${_apartment!.rooms.length > 1 ? 's' : ''}',
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
        ..._apartment!.rooms.asMap().entries.map((entry) {
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
                room.roomName ?? room.roomType.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(room.roomType.name),
              children: [
                _buildRoomContent(room),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRoomContent(dynamic room) {
    return Column(
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
                      placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
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
    );
  }

  Widget _buildCustomFieldsStep() {
    final surfaceField = _apartment?.customFields.firstWhere(
          (field) => field.fieldLabel == 'Surface totale',
      orElse: () => ApartmentCustomFieldModel(
        fieldLabel: 'Surface totale',
        fieldValue: '',
      ),
    );

    final otherFields = _apartment?.customFields
        .where((field) => field.fieldLabel != 'Surface totale')
        .toList() ?? [];

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
                  'Informations supplémentaires',
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
                  enabled: false,
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
        if (otherFields.isNotEmpty)
          ...otherFields.map((field) {
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
                          child: Icon(
                            field.isSystemField ? Icons.settings : Icons.label,
                            size: 22,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            field.fieldLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: TextEditingController(text: field.fieldValue),
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Valeur',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle),
                label: const Text('Terminer'),
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
