#!/bin/bash

# Script d'installation sécurisée de SeedballPlantation.com
# Architecture: Nginx reverse proxy + CouchDB + Let's Encrypt SSL
# Usage: ./setup-nginx.sh

set -e  # Arrêter si erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   Installation SeedballPlantation.com (Sécurisée)     ║"
echo "║   Architecture: Nginx + CouchDB + Let's Encrypt        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==========================================
# VÉRIFICATIONS PRÉLIMINAIRES
# ==========================================

echo -e "${BLUE}[1/10] Vérifications préliminaires...${NC}"

# Vérifier si root ou sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Erreur: Ce script doit être exécuté avec sudo${NC}"
    echo "Usage: sudo ./setup-nginx.sh"
    exit 1
fi

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé!${NC}"
    echo "Installation de Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo -e "${GREEN}✓ Docker installé${NC}"
else
    echo -e "${GREEN}✓ Docker déjà installé${NC}"
fi

# Vérifier Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose n'est pas disponible!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Docker Compose disponible${NC}"
fi

# ==========================================
# CONFIGURATION INTERACTIVE
# ==========================================

echo ""
echo -e "${BLUE}[2/10] Configuration...${NC}"

# Demander le domaine
read -p "Nom de domaine pour CouchDB (ex: db.seedballplantation.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Erreur: Le domaine est obligatoire${NC}"
    exit 1
fi

# Demander l'email pour Let's Encrypt
read -p "Email pour Let's Encrypt (notifications SSL): " EMAIL
if [ -z "$EMAIL" ]; then
    echo -e "${RED}Erreur: L'email est obligatoire${NC}"
    exit 1
fi

# Générer ou demander le mot de passe
echo ""
echo -e "${YELLOW}Mot de passe CouchDB:${NC}"
echo "1) Générer automatiquement (recommandé)"
echo "2) Saisir manuellement"
read -p "Choix [1]: " PASSWORD_CHOICE
PASSWORD_CHOICE=${PASSWORD_CHOICE:-1}

if [ "$PASSWORD_CHOICE" = "1" ]; then
    # Vérifier si pwgen est installé
    if command -v pwgen &> /dev/null; then
        COUCHDB_PASSWORD=$(pwgen -s 32 1)
    else
        # Générer avec openssl si pwgen absent
        COUCHDB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    fi
    echo -e "${GREEN}✓ Mot de passe généré: ${COUCHDB_PASSWORD}${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANT: Sauvegarder ce mot de passe dans un endroit sûr!${NC}"
    read -p "Appuyer sur Entrée pour continuer..."
