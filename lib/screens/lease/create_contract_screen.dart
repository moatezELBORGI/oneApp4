import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/lease_contract_service.dart';
import '../../services/lease_contract_enhanced_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateContractScreen extends StatefulWidget {
  final String apartmentId;

  const CreateContractScreen({
    Key? key,
    required this.apartmentId,
  }) : super(key: key);

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeaseContractService _contractService = LeaseContractService();
  final LeaseContractEnhancedService _enhancedService = LeaseContractEnhancedService();

  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _chargesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedTenantId;
  String _regionCode = 'BE-BXL';

  bool _isLoading = false;
  bool _loadingMembers = false;
  List<Map<String, dynamic>>? _buildingMembers;
  List<Map<String, dynamic>>? _standardArticles;
  List<Map<String, dynamic>> _customSections = [];

  @override
  void initState() {
    super.initState();
    _loadBuildingMembers();
    _loadStandardArticles();
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    _chargesController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildingMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final buildingId = authProvider.user?.buildingId;

      if (buildingId != null) {
        final response = await _enhancedService.getBuildingMembers(buildingId);
        setState(() {
          _buildingMembers = response;
          _loadingMembers = false;
        });
      }
    } catch (e) {
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _loadStandardArticles() async {
    try {
      final articles = await _enhancedService.getStandardArticles(_regionCode);
      setState(() => _standardArticles = articles);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des articles: $e')),
        );
      }
    }
  }

  Future<void> _createContract() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de début')),
      );
      return;
    }
    if (_selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un locataire')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ownerId = authProvider.user?.id;

      await _contractService.createContract(
        apartmentId: widget.apartmentId,
        ownerId: ownerId!,
        tenantId: _selectedTenantId!,
        startDate: _startDate!,
        endDate: _endDate,
        initialRentAmount: double.parse(_rentController.text.trim()),
        depositAmount: _depositController.text.isNotEmpty
            ? double.parse(_depositController.text.trim())
            : null,
        chargesAmount: _chargesController.text.isNotEmpty
            ? double.parse(_chargesController.text.trim())
            : null,
        regionCode: _regionCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrat créé avec succès')),
        );
        Navigator.pop(context, true);
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

  void _addCustomSection() {
    setState(() {
      _customSections.add({
        'title': '',
        'content': '',
      });
    });
  }

  void _removeCustomSection(int index) {
    setState(() {
      _customSections.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouveau contrat de bail'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations du locataire',
                      style: AppTheme.titleStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingMembers)
                      const Center(child: CircularProgressIndicator())
                    else if (_buildingMembers != null && _buildingMembers!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sélectionner le locataire',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedTenantId,
                                isExpanded: true,
                                hint: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Choisir un locataire'),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: currentUserId,
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.blue[700], size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Moi-même (propriétaire occupant)'),
                                      ],
                                    ),
                                  ),
                                  ..._buildingMembers!.map((member) {
                                    return DropdownMenuItem<String>(
                                      value: member['idUsers'],
                                      child: Text(
                                        '${member['fname']} ${member['lname']}',
                                      ),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (String? value) {
                                  setState(() => _selectedTenantId = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails du contrat',
                      style: AppTheme.titleStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date de début'),
                      subtitle: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Non définie',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Date de fin (optionnel)'),
                      subtitle: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Durée indéterminée',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate?.add(const Duration(days: 365)) ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _rentController,
                      label: 'Loyer mensuel (€)',
                      hint: 'Ex: 950.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le loyer';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un montant valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _depositController,
                      label: 'Garantie locative (€) - optionnel',
                      hint: 'Ex: 1900.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _chargesController,
                      label: 'Charges mensuelles (€) - optionnel',
                      hint: 'Ex: 150.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_standardArticles != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Articles standards du contrat',
                        style: AppTheme.titleStyle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_standardArticles!.length} articles seront inclus dans le contrat',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sections personnalisées',
                          style: AppTheme.titleStyle.copyWith(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                          onPressed: _addCustomSection,
                        ),
                      ],
                    ),
                    if (_customSections.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aucune section personnalisée.\nAppuyez sur + pour en ajouter.',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ..._customSections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Section ${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeCustomSection(index),
                                  ),
                                ],
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Titre',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  section['title'] = value;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Contenu',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                onChanged: (value) {
                                  section['content'] = value;
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Créer le contrat',
              onPressed: _isLoading ? null : _createContract,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
