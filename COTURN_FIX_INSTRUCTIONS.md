# Fix Coturn - Instructions de déploiement

## Problèmes identifiés dans la configuration initiale

### 1. **`no-stun` activé** ❌
- Désactivait le serveur STUN
- Le client Flutter tentait d'utiliser `stun:51.91.99.191:3478` mais le serveur refusait
- Causait des échecs de connexion ICE

### 2. **`no-tcp-relay` activé** ❌
- Désactivait le relay TCP
- Bloquait les connexions dans les réseaux restrictifs (firewalls corporatifs, certains FAI)
- Les clients ne pouvant pas utiliser UDP échouaient

### 3. **URIs STUN dans les réponses API** ❌
- Le contrôleur Java retournait des URIs STUN redondants
- Avec `no-stun` activé, ces URIs ne fonctionnaient pas

## Corrections appliquées

### 1. Configuration Coturn (`turnserver_fixed.conf`)

✅ **Supprimé `no-stun`**
- Active le support STUN
- Permet la découverte d'adresses IP publiques

✅ **Supprimé `no-tcp-relay`**
- Active le relay TCP
- Meilleure compatibilité avec les réseaux restrictifs

✅ **Ajouté optimisations WebRTC**
```conf
no-loopback-peers
no-multicast-peers
stale-nonce=600
```

### 2. API Java (`TurnCredentialsController.java`)

✅ **Supprimé l'URI STUN redondant**
- Avant: 3 URIs dont 1 STUN
- Après: 2 URIs TURN (UDP + TCP)
- Le client utilise déjà des serveurs STUN publics

## Instructions de déploiement

### Étape 1: Backup de la configuration actuelle
```bash
sudo cp /etc/turnserver.conf /etc/turnserver.conf.backup
```

### Étape 2: Appliquer la nouvelle configuration
```bash
sudo cp turnserver_fixed.conf /etc/turnserver.conf
```

### Étape 3: Vérifier les permissions
```bash
sudo chown turnserver:turnserver /etc/turnserver.conf
sudo chmod 644 /etc/turnserver.conf
```

### Étape 4: Créer le répertoire de logs si nécessaire
```bash
sudo mkdir -p /var/log/turnserver
sudo chown turnserver:turnserver /var/log/turnserver
```

### Étape 5: Vérifier les ports ouverts
```bash
# Vérifier que les ports sont ouverts dans le firewall
sudo ufw status
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw allow 49152:65535/tcp
sudo ufw allow 49152:65535/udp
```

### Étape 6: Redémarrer Coturn
```bash
sudo systemctl restart coturn
```

### Étape 7: Vérifier le statut
```bash
sudo systemctl status coturn
```

### Étape 8: Tester la configuration
```bash
# Vérifier que le serveur écoute sur les bons ports
sudo netstat -tuln | grep 3478

# Vérifier les logs
sudo tail -f /var/log/turnserver/turnserver.log
```

## Test de connectivité

Utilisez Trickle ICE pour tester:
https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/

### Paramètres de test:
- **STUN URI**: `stun:51.91.99.191:3478`
- **TURN UDP URI**: `turn:51.91.99.191:3478?transport=udp`
- **TURN TCP URI**: `turn:51.91.99.191:3478?transport=tcp`
- **Username**: Récupérer via l'API `/webrtc/turn-credentials`
- **Password**: Récupérer via l'API `/webrtc/turn-credentials`

### Résultats attendus:
- ✅ `host` candidates (adresse locale)
- ✅ `srflx` candidates (via STUN - adresse publique)
- ✅ `relay` candidates (via TURN - relayé)

Si vous obtenez les 3 types, la configuration fonctionne parfaitement!

## Redéploiement de l'application

Après avoir modifié le contrôleur Java:

```bash
# Rebuild l'application
./mvnw clean package -DskipTests

# Redémarrer l'application
sudo systemctl restart mschat
```

## Vérification finale

1. **Côté serveur**: Les logs Coturn montrent les connexions
```bash
sudo tail -f /var/log/turnserver/turnserver.log
```

2. **Côté client**: Les appels se connectent du premier coup
- Ouvrir l'app Flutter
- Initier un appel vocal
- Vérifier la connexion en moins de 5 secondes

## Résolution de problèmes

### Problème: "Permission denied" sur les ports
```bash
sudo setcap 'cap_net_bind_service=+ep' /usr/bin/turnserver
```

### Problème: ICE candidates "relay" manquants
- Vérifier que `no-tcp-relay` et `no-stun` sont bien absents de `/etc/turnserver.conf`
- Redémarrer coturn

### Problème: Timeout après 25 secondes
- Vérifier les ports UDP 49152-65535 sont ouverts
- Vérifier `external-ip` et `relay-ip` correspondent à l'IP publique du serveur

### Problème: "Authentication failed"
- Vérifier que `TURN_SECRET` dans le contrôleur Java correspond exactement à `static-auth-secret` dans turnserver.conf

## Performance attendue

Avec cette configuration:
- ✅ Connexion en 2-5 secondes
- ✅ Fonctionne derrière NAT symétrique
- ✅ Fonctionne derrière firewall corporate
- ✅ Pas besoin de plusieurs tentatives
- ✅ Audio/vidéo stable

## Architecture de fallback

L'application utilise cette stratégie:
1. **Tentative directe (host)** - P2P direct
2. **Via STUN (srflx)** - Traversée NAT simple
3. **Via TURN (relay)** - Relay complet (toujours fonctionne)

Avec la config corrigée, tous les chemins sont disponibles!
