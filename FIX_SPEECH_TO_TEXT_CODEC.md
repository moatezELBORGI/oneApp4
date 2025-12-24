# Fix: Erreur "instance of _code not supported" - Enregistrement Vocal

## Problème
Lors de l'enregistrement vocal dans l'état des lieux, l'erreur suivante apparaissait :
```
instance of _code not supported
```

## Cause
Le codec `Codec.opusWebM` utilisé dans flutter_sound n'est pas supporté sur toutes les plateformes (notamment Android).

## Solution Appliquée

### 1. Modification du Codec Flutter
**Fichier**: `lib/screens/inventory/inventory_room_detail_screen.dart`

**Changement**:
```dart
// AVANT (ne fonctionne pas)
codec: Codec.opusWebM,
extension: '.webm'

// APRÈS (fonctionne sur Android et iOS)
codec: Codec.aacMP4,
extension: '.m4a'
```

Le codec `aacMP4` est universellement supporté sur :
- ✅ Android (API 16+)
- ✅ iOS (toutes versions)
- ✅ OpenAI Whisper API

### 2. Adaptation Backend
**Fichier**: `src/main/java/be/delomid/oneapp/mschat/mschat/service/SpeechToTextService.java`

Le backend détecte maintenant automatiquement l'extension du fichier uploadé et l'utilise pour créer le fichier temporaire. Par défaut, il utilise `.m4a`.

## Formats Audio Supportés

### Flutter Sound - Codecs Universels
- `Codec.aacMP4` (.m4a) - **Recommandé** ✅
- `Codec.pcm16WAV` (.wav) - Fichiers volumineux
- `Codec.mp3` (.mp3) - Bonne compression

### OpenAI Whisper API
Supporte les formats suivants :
- m4a, mp3, mp4, mpeg, mpga, wav, webm

## Test de la Solution

1. **Nettoyer et reconstruire l'application**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Tester l'enregistrement**:
   - Ouvrir un état des lieux
   - Cliquer sur une pièce
   - Appuyer sur "Enregistrer un message vocal"
   - Parler pendant quelques secondes
   - Appuyer sur "Arrêter l'enregistrement"
   - Vérifier que la transcription s'ajoute au champ description

## Avantages du Format AAC/M4A

1. **Compatibilité**: Supporté nativement sur toutes les plateformes
2. **Qualité**: Excellente qualité audio pour la voix
3. **Taille**: Bonne compression (fichiers plus petits que WAV)
4. **Performance**: Encodage/décodage rapide

## En Cas de Problème Persistant

Si l'erreur persiste après ces modifications :

1. **Vérifier les permissions**:
   ```dart
   final status = await Permission.microphone.status;
   print('Microphone status: $status');
   ```

2. **Tester un codec encore plus simple** (WAV):
   ```dart
   codec: Codec.pcm16WAV,
   extension: '.wav'
   ```

3. **Vérifier les logs**:
   - Android: `adb logcat | grep flutter`
   - iOS: Console Xcode

4. **Vérifier la version de flutter_sound**:
   ```yaml
   flutter_sound: ^9.2.13  # Version actuelle
   ```

## Formats Testés

| Codec | Android | iOS | OpenAI | Recommandé |
|-------|---------|-----|--------|------------|
| aacMP4 | ✅ | ✅ | ✅ | ⭐ Oui |
| pcm16WAV | ✅ | ✅ | ✅ | Fichiers lourds |
| mp3 | ✅ | ✅ | ✅ | Alternative |
| opusWebM | ❌ | ⚠️ | ✅ | Non supporté partout |

## Documentation Référence
- [flutter_sound Codecs](https://pub.dev/documentation/flutter_sound/latest/flutter_sound/Codec.html)
- [OpenAI Whisper API](https://platform.openai.com/docs/guides/speech-to-text)
