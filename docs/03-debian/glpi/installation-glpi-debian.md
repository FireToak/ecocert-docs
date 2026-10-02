---
description: Rapport d'Ingénierie et Installation du Serveur GLPI 11 (Refonte CLI, ANSSI, Ségrégation) sur Debian 13.
tags:
  - GLPI
  - Debian
  - Sécurité
  - Installation
---

# Rapport d'Ingénierie et Installation du Serveur GLPI 11

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Méta-informations"

    - **Auteur(s) :** KADA Amine
    - **Date :** 23/09/2026
    - **Domaine :** Debian 13

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Préparation du système (Debian 13)](#3-preparation-du-systeme-debian-13)
- [4. Installation des prérequis (Serveur Web et Base de données)](#4-installation-des-prerequis-serveur-web-et-base-de-donnees)
- [5. Sécurisation de la base de données et de PHP](#5-securisation-de-la-base-de-donnees-et-de-php)
- [6. Création de la base de données GLPI](#6-creation-de-la-base-de-donnees-glpi)
- [7. Installation de GLPI et externalisation des données](#7-installation-de-glpi-et-externalisation-des-donnees)
- [8. Configuration du site web (VirtualHost Apache)](#8-configuration-du-site-web-virtualhost-apache)
- [9. Installation finale en ligne de commande (CLI)](#9-installation-finale-en-ligne-de-commande-cli)
- [10. Post-installation et Sécurités](#10-post-installation-et-securites)

## 2. Contexte

La **Mission 3** requiert l'installation en ligne de commande (CLI) du système de Helpdesk et d'inventaire GLPI (version 11). Ce déploiement s'effectue sur le nœud hyperviseur `pve2` (ID : 20805) via la machine virtuelle Debian 13 nommée **GLPIECOCERT** (IP : `172.16.54.40`, Passerelle : `172.16.54.253`). Cette documentation intègre toutes les bonnes pratiques de sécurité (PHP 8.4 FPM, sécurisation MariaDB, externalisation des dossiers sensibles et routage par Alias).

## 3. Préparation du système (Debian 13)

Avant d'installer GLPI, on met à jour le système pour avoir une base propre et sécurisée.

Mettez à jour les paquets :

```bash title="Terminal"
apt update && apt upgrade -y
```

L'option `-y` valide automatiquement les installations sans vous poser de questions.

## 4. Installation des prérequis (Serveur Web et Base de données)

GLPI a besoin d'un environnement classique : un serveur web (Apache), une base de données (MariaDB) et PHP.

### 4.1 Installation d'Apache et MariaDB

On installe Apache et MariaDB depuis les dépôts officiels.

```bash title="Terminal"
apt install apache2 mariadb-server -y
```

### 4.2 Ajout du dépôt pour PHP 8.4

GLPI 11 recommande d'utiliser PHP 8.4 pour de meilleures performances. On ajoute donc le dépôt officiel de Surý (le mainteneur PHP pour Debian).

```bash title="Terminal"
apt install -y apt-transport-https lsb-release ca-certificates curl
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
apt update
```

### 4.3 Installation de PHP et ses extensions

Pour des raisons de sécurité (recommandations ANSSI), on n'utilise plus le vieux module Apache (`mod_php`). On utilise **PHP-FPM** qui sépare l'exécution de PHP d'Apache.

```bash title="Terminal"
apt install -y php8.4 php8.4-fpm php8.4-mysql php8.4-xml php8.4-curl php8.4-gd php8.4-mbstring php8.4-intl php8.4-bz2 php8.4-zip php8.4-ldap php8.4-apcu
```

### 4.4 Configuration d'Apache

On active les modules Apache nécessaires pour faire le lien avec PHP et pour utiliser le HTTPS.

```bash title="Terminal"
a2enmod proxy_fcgi setenvif headers rewrite ssl
a2enconf php8.4-fpm
systemctl restart apache2
```

## 5. Sécurisation de la base de données et de PHP

### 5.1 Sécurisation de MariaDB et fuseaux horaires

Lancez ce script pour sécuriser la base de données (il supprime les accès anonymes et bloque le root à distance) :

```bash title="Terminal"
mysql_secure_installation
```

GLPI a besoin de connaître les fuseaux horaires mondiaux pour bien dater les tickets (SLA). On les importe avec cette commande :

```bash title="Terminal"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
```

### 5.2 Sécurisation de PHP (php.ini)

Éditez le fichier de configuration de PHP :

```bash title="Terminal"
nano /etc/php/8.4/fpm/php.ini
```

Voici les paramètres de sécurité à modifier. Remplacez les valeurs par défaut par celles-ci :

| Directive PHP (`php.ini`) | Valeur Cible | Raisonnement de Sécurité (ANSSI / CNIL) |
| :--- | :--- | :--- |
| `date.timezone` | `Europe/Paris` | Synchronise l'exécution PHP avec le fuseau horaire de l'infrastructure d'ECOCERT. |
| `expose_php` | `Off` | Supprime l'en-tête X-Powered-By: PHP/8.4, limitant la reconnaissance passive par les bots. |
| `session.cookie_secure` | `1` (ou `on`) | Interdit la transmission du cookie de session GLPI sur un réseau non chiffré (HTTP classique). |
| `session.cookie_httponly` | `1` (ou `on`) | Interdit au langage JavaScript exécuté côté client de lire le cookie de session (Protection XSS). |
| `session.cookie_samesite` | `Lax` (ou `Strict`) | Empêche l'envoi du cookie si la requête provient d'un domaine externe (Protection CSRF). |
| `disable_functions` | `exec,passthru,shell_exec...` | Désactive les primitives permettant à PHP d'interagir directement avec le shell système (Protection RCE). |

Appliquez les changements :

```bash title="Terminal"
systemctl restart php8.4-fpm
```

## 6. Création de la base de données GLPI

Pour la sécurité, GLPI ne doit pas utiliser l'utilisateur `root`. On lui crée un utilisateur dédié (`glpi_user`).

Connectez-vous à MariaDB :

```bash title="Terminal"
mysql -u root -p
```

Créez la base de données et l'utilisateur :

```sql title="MariaDB"
CREATE DATABASE glpi;
CREATE USER 'glpi_user'@'localhost' IDENTIFIED BY 'VotreMotDePasseIci';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi_user'@'localhost';
GRANT SELECT ON mysql.time_zone_name TO 'glpi_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Le droit `GRANT SELECT` sur la table `time_zone_name` permet à GLPI de gérer automatiquement les changements d'heure.

## 7. Installation de GLPI et externalisation des données

Par mesure de sécurité (recommandé par l'éditeur), on ne laisse plus les fichiers de données dans le dossier web `/var/www/html/`. On les déplace vers `/var/lib/` et `/etc/` pour empêcher les piratages.

### 7.1 Téléchargement de GLPI 11

```bash title="Terminal"
wget https://github.com/glpi-project/glpi/releases/download/11.0.11/glpi-11.0.11.tgz
tar -xzvf glpi-11.0.11.tgz -C /var/www/html/
```

### 7.2 Déplacement des dossiers sensibles

Créez les dossiers qui vont accueillir les données :

```bash title="Terminal"
mkdir -p /etc/glpi /var/lib/glpi/files /var/lib/glpi/plugins /var/log/glpi
```

Déplacez les configurations et les fichiers vers ces nouveaux dossiers sécurisés :

```bash title="Terminal"
mv /var/www/html/glpi/config/* /etc/glpi/
mv /var/www/html/glpi/files/* /var/lib/glpi/files/
```

### 7.3 Lien entre le code et les données

Il faut dire à GLPI où se trouvent ses fichiers de configuration. Créez ce fichier :

```bash title="Terminal"
nano /var/www/html/glpi/inc/downstream.php
```

```php title="/var/www/html/glpi/inc/downstream.php"
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
```

Créez ensuite le fichier de constantes pour lui dire où se trouvent les logs et les plugins :

```bash title="Terminal"
nano /etc/glpi/local_define.php
```

```php title="/etc/glpi/local_define.php"
<?php
// Définition du répertoire racine pour les données variables
define('GLPI_VAR_DIR', '/var/lib/glpi/files');

// Sous-déclinaisons
define('GLPI_DOC_DIR', GLPI_VAR_DIR);
define('GLPI_CRON_DIR', GLPI_VAR_DIR . '/_cron');
define('GLPI_DUMP_DIR', GLPI_VAR_DIR . '/_dumps');
define('GLPI_GRAPH_DIR', GLPI_VAR_DIR . '/_graphs');
define('GLPI_LOCK_DIR', GLPI_VAR_DIR . '/_lock');
define('GLPI_PICTURE_DIR', GLPI_VAR_DIR . '/_pictures');
define('GLPI_PLUGIN_DOC_DIR', GLPI_VAR_DIR . '/_plugins');
define('GLPI_RSS_DIR', GLPI_VAR_DIR . '/_rss');
define('GLPI_SESSION_DIR', GLPI_VAR_DIR . '/_sessions');
define('GLPI_TMP_DIR', GLPI_VAR_DIR . '/_tmp');
define('GLPI_UPLOAD_DIR', GLPI_VAR_DIR . '/_uploads');
define('GLPI_CACHE_DIR', GLPI_VAR_DIR . '/_cache');

// Externalisation des journaux
define('GLPI_LOG_DIR', '/var/log/glpi');

// Sécurisation critique des plugins
define('GLPI_MARKETPLACE_DIR', '/var/lib/glpi/plugins');
```

### 7.4 Droits d'accès

Donnez la propriété des dossiers à l'utilisateur du serveur web (`www-data`). Ne mettez jamais de chmod 777 !

```bash title="Terminal"
chown -R www-data:www-data /var/www/html/glpi /etc/glpi /var/lib/glpi /var/log/glpi
```

## 8. Configuration du site web (VirtualHost Apache)

On configure Apache pour pointer uniquement vers le sous-dossier `/public`. Les visiteurs ne peuvent donc pas accéder aux fichiers du moteur GLPI.

```bash title="Terminal"
nano /etc/apache2/sites-available/default-ssl.conf
```

```apache title="/etc/apache2/sites-available/default-ssl.conf"
# Cibler le Front Controller
DocumentRoot /var/www/html/glpi/public

# Définition des règles d'accès et de réécriture
<Directory /var/www/html/glpi/public>
    Require all granted
    
    # Activation du moteur de réécriture
    RewriteEngine On
    RewriteBase /
    
    # Sécurisation des en-têtes HTTP
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Autoriser la transmission des en-têtes d'API (Nécessaire pour l'agent GLPI)
    RewriteCond %{HTTP:Authorization} ^(.+)$
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    
    # Mécanisme de routage Front Controller (redirige tout trafic vers index.php)
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
</Directory>
```

```bash title="Terminal"
a2ensite default-ssl
systemctl restart apache2
```

## 9. Installation finale en ligne de commande (CLI)

Il est beaucoup plus sécurisé de lancer l'installation en ligne de commande plutôt que depuis le navigateur web (où quelqu'un d'autre pourrait s'y connecter avant vous).

### 9.1 Création des tables

Lancez l'installation de la base avec l'utilisateur `www-data` :

```bash title="Terminal"
cd /var/www/html/glpi
sudo -u www-data php bin/console db:install --db-host=localhost --db-name=glpi --db-user=glpi_user --db-password='VotreMotDePasseIci' --no-interaction
```

### 9.2 Sécurisation de la clé GLPI

On génère une clé de chiffrement forte pour protéger les mots de passe stockés dans GLPI :

```bash title="Terminal"
sudo -u www-data php bin/console glpi:security:change_key --no-interaction
```

### 9.3 Vérification finale

Lancer cette commande pour vérifier que l'environnement de GLPI est valide (s'il n'y a pas d'erreur rouge, c'est bon !) :

```bash title="Terminal"
sudo -u www-data php bin/console glpi:system:check_requirements
```

## 10. Post-installation et Sécurités

L'installation est terminée ! GLPI est accessible en HTTPS sur : [https://172.16.54.40](https://172.16.54.40).

### 10.1 Suppression du dossier d'installation

Le dossier d'installation ne sert plus et doit être supprimé pour éviter les piratages :

```bash title="Terminal"
rm -rf /var/www/html/glpi/install
```

### 10.2 Tâches automatiques (Cron)

On crée une tâche planifiée pour que GLPI gère les actions automatiques tout seul (comme les alertes email) :

```bash title="Terminal"
echo "* * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/glpi
```

### 10.3 Sécurité des comptes

Lors de votre première connexion, appliquez ces règles de sécurité :

- **Changer les mots de passe par défaut** : Les comptes par défaut (`glpi`, `tech`, `normal`, `post-only`) doivent avoir leur mot de passe changé immédiatement ou être désactivés / supprimer.
- **Activer le MFA (Double authentification)** : Activez le MFA pour tous les comptes administrateurs.
- **Stratégie de mots de passe** : Forcez des mots de passe de 12 caractères minimum dans la configuration de GLPI.
