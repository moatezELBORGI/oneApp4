#!/bin/bash

# Script de test de connectivité TURN/STUN
# Teste que le serveur est accessible et fonctionnel

TURN_IP="51.91.99.191"
TURN_PORT="3478"
API_URL="http://localhost:8080/webrtc/turn-credentials"

echo "========================================"
echo "  TEST CONNECTIVITÉ TURN/STUN"
echo "========================================"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "1. Test de connectivité réseau"
echo "-----------------------------------"
# Test ping
if ping -c 1 -W 2 "$TURN_IP" &> /dev/null; then
    check_pass "Serveur $TURN_IP accessible (ping)"
else
    check_fail "Serveur $TURN_IP inaccessible (ping)"
fi

# Test port UDP 3478
if nc -uz -w 2 "$TURN_IP" "$TURN_PORT" 2>/dev/null; then
    check_pass "Port UDP $TURN_PORT ouvert"
else
    check_fail "Port UDP $TURN_PORT fermé ou filtré"
fi

# Test port TCP 3478
if nc -z -w 2 "$TURN_IP" "$TURN_PORT" 2>/dev/null; then
    check_pass "Port TCP $TURN_PORT ouvert"
else
    check_fail "Port TCP $TURN_PORT fermé ou filtré"
fi
echo ""

echo "2. Test de l'API credentials"
echo "-----------------------------------"
if command -v curl &> /dev/null; then
    # Note: Ceci nécessite un token JWT valide
    check_info "Pour tester l'API, utilisez:"
    echo "   curl -H \"Authorization: Bearer YOUR_TOKEN\" $API_URL"
    echo ""
    check_info "Exemple de réponse attendue:"
    echo '   {"username":"1762954199:user123","password":"base64hash","ttl":600,"uris":[...]}'
else
    check_warn "curl non installé, impossible de tester l'API"
fi
echo ""

echo "3. Test STUN avec stunclient"
echo "-----------------------------------"
if command -v stunclient &> /dev/null; then
    check_info "Test STUN en cours..."
    STUN_OUTPUT=$(stunclient "$TURN_IP" "$TURN_PORT" 2>&1)

    if echo "$STUN_OUTPUT" | grep -q "Binding test: success"; then
        check_pass "Serveur STUN fonctionne correctement"
        # Extraire l'IP publique
        PUBLIC_IP=$(echo "$STUN_OUTPUT" | grep -oP 'Mapped address: \K[0-9.]+' | head -1)
        if [ -n "$PUBLIC_IP" ]; then
            check_info "Votre IP publique: $PUBLIC_IP"
        fi
    else
        check_fail "Serveur STUN ne répond pas correctement"
        echo "$STUN_OUTPUT" | sed 's/^/   /'
    fi
else
    check_warn "stunclient non installé"
    check_info "Installation: sudo apt-get install stun-client"
    echo ""
    check_info "Vous pouvez tester manuellement avec:"
    echo "   stunclient $TURN_IP $TURN_PORT"
fi
echo ""

echo "4. Test de résolution DNS"
echo "-----------------------------------"
# Tester la résolution DNS inverse
HOSTNAME=$(dig -x "$TURN_IP" +short 2>/dev/null | head -1)
if [ -n "$HOSTNAME" ]; then
    check_pass "DNS inverse: $HOSTNAME"
else
    check_info "Pas de DNS inverse configuré (normal)"
fi
echo ""

echo "5. Test des ports relay"
echo "-----------------------------------"
check_info "Plage de ports relay: 49152-65535"

# Tester quelques ports aléatoires dans la plage
RANDOM_PORTS=(49152 50000 55000 60000 65535)
OPEN_COUNT=0

for PORT in "${RANDOM_PORTS[@]}"; do
    if timeout 1 bash -c "echo > /dev/tcp/$TURN_IP/$PORT" 2>/dev/null; then
        ((OPEN_COUNT++))
    fi
done

if [ $OPEN_COUNT -gt 0 ]; then
    check_pass "$OPEN_COUNT/$((${#RANDOM_PORTS[@]})) ports relay testés sont accessibles"
else
    check_warn "Aucun port relay testé n'est accessible (peut être normal si non utilisé)"
fi
echo ""

echo "6. Test avec Trickle ICE (Web)"
echo "-----------------------------------"
check_info "Pour un test complet WebRTC, utilisez:"
echo "   https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/"
echo ""
echo "   Configuration à utiliser:"
echo "   - STUN URI: stun:$TURN_IP:$TURN_PORT"
echo "   - TURN URI: turn:$TURN_IP:$TURN_PORT?transport=udp"
echo "   - TURN URI: turn:$TURN_IP:$TURN_PORT?transport=tcp"
echo "   - Username: Récupérer via API /webrtc/turn-credentials"
echo "   - Password: Récupérer via API /webrtc/turn-credentials"
echo ""
check_info "Résultats attendus:"
echo "   ✓ host candidates (local)"
echo "   ✓ srflx candidates (STUN - adresse publique)"
echo "   ✓ relay candidates (TURN - relayé)"
echo ""

echo "7. Vérification des logs serveur"
echo "-----------------------------------"
if [ -f "/var/log/turnserver/turnserver.log" ]; then
    check_pass "Fichier de log trouvé"

    # Compter les sessions récentes (dernière heure)
    SESSION_COUNT=$(sudo grep -c "new session" /var/log/turnserver/turnserver.log 2>/dev/null || echo "0")
    check_info "$SESSION_COUNT sessions créées (total)"

    # Dernières lignes
    echo ""
    check_info "Dernières lignes du log:"
    sudo tail -n 3 /var/log/turnserver/turnserver.log 2>/dev/null | sed 's/^/   /' || echo "   (aucune)"
else
    check_warn "Fichier de log non trouvé"
    echo "   Vérifier: /var/log/turnserver/turnserver.log"
fi
echo ""

echo "========================================"
echo "  RÉSUMÉ"
echo "========================================"
echo ""

# Compter les succès/échecs
CRITICAL_ISSUES=0

if ! nc -uz -w 2 "$TURN_IP" "$TURN_PORT" 2>/dev/null; then
    echo -e "${RED}❌ CRITIQUE: Port UDP 3478 inaccessible${NC}"
    ((CRITICAL_ISSUES++))
fi

if ! nc -z -w 2 "$TURN_IP" "$TURN_PORT" 2>/dev/null; then
    echo -e "${RED}❌ CRITIQUE: Port TCP 3478 inaccessible${NC}"
    ((CRITICAL_ISSUES++))
fi

if [ $CRITICAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Connectivité réseau OK${NC}"
    echo ""
    echo "Prochaines étapes:"
    echo "1. Tester avec l'application Flutter"
    echo "2. Observer les logs: sudo tail -f /var/log/turnserver/turnserver.log"
    echo "3. Vérifier les logs Flutter pour: '[WebRTC] 🎯 ICE [RELAY] collecté'"
else
    echo -e "${RED}$CRITICAL_ISSUES problème(s) critique(s) détecté(s)${NC}"
    echo ""
    echo "Actions correctives:"
    echo "1. Vérifier que le serveur Coturn est démarré: sudo systemctl status coturn"
    echo "2. Vérifier le firewall: sudo ufw status"
    echo "3. Ouvrir les ports: sudo ufw allow 3478/tcp && sudo ufw allow 3478/udp"
    echo "4. Consulter: COTURN_QUICK_FIX.md"
fi

echo ""
echo "========================================"
