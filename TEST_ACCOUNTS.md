# Comptes de Test - OneApp

Ce document liste tous les comptes de test créés automatiquement au démarrage de l'application.

## Comptes Disponibles

### 1. Super Administrateur

| Champ | Valeur |
|-------|--------|
| **Email** | admin@oneapp.com |
| **Mot de passe** | admin123 |
| **Rôle** | SUPER_ADMIN |
| **Description** | Administrateur système avec accès complet |

### 2. Building Admin - Liège

| Champ | Valeur |
|-------|--------|
| **Email** | siamak.miandarbandi@delomid.com |
| **Mot de passe** | password123 |
| **Rôle** | BUILDING_ADMIN |
| **Bâtiment** | Delomid DM Liège |
| **Appartement** | 101 |
| **Description** | Administrateur du bâtiment de Liège |

### 3. Building Admin - Bruxelles

| Champ | Valeur |
|-------|--------|
| **Email** | amir.miandarbandi@delomid.com |
| **Mot de passe** | password123 |
| **Rôle** | BUILDING_ADMIN |
| **Bâtiment** | Delomid IT Bruxelles |
| **Appartement** | 101 |
| **Description** | Administrateur du bâtiment de Bruxelles |

### 4. Résidents - Liège

#### Moatez Borgi

| Champ | Valeur |
|-------|--------|
| **Email** | moatez.borgi@delomid.com |
| **Mot de passe** | password123 |
| **Rôle** | RESIDENT |
| **Bâtiments** | Liège (apt 102), Bruxelles (apt 102) |
| **Description** | Résident dans deux bâtiments |

#### Farzaneh Hajjel

| Champ | Valeur |
|-------|--------|
| **Email** | farzaneh.hajjel@delomid.com |
| **Mot de passe** | password123 |
| **Rôle** | RESIDENT |
| **Bâtiments** | Liège (apt 201), Bruxelles (apt 201) |
| **Description** | Résidente dans deux bâtiments |

### 5. Résident - Bruxelles

#### Somayyeh Gholami

| Champ | Valeur |
|-------|--------|
| **Email** | somayyeh.gholami@delomid.com |
| **Mot de passe** | password123 |
| **Rôle** | RESIDENT |
| **Bâtiment** | Bruxelles (apt 202) |
| **Description** | Résidente à Bruxelles uniquement |

---

## Comptes Propriétaire/Locataire (Nouveaux)

### 6. Propriétaire

| Champ | Valeur |
|-------|--------|
| **Email** | pierre.dupont@owner.com |
| **Mot de passe** | owner123 |
| **Rôle** | OWNER |
| **Bâtiment** | Delomid DM Liège |
| **Appartement possédé** | 101 |
| **Description** | Propriétaire de l'appartement 101 à Liège |

### 7. Locataire

| Champ | Valeur |
|-------|--------|
| **Email** | marie.martin@tenant.com |
| **Mot de passe** | tenant123 |
| **Rôle** | RESIDENT (Locataire) |
| **Bâtiment** | Delomid DM Liège |
| **Appartement loué** | 101 |
| **Description** | Locataire de l'appartement 101 à Liège |

---

## Données de Test Créées Automatiquement

### Bâtiments

1. **Delomid DM Liège**
   - ID: `BEL-2024-DM-LIEGE`
   - Adresse: Rue de la Régence 1, 4000 Liège
   - 3 appartements: 101, 102, 201

2. **Delomid IT Bruxelles**
   - ID: `BEL-2024-IT-BRUXELLES`
   - Adresse: Avenue Louise 100, 1050 Bruxelles
   - 4 appartements: 101, 102, 201, 202

### Appartement 101 - Liège (Avec Système Propriétaire/Locataire)

**Caractéristiques:**
- Propriétaire: Pierre Dupont
- Locataire: Marie Martin
- Surface: 75m²
- 3 pièces, 2 chambres
- Avec balcon/terrasse

**Pièces Créées:**
1. Salon - Grand salon lumineux avec baie vitrée
2. Chambre principale - Chambre spacieuse avec placard intégré
3. Cuisine - Cuisine équipée moderne
4. Salle de bain - Salle de bain avec douche et baignoire

**Contrat de Bail:**
- Statut: DRAFT (Brouillon)
- Loyer initial: 950,00 €
- Loyer actuel: 950,00 €
- Caution: 1 900,00 €
- Charges: 150,00 €
- Région: BE-BRU (Bruxelles)
- Date de début: Date du jour
- Durée: 1 an

**Articles de Contrat Standard (BE-BRU):**
1. Objet du contrat
2. Durée du contrat
3. Loyer et charges

---

## Comment Utiliser Ces Comptes

### Pour Tester le Système Propriétaire/Locataire:

1. **Connexion Propriétaire**
   - Email: pierre.dupont@owner.com
   - Mot de passe: owner123
   - Actions possibles:
     - Voir le contrat de bail
     - Signer le contrat en tant que propriétaire
     - Gérer les pièces de l'appartement
     - Créer un état des lieux
     - Indexer le loyer

