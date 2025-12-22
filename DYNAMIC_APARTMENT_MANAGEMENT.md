# Système de Gestion Dynamique des Appartements

## Vue d'ensemble

Ce document décrit le nouveau système de gestion dynamique des appartements qui permet une flexibilité maximale dans la définition et la gestion des propriétés immobilières.

## Fonctionnalités principales

### 1. Formulaire multi-étapes pour l'ajout d'appartements

Le système propose un formulaire en 3 étapes pour créer un appartement:

#### Étape 1: Informations de base
- Nom du bien
- Numéro d'appartement
- Étage (avec validation contre le nombre max d'étages de l'immeuble)
- Sélection du propriétaire (liste déroulante)

#### Étape 2: Ajout de pièces (dynamique)
- Sélection du type de pièce (cuisine, salle d'eau, salon, chambre)
- Champs spécifiques selon le type:
  - **Chambre**: Surface, Avec terrasse (oui/non), Images
  - **Cuisine**: Liste d'équipements avec images
  - **Salle d'eau**: Liste d'équipements avec images
  - **Salon**: Surface, Avec terrasse (oui/non)
- Bouton + pour ajouter autant de pièces que nécessaire
- Support d'équipements multiples par pièce
- Upload d'images pour les pièces et équipements

#### Étape 3: Champs spécifiques
- Champs par défaut:
  - Consommation énergie
  - Émission CO2
  - Numéro de rapport CPEB
- Bouton + pour ajouter des champs personnalisés (libellé, valeur)

### 2. Système de types de pièces extensible

Le système utilise une architecture dynamique qui permet:
- Définir des types de pièces au niveau système (partagés entre tous les immeubles)
- Ajouter des types de pièces spécifiques à un immeuble
- Définir des champs personnalisés pour chaque type de pièce
- Support de différents types de champs: TEXT, NUMBER, BOOLEAN, IMAGE_LIST, EQUIPMENT_LIST

### 3. Visualisation en accordions

#### Pour les locataires (Mon appartement)
- Vue en lecture seule
- Interface avec accordions pour une navigation intuitive
- Sections:
  - Informations générales
  - Pièces (avec détails, équipements et photos)
  - Informations spécifiques

#### Pour les propriétaires (Mes biens)
- Mode lecture par défaut
- Possibilité de basculer en mode édition
- Modification section par section (pièces ou champs spécifiques)
- Interface claire avec indicateurs visuels du mode actif
- Validation et enregistrement des modifications

## Architecture technique

### Base de données

#### Nouvelles tables créées:

1. **room_types**
   - Types de pièces (système ou spécifiques à un immeuble)

2. **room_type_field_definitions**
   - Définitions des champs pour chaque type de pièce
   - Support de différents types de données

3. **apartment_rooms**
   - Pièces d'un appartement
   - Liaison avec le type de pièce

4. **room_field_values**
   - Valeurs des champs pour chaque pièce
   - Stockage flexible (text_value, number_value, boolean_value)

5. **room_equipments**
   - Équipements d'une pièce (cuisine, salle d'eau, etc.)

6. **room_images**
   - Images des pièces et des équipements

7. **apartment_custom_fields**
   - Champs personnalisés pour un appartement

#### Modifications des tables existantes:
- Ajout de `property_name` à la table `apartments`
- Ajout de `max_floors` à la table `buildings`

### Backend (Spring Boot)

#### Nouvelles entités Java:
- `RoomType`
- `RoomTypeFieldDefinition`
- `ApartmentRoom` (restructuré)
- `RoomFieldValue`
- `RoomEquipment`
- `RoomImage`
- `ApartmentCustomField`
- `FieldType` (enum)

#### Service principal:
- `ApartmentManagementService`: Gère toute la logique métier
  - Création d'appartements avec pièces et champs personnalisés
  - Récupération complète des données
  - Mise à jour des pièces et champs personnalisés

#### API REST:
- `ApartmentManagementController`
  - POST `/api/apartment-management/apartments` - Créer un appartement
  - GET `/api/apartment-management/apartments/{id}` - Obtenir les détails
  - PUT `/api/apartment-management/apartments/{id}/rooms` - Mettre à jour les pièces
  - PUT `/api/apartment-management/apartments/{id}/custom-fields` - Mettre à jour les champs
  - GET `/api/apartment-management/room-types` - Obtenir les types de pièces système
  - GET `/api/apartment-management/room-types/{buildingId}` - Obtenir les types pour un immeuble

### Frontend (Flutter)

#### Nouveaux modèles:
- `RoomTypeModel`
- `RoomTypeFieldDefinitionModel`
- `ApartmentRoomCompleteModel`
- `RoomFieldValueModel`
- `RoomEquipmentModel`
- `RoomImageModel`
- `ApartmentCustomFieldModel`
- `ApartmentCompleteModel`

#### Service:
- `ApartmentManagementService`: Communication avec l'API

#### Écrans:
1. **CreateApartmentWizardScreen**
   - Formulaire multi-étapes ergonomique
   - Validation à chaque étape
   - Upload d'images
   - Gestion dynamique des pièces et équipements

2. **ApartmentDetailsAccordionScreen**
   - Vue locataire (lecture seule)
   - Interface avec accordions
   - Affichage des pièces avec détails complets
   - Galerie d'images interactive

3. **PropertyDetailsEditableScreen**
   - Vue propriétaire (lecture/modification)
   - Bascule entre modes lecture et édition
   - Modification section par section
   - Sauvegarde des modifications

## Sécurité

Le système implémente Row Level Security (RLS) sur toutes les tables:
- Les membres d'un immeuble peuvent voir les données
- Seuls les admins et propriétaires peuvent modifier
- Politiques spécifiques pour chaque opération (SELECT, INSERT, UPDATE, DELETE)

## Avantages du nouveau système

1. **Flexibilité maximale**: Ajout de nouveaux types de pièces sans modification du code
2. **Extensibilité**: Support de champs personnalisés illimités
3. **Interface unifiée**: Même interface pour tous les types de biens
4. **Expérience utilisateur optimale**: Formulaire multi-étapes intuitif
5. **Mode d'affichage adapté**: Vue lecture pour locataires, lecture/édition pour propriétaires
6. **Gestion des médias**: Upload et affichage d'images pour pièces et équipements

## Migration des données

La migration V14 crée toutes les nouvelles tables et insère les types de pièces par défaut:
- Chambre (Surface, Avec terrasse, Images)
- Cuisine (Équipements)
- Salle d'eau (Équipements, Images)
- Salon (Surface, Avec terrasse)

Les données existantes des appartements ne sont pas affectées et restent accessibles.

## Utilisation

### Pour créer un appartement (Admin):
1. Aller dans "Gestion de l'immeuble"
2. Cliquer sur "Ajouter un appartement"
3. Remplir les informations de base
4. Ajouter les pièces avec leurs caractéristiques
5. Définir les champs spécifiques
6. Valider la création

### Pour consulter (Locataire):
1. Aller dans "Mon appartement"
2. Explorer les sections via les accordions
3. Voir les détails des pièces et équipements
4. Consulter les photos en plein écran

### Pour modifier (Propriétaire):
1. Aller dans "Mes biens"
2. Sélectionner le bien
3. Activer le mode édition
4. Modifier les sections souhaitées
5. Enregistrer les modifications

## Prochaines étapes possibles

1. Ajout de types de pièces personnalisés via l'interface
2. Drag & drop pour réorganiser les photos
3. Export PDF des détails d'un bien
4. Historique des modifications
5. Templates de pièces pré-configurées
