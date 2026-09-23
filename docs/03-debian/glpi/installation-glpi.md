---
description: Installation système du moteur GLPI 11 et de la pile LAMP en ligne de commande (CLI) sur Debian 13.
---

# Installation du Serveur GLPI

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)


- **Auteur :** KADA Amine
- **Date :** 23/09/2026
- **Domaine :** Debian / GLPI

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Préparation du système d'exploitation](#3-preparation-du-systeme-dexploitation)
- [4. Installation de la pile LAMP & PHP 8.4](#4-installation-de-la-pile-lamp--php-84)
- [5. Sécurisation et configuration (MariaDB & PHP)](#5-securisation-et-configuration-mariadb--php)
- [6. Création de la base de données MariaDB](#6-creation-de-la-base-de-donnees-mariadb)
- [7. Téléchargement et sécurisation de GLPI](#7-telechargement-et-securisation-de-glpi)
- [8. Configuration du routage Apache](#8-configuration-du-routage-apache)
- [9. Installation finale (Interface Web)](#9-installation-finale-interface-web)

## 2. Contexte

La **Mission 3** requiert l'installation en ligne de commande (CLI) du système de Helpdesk et d'inventaire GLPI (version 11). Ce déploiement s'effectue sur le nœud hyperviseur `pve2` (ID : 20805) via la machine virtuelle Debian 13 nommée **GLPIECOCERT** (IP : `172.16.54.40`, Passerelle : `172.16.54.253`). Cette documentation intègre toutes les bonnes pratiques de sécurité (PHP 8.4 FPM, sécurisation MariaDB, externalisation des dossiers sensibles et routage par Alias).

## 3. Préparation du système d'exploitation

3.1.  **Mise à jour**. Avant toute installation, il est nécessaire de mettre à jour la liste des paquets et le système Debian.

```bash title="Terminal"
apt update && apt upgrade -y
```

- `update` : Actualise la liste des paquets disponibles depuis les dépôts.
- `upgrade` : Installe les dernières versions des paquets déjà présents sur le système.

## 4. Installation de la pile LAMP & PHP 8.4

4.1.  **Serveur Web et Base de données**. Installation d'Apache et MariaDB.

```bash title="Terminal"
apt install apache2 mariadb-server -y
```

4.2.  **Ajout du dépôt SURY pour PHP 8.4**. Debian 13 intégrant nativement PHP 8.2 (déprécié par les nouvelles normes), il faut ajouter un dépôt officiel tiers :

```bash title="Terminal"
apt install -y apt-transport-https lsb-release ca-certificates curl
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
apt update
```

4.3.  **Installation de PHP 8.4 FPM et ses extensions**.

```bash title="Terminal"
apt install -y php8.4 php8.4-fpm php8.4-mysql php8.4-xml php8.4-curl php8.4-gd php8.4-mbstring php8.4-intl php8.4-bz2 php8.4-zip php8.4-ldap php8.4-apcu
```

4.4.  **Activation de PHP-FPM dans Apache**.

```bash title="Terminal"
a2enmod proxy_fcgi setenvif
a2enconf php8.4-fpm
systemctl restart apache2 php8.4-fpm
```

## 5. Sécurisation et configuration (MariaDB & PHP)

5.1.  **Sécurisation de MariaDB**. Lancement du script de sécurité pour fermer les failles par défaut (répondre 'Y' à toutes les questions).

```bash title="Terminal"
mysql_secure_installation
```

5.2.  **Injection des fuseaux horaires**.

```bash title="Terminal"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
```

5.3.  **Configuration PHP-FPM**.

```bash title="Terminal"
nano /etc/php/8.4/fpm/php.ini
```

Recherchez et modifiez ces lignes pour définir l'heure française et sécuriser les cookies :

```ini title="/etc/php/8.4/fpm/php.ini"
date.timezone = Europe/Paris
session.cookie_secure = on
```

Redémarrez PHP-FPM :
```bash title="Terminal"
systemctl restart php8.4-fpm
```

## 6. Création de la base de données MariaDB

6.1.  **Création de l'espace SQL**.

```bash title="Terminal"
mysql -u root -p
```

```sql title="Invite MariaDB"
CREATE DATABASE glpi;
CREATE USER 'glpi_user'@'localhost' IDENTIFIED BY 'Ecocert2026!';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi_user'@'localhost';
GRANT SELECT ON mysql.time_zone_name TO 'glpi_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 7. Téléchargement et sécurisation de GLPI

7.1.  **Téléchargement et extraction**.

```bash title="Terminal"
wget https://github.com/glpi-project/glpi/releases/download/11.0.0/glpi-11.0.0.tgz
tar -xzvf glpi-11.0.0.tgz -C /var/www/html/
```

7.2.  **Externalisation des dossiers sensibles**. GLPI exige que les dossiers de configuration et de données soient isolés de la racine web.

```bash title="Terminal"
mkdir /etc/glpi /var/lib/glpi
mv /var/www/html/glpi/config/* /etc/glpi/
mv /var/www/html/glpi/files/* /var/lib/glpi/
```

7.3.  **Création des liens de routage PHP**. 

Création de `downstream.php` :

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

Création de `local_define.php` :

```bash title="Terminal"
nano /etc/glpi/local_define.php
```

```php title="/etc/glpi/local_define.php"
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
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
define('GLPI_LOG_DIR', GLPI_VAR_DIR . '/_log');
```

7.4.  **Attribution des permissions**. L'utilisateur d'Apache (`www-data`) doit posséder les droits sur tous les dossiers associés.

```bash title="Terminal"
chown -R www-data:www-data /var/www/html/glpi /etc/glpi /var/lib/glpi
```

## 8. Configuration du routage Apache

8.1.  **Création du fichier d'Alias**. Redirection du trafic vers le sous-dossier `/public` obligatoire.

```bash title="Terminal"
nano /etc/apache2/conf-available/glpi.conf
```

Contenu à insérer :

```apacheconf title="/etc/apache2/conf-available/glpi.conf"
Alias /glpi /var/www/html/glpi/public

<Directory /var/www/html/glpi/public>
    Require all granted
    RewriteEngine On
    RewriteBase /glpi/
    
    # Autoriser la transmission des en-têtes d'API
    RewriteCond %{HTTP:Authorization} ^(.+)$
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    
    # Redirection vers le routeur GLPI
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
</Directory>
```

8.2.  **Activation et redémarrage**.

```bash title="Terminal"
a2enmod rewrite
a2enconf glpi
systemctl restart apache2
```

8.3.  **Configuration du HTTPS (SSL) sur la racine**. Pour que GLPI réponde directement sur le port 443 sans avoir à spécifier le sous-dossier `/glpi` dans l'URL, il faut ajuster le VirtualHost SSL par défaut.

```bash title="Terminal"
nano /etc/apache2/sites-available/default-ssl.conf
```

Dans ce fichier, modifiez le `DocumentRoot` et ajoutez le bloc de routage :

```apacheconf title="/etc/apache2/sites-available/default-ssl.conf"
DocumentRoot /var/www/html/glpi/public

<Directory /var/www/html/glpi/public>
    Require all granted
    RewriteEngine On
    RewriteBase /
    
    # Autoriser la transmission des en-têtes d'API
    RewriteCond %{HTTP:Authorization} ^(.+)$
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    
    # Redirection vers le routeur GLPI
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
</Directory>
```

8.4.  **Redémarrage final**. Relancez le service web pour qu'il prenne en compte le nouveau chemin sur le port 443.

```bash title="Terminal"
systemctl restart apache2
```

## 9. Installation finale (Interface Web)

L'installation en ligne de commande est terminée. L'initialisation finale s'effectue via un navigateur web de manière sécurisée (HTTPS).

1. Sur un poste client, ouvrez un navigateur web.
2. Accédez à l'URL suivante (directement sur la racine) : [https://172.16.54.40](https://172.16.54.40)
3. Suivez l'assistant d'installation graphique de GLPI.
