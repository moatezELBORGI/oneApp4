import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/lease_contract_service.dart';
import '../../services/lease_contract_enhanced_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/user_avatar.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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
    if (_selectedTenant == null) {
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
                    TextField(
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
                      onChanged: (value) {
                        setState(() => _showUsersList = value.isNotEmpty);
                        _loadNonResidentUsers(search: value);
                      },
                      onTap: () {
                        setState(() => _showUsersList = true);
                      },
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
                                      imageUrl: user['picture'],
                                      name: '${user['fname']} ${user['lname']}',
                                      radius: 20,
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
                              imageUrl: _selectedTenant!['picture'],
                              name: '${_selectedTenant!['fname']} ${_selectedTenant!['lname']}',
                              radius: 25,
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
            if (_standardArticles.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Articles standards du contrat',
                                  style: AppTheme.titleStyle.copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cliquez sur un article pour le voir et le modifier',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._standardArticles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final article = entry.value;
                        final isExpanded = article['isExpanded'] ?? false;
                        final isModified = article['isModified'] ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isModified ? Colors.orange.shade50 : null,
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isModified
                                      ? Colors.orange
                                      : AppTheme.primaryColor,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  article['articleTitle'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: article['isMandatory'] == true
                                    ? const Text(
                                        'Obligatoire',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                trailing: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                ),
                                onTap: () {
                                  setState(() {
                                    article['isExpanded'] = !isExpanded;
                                  });
                                },
                              ),
                              if (isExpanded)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isModified)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 8),
                                              const Expanded(
                                                child: Text(
                                                  'Cet article a été modifié',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    article['modifiedTitle'] = article['articleTitle'];
                                                    article['modifiedContent'] = article['articleContent'];
                                                    article['isModified'] = false;
                                                  });
                                                },
                                                child: const Text(
                                                  'Réinitialiser',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      TextField(
                                        controller: TextEditingController(
                                          text: article['modifiedTitle'] ?? article['articleTitle'],
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'Titre de l\'article',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            article['modifiedTitle'] = value;
                                            article['isModified'] = true;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: TextEditingController(
                                          text: article['modifiedContent'] ?? article['articleContent'],
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'Contenu de l\'article',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 6,
                                        onChanged: (value) {
                                          setState(() {
                                            article['modifiedContent'] = value;
                                            article['isModified'] = true;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
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
