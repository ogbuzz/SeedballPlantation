# Guide d'installation sécurisée - SeedballPlantation.com
## Architecture Nginx + CouchDB + Let's Encrypt

---

## 📋 Vue d'ensemble

Ce guide installe une architecture **sécurisée** pour SeedballPlantation.com avec:
- ✅ Nginx comme reverse proxy (sécurité)
- ✅ CouchDB isolé (pas d'accès direct Internet)
- ✅ SSL/TLS automatique (Let's Encrypt)
- ✅ Rate limiting (anti-DDoS)
- ✅ CORS restrictif
- ✅ Backups automatiques quotidiens

**Temps d'installation:** 30-45 minutes  
**Niveau requis:** Intermédiaire (tu sais utiliser SSH et éditer des fichiers)

---

## 🎯 Prérequis

### Sur ton ordinateur local:
- [ ] Tous les fichiers téléchargés depuis Claude:
  - `docker-compose-secure.yml`
  - `nginx.conf`
  - `.env.example`
  - `setup-nginx.sh`
  - Ce guide (`GUIDE-INSTALLATION.md`)

### Sur le VPS Hetzner:
- [ ] VPS CX11 loué et démarré
- [ ] Ubuntu 24.04 installé
- [ ] Accès SSH fonctionnel
- [ ] Adresse IP publique notée

### DNS:
- [ ] Domaine ou sous-domaine disponible (ex: `db.seedballplantation.com`)
- [ ] Accès au panneau de configuration DNS

---

## 🚀 Étape 1: Préparer le DNS

### Créer l'enregistrement DNS

**Dans ton panneau DNS (ex: Cloudflare, Namecheap, etc.):**

```
Type: A
Nom: db
Valeur: [IP-DU-VPS]
TTL: 300 (5 minutes)
```

**Résultat:** `db.seedballplantation.com` pointe vers ton VPS

### Vérifier la propagation DNS

```bash
# Sur ton ordinateur local
nslookup db.seedballplantation.com

# OU
dig db.seedballplantation.com +short
```

**Attendre que ça retourne l'IP de ton VPS avant de continuer.**

---

## 🚀 Étape 2: Connexion au VPS

### Se connecter en SSH

```bash
# Remplace IP-VPS par l'IP réelle
ssh root@IP-VPS
```

**Si première connexion:**
- Taper `yes` pour accepter la clé SSH
- Entrer le mot de passe root (reçu par email de Hetzner)

### Mettre à jour le système

```bash
apt update
apt upgrade -y
```

---

## 🚀 Étape 3: Transférer les fichiers de configuration

### Option A: Avec SCP (recommandé)

**Sur ton ordinateur local** (dans le dossier où sont les fichiers):

```bash
# Créer un dossier temporaire sur le VPS
ssh root@IP-VPS "mkdir -p /tmp/seedball-config"

# Transférer tous les fichiers
scp docker-compose-secure.yml root@IP-VPS:/tmp/seedball-config/
scp nginx.conf root@IP-VPS:/tmp/seedball-config/
scp .env.example root@IP-VPS:/tmp/seedball-config/
scp setup-nginx.sh root@IP-VPS:/tmp/seedball-config/
```

### Option B: Avec copy-paste manuel

**Sur le VPS:**

```bash
mkdir -p /tmp/seedball-config
cd /tmp/seedball-config

# Créer chaque fichier avec nano
nano docker-compose-secure.yml
# Coller le contenu, puis Ctrl+X, Y, Enter

nano nginx.conf
# Coller le contenu, puis Ctrl+X, Y, Enter

nano .env.example
# Coller le contenu, puis Ctrl+X, Y, Enter

nano setup-nginx.sh
# Coller le contenu, puis Ctrl+X, Y, Enter
```

---

## 🚀 Étape 4: Rendre le script exécutable

```bash
cd /tmp/seedball-config
chmod +x setup-nginx.sh
```

---

## 🚀 Étape 5: Exécuter le script d'installation

### Lancer l'installation automatique

```bash
sudo ./setup-nginx.sh
```

### Le script va te demander:

**1. Nom de domaine:**
```
Nom de domaine pour CouchDB (ex: db.seedballplantation.com): 
```
→ Taper: `db.seedballplantation.com` (ton vrai domaine)

**2. Email pour Let's Encrypt:**
```
Email pour Let's Encrypt (notifications SSL): 
```
→ Taper ton email (pour renouvellement SSL)

**3. Mot de passe CouchDB:**
```
1) Générer automatiquement (recommandé)
2) Saisir manuellement
Choix [1]: 
```
→ Taper: `1` (recommandé - génère un mot de passe ultra sécurisé)

**⚠️ IMPORTANT:** Le script affichera le mot de passe généré.  
**COPIE-LE IMMÉDIATEMENT** dans un gestionnaire de mots de passe!

### Le script va:

1. ✅ Vérifier Docker (installer si nécessaire)
2. ✅ Créer la structure de fichiers
3. ✅ Configurer le firewall UFW
4. ✅ Démarrer CouchDB et Nginx
5. ✅ Obtenir le certificat SSL
6. ✅ Créer la base de données `seedballs`
7. ✅ Configurer les backups automatiques
8. ✅ Tester l'installation

**Durée:** ~10-15 minutes

---

## 🚀 Étape 6: Noter les informations importantes

### À la fin, le script affiche:

```
╔════════════════════════════════════════════════════════╗
║          INSTALLATION TERMINÉE AVEC SUCCÈS!            ║
╚════════════════════════════════════════════════════════╝

📋 INFORMATIONS IMPORTANTES:

Domaine:              db.seedballplantation.com
CouchDB User:         admin
CouchDB Password:     Kx9mP2nQ7vB4wL8fR5tY1jH6cZ3dN0sA

⚠️  SAUVEGARDER CES INFORMATIONS DANS UN ENDROIT SÛR!
```

**🔐 SAUVEGARDER:**
- Le domaine
- Le user (admin)
- Le mot de passe
- L'IP du VPS

**Où sauvegarder:** 
- Gestionnaire de mots de passe (1Password, Bitwarden, etc.)
- Fichier crypté local
- **JAMAIS dans Git ou email non chiffré!**

---

## 🚀 Étape 7: Tester l'installation

### Test 1: Vérifier que CouchDB répond via Nginx

```bash
# Sur le VPS
curl https://db.seedballplantation.com/seedballs
```

**Réponse attendue:**
```json
{"db_name":"seedballs","update_seq":"0-g1A...","sizes":{"file":8440,...},...}
```

### Test 2: Vérifier l'isolation de CouchDB

```bash
# Sur le VPS - ceci doit ÉCHOUER
curl http://localhost:5984
```

**Résultat attendu:**
```
curl: (7) Failed to connect to localhost port 5984 after 0 ms: Connection refused
```

✅ **C'est NORMAL!** CouchDB n'est accessible que via Nginx.

### Test 3: Tester depuis Internet

**Sur ton ordinateur local:**

```bash
curl https://db.seedballplantation.com/health
```

**Réponse attendue:**
```
healthy
```

---

## 🚀 Étape 8: Configurer WHC.ca

### Modifier le fichier .htaccess

**Se connecter au cPanel WHC.ca:**

1. Aller dans **File Manager**
2. Naviguer vers `/public_html/`
3. Éditer (ou créer) `.htaccess`

**Ajouter cette configuration:**

```apache
# Proxy vers CouchDB sécurisé sur VPS
<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Proxy vers Nginx sur VPS (HTTPS)
    RewriteCond %{REQUEST_URI} ^/seedballs
    RewriteRule ^(.*)$ https://db.seedballplantation.com/$1 [P,L]
    
    RewriteCond %{REQUEST_URI} ^/_session
    RewriteRule ^(.*)$ https://db.seedballplantation.com/$1 [P,L]
</IfModule>

# Note: Plus besoin de headers CORS ici - géré par Nginx
```

**Sauvegarder le fichier.**

---

## 🚀 Étape 9: Tester l'intégration complète

### Test depuis ton site

**Ouvre:** `https://seedballplantation.com/test-api.html`

**Créer ce fichier de test sur WHC.ca:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Test API CouchDB</title>
</head>
<body>
    <h1>Test API CouchDB</h1>
    <button onclick="testAPI()">Tester la connexion</button>
    <pre id="result"></pre>

    <script src="https://cdn.jsdelivr.net/npm/pouchdb@8.0.1/dist/pouchdb.min.js"></script>
    <script>
        async function testAPI() {
            const result = document.getElementById('result');
            result.textContent = 'Test en cours...\n';

            try {
                // Test 1: Accès direct API
                result.textContent += '\n1. Test API REST...\n';
                const response = await fetch('/seedballs');
                const data = await response.json();
                result.textContent += '✅ API accessible: ' + data.db_name + '\n';

                // Test 2: PouchDB sync
                result.textContent += '\n2. Test PouchDB...\n';
                const db = new PouchDB('/seedballs');
                const info = await db.info();
                result.textContent += '✅ PouchDB connecté: ' + info.doc_count + ' documents\n';

                // Test 3: Écriture
                result.textContent += '\n3. Test écriture...\n';
                const doc = await db.put({
                    _id: 'test-' + Date.now(),
                    type: 'test',
                    message: 'Hello from WHC.ca!'
                });
                result.textContent += '✅ Document créé: ' + doc.id + '\n';

                result.textContent += '\n🎉 TOUS LES TESTS RÉUSSIS!\n';
            } catch (error) {
                result.textContent += '\n❌ ERREUR: ' + error.message + '\n';
                console.error(error);
            }
        }
    </script>
</body>
</html>
```

**Tester dans le navigateur:**
1. Aller sur `https://seedballplantation.com/test-api.html`
2. Cliquer "Tester la connexion"
3. Vérifier que tous les tests passent ✅

---

## 🚀 Étape 10: Configuration finale de sécurité

### Activer l'authentification CouchDB

**Sur le VPS:**

```bash
cd ~/seedballplantation

# Créer un utilisateur pour l'application web
docker compose exec couchdb curl -X PUT \
  "http://admin:TON_MOT_DE_PASSE@localhost:5984/_users/org.couchdb.user:webapp" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "webapp",
    "password": "autre_mot_de_passe_securise",
    "roles": ["contributor"],
    "type": "user"
  }'
```

**Résultat:**
```json
{"ok":true,"id":"org.couchdb.user:webapp","rev":"1-xxx"}
```

### Configurer les permissions de la base

```bash
# Seuls les admins peuvent modifier les permissions
docker compose exec couchdb curl -X PUT \
  "http://admin:TON_MOT_DE_PASSE@localhost:5984/seedballs/_security" \
  -H "Content-Type: application/json" \
  -d '{
    "admins": {
      "names": ["admin"],
      "roles": []
    },
    "members": {
      "names": [],
      "roles": ["contributor"]
    }
  }'
```

**Maintenant:** 
- Seul l'admin peut tout faire
- Les utilisateurs avec rôle "contributor" peuvent lire/écrire

---

## 📊 Vérifications finales

### Checklist de sécurité

- [ ] Port 5984 **non accessible** directement (test: `curl http://IP-VPS:5984`)
- [ ] HTTPS fonctionne (`https://db.seedballplantation.com/health`)
- [ ] API accessible via WHC.ca (`https://seedballplantation.com/seedballs`)
- [ ] PouchDB sync fonctionne
- [ ] Certificat SSL valide (cadenas vert dans le navigateur)
- [ ] Backups configurés (vérifier: `ls ~/seedballplantation/backup/`)
- [ ] Mot de passe CouchDB sauvegardé en lieu sûr
- [ ] Firewall actif (`sudo ufw status`)

### Vérifier les logs

```bash
# Logs Nginx
docker compose logs nginx

# Logs CouchDB
docker compose logs couchdb

# Logs en temps réel
docker compose logs -f
```

---

## 🛠️ Commandes de maintenance

### Redémarrer les services

```bash
cd ~/seedballplantation
docker compose restart
```

### Voir le statut

```bash
docker compose ps
```

### Backup manuel

```bash
~/seedballplantation/backup/backup-couchdb.sh
```

### Voir les backups

```bash
ls -lh ~/seedballplantation/backup/
```

### Restaurer un backup

```bash
# Décompresser
gunzip ~/seedballplantation/backup/seedballs-20251126.json.gz

# Restaurer (attention: écrase les données actuelles!)
cat ~/seedballplantation/backup/seedballs-20251126.json | \
  docker compose exec -T couchdb curl -X POST \
  "http://admin:TON_MOT_DE_PASSE@localhost:5984/seedballs/_bulk_docs" \
  -H "Content-Type: application/json" \
  -d @-
```

### Renouveler SSL manuellement

```bash
docker compose run --rm certbot renew
docker compose restart nginx
```

---

## ❓ Dépannage

### Problème: "Connection refused" depuis WHC.ca

**Causes possibles:**
1. DNS pas propagé → Attendre 5-15 minutes
2. Firewall bloque → `sudo ufw status`
3. Nginx pas démarré → `docker compose ps`
4. Certificat SSL manquant → `ls ~/seedballplantation/certbot/conf/live/`

**Solution:**
```bash
# Vérifier les logs
docker compose logs nginx

# Redémarrer Nginx
docker compose restart nginx
```

### Problème: Erreur SSL/TLS

**Solution:**
```bash
# Vérifier le certificat
docker compose exec nginx ls -la /etc/letsencrypt/live/

# Si absent, obtenir nouveau certificat
docker compose run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  -d db.seedballplantation.com
```

### Problème: CORS errors dans le navigateur

**Vérifier la config Nginx:**
```bash
cd ~/seedballplantation
nano nginx/nginx.conf

# Vérifier la ligne:
# set $cors_origin "";
# if ($http_origin ~* "^https://(www\.)?seedballplantation\.com$") {

# Redémarrer si modifié
docker compose restart nginx
```

### Problème: "429 Too Many Requests"

C'est le rate limiting (normal). Attendre quelques secondes.

**Pour augmenter les limites:**
```bash
nano nginx/nginx.conf

# Modifier:
# limit_req_zone $binary_remote_addr zone=api:10m rate=20r/s;

docker compose restart nginx
```

---

## 📞 Support

**En cas de problème:**

1. Vérifier les logs: `docker compose logs`
2. Vérifier le firewall: `sudo ufw status`
3. Tester DNS: `nslookup db.seedballplantation.com`
4. Tester SSL: `curl -v https://db.seedballplantation.com/health`

**Logs utiles:**
```bash
# Tout
docker compose logs

# Dernières 50 lignes
docker compose logs --tail=50

# Temps réel
docker compose logs -f
```

---

## ✅ Installation terminée!

Tu as maintenant une architecture **sécurisée** et **professionnelle**:

- ✅ CouchDB isolé (pas d'accès Internet direct)
- ✅ Nginx reverse proxy avec SSL
- ✅ Rate limiting anti-DDoS
- ✅ CORS restrictif
- ✅ Backups automatiques quotidiens
- ✅ Monitoring via logs

**Coût total:** 6.22 CAD$/mois  
**Niveau de sécurité:** Production-ready 🔒

**Prochaines étapes:**
1. Uploader tes pages HTML sur WHC.ca
2. Tester les formulaires de contribution
3. Inviter des beta-testeurs
4. Monitorer les logs pendant quelques jours

**Félicitations! 🎉**
