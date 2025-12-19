# Système de Gestion Propriétaires, Locataires et Contrats de Bail

## Vue d'ensemble

Ce document décrit l'implémentation complète du système de gestion des propriétaires, locataires, contrats de bail et états des lieux pour l'application OneApp.

## Table des matières

1. [Nouveau Type d'Utilisateur](#nouveau-type-dutilisateur)
2. [Structure de la Base de Données](#structure-de-la-base-de-données)
3. [Gestion des Propriétaires](#gestion-des-propriétaires)
4. [Gestion des Locataires](#gestion-des-locataires)
5. [Contrats de Bail](#contrats-de-bail)
6. [États des Lieux](#états-des-lieux)
7. [API Endpoints](#api-endpoints)
8. [Modèles Flutter](#modèles-flutter)
9. [Services Flutter](#services-flutter)

---

## Nouveau Type d'Utilisateur

### Rôle OWNER (Propriétaire)

Un nouveau rôle `OWNER` a été ajouté à l'énumération `UserRole`:

```java
public enum UserRole {
    RESIDENT,           // Résident simple
    OWNER,              // Propriétaire
    BUILDING_ADMIN,     // Admin d'un immeuble
    GROUP_ADMIN,        // Admin d'un groupe d'immeubles
    SUPER_ADMIN         // Super admin
}
```

### Règles de Gestion

- Un **admin_building** peut créer des comptes propriétaires
- Un **admin_building** peut être lui-même :
  - Un résident locataire
  - Un propriétaire
  - Les deux à la fois
  - Ni l'un ni l'autre (admin uniquement)
- Un **propriétaire** peut posséder plusieurs appartements dans un même bâtiment
- Un **propriétaire** peut créer des locataires pour ses biens

---

## Structure de la Base de Données

### Migration V12__Create_owner_tenant_lease_system.sql

La migration crée les tables suivantes :

#### 1. Modifications sur `apartments`
```sql
ALTER TABLE apartments
ADD COLUMN owner_id TEXT REFERENCES residents(id_users),
ADD COLUMN tenant_id TEXT REFERENCES residents(id_users);
```

#### 2. `apartment_rooms` - Pièces de l'appartement
- Stockage dynamique des pièces (salon, chambres, etc.)
- Description et photos par pièce
- Ordre d'affichage personnalisable

#### 3. `lease_contracts` - Contrats de bail
- Lien entre propriétaire, locataire et appartement
- Montants : loyer initial, loyer actuel, caution, charges
- Dates de début et fin
- Code région pour la législation applicable
- Signatures électroniques (propriétaire et locataire)
- Statuts : DRAFT, PENDING_SIGNATURE, SIGNED, ACTIVE, TERMINATED

#### 4. `lease_contract_articles` - Articles standards par région
- Articles prédéfinis selon la législation régionale
- Possibilité de marquer comme obligatoire

#### 5. `lease_contract_custom_sections` - Sections personnalisées
- Ajout de clauses spécifiques au contrat
- Ordre d'affichage personnalisable

#### 6. `rent_indexations` - Historique des indexations
- Montant précédent et nouveau montant
- Taux d'indexation appliqué
- Indices de base et nouveaux
- Notes explicatives
- Conservation de tout l'historique

#### 7. `inventories` - États des lieux
- Type : ENTRY (entrée) ou EXIT (sortie)
- Relevés de compteurs (électricité, eau, chauffage)
- Clés remises (appartement, boîte aux lettres, cave, badges, télécommandes)
- Signatures électroniques
- Génération de PDF
- Statuts : DRAFT, PENDING_SIGNATURE, SIGNED, FINALIZED

#### 8. `inventory_room_entries` - Détails par pièce dans l'état des lieux
- Lien avec les pièces prédéfinies ou sections personnalisées
- Description textuelle libre
- Photos multiples

---

## Gestion des Propriétaires

### Création d'un Propriétaire

**Endpoint**: `POST /api/owners`

L'admin_building peut créer un compte propriétaire et lui attribuer des appartements :

```java
CreateOwnerRequest {
    String fname;
    String lname;
    String email;
    String phoneNumber;
    String buildingId;
    List<String> apartmentIds;
}
```

**Fonctionnalités** :
- Génération automatique d'un mot de passe temporaire
- Attribution automatique des appartements au propriétaire
- Notification par email (à implémenter)

### Assignation d'appartements

**Endpoint**: `PUT /api/owners/assign-apartment`

Permet d'attribuer un appartement supplémentaire à un propriétaire existant.

### Liste des propriétaires

**Endpoint**: `GET /api/owners/building/{buildingId}`

Retourne tous les propriétaires d'un bâtiment.

---

## Gestion des Locataires

### Création d'un Locataire

Le propriétaire peut :
1. **Créer un nouveau compte locataire** via l'endpoint de création de résident
2. **Rattacher un compte existant** en l'associant à un contrat de bail

### Accès à l'application

Le locataire n'accède à l'application qu'**après signature du contrat de bail**.

---

## Contrats de Bail

### Création d'un Contrat

**Endpoint**: `POST /api/lease-contracts`

```java
CreateLeaseContractRequest {
    String apartmentId;
    String ownerId;
    String tenantId;
    LocalDate startDate;
    LocalDate endDate;
    BigDecimal initialRentAmount;
    BigDecimal depositAmount;
    BigDecimal chargesAmount;
    String regionCode;  // Ex: "BE-BRU", "BE-WAL", "BE-FLA"
}
```

### Cycle de Vie d'un Contrat

1. **DRAFT** : Création initiale
2. **PENDING_SIGNATURE** : Une des parties a signé
3. **SIGNED** : Les deux parties ont signé
4. **ACTIVE** : Contrat en cours d'exécution
5. **TERMINATED** : Contrat terminé

### Signature du Contrat

#### Par le propriétaire
**Endpoint**: `POST /api/lease-contracts/{contractId}/sign-owner`

#### Par le locataire
**Endpoint**: `POST /api/lease-contracts/{contractId}/sign-tenant`

```java
SignatureRequest {
    String signatureData;  // Base64 de l'image de signature
}
```

### Articles du Contrat

Les articles standards sont chargés automatiquement selon le `regionCode`.

Le propriétaire peut ajouter des sections personnalisées :

**Modèle**: `LeaseContractCustomSection`
- Titre de la section
- Contenu de la section
- Ordre d'affichage

### Indexation Automatique du Loyer

**Endpoint**: `POST /api/lease-contracts/{contractId}/index-rent`

```java
Parameters:
- indexationRate: BigDecimal    // Taux d'indexation (ex: 0.0345 pour 3.45%)
- baseIndex: BigDecimal         // Indice de base
- newIndex: BigDecimal          // Nouvel indice
- notes: String                 // Notes explicatives
```

**Calcul automatique** :
```
nouveau_loyer = loyer_actuel × (1 + taux_indexation)
```

**Historique complet** :
Toutes les indexations sont conservées dans la table `rent_indexations`.

---

## États des Lieux

### Création d'un État des Lieux

**Endpoint**: `POST /api/inventories`

```java
CreateInventoryRequest {
    String contractId;
    String type;              // "ENTRY" ou "EXIT"
    LocalDate inventoryDate;
}
```

À la création, les pièces de l'appartement sont automatiquement ajoutées.

### Structure d'un État des Lieux

#### En-tête du Document

```
PROCÈS-VERBAL D'ÉTAT DES LIEUX D'ENTRÉE / SORTIE

Le : [date]

Je, soussigné(e) :
PROPRIÉTAIRE : [nom prénom]
ET
LOCATAIRE : [nom prénom]

LOCATAIRE ENTRANT / SORTANT
Occupant l'appartement situé à : [adresse complète]
```

#### Relevés de Compteurs

- **Électricité** : Numéro de compteur, index jour, index nuit
- **Eau froide** : Numéro de compteur, index
- **Calorimètre** : Numéro, index kWh, index m³

#### Clés Remises

- Clés universelles appartement + immeuble
- Clés boîte aux lettres
- Clés cave
- Cartes d'accès
- Télécommandes parking

#### Sections par Pièce

Pour chaque pièce de l'appartement :
- Champ texte libre pour description
- Photos multiples
- Possibilité d'utiliser la caméra

Le propriétaire peut ajouter des **sections personnalisées** en plus des pièces prédéfinies.

### Signature de l'État des Lieux

#### Par le propriétaire
**Endpoint**: `POST /api/inventories/{inventoryId}/sign-owner`

#### Par le locataire
**Endpoint**: `POST /api/inventories/{inventoryId}/sign-tenant`

Une fois les **deux signatures** apposées :
- Le statut passe à `SIGNED`
- Le document peut être complété
- Le PDF peut être généré

### Génération du PDF

Le PDF final :
- Est stocké dans le dossier de l'appartement
- Est accessible au propriétaire et au locataire
- Suit le format officiel requis

---

## API Endpoints

### Propriétaires (Owners)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/owners` | Créer un propriétaire |
| GET | `/api/owners/building/{buildingId}` | Liste des propriétaires d'un bâtiment |
| PUT | `/api/owners/assign-apartment` | Attribuer un appartement |

### Contrats de Bail (Lease Contracts)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/lease-contracts` | Créer un contrat |
| GET | `/api/lease-contracts/{contractId}` | Détails d'un contrat |
| GET | `/api/lease-contracts/owner/{ownerId}` | Contrats d'un propriétaire |
| GET | `/api/lease-contracts/tenant/{tenantId}` | Contrats d'un locataire |
| GET | `/api/lease-contracts/my-contracts` | Mes contrats |
| POST | `/api/lease-contracts/{contractId}/sign-owner` | Signature propriétaire |
| POST | `/api/lease-contracts/{contractId}/sign-tenant` | Signature locataire |
| POST | `/api/lease-contracts/{contractId}/index-rent` | Indexer le loyer |

### États des Lieux (Inventories)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/inventories` | Créer un état des lieux |
| GET | `/api/inventories/{inventoryId}` | Détails d'un état des lieux |
| GET | `/api/inventories/contract/{contractId}` | États des lieux d'un contrat |
| PUT | `/api/inventories/{inventoryId}` | Mettre à jour |
| POST | `/api/inventories/{inventoryId}/sign-owner` | Signature propriétaire |
| POST | `/api/inventories/{inventoryId}/sign-tenant` | Signature locataire |

### Pièces d'Appartement (Apartment Rooms)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/apartment-rooms` | Créer une pièce |
| GET | `/api/apartment-rooms/apartment/{apartmentId}` | Liste des pièces |
| PUT | `/api/apartment-rooms/{roomId}` | Mettre à jour une pièce |
| DELETE | `/api/apartment-rooms/{roomId}` | Supprimer une pièce |
| POST | `/api/apartment-rooms/{roomId}/photos` | Ajouter une photo |

---

## Modèles Flutter

Les modèles Flutter suivants ont été créés :

### LeaseContractModel
- Représente un contrat de bail
- Contient les informations propriétaire/locataire
- Historique des indexations
- Signatures électroniques

### InventoryModel
- Représente un état des lieux
- Relevés de compteurs
- Clés remises
- Entrées par pièce

### ApartmentRoomModel
- Représente une pièce d'appartement
- Photos de la pièce
- Description

### RentIndexationModel
- Historique d'indexation du loyer

---

## Services Flutter

Les services Flutter suivants ont été créés pour communiquer avec l'API :

### LeaseContractService
```dart
- createContract()
- getMyContracts()
- getContractById()
- signContractByOwner()
- signContractByTenant()
- indexRent()
```

### InventoryService
```dart
- createInventory()
- getInventoryById()
- getInventoriesByContract()
- updateInventory()
- signInventoryByOwner()
- signInventoryByTenant()
```

### OwnerService
```dart
- createOwner()
- getOwnersByBuilding()
- assignApartmentToOwner()
```

### ApartmentRoomService
```dart
- createRoom()
- getRoomsByApartment()
- updateRoom()
- deleteRoom()
- addPhotoToRoom()
```

---

## Flux de Travail Typique

### 1. Création d'un Propriétaire
```
Admin Building → Crée le compte propriétaire → Attribue des appartements
```

### 2. Définition des Pièces de l'Appartement
```
Propriétaire → Ajoute les pièces (chambres, salon, etc.) → Ajoute des photos
```

### 3. Création d'un Locataire
```
Propriétaire → Crée le compte locataire OU rattache un compte existant
```

### 4. Création du Contrat de Bail
```
Propriétaire → Crée le contrat → Définit loyer, caution, charges
→ Ajoute sections personnalisées si nécessaire
→ Signe le contrat
→ Locataire reçoit notification
→ Locataire signe le contrat
→ Contrat devient SIGNED
```

### 5. État des Lieux d'Entrée
```
Propriétaire OU Locataire → Crée l'état des lieux d'entrée
→ Remplit les relevés de compteurs
→ Remplit les clés remises
→ Pour chaque pièce : ajoute description et photos
→ Ajoute sections personnalisées si nécessaire
→ Les deux parties signent
→ PDF généré et stocké
```

### 6. Indexation du Loyer (annuelle)
```
Propriétaire → Lance l'indexation
→ Saisit le taux d'indexation et les indices
→ Nouveau loyer calculé automatiquement
→ Historique conservé
```

### 7. État des Lieux de Sortie
```
Même processus que l'entrée, avec type = "EXIT"
→ Comparaison possible avec l'état d'entrée
→ PDF généré et stocké
```

---

## Sécurité et Permissions

### Règles d'accès

- **Admin Building** : Peut créer des propriétaires et gérer les attributions
- **Propriétaire** :
  - Peut voir et gérer ses appartements
  - Peut créer des locataires
  - Peut créer et gérer les contrats de ses appartements
  - Peut créer et gérer les états des lieux
- **Locataire** :
  - Peut voir ses contrats
  - Peut signer ses contrats et états des lieux
  - Accès limité aux données de ses locations

---

## Prochaines Étapes

Pour compléter l'implémentation, il reste à :

1. **Créer les écrans Flutter** pour :
   - Gestion des propriétaires
   - Création et signature de contrats
   - Création et signature d'états des lieux
   - Visualisation de l'historique des indexations

2. **Implémenter la génération PDF** :
   - Service backend pour générer les PDFs
   - Format conforme aux exigences légales
   - Stockage dans le système de fichiers

3. **Ajouter les notifications** :
   - Notification au locataire quand contrat prêt à signer
   - Notification quand état des lieux prêt à signer
   - Rappels pour indexation annuelle

4. **Tester l'ensemble du système** :
   - Tests unitaires
   - Tests d'intégration
   - Tests end-to-end

---

## Notes Techniques

### Base de Données
- La migration V12 doit être exécutée sur la base de données
- Les tables utilisent des UUIDs pour les clés primaires
- Les relations sont gérées par JPA/Hibernate

### Backend (Java Spring Boot)
- Tous les modèles JPA sont créés
- Tous les repositories sont créés
- Services métier implémentés
- Contrôleurs REST exposés
- Documentation Swagger disponible

### Frontend (Flutter)
- Modèles Dart créés
- Services API créés
- Prêt pour l'implémentation des écrans

---

## Support et Maintenance

Pour toute question ou problème :
- Consulter la documentation Swagger : `/swagger-ui.html`
- Vérifier les logs applicatifs
- Contacter l'équipe de développement

---

**Date de création** : 11 décembre 2025
**Version** : 1.0
**Auteur** : Équipe OneApp
