# Amélioration du système de gestion des équipements

## Vue d'ensemble

Le système de gestion des équipements a été amélioré pour offrir une expérience utilisateur moderne avec :
- ✅ Liste d'équipements prédéfinis stockés en base de données
- ✅ Interface de sélection avec recherche intelligente
- ✅ Upload d'images pour chaque équipement
- ✅ Pré-sélection automatique d'équipements par défaut selon le type de pièce

## Modifications apportées

### 1. Base de données (Migration V16)

**Table créée : `equipment_templates`**
- Stockage des équipements prédéfinis pour chaque type de pièce
- 12 équipements pour "Cuisine" : Four, Réfrigérateur, Lave-vaisselle, etc.
- 12 équipements pour "Salle d'eau" : Douche, Lavabo, WC, etc.

```sql
CREATE TABLE equipment_templates (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  room_type_id BIGINT NOT NULL,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Backend (Spring Boot)

**Nouveaux endpoints :**
- `GET /api/equipment-templates` - Liste tous les templates actifs
- `GET /api/equipment-templates/room-type/{roomTypeId}` - Templates par type de pièce
- `GET /api/apartment-rooms/room-types` - Liste des types de pièces
- `POST /api/apartment-rooms/with-equipments` - Créer une pièce avec équipements
- `POST /api/apartment-rooms/equipments/{equipmentId}/upload-image` - Upload image équipement

**Nouveaux fichiers créés :**
- `model/EquipmentTemplate.java`
- `dto/EquipmentTemplateDto.java`
- `dto/CreateRoomWithEquipmentsRequest.java`
- `repository/EquipmentTemplateRepository.java`
- `service/EquipmentTemplateService.java`
- `controller/EquipmentTemplateController.java`

### 3. Frontend (Flutter)

#### Widget principal : `EquipmentSelectorWidget`

Fonctionnalités :
- **Recherche intelligente** : Filtre les équipements par nom et description
- **Sélection multiple** : Ajout/suppression facile d'équipements
- **Upload d'images** : Plusieurs photos par équipement
- **Pré-sélection automatique** : 4 équipements de base suggérés selon le type
- **Interface moderne** : Cards avec preview des images

**Équipements pré-sélectionnés :**

Pour les **Cuisines** :
1. Four
2. Plaque de cuisson
3. Réfrigérateur
4. Évier

Pour les **Salles d'eau** :
1. Douche
2. Lavabo
3. Toilette
4. Miroir

#### Intégration dans les écrans

**1. AddRoomScreen** (nouveau)
- Écran dédié pour ajouter une pièce
- Sélection du type de pièce (dropdown)
- Affichage automatique du sélecteur d'équipements pour Cuisine et Salle d'eau
- Upload d'images pour chaque équipement

**2. CreateApartmentWizardScreen** (mis à jour)
- Utilise maintenant `EquipmentSelectorWidget` au lieu du dialogue manuel
- Upload automatique des images d'équipements lors de la soumission
- Support des équipements prédéfinis + équipements personnalisés

**3. ApartmentRoomsScreen** (mis à jour)
- Navigue vers le nouveau `AddRoomScreen` au lieu du dialogue simple

### 4. Services

**EquipmentTemplateService** (Flutter)
```dart
// Récupère tous les templates actifs
Future<List<EquipmentTemplateModel>> getAllTemplates()

// Récupère les templates par type de pièce
Future<List<EquipmentTemplateModel>> getTemplatesByRoomType(String roomTypeId)
```

**ApartmentRoomService** (mis à jour)
```dart
// Récupère tous les types de pièces
Future<List<RoomTypeModel>> getAllRoomTypes()

// Crée une pièce avec ses équipements
Future<String> createRoomWithEquipments({
  required String apartmentId,
  required String roomName,
  required String roomTypeId,
  List<SelectedEquipment>? equipments,
})
```

## Flux utilisateur amélioré

### Avant
1. L'utilisateur clique sur "Ajouter une pièce"
2. Dialogue simple demandant nom + type (texte libre)
3. Aucune suggestion d'équipements
4. Pas de support pour les images

### Après
1. L'utilisateur clique sur "Ajouter une pièce"
2. Écran complet avec formulaire structuré
3. **Sélection du type depuis une liste** (Cuisine, Salle d'eau, etc.)
4. **Équipements suggérés automatiquement** selon le type
5. **Recherche intelligente** dans la liste des équipements
6. **Upload de photos** pour chaque équipement
7. Interface moderne avec preview des images

## Exemple d'utilisation

```dart
// Dans un écran
EquipmentSelectorWidget(
  roomTypeId: '123', // ID du type de pièce (Cuisine, Salle d'eau, etc.)
  onEquipmentsChanged: (equipments) {
    // Callback avec la liste des équipements sélectionnés
    print('${equipments.length} équipements sélectionnés');
  },
  initialEquipments: [], // Liste initiale (optionnel)
)
```

## Base de données - Équipements disponibles

### Cuisine (12 équipements)
1. Four
2. Plaque de cuisson
3. Hotte aspirante
4. Réfrigérateur
5. Congélateur
6. Lave-vaisselle
7. Micro-ondes
8. Évier
9. Plan de travail
10. Meubles de cuisine
11. Cave à vin
12. Hotte décorative

### Salle d'eau (12 équipements)
1. Douche
2. Baignoire
3. Lavabo
4. Toilette
5. Bidet
6. Meuble sous-vasque
7. Miroir
8. Armoire de toilette
9. Sèche-serviettes
10. VMC
11. Colonne de douche
12. Porte-serviettes

## Sécurité (RLS)

Toutes les opérations sont sécurisées avec Row Level Security :
- Lecture des templates : accessible aux utilisateurs authentifiés
- Modification des templates : réservée aux administrateurs
- Upload d'images : vérification de l'appartenance à la pièce

## Prochaines améliorations possibles

1. **Ajout de types d'équipements supplémentaires** pour d'autres pièces (Chambre, Salon, etc.)
2. **Import/Export** de listes d'équipements personnalisées
3. **Historique** des modifications d'équipements
4. **États des équipements** (Neuf, Bon, Usé, À remplacer)
5. **Maintenance** : planification et suivi des interventions
6. **Garanties** : dates et durées de garantie par équipement

## Notes techniques

- Les images sont stockées dans `/uploads/equipment-images/`
- Format supporté : JPEG, PNG, GIF, WebP
- Limite : 4 équipements pré-sélectionnés par défaut
- La recherche est insensible à la casse et porte sur nom + description
