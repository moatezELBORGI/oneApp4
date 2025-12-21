# Utilisation Exclusive de Votre Serveur Coturn

## ✅ Modifications Appliquées

### 1. Backend Java - Ajout de l'URI STUN

**Fichier**: `TurnCredentialsController.java`

L'API retourne maintenant **3 URIs** pour votre serveur:
```java
"stun:51.91.99.191:3478",           // STUN pour découverte d'adresse
"turn:51.91.99.191:3478?transport=udp",  // TURN relay UDP
"turn:51.91.99.191:3478?transport=tcp"   // TURN relay TCP
```

### 2. Flutter Client - Utilisation Exclusive

**Fichier**: `webrtc_service.dart`

```dart
final config = {
  'iceServers': [
    // UNIQUEMENT votre serveur avec credentials
    {
      'urls': [
        'stun:51.91.99.191:3478',
        'turn:51.91.99.191:3478?transport=udp',
        'turn:51.91.99.191:3478?transport=tcp'
      ],
      'username': data['username'],
      'credential': data['password'],
    },
  ],
};
```

**Avant**: Utilisait Google STUN + votre TURN
**Après**: Utilise UNIQUEMENT votre serveur pour STUN ET TURN

### 3. Configuration Coturn Optimisée

**Fichier**: `turnserver_optimal.conf`

Corrections appliquées:
- ✅ Supprimé les duplications (`no-multicast-peers`, `stale-nonce`)
- ✅ Gardé `no-tlsv1` et `no-tlsv1_1` (anciennes versions)
- ✅ Retiré `no-tlsv1_2` (TLS 1.2 est encore nécessaire)
- ✅ Support complet STUN + TURN (UDP + TCP)

## 🚀 Déploiement

### Étape 1: Configuration Coturn

```bash
# Backup de la config actuelle
sudo cp /etc/turnserver.conf /etc/turnserver.conf.backup

# Appliquer la nouvelle config
sudo cp turnserver_optimal.conf /etc/turnserver.conf

# Permissions
sudo chown turnserver:turnserver /etc/turnserver.conf
sudo chmod 644 /etc/turnserver.conf
```

### Étape 2: Vérification de la Configuration

```bash
# Vérifier qu'il n'y a pas de duplications ni d'erreurs
cat /etc/turnserver.conf

# Vérifier que no-stun et no-tcp-relay sont absents
grep "^no-stun" /etc/turnserver.conf
grep "^no-tcp-relay" /etc/turnserver.conf
# Ces commandes ne doivent RIEN retourner
```

### Étape 3: Firewall

```bash
# S'assurer que tous les ports sont ouverts
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw allow 49152:65535/tcp
sudo ufw allow 49152:65535/udp

# Vérifier
sudo ufw status | grep 3478
sudo ufw status | grep 49152
```

### Étape 4: Redémarrage

```bash
# Redémarrer Coturn
sudo systemctl restart coturn

# Vérifier le statut
sudo systemctl status coturn

# Vérifier que le serveur écoute
sudo netstat -tuln | grep 3478
# Doit montrer TCP et UDP sur 3478
```

### Étape 5: Backend Java

```bash
# Rebuild
./mvnw clean package -DskipTests

# Redémarrer
sudo systemctl restart mschat

# Vérifier les logs
sudo journalctl -u mschat -f
```

### Étape 6: Application Flutter

```bash
# Nettoyer et rebuild
flutter clean
flutter pub get
flutter run
```

## 🔍 Vérification

### 1. Vérifier les Logs Coturn

```bash
sudo tail -f /var/log/turnserver/turnserver.log
```

Au démarrage, vous devriez voir:
```
listening on IPv4/IPv6 addr 0.0.0.0:3478
RFC 3489/5389/5766/5780/6062/6156 STUN/TURN server
```