else
    read -sp "Mot de passe CouchDB (minimum 20 caractères): " COUCHDB_PASSWORD
    echo ""
    if [ ${#COUCHDB_PASSWORD} -lt 20 ]; then
        echo -e "${RED}Erreur: Le mot de passe doit faire au moins 20 caractères${NC}"
        exit 1
    fi
fi

# ==========================================
# CRÉATION DE LA STRUCTURE
# ==========================================

echo ""
echo -e "${BLUE}[3/10] Création de la structure de fichiers...${NC}"

# Créer les dossiers
mkdir -p ~/seedballplantation/nginx
mkdir -p ~/seedballplantation/certbot/conf
mkdir -p ~/seedballplantation/certbot/www
mkdir -p ~/seedballplantation/backup

cd ~/seedballplantation

echo -e "${GREEN}✓ Structure créée dans ~/seedballplantation${NC}"

# ==========================================
# CRÉATION DU FICHIER .env
# ==========================================

echo ""
echo -e "${BLUE}[4/10] Création du fichier .env...${NC}"

cat > .env << EOF
# Configuration CouchDB
# ⚠️ NE JAMAIS COMMITER CE FICHIER DANS GIT

COUCHDB_USER=admin
COUCHDB_PASSWORD=${COUCHDB_PASSWORD}

# Généré le: $(date)
EOF

chmod 600 .env
echo -e "${GREEN}✓ Fichier .env créé et sécurisé (chmod 600)${NC}"

# ==========================================
# COPIE DES FICHIERS DE CONFIGURATION
# ==========================================

echo ""
echo -e "${BLUE}[5/10] Copie des fichiers de configuration...${NC}"

# Vérifier si les fichiers existent dans le répertoire courant
if [ ! -f "docker-compose-secure.yml" ] || [ ! -f "nginx.conf" ]; then
    echo -e "${YELLOW}⚠️  Fichiers de configuration non trouvés dans le répertoire courant${NC}"
    echo "Assurez-vous que docker-compose-secure.yml et nginx.conf sont présents"
    echo "Ou copiez-les depuis /mnt/user-data/outputs/"
    exit 1
fi

# Copier docker-compose
cp docker-compose-secure.yml docker-compose.yml
echo -e "${GREEN}✓ docker-compose.yml copié${NC}"

# Copier nginx.conf et remplacer le domaine
sed "s/db\.seedballplantation\.com/$DOMAIN/g" nginx.conf > nginx/nginx.conf
echo -e "${GREEN}✓ nginx.conf configuré avec le domaine $DOMAIN${NC}"

# ==========================================
# CONFIGURATION DU FIREWALL
# ==========================================

echo ""
echo -e "${BLUE}[6/10] Configuration du firewall UFW...${NC}"

# Installer UFW si nécessaire
if ! command -v ufw &> /dev/null; then
    apt-get update
    apt-get install -y ufw
fi

# Configuration UFW
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable

echo -e "${GREEN}✓ Firewall configuré (ports 22, 80, 443 ouverts)${NC}"

# ==========================================
# DÉMARRAGE DES CONTAINERS
# ==========================================

echo ""
echo -e "${BLUE}[7/10] Démarrage des containers Docker...${NC}"

docker compose up -d

echo "Attente du démarrage de CouchDB (30 secondes)..."
sleep 30

# Vérifier que CouchDB répond
if docker compose exec couchdb curl -f http://localhost:5984/_up &> /dev/null; then
    echo -e "${GREEN}✓ CouchDB démarré et fonctionnel${NC}"
else
    echo -e "${RED}Erreur: CouchDB ne répond pas${NC}"
    docker compose logs couchdb
    exit 1
fi

# ==========================================
# CONFIGURATION SSL (LET'S ENCRYPT)
# ==========================================

echo ""
echo -e "${BLUE}[8/10] Configuration SSL Let's Encrypt...${NC}"

# Obtenir le certificat SSL
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    -d "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --non-interactive

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Certificat SSL obtenu pour $DOMAIN${NC}"
    
    # Redémarrer Nginx pour charger le certificat
    docker compose restart nginx
    sleep 5
    
    echo -e "${GREEN}✓ Nginx redémarré avec SSL${NC}"
else
    echo -e "${RED}Erreur lors de l'obtention du certificat SSL${NC}"
    echo "Vérifiez que:"
    echo "  1. Le domaine $DOMAIN pointe vers ce serveur"
    echo "  2. Les ports 80 et 443 sont accessibles"
    exit 1
fi

# ==========================================
# CRÉATION DE LA BASE DE DONNÉES
# ==========================================

echo ""
echo -e "${BLUE}[9/10] Création de la base de données 'seedballs'...${NC}"

# Attendre quelques secondes
sleep 5

# Créer la base
docker compose exec -T couchdb curl -X PUT \
    "http://admin:${COUCHDB_PASSWORD}@localhost:5984/seedballs"

echo -e "${GREEN}✓ Base de données 'seedballs' créée${NC}"

# ==========================================
# TESTS FINAUX
# ==========================================

echo ""
echo -e "${BLUE}[10/10] Tests finaux...${NC}"

# Test 1: Vérifier que CouchDB n'est pas accessible directement
echo -n "Test 1: CouchDB isolé... "
if timeout 2 bash -c "curl -f http://localhost:5984" &> /dev/null; then
    echo -e "${RED}ÉCHEC (CouchDB accessible directement)${NC}"
else
    echo -e "${GREEN}OK${NC}"
fi

# Test 2: Vérifier Nginx HTTPS
echo -n "Test 2: Nginx HTTPS... "
if curl -f -k "https://localhost/health" &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}ÉCHEC${NC}"
fi

# Test 3: Vérifier l'API via Nginx
echo -n "Test 3: API CouchDB via Nginx... "
if curl -f -k "https://localhost/seedballs" &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}ÉCHEC${NC}"
fi

