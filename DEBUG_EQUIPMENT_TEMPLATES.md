# Débogage - Equipment Templates API

## Problème
L'application Flutter ne peut pas récupérer les équipements templates depuis l'API.

## Causes possibles

### 1. Row Level Security (RLS) bloque l'accès ✅ CORRIGÉ
**Problème** : La table `equipment_templates` avait RLS activé avec des policies qui bloquaient l'accès depuis Spring Boot.

**Solution appliquée** : Désactivation du RLS dans la migration V16.

**Pour appliquer le correctif** :
```bash
# Option 1 : Exécuter le script SQL manuellement
psql -U postgres -d votre_database < fix_equipment_templates_rls.sql

# Option 2 : Via Docker si vous utilisez Docker
docker exec -i postgres_container psql -U postgres -d votre_database < fix_equipment_templates_rls.sql
```

### 2. La migration n'a pas été appliquée
**Vérification** :
```sql
-- Vérifier que la table existe
SELECT table_name FROM information_schema.tables
WHERE table_name = 'equipment_templates';

-- Vérifier les données
SELECT COUNT(*) FROM equipment_templates;

-- Vérifier par type de pièce
SELECT rt.name, COUNT(et.*)
FROM room_types rt
LEFT JOIN equipment_templates et ON et.room_type_id = rt.id
GROUP BY rt.name;
```

**Si la table n'existe pas** : Redémarrer Spring Boot pour que Flyway applique la migration V16.

### 3. Problème d'authentification JWT
**Vérification côté Flutter** :
```dart
// Vérifier que le token est bien présent
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token');
print('Token: $token'); // Doit afficher un token JWT

// Ajouter plus de logs dans le service
Future<List<EquipmentTemplateModel>> getAllTemplates() async {
  try {
    final token = await _getToken();
    print('Making request to: $baseUrl');
    print('Token présent: ${token != null}');

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => EquipmentTemplateModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load equipment templates: ${response.statusCode}');
    }
  } catch (e) {
    print('Error details: $e');
    throw Exception('Error fetching equipment templates: $e');
  }
}
```

### 4. URL incorrecte
**Vérification** :
```dart
// Dans equipment_template_service.dart
static const String baseUrl = '${Constants.baseUrl}/equipment-templates';

// Vérifier Constants.baseUrl dans lib/utils/constants.dart
// Devrait être quelque chose comme: http://localhost:8080/api
```

### 5. Backend non démarré
**Vérification** :
```bash
# Vérifier que Spring Boot tourne
curl http://localhost:8080/actuator/health

# Tester l'endpoint directement avec un token
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     http://localhost:8080/api/equipment-templates
```

## Solution recommandée

### Étape 1 : Appliquer le fix RLS
```bash
cd /tmp/cc-agent/61802663/project
psql -U votre_user -d votre_database -f fix_equipment_templates_rls.sql
```

### Étape 2 : Vérifier les données
```sql
SELECT * FROM equipment_templates LIMIT 5;
```

### Étape 3 : Redémarrer Spring Boot
```bash
./mvnw spring-boot:run
```

### Étape 4 : Tester l'endpoint
```bash
# Récupérer un token en se connectant
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your_email","password":"your_password"}'

# Utiliser le token pour tester
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8080/api/equipment-templates
```

### Étape 5 : Tester dans Flutter
```dart
// Dans un écran de test
ElevatedButton(
  onPressed: () async {
    final service = EquipmentTemplateService();
    try {
      final templates = await service.getAllTemplates();
      print('✅ Récupéré ${templates.length} templates');
      templates.forEach((t) => print('- ${t.name}'));
    } catch (e) {
      print('❌ Erreur: $e');
    }
  },
  child: Text('Test Equipment Templates'),
)
```

## Vérifications supplémentaires

### Vérifier que room_types existe
```sql
-- Les equipment templates dépendent de room_types
SELECT id, name FROM room_types WHERE name IN ('Cuisine', 'Salle d''eau');
```

Si `room_types` est vide, les templates ne seront pas créés.

### Vérifier les logs Spring Boot
Rechercher dans les logs :
- `Flyway migration V16` - devrait indiquer que la migration s'est exécutée
- Erreurs de connexion à la base de données
- Erreurs d'authentification JWT

### Vérifier le modèle Flutter
```dart
// Vérifier que EquipmentTemplateModel.fromJson() correspond à la réponse du backend
class EquipmentTemplateModel {
  final int id;
  final String name;
  final int roomTypeId;
  final String? description;
  final int displayOrder;
  final bool isActive;

  // S'assurer que les noms de champs correspondent exactement
}
```

## Code de test complet

```dart
import 'package:flutter/material.dart';
import '../services/equipment_template_service.dart';

class TestEquipmentTemplatesScreen extends StatefulWidget {
  @override
  State<TestEquipmentTemplatesScreen> createState() => _TestEquipmentTemplatesScreenState();
}

class _TestEquipmentTemplatesScreenState extends State<TestEquipmentTemplatesScreen> {
  final _service = EquipmentTemplateService();
  bool _loading = false;
  String _result = '';

  Future<void> _testGetAll() async {
    setState(() {
      _loading = true;
      _result = 'Chargement...';
    });

    try {
      final templates = await _service.getAllTemplates();
      setState(() {
        _result = '✅ ${templates.length} templates chargés\n\n' +
            templates.map((t) => '• ${t.name} (Type: ${t.roomTypeId})').join('\n');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Erreur: $e';
        _loading = false;
      });
    }
  }

  Future<void> _testGetByRoomType(String roomTypeId) async {
    setState(() {
      _loading = true;
      _result = 'Chargement pour type $roomTypeId...';
    });

    try {
      final templates = await _service.getTemplatesByRoomType(roomTypeId);
      setState(() {
        _result = '✅ ${templates.length} templates pour type $roomTypeId\n\n' +
            templates.map((t) => '• ${t.name}').join('\n');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Erreur: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Equipment Templates')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _testGetAll,
              child: Text('Charger tous les templates'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : () => _testGetByRoomType('1'),
              child: Text('Charger templates Cuisine (ID=1)'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : () => _testGetByRoomType('2'),
              child: Text('Charger templates Salle d\'eau (ID=2)'),
            ),
            SizedBox(height: 24),
            if (_loading)
              Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_result),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

## Résumé des corrections apportées

1. ✅ **Migration V16 corrigée** - RLS désactivé
2. ✅ **Script SQL de correction créé** - `fix_equipment_templates_rls.sql`
3. ✅ **Documentation de débogage** - Ce fichier

## Prochaines étapes

1. Appliquer le script `fix_equipment_templates_rls.sql`
2. Redémarrer Spring Boot
3. Tester avec le code de test fourni ci-dessus
4. Vérifier les logs pour identifier l'erreur exacte
