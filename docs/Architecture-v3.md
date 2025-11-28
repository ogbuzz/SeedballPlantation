# Documentation Technique Complète - Version 3.0

## 1. Vue d'ensemble du projet
SeedballPlantation.com est un wiki collaboratif open source pour le partage de connaissances sur les recettes de seedballs. Architecture hybride sécurisée optimisée : pages web hébergées sur WHC.ca (LiteSpeed), base de données CouchDB isolée sur VPS dédié avec reverse proxy Nginx pour un usage offline-first avec synchronisation cloud.

### 1.1 Objectifs du projet
- Permettre aux contributeurs de partager leurs recettes de seedballs de manière collaborative
- Fonctionnement offline-first pour usage sur le terrain sans connexion Internet
- Synchronisation automatique bidirectionnelle avec base de données centrale
- Architecture hybride économique utilisant l'hébergement WHC.ca existant
- Sécurité production-ready avec isolation complète et chiffrement SSL/TLS
- PWA (Progressive Web App) installable sur mobile pour usage terrain
- Coût opérationnel minimal (6.22 CAD$/mois) pour maximiser l'accessibilité

### 1.2 Caractéristiques techniques
[Colle ici le tableau de ta doc v3, ligne par ligne – ex. Composant | Description]

## 2. Architecture technique
### 2.1 Schéma d'architecture hybride sécurisée
[Colle le schéma ASCII de ta doc v3 verbatim]

[Continue avec tout le reste de ton DOCX : 2.2 Flux de données, 2.3 Structure des fichiers, 3. Configuration (docker-compose.yml, .env, nginx.conf, .htaccess), etc., jusqu'à la fin – c'est ~18 pages, mais GitHub gère les longs fichiers.]

## Annexe : Scaling (de Scaling.pdf)
### Capacité réelle du VPS CX11 (2 GB RAM)
[Colle le tableau des scénarios : Lecture simple 200-300, etc.]

### Facteurs limitants sur CX11
- 🔴 1 seul vCPU - Le plus limitant
- 🟡 2 GB RAM - Suffisant si documents légers
- 🟢 20 GB SSD - Largement suffisant pour DB

### Niveau 1: Optimisations gratuites (0-200 utilisateurs)
[Colle le docker-compose.yml optimisé de Scaling.pdf]

### Fichier local.ini (optimisations)
[Colle le contenu local.ini]

Gains attendus: +30% capacité

### Niveau 2: Upgrade VPS vertical (200-500 utilisateurs)
Option A: CX21 - 11.70 CAD$/mois
- 2 vCPU ← Double la capacité!
- 4 GB RAM
- 40 GB SSD
- Capacité: 300-500 utilisateurs simultanés

[Colle le reste : Migration, Niveau 3 Réplicas, Niveau 4 Clustering, Monitoring, Recommandations par phase, Ma recommandation]

Fin du document.