2. **Connexion Locataire**
   - Email: marie.martin@tenant.com
   - Mot de passe: tenant123
   - Actions possibles:
     - Voir le contrat de bail
     - Signer le contrat en tant que locataire
     - Participer à l'état des lieux
     - Signer l'état des lieux

3. **Connexion Building Admin (pour créer des propriétaires)**
   - Email: siamak.miandarbandi@delomid.com
   - Mot de passe: password123
   - Actions possibles:
     - Créer de nouveaux propriétaires
     - Attribuer des appartements aux propriétaires
     - Gérer les bâtiments

---

## Flux de Test Complet

### Étape 1: Signature du Contrat de Bail

1. Connectez-vous avec le compte **propriétaire** (pierre.dupont@owner.com)
2. Allez dans "Mes Contrats de Bail"
3. Ouvrez le contrat pour l'appartement 101
4. Cliquez sur "Signer" côté propriétaire
5. Dessinez votre signature
6. Le contrat passe à "EN ATTENTE DE SIGNATURE"

7. Déconnectez-vous et connectez-vous avec le compte **locataire** (marie.martin@tenant.com)
8. Allez dans "Mes Contrats de Bail"
9. Ouvrez le contrat pour l'appartement 101
10. Cliquez sur "Signer" côté locataire
11. Dessinez votre signature
12. Le contrat passe à "SIGNÉ"

### Étape 2: Création d'un État des Lieux

1. Connectez-vous avec le compte **propriétaire** ou **locataire**
2. Allez dans "États des Lieux"
3. Développez le contrat 101
4. Cliquez sur "Créer un état des lieux"
5. Choisissez "État des lieux d'entrée"
6. Remplissez les compteurs:
   - Électricité: Numéro + indices jour/nuit
   - Eau: Numéro + index
   - Chauffage: Numéro + index
7. Remplissez les clés remises:
   - 2 clés appartement
   - 1 clé boîte aux lettres
   - 1 clé cave
   - 1 carte d'accès
   - 1 télécommande parking
8. Cliquez sur "Sauvegarder"

### Étape 3: Signature de l'État des Lieux

1. Dans l'état des lieux, cliquez sur "Signer" côté propriétaire
2. Dessinez votre signature
3. L'état des lieux passe à "EN ATTENTE DE SIGNATURE"

4. Connectez-vous avec l'autre compte (locataire)
5. Ouvrez le même état des lieux
6. Cliquez sur "Signer" côté locataire
7. Dessinez votre signature
8. L'état des lieux passe à "SIGNÉ"

### Étape 4: Génération du PDF

1. Une fois l'état des lieux signé par les deux parties
2. Cliquez sur l'icône PDF dans la barre d'outils
3. Le PDF est généré et stocké
4. Un message de confirmation s'affiche avec le chemin du PDF

### Étape 5: Indexation du Loyer

1. Connectez-vous avec le compte **propriétaire**
2. Allez dans le détail du contrat
3. (Endpoint disponible: `/api/lease-contracts/{contractId}/index-rent`)
4. Fournissez:
   - Taux d'indexation (ex: 0.0345 pour 3,45%)
   - Index de base
   - Nouvel index
   - Notes
5. Le nouveau loyer est calculé automatiquement
6. L'historique des indexations est conservé

---

## Endpoints API Principaux

### Propriétaires
- `POST /api/owners` - Créer un propriétaire
- `GET /api/owners/building/{buildingId}` - Liste des propriétaires

### Contrats de Bail
- `POST /api/lease-contracts` - Créer un contrat
- `GET /api/lease-contracts/my-contracts` - Mes contrats
- `POST /api/lease-contracts/{id}/sign-owner` - Signer (propriétaire)
- `POST /api/lease-contracts/{id}/sign-tenant` - Signer (locataire)
- `POST /api/lease-contracts/{id}/index-rent` - Indexer le loyer

### États des Lieux
- `POST /api/inventories` - Créer un état des lieux
- `GET /api/inventories/{id}` - Détails d'un état des lieux
- `PUT /api/inventories/{id}` - Mettre à jour
- `POST /api/inventories/{id}/sign-owner` - Signer (propriétaire)
- `POST /api/inventories/{id}/sign-tenant` - Signer (locataire)
- `POST /api/inventories/{id}/generate-pdf` - Générer le PDF

### Pièces d'Appartement
- `POST /api/apartment-rooms` - Créer une pièce
- `GET /api/apartment-rooms/apartment/{id}` - Liste des pièces
- `PUT /api/apartment-rooms/{id}` - Mettre à jour
- `DELETE /api/apartment-rooms/{id}` - Supprimer

---

## Documentation Complète

Pour plus d'informations, consultez:
- `OWNER_TENANT_LEASE_SYSTEM.md` - Documentation technique complète
- Swagger UI: `http://localhost:8080/swagger-ui.html` - Documentation API interactive

---

**Note**: Tous ces comptes et données sont créés automatiquement au premier démarrage de l'application. Si la base de données est réinitialisée, ces données seront recréées.
