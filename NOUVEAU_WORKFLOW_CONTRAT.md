# Nouveau Workflow de Création de Contrat

## Vue d'ensemble

Le workflow de création de contrat a été modifié pour exiger un état des lieux d'entrée signé avant que le contrat puisse être finalisé. Ce changement garantit que tous les contrats de location sont accompagnés d'un état des lieux complet et signé.

## Changements Implémentés

### 1. Modification de la Base de Données

**Fichier**: `V19__Add_entry_inventory_to_lease_contracts.sql`

- Ajout du champ `entry_inventory_id` dans la table `lease_contracts`
- Ce champ référence l'état des lieux d'entrée obligatoire
- Contrainte de clé étrangère vers la table `inventories`

### 2. Modification du Modèle LeaseContract

**Fichier**: `LeaseContract.java`

- Ajout de la relation `@ManyToOne` vers `Inventory entryInventory`
- Cette relation stocke la référence à l'état des lieux d'entrée

### 3. Modification du Service InventoryService

**Fichier**: `InventoryService.java`

#### Nouvelle méthode: `copySignaturesToContractIfEntry()`

Cette méthode est appelée automatiquement après qu'un état des lieux d'entrée soit signé par les deux parties. Elle effectue les opérations suivantes:

1. **Copie des signatures**: Les signatures du propriétaire et du locataire de l'état des lieux sont automatiquement copiées vers le contrat
2. **Mise à jour du statut du contrat**: Le contrat passe au statut `SIGNED`
3. **Mise à jour de l'appartement**: Le locataire est défini comme résident actuel de l'appartement
4. **Création de l'entrée resident_building**:
   - Si le locataire n'est pas le propriétaire (propriétaire occupant), une nouvelle entrée est créée dans `resident_building`
   - Si une entrée existe déjà, elle est mise à jour avec le nouvel appartement et activée
   - Le rôle attribué est `RESIDENT`

### 4. Modification du Service LeaseContractService

**Fichier**: `LeaseContractService.java`

Les méthodes de signature directe du contrat ont été désactivées:
- `signContractByOwner()`: Lève maintenant une exception
- `signContractByTenant()`: Lève maintenant une exception

Ces méthodes retournent une erreur expliquant que la signature doit se faire via l'état des lieux d'entrée.

## Nouveau Workflow

### Étape 1: Création du Contrat
Le propriétaire crée un contrat avec toutes les informations nécessaires:
- Informations du locataire
- Montant du loyer
- Dates de début et de fin
- Articles et sections personnalisées

Le contrat est créé avec le statut `DRAFT`.

### Étape 2: Création de l'État des Lieux d'Entrée
Un état des lieux d'entrée (`InventoryType.ENTRY`) doit être créé pour le contrat:
- Lié au contrat via `contract_id`
- Contient toutes les pièces de l'appartement
- Photos et descriptions de l'état initial

### Étape 3: Signature de l'État des Lieux
Le propriétaire et le locataire signent l'état des lieux d'entrée dans n'importe quel ordre.

Lorsque la **deuxième signature** est apposée:

1. **État des lieux**:
   - Statut passe à `SIGNED`

2. **Contrat** (automatique):
   - Les signatures sont copiées depuis l'état des lieux
   - Le champ `entry_inventory_id` est défini
   - Statut passe à `SIGNED`

3. **Appartement** (automatique):
   - Le locataire est défini comme résident actuel

4. **Resident Building** (automatique):
   - Une entrée est créée pour donner l'accès au locataire dans l'immeuble
   - Rôle: `RESIDENT`
   - Associé à l'appartement

### Étape 4: Contrat Finalisé
Le contrat est maintenant complètement signé et actif:
- Les deux parties ont signé via l'état des lieux
- Le locataire a accès à l'appartement dans le système
- L'état des lieux d'entrée est lié au contrat

## Avantages

1. **Cohérence**: Tous les contrats ont un état des lieux d'entrée complet
2. **Traçabilité**: Les signatures sont liées entre l'état des lieux et le contrat
3. **Automatisation**: La création du résident dans le système est automatique
4. **Sécurité**: Impossible de signer un contrat sans état des lieux

## Notes Techniques

### Gestion des Propriétaires Occupants
Si le propriétaire et le locataire sont la même personne (propriétaire occupant):
- La création d'une entrée `resident_building` est sautée
- Le propriétaire a déjà accès via son rôle de `OWNER`

### Gestion des Résidents Existants
Si un résident a déjà une entrée `resident_building` dans l'immeuble:
- L'entrée existante est mise à jour avec le nouvel appartement
- L'entrée est réactivée (`is_active = true`)

## Migration pour les Contrats Existants

Les contrats existants dans la base de données ne sont pas affectés:
- Le champ `entry_inventory_id` est nullable
- Les anciens contrats peuvent continuer à fonctionner
- Seuls les nouveaux contrats suivent le nouveau workflow