# ==========================================
# SCRIPT DE BACKUP
# ==========================================

echo ""
echo -e "${BLUE}Création du script de backup automatique...${NC}"

cat > ~/seedballplantation/backup/backup-couchdb.sh << 'BACKUP_SCRIPT'
#!/bin/bash

# Script de backup automatique CouchDB
# À exécuter quotidiennement via cron

set -e

# Configuration
BACKUP_DIR="/root/seedballplantation/backup"
DATE=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS=30

# Charger les variables d'environnement
cd /root/seedballplantation
source .env

# Créer le backup
echo "Backup en cours..."
docker compose exec -T couchdb curl -s \
    "http://admin:${COUCHDB_PASSWORD}@localhost:5984/seedballs/_all_docs?include_docs=true" \
    > "${BACKUP_DIR}/seedballs-${DATE}.json"

# Compresser
gzip "${BACKUP_DIR}/seedballs-${DATE}.json"

# Supprimer les backups > 30 jours
find "${BACKUP_DIR}" -name "seedballs-*.json.gz" -mtime +${RETENTION_DAYS} -delete

echo "✓ Backup terminé: seedballs-${DATE}.json.gz"
echo "Taille: $(du -h ${BACKUP_DIR}/seedballs-${DATE}.json.gz | cut -f1)"
BACKUP_SCRIPT

chmod +x ~/seedballplantation/backup/backup-couchdb.sh

# Ajouter au crontab
(crontab -l 2>/dev/null; echo "0 3 * * * /root/seedballplantation/backup/backup-couchdb.sh >> /root/seedballplantation/backup/backup.log 2>&1") | crontab -

echo -e "${GREEN}✓ Script de backup créé (s'exécutera tous les jours à 3h)${NC}"

# ==========================================
# RÉSUMÉ FINAL
# ==========================================

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║          INSTALLATION TERMINÉE AVEC SUCCÈS!            ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}📋 INFORMATIONS IMPORTANTES:${NC}"
echo ""
echo -e "Domaine:              ${GREEN}$DOMAIN${NC}"
echo -e "CouchDB User:         ${GREEN}admin${NC}"
echo -e "CouchDB Password:     ${GREEN}$COUCHDB_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}⚠️  SAUVEGARDER CES INFORMATIONS DANS UN ENDROIT SÛR!${NC}"
echo ""
echo -e "${BLUE}📡 URLS:${NC}"
echo -e "  API CouchDB:        https://$DOMAIN/seedballs"
echo -e "  Session:            https://$DOMAIN/_session"
echo -e "  Health check:       https://$DOMAIN/health"
echo ""
echo -e "${BLUE}🔧 COMMANDES UTILES:${NC}"
echo -e "  Voir les logs:      ${GREEN}cd ~/seedballplantation && docker compose logs -f${NC}"
echo -e "  Redémarrer:         ${GREEN}docker compose restart${NC}"
echo -e "  Arrêter:            ${GREEN}docker compose down${NC}"
echo -e "  Backup manuel:      ${GREEN}~/seedballplantation/backup/backup-couchdb.sh${NC}"
echo ""
echo -e "${BLUE}📝 PROCHAINES ÉTAPES:${NC}"
echo "  1. Configurer le DNS: $DOMAIN → $(curl -s ifconfig.me)"
echo "  2. Mettre à jour .htaccess sur WHC.ca"
echo "  3. Tester l'API depuis seedballplantation.com"
echo "  4. Configurer l'authentification CouchDB"
echo ""
echo -e "${GREEN}Installation réussie! 🎉${NC}"
echo ""
