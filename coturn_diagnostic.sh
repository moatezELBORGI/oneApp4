#!/bin/bash

# Script de diagnostic Coturn
# Vérifie que le serveur TURN/STUN est correctement configuré

echo "========================================"
echo "  DIAGNOSTIC COTURN POUR WEBRTC"
echo "========================================"
echo ""

TURN_IP="51.91.99.191"
TURN_PORT="3478"
LOG_FILE="/var/log/turnserver/turnserver.log"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction de test
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. Vérification du service Coturn"
echo "-----------------------------------"
if systemctl is-active --quiet coturn; then
    check_pass "Service coturn actif"
else
    check_fail "Service coturn inactif"
    echo "   Commande: sudo systemctl start coturn"
fi

if systemctl is-enabled --quiet coturn; then
    check_pass "Service coturn activé au démarrage"
else
    check_warn "Service coturn non activé au démarrage"
    echo "   Commande: sudo systemctl enable coturn"
fi
echo ""

echo "2. Vérification des ports"
echo "-----------------------------------"
# Port 3478 UDP
if sudo netstat -uln | grep -q ":3478 "; then
    check_pass "Port 3478/UDP ouvert"
else
    check_fail "Port 3478/UDP non ouvert"
fi

# Port 3478 TCP
if sudo netstat -tln | grep -q ":3478 "; then
    check_pass "Port 3478/TCP ouvert"
else
    check_fail "Port 3478/TCP non ouvert"
fi

# Port 5349 TCP
if sudo netstat -tln | grep -q ":5349 "; then
    check_pass "Port 5349/TCP ouvert"
else
    check_warn "Port 5349/TCP non ouvert (TLS désactivé)"
fi
echo ""

echo "3. Vérification de la configuration"
echo "-----------------------------------"
CONFIG_FILE="/etc/turnserver.conf"

if [ -f "$CONFIG_FILE" ]; then
    check_pass "Fichier de configuration trouvé"

    # Vérifier no-stun
    if grep -q "^no-stun" "$CONFIG_FILE"; then
        check_fail "PROBLÈME: 'no-stun' est activé (doit être supprimé)"
    else
        check_pass "'no-stun' absent (correct)"
    fi

    # Vérifier no-tcp-relay
    if grep -q "^no-tcp-relay" "$CONFIG_FILE"; then
        check_warn "ATTENTION: 'no-tcp-relay' est activé (peut causer des problèmes)"
    else
        check_pass "'no-tcp-relay' absent (correct)"
    fi

    # Vérifier external-ip
    if grep -q "^external-ip=" "$CONFIG_FILE"; then
        EXTERNAL_IP=$(grep "^external-ip=" "$CONFIG_FILE" | cut -d'=' -f2)
        check_pass "external-ip configuré: $EXTERNAL_IP"
    else
        check_warn "external-ip non configuré"
    fi

    # Vérifier static-auth-secret
    if grep -q "^static-auth-secret=" "$CONFIG_FILE"; then
        check_pass "static-auth-secret configuré"
    else
        check_fail "static-auth-secret manquant"
    fi
else
    check_fail "Fichier de configuration non trouvé: $CONFIG_FILE"
fi
echo ""

echo "4. Vérification du firewall"
echo "-----------------------------------"
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "inactive"; then
        check_warn "UFW désactivé"
    else
        check_pass "UFW actif"

        # Vérifier port 3478
        if sudo ufw status | grep -q "3478"; then
            check_pass "Port 3478 autorisé dans UFW"
        else
            check_warn "Port 3478 non trouvé dans UFW"
            echo "   Commandes:"
            echo "   sudo ufw allow 3478/tcp"
            echo "   sudo ufw allow 3478/udp"
        fi

        # Vérifier plage de ports pour le relay
        if sudo ufw status | grep -q "49152:65535"; then
            check_pass "Plage de ports relay autorisée (49152-65535)"
        else
            check_warn "Plage de ports relay non trouvée dans UFW"
            echo "   Commandes:"
            echo "   sudo ufw allow 49152:65535/tcp"
            echo "   sudo ufw allow 49152:65535/udp"
        fi
    fi
else
    check_warn "UFW non installé (vérifier iptables manuellement)"
fi
echo ""

echo "5. Vérification des logs récents"
echo "-----------------------------------"
if [ -f "$LOG_FILE" ]; then
    check_pass "Fichier de log trouvé"

    # Vérifier les erreurs récentes
    ERROR_COUNT=$(sudo tail -n 100 "$LOG_FILE" | grep -i "error\|fail" | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        check_warn "$ERROR_COUNT erreur(s) trouvée(s) dans les 100 dernières lignes"
        echo "   Voir: sudo tail -n 50 $LOG_FILE"
    else
        check_pass "Aucune erreur récente dans les logs"
    fi

    # Afficher les 5 dernières lignes
    echo ""
    echo "Dernières lignes du log:"
    sudo tail -n 5 "$LOG_FILE" 2>/dev/null | sed 's/^/   /'
else
    check_warn "Fichier de log non trouvé: $LOG_FILE"
fi
echo ""

echo "6. Test de connectivité"
echo "-----------------------------------"
# Test STUN
echo "Test STUN sur $TURN_IP:$TURN_PORT..."
if nc -uz -w 2 "$TURN_IP" "$TURN_PORT" 2>/dev/null; then
    check_pass "Serveur accessible sur UDP $TURN_PORT"
else
    check_fail "Serveur inaccessible sur UDP $TURN_PORT"
fi

if nc -z -w 2 "$TURN_IP" "$TURN_PORT" 2>/dev/null; then
    check_pass "Serveur accessible sur TCP $TURN_PORT"
else
    check_fail "Serveur inaccessible sur TCP $TURN_PORT"
fi
echo ""

echo "========================================"
echo "  RÉSUMÉ ET RECOMMANDATIONS"
echo "========================================"
echo ""

# Compter les problèmes
ISSUES=0

if ! systemctl is-active --quiet coturn; then
    echo "❌ CRITIQUE: Démarrer le service coturn"
    ((ISSUES++))
fi

if grep -q "^no-stun" "$CONFIG_FILE" 2>/dev/null; then
    echo "❌ CRITIQUE: Supprimer 'no-stun' de la configuration"
    ((ISSUES++))
fi

if grep -q "^no-tcp-relay" "$CONFIG_FILE" 2>/dev/null; then
    echo "⚠️  IMPORTANT: Supprimer 'no-tcp-relay' pour meilleure compatibilité"
fi

if ! sudo netstat -uln | grep -q ":3478 "; then
    echo "❌ CRITIQUE: Le port 3478/UDP n'écoute pas"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Aucun problème critique détecté!${NC}"
    echo ""
    echo "Pour tester votre configuration, utilisez:"
    echo "https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/"
    echo ""
    echo "Paramètres:"
    echo "  STUN: stun:$TURN_IP:$TURN_PORT"
    echo "  TURN: turn:$TURN_IP:$TURN_PORT?transport=udp"
    echo "  Username/Password: Récupérer via /webrtc/turn-credentials"
else
    echo -e "${RED}$ISSUES problème(s) critique(s) détecté(s)${NC}"
    echo ""
    echo "Consultez COTURN_FIX_INSTRUCTIONS.md pour les instructions de correction"
fi

echo ""
echo "========================================"
