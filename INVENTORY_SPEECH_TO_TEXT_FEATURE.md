# Module États des Lieux - Récupération des Pièces et Transcription Vocale

## Résumé des Modifications

Ce document décrit les modifications apportées au module des états des lieux pour récupérer automatiquement les pièces saisies lors de l'ajout d'un appartement et permettre la transcription vocale en temps réel.

## 1. Récupération Automatique des Pièces

### Backend

#### Modèle InventoryRoomEntry
- **Fichier**: `InventoryRoomEntry.java`
- **Modification**: La relation pointe maintenant vers `ApartmentRoom` (nouveau système) au lieu de `ApartmentRoomLegacy`
- **Champ**: `apartment_room_id` au lieu de `room_id`

#### Service InventoryService
- **Fichier**: `InventoryService.java`
- **Modifications**:
  - Utilise `ApartmentRoomNewRepository` pour récupérer les pièces
  - Lors de la création d'un état des lieux, récupère automatiquement:
    - Toutes les pièces de l'appartement avec leurs détails
    - Le nom de la pièce (roomName ou roomType.name)
    - Les images de chaque pièce (via RoomImage)
  - Copie automatiquement les images des pièces vers les photos d'inventaire

#### Migration SQL
- **Fichier**: `V17__Update_inventory_room_entries_to_apartment_rooms.sql`
- **Actions**:
  - Renomme `room_id` en `apartment_room_id`
  - Met à jour la contrainte de clé étrangère vers `apartment_rooms`

### Flux de Création d'un État des Lieux

1. **Création de l'inventaire** → `POST /inventories`
2. **Récupération automatique des pièces** de l'appartement
3. **Pour chaque pièce**:
   - Création d'une entrée `InventoryRoomEntry`
   - Titre = nom de la pièce ou type de pièce
   - Copie des images de la pièce vers les photos d'inventaire

## 2. Transcription Vocale avec OpenAI

### Backend

#### Service SpeechToTextService
- **Fichier**: `SpeechToTextService.java`
- **Fonctionnalités**:
  - Utilise OpenAI Whisper API pour la transcription
  - Supporte le format WebM (codec Opus)
  - Langue: Français par défaut
  - Suppression automatique du fichier temporaire après transcription

#### Controller SpeechToTextController
- **Fichier**: `SpeechToTextController.java`
- **Endpoint**: `POST /speech-to-text/transcribe`
- **Paramètres**:
  - `audio` (MultipartFile): Fichier audio à transcrire
- **Réponse**:
  ```json
  {
    "transcription": "texte transcrit",
    "status": "success"
  }
  ```

#### Configuration OpenAI
- **Fichier**: `application.properties`
- **Propriétés ajoutées**:
  ```properties
  openai.api.key=sk-proj-your-api-key-here
  openai.api.base-url=https://api.openai.com/v1
  ```

**IMPORTANT**: Remplacer `sk-proj-your-api-key-here` par votre vraie clé API OpenAI

### Frontend (Flutter)

#### Écran InventoryRoomDetailScreen
- **Fichier**: `inventory_room_detail_screen.dart`
- **Nouvelles fonctionnalités**:
  1. **Bouton Micro**: Permet d'enregistrer un message vocal
  2. **Indicateur d'enregistrement**: Point rouge animé pendant l'enregistrement
  3. **Transcription automatique**: Après l'arrêt, le texte est ajouté à la description
  4. **Indicateur de transcription**: Loader pendant la transcription

#### Flux d'Utilisation

1. **Appui sur le bouton "Enregistrer un message vocal"**
   - Demande de permission microphone si nécessaire
   - Début de l'enregistrement (format WebM)
   - Affichage de l'indicateur rouge

2. **Appui sur "Arrêter l'enregistrement"**
   - Arrêt de l'enregistrement
   - Affichage du loader "Transcription en cours..."
   - Envoi du fichier audio à l'API backend

3. **Réception de la transcription**
   - Ajout automatique du texte transcrit dans le champ description
   - Message de confirmation
   - Suppression du fichier audio temporaire

## 3. Permissions Requises

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>L'application a besoin d'accéder au microphone pour enregistrer les descriptions vocales des états des lieux</string>
```

## 4. Dépendances Flutter

Les packages suivants sont déjà présents dans `pubspec.yaml`:
- `flutter_sound: ^9.2.13` - Enregistrement audio
- `permission_handler: ^11.0.1` - Gestion des permissions
- `path_provider: ^2.1.1` - Accès au répertoire temporaire
- `http: ^1.1.0` - Requêtes HTTP

## 5. Structure des Données

### État des Lieux avec Pièces

```json
{
  "id": "uuid",
  "type": "ENTRY",
  "inventoryDate": "2024-01-15",
  "roomEntries": [
    {
      "id": "uuid",
      "sectionName": "Salon",
      "description": "Pièce en bon état, murs fraîchement peints",
      "photos": [
        {
          "id": "uuid",
          "photoUrl": "https://...",
          "orderIndex": 0
        }
      ]
    }
  ]
}
```

## 6. Avantages

### Pour l'Utilisateur
1. **Gain de temps**: Les pièces sont automatiquement remplies avec leurs images
2. **Cohérence**: Les informations viennent directement de l'appartement
3. **Facilité**: Possibilité de dicter au lieu de taper
4. **Précision**: Transcription automatique évite les fautes de frappe

### Pour le Système
1. **Traçabilité**: Lien direct entre les pièces de l'appartement et l'inventaire
2. **Évolutivité**: Ajout/modification de pièces se reflète dans les nouveaux inventaires
3. **Réutilisabilité**: Les images des pièces sont automatiquement disponibles

## 7. Points d'Attention

### Coûts OpenAI
- L'API Whisper d'OpenAI est payante
- Prix: environ $0.006 par minute d'audio
- Prévoir un monitoring des coûts

### Performance
- La transcription prend quelques secondes (dépend de la durée de l'audio)
- Prévoir un timeout approprié (actuellement 2 minutes par défaut)

### Sécurité
- La clé API OpenAI doit être sécurisée (variables d'environnement en production)
- Les fichiers audio temporaires sont automatiquement supprimés

## 8. Tests Recommandés

1. **Création d'état des lieux**:
   - Vérifier que toutes les pièces sont bien récupérées
   - Vérifier que les images sont copiées correctement

2. **Transcription vocale**:
   - Tester avec différentes durées d'enregistrement
   - Tester avec différents accents/intonations
   - Vérifier la gestion des erreurs (pas de connexion, API indisponible)

3. **Permissions**:
   - Tester le refus de permission microphone
   - Tester l'acceptation de permission microphone

## 9. Évolutions Futures Possibles

1. **Édition des images**: Permettre de modifier/supprimer les images héritées
2. **Transcription en temps réel**: Afficher le texte pendant l'enregistrement
3. **Support multilingue**: Détecter automatiquement la langue
4. **Alternatives**: Ajouter d'autres fournisseurs de speech-to-text (Google, Azure)
5. **Mode offline**: Transcription locale pour les zones sans connexion
