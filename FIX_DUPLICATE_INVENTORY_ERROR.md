# Fix: Erreur "Query did not return a unique result: 2 results were returned"

## Problème

Lors de la consultation des contrats d'un appartement, l'erreur suivante se produisait :

```
org.springframework.dao.IncorrectResultSizeDataAccessException: Query did not return a unique result: 2 results were returned
```

**Localisation** : `LeaseContractEnhancedService.convertToDtoWithInventoryStatus` (ligne 81)

## Cause

Le problème venait de la méthode `findByContract_IdAndType` du `InventoryRepository` qui s'attendait à retourner un seul inventaire (dans un `Optional`), mais plusieurs inventaires du même type (ENTRY ou EXIT) existaient pour le même contrat dans la base de données.

### Scénario problématique

1. Un utilisateur crée un premier état des lieux d'entrée pour un contrat
2. Pour une raison quelconque (test, erreur, doublon), un deuxième état des lieux d'entrée est créé pour le même contrat
3. La requête `findByContract_IdAndType` trouve 2 résultats au lieu d'1
4. Hibernate lève une exception `NonUniqueResultException`

## Solution Appliquée

### 1. Ajout d'une nouvelle méthode au Repository

**Fichier** : `InventoryRepository.java`

Ajout de la méthode qui retourne une liste triée par date de création :

```java
List<Inventory> findByContract_IdAndTypeOrderByCreatedAtDesc(UUID contractId, InventoryType type);
```

Cette méthode :
- Retourne **tous** les inventaires correspondant au contrat et au type
- Les trie par date de création **décroissante** (le plus récent en premier)

### 2. Modification du Service

**Fichier** : `LeaseContractEnhancedService.java`

#### Méthode `convertToDtoWithInventoryStatus` (ligne 80-85)

**AVANT** :
```java
Optional<Inventory> entryInventory = inventoryRepository.findByContract_IdAndType(contract.getId(), InventoryType.ENTRY);
Optional<Inventory> exitInventory = inventoryRepository.findByContract_IdAndType(contract.getId(), InventoryType.EXIT);
```

**APRÈS** :
```java
List<Inventory> entryInventories = inventoryRepository.findByContract_IdAndTypeOrderByCreatedAtDesc(contract.getId(), InventoryType.ENTRY);
Optional<Inventory> entryInventory = entryInventories.isEmpty() ? Optional.empty() : Optional.of(entryInventories.get(0));

List<Inventory> exitInventories = inventoryRepository.findByContract_IdAndTypeOrderByCreatedAtDesc(contract.getId(), InventoryType.EXIT);
Optional<Inventory> exitInventory = exitInventories.isEmpty() ? Optional.empty() : Optional.of(exitInventories.get(0));
```

#### Méthode `canTerminateContract` (ligne 42-48)

**AVANT** :
```java
Optional<Inventory> exitInventory = inventoryRepository.findByContract_IdAndType(contractId, InventoryType.EXIT);
return exitInventory.isPresent() && exitInventory.get().getStatus() == InventoryStatus.SIGNED;
```

**APRÈS** :
```java
List<Inventory> exitInventories = inventoryRepository.findByContract_IdAndTypeOrderByCreatedAtDesc(contractId, InventoryType.EXIT);
if (exitInventories.isEmpty()) {
    return false;
}
return exitInventories.get(0).getStatus() == InventoryStatus.SIGNED;
```

## Logique de la Solution

1. **Récupération de tous les inventaires** correspondant aux critères (contrat + type)
2. **Tri par date de création décroissante** → le plus récent en premier
3. **Sélection du premier élément** (le plus récent) si la liste n'est pas vide
4. **Utilisation dans le DTO** comme auparavant avec un `Optional`

## Avantages de cette Approche

✅ **Résout les doublons** : Gère le cas où plusieurs inventaires existent
✅ **Logique métier cohérente** : Utilise toujours l'inventaire le plus récent
✅ **Rétrocompatibilité** : Le reste du code continue de fonctionner avec des `Optional`
✅ **Préventif** : Évite les erreurs futures si d'autres doublons sont créés

## Test de la Solution

1. **Vérifier les contrats avec inventaires multiples** :
   ```sql
   SELECT contract_id, type, COUNT(*) as count
   FROM inventories
   GROUP BY contract_id, type
   HAVING COUNT(*) > 1;
   ```

2. **Tester l'affichage des contrats** :
   - Ouvrir l'application Flutter
   - Naviguer vers "Mes Propriétés" → Sélectionner un appartement
   - Cliquer sur "Contrats de location"
   - Vérifier que la liste s'affiche sans erreur

3. **Vérifier que le bon inventaire est affiché** :
   - L'inventaire affiché devrait être le plus récent (created_at le plus grand)

## Nettoyage Recommandé (Optionnel)

Si vous souhaitez supprimer les inventaires en double pour éviter la confusion :

```sql
-- Identifier les doublons
WITH RankedInventories AS (
    SELECT
        id,
        contract_id,
        type,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY contract_id, type ORDER BY created_at DESC) as rn
    FROM inventories
)
-- Voir les inventaires qui seraient supprimés (rn > 1)
SELECT * FROM RankedInventories WHERE rn > 1;

-- Pour supprimer les doublons (ATTENTION : Tester d'abord en dev !)
-- DELETE FROM inventories
-- WHERE id IN (
--     SELECT id FROM RankedInventories WHERE rn > 1
-- );
```

⚠️ **ATTENTION** : Ne pas exécuter le DELETE sans avoir d'abord vérifié les données et fait un backup !

## Prévention Future

Pour éviter la création de doublons à l'avenir, on pourrait :

1. **Ajouter une contrainte unique** en base de données :
   ```sql
   ALTER TABLE inventories
   ADD CONSTRAINT unique_contract_type
   UNIQUE (contract_id, type);
   ```

   ⚠️ **Mais attention** : Cela empêcherait de créer un nouvel état des lieux si on veut remplacer l'ancien

2. **Logique applicative** : Avant de créer un inventaire, vérifier s'il en existe déjà un du même type et :
   - Soit empêcher la création
   - Soit archiver/supprimer l'ancien
   - Soit demander confirmation à l'utilisateur

## Conclusion

Le problème est maintenant résolu. L'application gère correctement les cas où plusieurs inventaires du même type existent pour un contrat en utilisant toujours le plus récent.
