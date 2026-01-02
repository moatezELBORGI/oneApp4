import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/lease_contract_service.dart';
import '../../services/lease_contract_enhanced_service.dart';
import '../../services/tenant_quick_create_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/user_avatar.dart';
import '../inventory/inventory_detail_screen.dart';

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
  final TenantQuickCreateService _tenantQuickCreateService = TenantQuickCreateService();
  final InventoryService _inventoryService = InventoryService();

  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _chargesController = TextEditingController();
  final _searchController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _selectedTenant;
  String _regionCode = 'BE-BXL';

  bool _isLoading = false;
  bool _loadingUsers = false;
  List<Map<String, dynamic>> _nonResidentUsers = [];
  List<Map<String, dynamic>> _standardArticles = [];
  List<Map<String, dynamic>> _customSections = [];
  bool _showUsersList = false;

  Timer? _debounce;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadStandardArticles();
    _loadNonResidentUsers();
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    _chargesController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadNonResidentUsers({String? search}) async {
    setState(() => _loadingUsers = true);
    try {
      final users = await _enhancedService.getNonResidentUsers(search: search);
      setState(() {
        _nonResidentUsers = users;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
      if (mounted) {
        _showErrorSnackBar('Erreur lors du chargement des utilisateurs: $e');
      }
    }
  }

  Future<void> _loadStandardArticles() async {
    try {
      final articles = await _enhancedService.getStandardArticles(_regionCode);
      setState(() {
        _standardArticles = articles.map((article) {
          return {
            ...article,
            'isExpanded': false,
            'isModified': false,
            'modifiedTitle': article['articleTitle'],
            'modifiedContent': article['articleContent'],
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors du chargement des articles: $e');
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _showUsersList = value.isNotEmpty);
      _loadNonResidentUsers(search: value);
    });
  }

  Future<void> _createContractAndNavigateToInventory() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation groupée
    final validationErrors = <String>[];
    if (_startDate == null) {
      validationErrors.add('Veuillez sélectionner une date de début');
    }
    if (_selectedTenant == null) {
      validationErrors.add('Veuillez sélectionner un locataire');
    }
    if (_endDate != null && _endDate!.isBefore(_startDate!)) {
      validationErrors.add('La date de fin doit être après la date de début');
    }

    if (validationErrors.isNotEmpty) {
      _showValidationErrors(validationErrors);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ownerId = authProvider.user?.id;

      if (ownerId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final contract = await _contractService.createContract(
        apartmentId: widget.apartmentId,
        ownerId: ownerId,
        tenantId: _selectedTenant!['idUsers'],
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

      final inventory = await _inventoryService.createInventory(
        contractId: contract.id,
        type: 'ENTREE',
        inventoryDate: DateTime.now(),
      );

      if (mounted) {
        _showSuccessSnackBar('Contrat enregistré en brouillon');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InventoryDetailScreen(
              inventoryId: inventory.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la création du contrat: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateTenantDialog() {
    final fnameController = TextEditingController();
    final lnameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Créer un nouveau locataire'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        controller: fnameController,
                        label: 'Prénom',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le prénom est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: lnameController,
                        label: 'Nom',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'L\'email est obligatoire';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: phoneController,
                        label: 'Téléphone',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le téléphone est obligatoire';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isCreating ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isCreating = true);
                      try {
                        final newTenant = await _tenantQuickCreateService.createTenantQuick(
                          fname: fnameController.text.trim(),
                          lname: lnameController.text.trim(),
                          email: emailController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {
                            _selectedTenant = newTenant;
                            _searchController.text = '${newTenant['fname']} ${newTenant['lname']}';
                            _showUsersList = false;
                          });
                          _showSuccessSnackBar('Locataire créé avec succès. Un email de bienvenue a été envoyé.');
                          _loadNonResidentUsers();
                        }
                      } catch (e) {
                        setDialogState(() => isCreating = false);
                        if (mounted) {
                          _showErrorSnackBar('Erreur lors de la création: $e');
                        }
                      }
                    }
                  },
                  child: isCreating
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showValidationErrors(List<String> errors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('• $e'),
          )).toList(),
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDate({
    required bool isStartDate,
  }) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate?.add(const Duration(days: 365)) ?? DateTime.now().add(const Duration(days: 365)));

    final firstDate = isStartDate
        ? DateTime.now()
        : (_startDate ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
      locale: const Locale('fr', 'FR'),
      helpText: isStartDate ? 'Sélectionner la date de début' : 'Sélectionner la date de fin',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          // Si la date de fin existe et est avant la nouvelle date de début, on la réinitialise
          if (_endDate != null && _endDate!.isBefore(date)) {
            _endDate = null;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouveau contrat de bail'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Locataire
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
                        Semantics(
                          label: 'Rechercher un locataire',
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Rechercher un utilisateur',
                              hintText: 'Nom, prénom ou email',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _showUsersList = false;
                                  });
                                  _loadNonResidentUsers();
                                },
                              )
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: _onSearchChanged,
                            onTap: () {
                              if (_searchController.text.isNotEmpty) {
                                setState(() => _showUsersList = true);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showCreateTenantDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Utilisateur non trouvé ? Créer un nouveau locataire',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showUsersList && !_loadingUsers) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _nonResidentUsers.isEmpty
                                ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Aucun utilisateur trouvé',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                                : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _nonResidentUsers.length,
                              itemBuilder: (context, index) {
                                final user = _nonResidentUsers[index];
                                return ListTile(
                                  leading: UserAvatar(
                                    profilePictureUrl: user['picture'],
                                    lastName: '${user['fname']} ${user['lname']}',
                                    radius: 20,
                                    firstName: '',
                                  ),
                                  title: Text('${user['fname']} ${user['lname']}'),
                                  subtitle: Text(user['email'] ?? ''),
                                  onTap: () {
                                    setState(() {
                                      _selectedTenant = user;
                                      _searchController.text = '${user['fname']} ${user['lname']}';
                                      _showUsersList = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                        if (_loadingUsers) ...[
                          const SizedBox(height: 16),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        if (_selectedTenant != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Locataire sélectionné',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(
                                  profilePictureUrl: _selectedTenant!['picture'],
                                  lastName: '${_selectedTenant!['fname']} ${_selectedTenant!['lname']}',
                                  radius: 25,
                                  firstName: '',
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_selectedTenant!['fname']} ${_selectedTenant!['lname']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_selectedTenant!['email'] != null)
                                        Text(
                                          _selectedTenant!['email'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      if (_selectedTenant!['phoneNumber'] != null)
                                        Text(
                                          _selectedTenant!['phoneNumber'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _selectedTenant = null;
                                      _searchController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section Détails du contrat
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
                          title: const Text('Date de début *'),
                          subtitle: Text(
                            _startDate != null
                                ? _dateFormat.format(_startDate!)
                                : 'Non définie',
                            style: TextStyle(
                              color: _startDate != null ? Colors.black87 : Colors.red,
                              fontWeight: _startDate != null ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(isStartDate: true),
                        ),
                        ListTile(
                          title: const Text('Date de fin (optionnel)'),
                          subtitle: Text(
                            _endDate != null
                                ? _dateFormat.format(_endDate!)
                                : 'Durée indéterminée',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20, color: Colors.red),
                                  onPressed: () => setState(() => _endDate = null),
                                ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                          onTap: () => _selectDate(isStartDate: false),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _rentController,
                          label: 'Loyer mensuel (€) *',
                          hint: 'Ex: 950.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le loyer';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null) {
                              return 'Veuillez entrer un montant valide';
                            }
                            if (amount <= 0) {
                              return 'Le loyer doit être supérieur à 0';
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
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null) {
                                return 'Veuillez entrer un montant valide';
                              }
                              if (amount < 0) {
                                return 'Le montant ne peut pas être négatif';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _chargesController,
                          label: 'Charges mensuelles (€) - optionnel',
                          hint: 'Ex: 150.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null) {
                                return 'Veuillez entrer un montant valide';
                              }
                              if (amount < 0) {
                                return 'Le montant ne peut pas être négatif';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton principal avec texte adaptatif
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Si l'écran est petit, on utilise un texte plus court
                    final buttonText = constraints.maxWidth < 400
                        ? 'Créer contrat et état des lieux'
                        : 'Enregistrer et créer un état de lieu d\'entrée';

                    return CustomButton(
                      text: buttonText,
                      onPressed: _isLoading ? null : _createContractAndNavigateToInventory,
                      isLoading: _isLoading,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

            // Indicateur de chargement global
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}