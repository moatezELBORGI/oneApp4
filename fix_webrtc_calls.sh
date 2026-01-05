#!/bin/bash

# Script d'installation rapide - Fix WebRTC Calls
# Résout le problème des appels qui fonctionnent après plusieurs tentatives

set -e

echo "=========================================="
echo "   FIX APPELS WEBRTC - Installation"
echo "=========================================="
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then
    error "Ce script doit être exécuté en tant que root (sudo)"
    exit 1
fi

info "Vérification du système..."

# Vérifier que Coturn est installé
if ! command -v turnserver &> /dev/null; then
    error "Coturn n'est pas installé. Installez-le d'abord:"
    echo "  sudo apt-get install coturn"
    exit 1
fi

info "Coturn détecté ✓"

# Arrêter Coturn
info "Arrêt de Coturn..."
systemctl stop coturn

# Backup de l'ancienne configuration
BACKUP_FILE="/etc/turnserver.conf.backup.$(date +%Y%m%d_%H%M%S)"
if [ -f "/etc/turnserver.conf" ]; then
    info "Sauvegarde de l'ancienne configuration vers: $BACKUP_FILE"
    cp /etc/turnserver.conf "$BACKUP_FILE"
fi

# Installer la nouvelle configuration
info "Installation de la nouvelle configuration optimisée..."
if [ -f "turnserver_optimal_fix.conf" ]; then
    cp turnserver_optimal_fix.conf /etc/turnserver.conf
    info "Configuration installée ✓"
else
    error "Fichier turnserver_optimal_fix.conf introuvable!"
    error "Assurez-vous d'exécuter ce script depuis le répertoire du projet."
    exit 1
fi

# Créer le répertoire de logs si nécessaire
if [ ! -d "/var/log/turnserver" ]; then
    info "Création du répertoire de logs..."
    mkdir -p /var/log/turnserver
    chown turnserver:turnserver /var/log/turnserver
fi

# Redémarrer Coturn
info "Redémarrage de Coturn..."
systemctl start coturn

# Attendre que le service démarre
sleep 2

# Vérifier le statut
if systemctl is-active --quiet coturn; then
    info "✓✓✓ Coturn démarré avec succès ✓✓✓"
else
    error "Échec du démarrage de Coturn"
    error "Vérifiez les logs: sudo journalctl -u coturn -n 50"
    exit 1
fi

# Activer Coturn au démarrage
systemctl enable coturn > /dev/null 2>&1

# Vérifier les ports
info "Vérification des ports..."
sleep 1

if netstat -tuln | grep -q ":3478"; then
    info "Port 3478 (STUN/TURN) ouvert ✓"
else
    warning "Port 3478 non détecté. Vérifiez la configuration."
fi

if netstat -tuln | grep -q ":5349"; then
    info "Port 5349 (TURNS) ouvert ✓"
else
    warning "Port 5349 non détecté (TLS non configuré, normal)"
fi

echo ""
echo "=========================================="
echo "   Installation terminée avec succès!"
echo "=========================================="
echo ""
info "Configuration Coturn mise à jour ✓"
info "Service Coturn démarré ✓"
echo ""
echo "Prochaines étapes:"
echo "  1. Redéployer l'application backend Java (credentials TTL augmenté)"
echo "  2. Redéployer l'application Flutter (Trickle ICE activé)"
echo "  3. Tester un appel audio/vidéo"
echo ""
echo "Commandes utiles:"
echo "  - Logs temps réel:  sudo tail -f /var/log/turnserver/turnserver.log"
echo "  - Statut Coturn:    sudo systemctl status coturn"
echo "  - Redémarrer:       sudo systemctl restart coturn"
echo ""
warning "N'oubliez pas de vérifier que les ports sont ouverts dans le firewall OVH:"
echo "  - 3478 (UDP/TCP)"
echo "  - 5349 (TCP)"
echo "  - 49152-65535 (UDP/TCP)"
echo ""
info "Guide complet: SOLUTION_APPELS_WEBRTC.md"
echo ""
