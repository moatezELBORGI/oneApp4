# Modifications du Workflow de Création de Contrat - Guide d'Implémentation

## Modifications Backend Effectuées

### 1. InventoryService
- **Validation ajoutée**: Un seul état des lieux d'entrée et un seul de sortie par contrat
- **Génération automatique des PDFs**: Lorsque l'état des lieux d'entrée est signé par les deux parties:
  - PDF de l'état des lieux généré automatiquement
  - PDF du contrat généré automatiquement
  - Les deux parties sont considérées comme ayant signé le contrat
  - Le locataire est ajouté à `resident_building` avec le rôle `RESIDENT`

### 2. LeaseContractService
- **Signature directe bloquée**: Les méthodes `signContractByOwner` et `signContractByTenant` lèvent maintenant une exception
- Message d'erreur clair indiquant qu'il faut passer par l'état des lieux d'entrée

### 3. Nouveau Service: TenantQuickCreateService
- **Endpoint**: `POST /residents/tenant-quick`
- **Fonctionnalités**:
  - Crée un nouveau locataire rapidement
  - Génère automatiquement un mot de passe sécurisé (12 caractères avec majuscules, minuscules, chiffres et caractères spéciaux)
  - Envoie un email de bienvenue avec les identifiants
  - Active le compte immédiatement (pas de vérification OTP nécessaire)

**Payload**:
```json
{
  "fname": "Prénom",
  "lname": "Nom",
  "email": "email@example.com",
  "phoneNumber": "+32499123456"
}
```

**Réponse**:
```json
{
  "idUsers": "uuid",
  "fname": "Prénom",
  "lname": "Nom",
  "email": "email@example.com",
  "phoneNumber": "+32499123456",
  "role": "RESIDENT",
  "accountStatus": "ACTIVE",
  "isEnabled": true
}
```

## Modifications Frontend Nécessaires

### 1. Écran create_contract_screen.dart

#### Modifications à apporter:

**A. Retirer toute section de signature**
- Supprimer tous les widgets liés à la signature du contrat
- Le contrat est sauvegardé en DRAFT et sera signé automatiquement via l'état des lieux

**B. Modifier le bouton principal**
Remplacer:
```dart
CustomButton(
  text: 'Créer le contrat',
  onPressed: _isLoading ? null : _createContract,
)
```

Par:
```dart
CustomButton(
  text: 'Enregistrer et créer un état des lieux d\'entrée',
  onPressed: _isLoading ? null : _saveContractAndCreateInventory,
  icon: Icons.description,
)
```

**C. Ajouter le lien "Utilisateur non trouvé?"**
Dans la section de sélection du locataire, après la liste des utilisateurs:
```dart
TextButton.icon(
  onPressed: () => _showCreateTenantDialog(),
  icon: Icon(Icons.person_add, color: AppTheme.primaryColor),
  label: Text(
    'Utilisateur non trouvé ?',
    style: TextStyle(color: AppTheme.primaryColor),
  ),
)
```

**D. Nouvelle méthode: _saveContractAndCreateInventory**
```dart
Future<void> _saveContractAndCreateInventory() async {
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

    final contractResponse = await _contractService.createContract(
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

    final contractId = contractResponse['id'];

    final inventoryResponse = await _inventoryService.createInventory(
      contractId: contractId,
      type: 'ENTRY',
      inventoryDate: DateTime.now(),
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryDetailScreen(
            inventoryId: inventoryResponse['id'],
            contractId: contractId,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrat sauvegardé. Complétez l\'état des lieux d\'entrée.'),
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
```

**E. Nouvelle méthode: _showCreateTenantDialog**
```dart
Future<void> _showCreateTenantDialog() async {
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ajouter un nouveau locataire'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: fnameController,
                label: 'Prénom',
                required: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: lnameController,
                label: 'Nom',
                required: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: emailController,
                label: 'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: phoneController,
                label: 'Téléphone',
                required: true,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Text(
                'Un mot de passe sera généré automatiquement et envoyé par email au locataire.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'fname': fnameController.text.trim(),
                'lname': lnameController.text.trim(),
                'email': emailController.text.trim(),
                'phoneNumber': phoneController.text.trim(),
              });
            }
          },
          child: const Text('Créer'),
        ),
      ],
    ),
  );

  if (result != null) {
    setState(() => _isLoading = true);
    try {
      final newTenant = await _enhancedService.createTenantQuick(
        fname: result['fname'],
        lname: result['lname'],
        email: result['email'],
        phoneNumber: result['phoneNumber'],
      );

      setState(() {
        _selectedTenant = newTenant;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Locataire créé avec succès. Un email a été envoyé à ${result['email']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
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
```

### 2. Service lease_contract_enhanced_service.dart

Ajouter la méthode suivante:

```dart
Future<Map<String, dynamic>> createTenantQuick({
  required String fname,
  required String lname,
  required String email,
  required String phoneNumber,
}) async {
  final response = await _apiService.post(
    '/residents/tenant-quick',
    {
      'fname': fname,
      'lname': lname,
      'email': email,
      'phoneNumber': phoneNumber,
    },
  );

  return response;
}
```

### 3. Service inventory_service.dart

Vérifier qu'il existe une méthode `createInventory`:

```dart
Future<Map<String, dynamic>> createInventory({
  required String contractId,
  required String type,
  required DateTime inventoryDate,
}) async {
  final response = await _apiService.post(
    '/inventories',
    {
      'contractId': contractId,
      'type': type,
      'inventoryDate': inventoryDate.toIso8601String(),
    },
  );

  return response;
}
```

## Workflow Complet

### Étape 1: Création du contrat
1. Le propriétaire remplit le formulaire de contrat
2. Il cherche un locataire existant OU clique sur "Utilisateur non trouvé?" pour en créer un nouveau
3. Si nouveau locataire:
   - Popup s'ouvre avec formulaire (Nom, Prénom, Email, Téléphone)
   - Système génère mot de passe et envoie email
   - Locataire est sélectionné automatiquement
4. Clic sur "Enregistrer et créer un état des lieux d'entrée"
5. Contrat sauvegardé en DRAFT
6. Redirection automatique vers l'écran de l'état des lieux d'entrée

### Étape 2: État des lieux d'entrée
1. L'écran de l'état des lieux d'entrée s'ouvre automatiquement
2. Le propriétaire et le locataire remplissent l'état des lieux
3. Les deux parties signent l'état des lieux

### Étape 3: Finalisation automatique
Lorsque la deuxième signature est apposée sur l'état des lieux:
1. État des lieux passe à SIGNED
2. PDFs générés automatiquement (état des lieux + contrat)
3. Signatures copiées vers le contrat
4. Contrat passe à SIGNED
5. Locataire ajouté dans resident_building
6. Appartement mis à jour avec le nouveau résident

## Notes Importantes

1. **Validation backend**: Il est impossible de créer deux états des lieux d'entrée pour le même contrat
2. **Signature unique**: Le contrat ne peut être signé QUE via l'état des lieux d'entrée
3. **Email automatique**: Lors de la création rapide d'un locataire, un email est envoyé avec les identifiants
4. **Compte actif**: Les locataires créés via cette méthode ont un compte actif immédiatement (pas d'OTP)
5. **PDFs automatiques**: Les PDFs sont générés automatiquement, pas besoin de bouton manuel
