#!/bin/bash

# Script de déploiement pour utiliser UNIQUEMENT le serveur Coturn
# Ce script configure le système pour utiliser 51.91.99.191 exclusivement

echo "========================================"
echo "  DÉPLOIEMENT COTURN EXCLUSIF"
echo "  Serveur: 51.91.99.191"
echo "========================================"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${BLUE}➜${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Vérifier les privilèges sudo
if ! sudo -v &>/dev/null; then
    error "Ce script nécessite les privilèges sudo"
    exit 1
fi

echo "Étape 1/6: Configuration Coturn"
echo "-----------------------------------"

# Backup de la config actuelle
if [ -f "/etc/turnserver.conf" ]; then
    info "Backup de la configuration actuelle..."
    sudo cp /etc/turnserver.conf /etc/turnserver.conf.backup.$(date +%Y%m%d_%H%M%S)
    success "Backup créé"
else
    warn "Aucune configuration existante trouvée"
fi

# Copier la nouvelle config
if [ -f "turnserver_optimal.conf" ]; then
    info "Application de la nouvelle configuration..."
    sudo cp turnserver_optimal.conf /etc/turnserver.conf
    sudo chown turnserver:turnserver /etc/turnserver.conf 2>/dev/null || sudo chown root:root /etc/turnserver.conf
    sudo chmod 644 /etc/turnserver.conf
    success "Configuration appliquée"
else
    error "Fichier turnserver_optimal.conf introuvable"
    exit 1
fi

# Vérifier la config
info "Vérification de la configuration..."
if grep -q "^no-stun" /etc/turnserver.conf; then
    error "PROBLÈME: 'no-stun' est présent dans la config!"
    exit 1
fi

if grep -q "^no-tcp-relay" /etc/turnserver.conf; then
    error "PROBLÈME: 'no-tcp-relay' est présent dans la config!"
    exit 1
fi

success "Configuration vérifiée (pas de no-stun, pas de no-tcp-relay)"
echo ""

echo "Étape 2/6: Firewall"
echo "-----------------------------------"

info "Configuration du firewall..."

# Vérifier si UFW est installé
if command -v ufw &> /dev/null; then
    sudo ufw allow 3478/tcp &>/dev/null
    sudo ufw allow 3478/udp &>/dev/null
    sudo ufw allow 5349/tcp &>/dev/null
    sudo ufw allow 49152:65535/tcp &>/dev/null
    sudo ufw allow 49152:65535/udp &>/dev/null
    success "Ports firewall configurés"
else
    warn "UFW non installé, vérifier manuellement les ports"
fi
echo ""

echo "Étape 3/6: Coturn"
echo "-----------------------------------"

info "Redémarrage de Coturn..."
sudo systemctl restart coturn

# Attendre un peu
sleep 2

if sudo systemctl is-active --quiet coturn; then
    success "Coturn actif et fonctionnel"
else
    error "Coturn n'a pas démarré correctement"
    sudo journalctl -u coturn -n 20
    exit 1
fi

# Vérifier les ports
if sudo netstat -tuln | grep -q ":3478 "; then
    success "Port 3478 en écoute"
else
    error "Port 3478 non accessible"
    exit 1
fi
echo ""

echo "Étape 4/6: Backend Java"
echo "-----------------------------------"

if [ -f "pom.xml" ]; then
    info "Rebuild du backend..."
    ./mvnw clean package -DskipTests

    if [ $? -eq 0 ]; then
        success "Backend compilé avec succès"

        # Redémarrer si c'est un service
        if sudo systemctl list-units --type=service | grep -q mschat; then
            info "Redémarrage du service mschat..."
            sudo systemctl restart mschat
            sleep 2

            if sudo systemctl is-active --quiet mschat; then
                success "Service mschat redémarré"
            else
                warn "Service mschat n'a pas redémarré correctement"
            fi
        else
            warn "Service mschat non trouvé, redémarrer manuellement"
        fi
    else
        error "Échec de compilation du backend"
        exit 1
    fi
else
    warn "pom.xml non trouvé, rebuild manuel nécessaire"
fi
echo ""

echo "Étape 5/6: Vérifications"
echo "-----------------------------------"

# Vérifier l'API
info "Test de l'API TURN credentials..."
API_RESPONSE=$(curl -s http://localhost:8080/webrtc/turn-credentials -H "Authorization: Bearer test" 2>/dev/null || echo "")

if [ -n "$API_RESPONSE" ]; then
    # Vérifier si la réponse contient 51.91.99.191
    if echo "$API_RESPONSE" | grep -q "51.91.99.191"; then
        success "API retourne le serveur 51.91.99.191"

        # Compter les URIs
        URI_COUNT=$(echo "$API_RESPONSE" | grep -o "51.91.99.191" | wc -l)
        info "Nombre d'URIs: $URI_COUNT (attendu: 3)"

        if [ "$URI_COUNT" -ge 3 ]; then
            success "3 URIs détectées (STUN + TURN UDP + TURN TCP)"
        else
            warn "Moins de 3 URIs détectées"
        fi
    else
        warn "API accessible mais ne retourne pas 51.91.99.191"
    fi
else
    warn "API non accessible (authentification requise)"
    info "Tester manuellement: curl -H 'Authorization: Bearer YOUR_TOKEN' http://localhost:8080/webrtc/turn-credentials"
fi

# Vérifier les logs Coturn
info "Vérification des logs Coturn..."
if [ -f "/var/log/turnserver/turnserver.log" ]; then
    if sudo tail -n 5 /var/log/turnserver/turnserver.log | grep -q "listening"; then
        success "Coturn écoute correctement"
    else
        warn "Vérifier les logs: sudo tail -f /var/log/turnserver/turnserver.log"
    fi
else
    warn "Fichier de log non trouvé"
fi
echo ""

echo "Étape 6/6: Application Flutter"
echo "-----------------------------------"

info "Pour l'application Flutter, exécuter:"
echo "   flutter clean"
echo "   flutter pub get"
echo "   flutter run"
echo ""

echo "========================================"
echo "  DÉPLOIEMENT TERMINÉ"
echo "========================================"
echo ""

success "Configuration appliquée avec succès!"
echo ""
echo "Prochaines étapes:"
echo ""
echo "1. Rebuild l'app Flutter:"
echo "   ${BLUE}flutter clean && flutter pub get && flutter run${NC}"
echo ""
echo "2. Observer les logs Flutter au démarrage:"
echo "   ${BLUE}[WebRTC] URIs: [stun:51.91.99.191:3478, ...]${NC}"
echo ""
echo "3. Lors d'un appel, vérifier:"
echo "   ${BLUE}[WebRTC] 🎯 ICE [RELAY] collecté - TURN fonctionne!${NC}"
echo "   ${BLUE}[WebRTC] ✓✓✓ APPEL CONNECTÉ ✓✓✓${NC}"
echo ""
echo "4. Observer les logs Coturn:"
echo "   ${BLUE}sudo tail -f /var/log/turnserver/turnserver.log${NC}"
echo ""
echo "📊 Résultat attendu:"
echo "   ✓ 100% du trafic via votre serveur 51.91.99.191"
echo "   ✓ Appel se connecte en 3-8 secondes dès le premier essai"
echo "   ✓ Logs Coturn montrent les allocations"
echo ""
echo "Documentation: ${BLUE}DEPLOY_COTURN_ONLY.md${NC}"
echo ""
