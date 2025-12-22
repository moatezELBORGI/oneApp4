# Résumé des corrections de types

## Problème identifié

Il y avait un conflit entre deux systèmes de gestion des pièces d'appartement:
1. **Ancien système (V12)**: Table `apartment_rooms` avec UUID, utilisé pour les inventaires
2. **Nouveau système (V14)**: Table `apartment_rooms` avec BIGSERIAL, pour la gestion dynamique

## Solutions appliquées

### 1. Migration de base de données (V14)

Ajout de commandes pour renommer les anciennes tables avant de créer les nouvelles:
- `apartment_rooms` → `apartment_rooms_legacy`
- `apartment_room_photos` → `apartment_room_photos_legacy`

### 2. Création d'entités Legacy

**ApartmentRoomLegacy.java**
- Pointe vers `apartment_rooms_legacy`
- Utilise UUID comme ID
- Conserve la structure originale avec `apartment` (relation ManyToOne)

**ApartmentRoomPhoto.java** (mis à jour)
- Pointe vers `apartment_room_photos_legacy`
- Référence `ApartmentRoomLegacy` au lieu d'`ApartmentRoom`

### 3. Création du repository Legacy

**ApartmentRoomLegacyRepository.java**
- Repository pour `ApartmentRoomLegacy` avec UUID
- Méthode: `findByApartment_IdApartmentOrderByOrderIndex`

### 4. Correction des repositories existants

**ApartmentRoomRepository.java**
- Ancien repository supprimé
- `ApartmentRoomNewRepository` renommé en `ApartmentRoomRepository`
- Utilise la nouvelle entité `ApartmentRoom` avec Long

### 5. Mise à jour des services

**ApartmentManagementService.java**
- Utilise `ApartmentRoomRepository` (nouvelle version avec Long)
- Gère la nouvelle structure dynamique

**InventoryService.java**
- Utilise `ApartmentRoomLegacyRepository`
- Référence `ApartmentRoomLegacy` pour la compatibilité avec les inventaires existants

**DataInitializationService.java**
- Utilise `ApartmentRoomLegacyRepository`
- Crée des données de test avec l'ancienne structure

**ApartmentRoomService.java**
- Service obsolète supprimé (remplacé par `ApartmentManagementService`)

### 6. Mise à jour des modèles associés

**InventoryRoomEntry.java**
- Relation `room` pointe vers `ApartmentRoomLegacy`
- Maintient la compatibilité avec les inventaires existants

## Structure finale

### Nouveau système (dynamique)
```
apartment_rooms (BIGSERIAL)
├── room_types
├── room_type_field_definitions
├── room_field_values
├── room_equipments
└── room_images
```

### Ancien système (legacy, pour inventaires)
```
apartment_rooms_legacy (UUID)
└── apartment_room_photos_legacy
```

## Avantages de cette approche

1. **Compatibilité rétroactive**: Les inventaires existants continuent de fonctionner
2. **Séparation claire**: Deux systèmes distincts sans confusion
3. **Migration progressive**: Possibilité de migrer les données anciennes vers le nouveau système
4. **Pas de perte de données**: Toutes les données existantes sont préservées

## Prochaines étapes possibles

1. Créer un script de migration des données de `apartment_rooms_legacy` vers le nouveau système
2. Mettre à jour les inventaires pour utiliser le nouveau système dynamique
3. Supprimer l'ancien système une fois la migration complète
