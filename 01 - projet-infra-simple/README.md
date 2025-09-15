# Projet Infrastructure Simple avec Vagrant

Ce projet configure automatiquement deux machines virtuelles avec Vagrant :
- **Web Server** : Ubuntu 22.04 avec Nginx
- **Database Server** : CentOS 9 avec MySQL 8.0

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Web Server    │    │  Database Server│
│   Ubuntu 22.04  │    │   CentOS 9      │
│  192.168.56.10  │◄──►│  192.168.56.20  │
│     Nginx       │    │    MySQL 8.0    │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┘
              192.168.56.0/24
                (Réseau Privé)
```

## Structure du Projet

```
projet-infra-simple/
├── Vagrantfile
├── scripts/
│   ├── provision-web-ubuntu.sh
│   └── provision-db-centos.sh
├── website/
│   └── (contenu du repository GitHub cloné)
├── database/
│   ├── create-table.sql
│   └── insert-demo-data.sql
└── README.md
```

## Prérequis

- Windows avec Vagrant et VirtualBox installés ✅
- Au moins 4GB de RAM libre (1GB par VM)
- Connexion Internet pour télécharger les boxes et cloner le repo

## Installation et Utilisation

### 1. Créer la Structure des Dossiers

```bash
mkdir scripts database
```

### 2. Lancer les Machines Virtuelles

```bash
# Lancer toutes les VMs
vagrant up

# Ou lancer individuellement
vagrant up web-server
vagrant up db-server
```

### 3. Vérifier l'Installation

**Web Server :**
- Site web : `http://192.168.56.10`
- SSH : `vagrant ssh web-server`

**Database Server :**
- Depuis la machine hôte : `mysql -h localhost -P 3307 -u demo_user -p demo_db`
- SSH : `vagrant ssh db-server`

## Configuration des Services

### Web Server (Ubuntu)

- **OS** : Ubuntu 22.04 LTS
- **RAM** : 1024 MB
- **CPU** : 1 vCPU  
- **IP Privée** : 192.168.56.10
- **Services** : Nginx
- **Contenu** : Site web cloné depuis GitHub (Sprint-2)
- **Sync Folder** : `./website/` ↔ `/var/www/html/`
- **Sécurité** : Utilisateur `web-admin` avec sudo

### Database Server (CentOS)

- **OS** : CentOS 9 Stream
- **RAM** : 1024 MB
- **CPU** : 1 vCPU
- **IP Privée** : 192.168.56.20
- **Services** : MySQL 8.0
- **Port Forward** : 3306 → 3307 (localhost)
- **Base de données** : `demo_db`
- **Table** : `users` créée via scripts SQL séparés
- **Sécurité** : Utilisateur `vagrant-admin` avec sudo

## Informations de Connexion

### Base de Données

- **Host** : localhost (depuis Windows)
- **Port** : 3307
- **Database** : demo_db
- **Username** : demo_user
- **Password** : DemoPassword123!
- **Root Access** : `mysql -u root` (pas de mot de passe)

### Connexion MySQL depuis Windows

```bash
mysql -h localhost -P 3307 -u demo_user -p demo_db
```

## Commandes Vagrant Utiles

```bash
# État des VMs
vagrant status

# Redémarrer une VM
vagrant reload web-server

# Reprovisioner (réexécuter les scripts)
vagrant provision db-server

# Arrêter les VMs
vagrant halt

# Supprimer les VMs
vagrant destroy

# Se connecter en SSH
vagrant ssh web-server
vagrant ssh db-server
```

## Test de Connectivité

### Depuis le Web Server vers la Base de Données

```bash
vagrant ssh web-server
ping 192.168.56.20
```

### Depuis Windows vers les deux Serveurs

```bash
# Test Web Server
ping 192.168.56.10
curl http://192.168.56.10

# Test Database Server
ping 192.168.56.20
mysql -h localhost -P 3307 -u demo_user -p demo_db -e "SELECT COUNT(*) FROM users;"
```

## Structure de la Base de Données

```sql
Table: users
├── id (INT, AUTO_INCREMENT, PRIMARY KEY)
├── nom (VARCHAR(100), NOT NULL)
├── email (VARCHAR(150), UNIQUE, NOT NULL)
└── date_creation (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
```

## Dépannage

### Problèmes Courants

1. **Erreur de port** : Vérifier que le port 3307 n'est pas utilisé
2. **Problème de réseau** : Redémarrer VirtualBox
3. **VM ne démarre pas** : Vérifier la RAM disponible

### Logs Utiles

```bash
# Logs Vagrant
vagrant up --debug

# Logs dans les VMs
vagrant ssh web-server -c "sudo journalctl -u nginx"
vagrant ssh db-server -c "sudo journalctl -u mysqld"
```

## Personnalisation

- Modifier `scripts/provision-web-ubuntu.sh` pour personnaliser le web server
- Modifier `scripts/provision-db-centos.sh` pour personnaliser la base de données  
- Ajouter des fichiers dans `database/` pour des scripts SQL personnalisés