### 2. Vérifier l'API

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/webrtc/turn-credentials
```

Réponse attendue:
```json
{
  "username": "1762954199:user123",
  "password": "base64encodedpassword",
  "ttl": 600,
  "uris": [
    "stun:51.91.99.191:3478",
    "turn:51.91.99.191:3478?transport=udp",
    "turn:51.91.99.191:3478?transport=tcp"
  ]
}
```

### 3. Logs Flutter au Démarrage

```
[WebRTC] Warmup TURN...
[WebRTC] ✓ TURN chargé (3 URIs, TTL: 600s)
[WebRTC] Username: 1762954199:user123
[WebRTC] URIs: [stun:51.91.99.191:3478, turn:51.91.99.191:3478?transport=udp, ...]
[WebRTC] ✓ Warmup TURN terminé
```

### 4. Lors d'un Appel

**Flutter**:
```
[WebRTC] ✓ TURN depuis cache
[WebRTC] Config ICE: [{urls: [stun:51.91.99.191:3478, ...], username: ..., credential: ...}]
[WebRTC] ICE [HOST] collecté
[WebRTC] ICE [SRFLX] collecté  ← Via STUN de votre serveur
[WebRTC] 🎯 ICE [RELAY] collecté - TURN fonctionne!  ← Via TURN de votre serveur
[WebRTC] ✓✓✓ ICE Gathering terminé avec RELAY ✓✓✓
[WebRTC] ✓✓✓ APPEL CONNECTÉ ✓✓✓
```

**Coturn**:
```
session 001000000000000001: realm <51.91.99.191> user <1762954199:user123>
session 001000000000000001: incoming packet ALLOCATE processed
session 001000000000000001: allocation created: relay 51.91.99.191:49152
```

## 🎯 Flow des Connexions

### Avec Votre Configuration

1. **STUN (Découverte)**: `stun:51.91.99.191:3478`
   - Le client découvre son adresse IP publique via votre serveur
   - Génère des candidates `srflx` (Server Reflexive)

2. **TURN UDP (Relay principal)**: `turn:51.91.99.191:3478?transport=udp`
   - Si connexion directe impossible
   - Relay via UDP (plus rapide, moins de latence)

3. **TURN TCP (Fallback)**: `turn:51.91.99.191:3478?transport=tcp`
   - Si UDP bloqué (firewalls strictes)
   - Relay via TCP (plus lent mais fonctionne partout)

### Types de Candidates Collectés

Tous proviennent de votre serveur `51.91.99.191`:

- **host**: Adresse locale (192.168.x.x)
- **srflx**: Adresse publique via STUN 51.91.99.191
- **relay**: Adresse relay via TURN 51.91.99.191

## 📊 Avantages

| Aspect | Avant (Google + Votre serveur) | Après (Uniquement votre serveur) |
|--------|-------------------------------|----------------------------------|
| **Serveurs utilisés** | Google STUN + Votre TURN | Uniquement le vôtre |
| **Latence** | Variable (Google peut être loin) | Constante (votre serveur) |
| **Contrôle** | Partiel | Total |
| **Dépendance externe** | Oui (Google) | Non |
| **Coût bande passante** | Partagé | 100% contrôlé |
| **Logs** | Incomplets | Complets |
| **Debugging** | Difficile | Facile |

## 🐛 Diagnostic

### Problème: Pas de RELAY Candidates

```bash
# Vérifier que Coturn fonctionne
sudo systemctl status coturn

# Vérifier les credentials
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8080/webrtc/turn-credentials

# Vérifier les logs Coturn
sudo tail -n 50 /var/log/turnserver/turnserver.log | grep -i "error\|fail"

# Tester l'accessibilité
nc -zv 51.91.99.191 3478
```

### Problème: Authentication Failed

**Cause**: Le `TURN_SECRET` ne correspond pas

**Solution**:
```bash
# Vérifier le secret dans Coturn
grep "static-auth-secret" /etc/turnserver.conf

# Vérifier le secret dans le code Java
grep "TURN_SECRET" src/main/java/be/delomid/oneapp/mschat/mschat/controller/TurnCredentialsController.java

# Ils doivent être IDENTIQUES
```

### Problème: Appel Timeout

**Cause**: Ports relay bloqués

**Solution**:
```bash
# Vérifier les ports relay
sudo ufw status | grep 49152

# Ouvrir si nécessaire
sudo ufw allow 49152:65535/tcp
sudo ufw allow 49152:65535/udp
```

## ✅ Checklist Finale

- [ ] Configuration Coturn appliquée (`turnserver_optimal.conf`)
- [ ] Coturn redémarré et actif
- [ ] Ports firewall ouverts (3478, 49152-65535)
- [ ] Backend Java rebuild et redémarré
- [ ] Application Flutter rebuild
- [ ] API retourne 3 URIs (1 STUN + 2 TURN)
- [ ] Logs Flutter montrent votre serveur uniquement
- [ ] Premier appel se connecte en 3-8s
- [ ] Logs Coturn montrent les allocations

## 📈 Métriques de Succès

Après ce déploiement:

- ✅ **100% du trafic** passe par votre serveur 51.91.99.191
- ✅ **SRFLX candidates** proviennent de votre STUN
- ✅ **RELAY candidates** proviennent de votre TURN
- ✅ **Logs complets** dans Coturn
- ✅ **Contrôle total** sur la qualité de service
- ✅ **Pas de dépendance** à Google ou autres services externes

## 🚦 Status

- **Backend**: ✅ Modifié (3 URIs)
- **Flutter**: ✅ Modifié (serveur unique)
- **Config Coturn**: ✅ Optimisée (sans duplications)
- **Fallback**: ⚠️ Google STUN (seulement si API inaccessible)

---

**Important**: Le fallback vers Google STUN ne sera utilisé que si votre backend est complètement inaccessible. Dans l'utilisation normale, **100% du trafic** passe par votre serveur `51.91.99.191`.
