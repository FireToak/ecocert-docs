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
    - **Auteur(s) :** KADA Amine (Documentation révisée et augmentée)
    - **Date de MAJ :** 23/09/2026
    - **Domaine :** Infrastructures Linux Debian 13 / ITSM GLPI 11 / Cybersécurité

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Ingénierie de l'Infrastructure et Préparation du Système d'Exploitation](#3-ingenierie-de-linfrastructure-et-preparation-du-systeme-dexploitation)
- [4. Architecture et Déploiement de la Pile LAMP](#4-architecture-et-deploiement-de-la-pile-lamp)
- [5. Durcissement et Sécurisation (ANSSI, MariaDB, PHP)](#5-durcissement-et-securisation-anssi-mariadb-php)
- [6. Création et Cloisonnement de la Base de Données GLPI](#6-creation-et-cloisonnement-de-la-base-de-donnees-glpi)
- [7. Téléchargement, Isolation et Ségrégation de l'Architecture GLPI](#7-telechargement-isolation-et-segregation-de-larchitecture-glpi)
- [8. Configuration du Routage Front Controller Apache](#8-configuration-du-routage-front-controller-apache)
- [9. Initialisation par l'Interface en Ligne de Commande (CLI) et Chiffrement](#9-initialisation-par-linterface-en-ligne-de-commande-cli-et-chiffrement)
- [10. Post-Installation et Conformité Administrative (CNIL / Sécurité)](#10-post-installation-et-conformite-administrative-cnil-securite)

## 2. Contexte

La **Mission 3** requiert l'installation en ligne de commande (CLI) du système de Helpdesk et d'inventaire GLPI (version 11). Ce déploiement s'effectue sur le nœud hyperviseur `pve2` (ID : 20805) via la machine virtuelle Debian 13 nommée **GLPIECOCERT** (IP : `172.16.54.40`, Passerelle : `172.16.54.253`). Cette documentation intègre toutes les bonnes pratiques de sécurité (PHP 8.4 FPM, sécurisation MariaDB, externalisation des dossiers sensibles et routage par Alias).

## 3. Ingénierie de l'Infrastructure et Préparation du Système d'Exploitation

La fondation du déploiement repose sur un système Debian 13 sain, à jour et minimaliste. Avant de superposer les couches logicielles, il est impératif de s'assurer de l'intégrité de la distribution.

Exécutez la commande d'actualisation globale du système :

```bash title="Terminal"
apt update && apt upgrade -y
```

Le drapeau `-y` automatise l'acceptation des modifications, facilitant ainsi l'intégration de cette documentation dans des scripts de provisionnement automatisés.

## 4. Architecture et Déploiement de la Pile LAMP

L'acronyme LAMP désigne l'écosystème Linux, Apache, MariaDB et PHP. Pour GLPI 11, la synergie entre ces composants doit être orchestrée avec précision.

### 4.1 Installation du Serveur Web et du Moteur Relationnel

Le serveur HTTP Apache (version 2.4) et le système de gestion de base de données MariaDB sont déployés à partir des dépôts officiels de Debian.

```bash title="Terminal"
apt install apache2 mariadb-server -y
```

### 4.2 Intégration du Dépôt SURY pour PHP 8.4

Le cycle de vie de développement de GLPI 11 et les impératifs de performance dictent l'utilisation de PHP 8.4. Pour garantir l'accès aux correctifs de sécurité immédiats pour cette branche spécifique, l'infrastructure s'appuie sur le dépôt officiel de l'Ondřej Surý.

```bash title="Terminal"
apt install -y apt-transport-https lsb-release ca-certificates curl
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
apt update
```

### 4.3 Déploiement du Moteur PHP-FPM et des Extensions Applicatives

Historiquement, PHP était intégré à Apache via le module `mod_php`. Cette architecture monolithique est obsolète et contraire aux recommandations de l'ANSSI. La documentation déploie **PHP-FPM** (FastCGI Process Manager), qui crée un service d'exécution isolé.

```bash title="Terminal"
apt install -y php8.4 php8.4-fpm php8.4-mysql php8.4-xml php8.4-curl php8.4-gd php8.4-mbstring php8.4-intl php8.4-bz2 php8.4-zip php8.4-ldap php8.4-apcu
```

### 4.4 Interface et Activation des Modules Apache

Pour qu'Apache puisse relayer le trafic HTTP vers le socket PHP-FPM, des modules proxy spécifiques doivent être activés.

```bash title="Terminal"
a2enmod proxy_fcgi setenvif headers rewrite ssl
a2enconf php8.4-fpm
systemctl restart apache2
```

## 5. Durcissement et Sécurisation (ANSSI, MariaDB, PHP)

### 5.1 Verrouillage du SGBD MariaDB et Gestion des Fuseaux Horaires

Le script interactif supprime les comptes anonymes, interdit les connexions distantes pour l'utilisateur root, et efface les bases de données de test.

```bash title="Terminal"
mysql_secure_installation
```

L'exactitude temporelle est critique pour un outil ITSM. Il faut extraire les informations temporelles du système d'exploitation Debian et les injecter dans le dictionnaire interne du SGBD :

```bash title="Terminal"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
```

### 5.2 Sécurisation Avancée de PHP-FPM (Conformité CNIL et ANSSI)

Ouvrez le fichier de configuration avec un éditeur de texte :

```bash title="Terminal"
nano /etc/php/8.4/fpm/php.ini
```

La table ci-dessous détaille les directives à modifier, leurs nouvelles valeurs et la justification de sécurité associée :

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

## 6. Création et Cloisonnement de la Base de Données GLPI

La base de données doit être isolée. L'application GLPI ne doit en aucun cas utiliser le compte d'administration global (`root`).

Lancez l'interpréteur de commandes MariaDB :

```bash title="Terminal"
mysql -u root -p
```

Exécutez les requêtes suivantes :

```sql title="MariaDB"
CREATE DATABASE glpi;
CREATE USER 'glpi_user'@'localhost' IDENTIFIED BY 'Ecocert2026!';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi_user'@'localhost';
GRANT SELECT ON mysql.time_zone_name TO 'glpi_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

L'octroi du droit de lecture (`GRANT SELECT`) sur la table `mysql.time_zone_name` est vital pour gérer les changements d'heure (heure d'été/hiver).

## 7. Téléchargement, Isolation et Ségrégation de l'Architecture GLPI

L'installation traditionnelle plaçait l'intégralité du code dans `/var/www/html/glpi`. Cette conception monolithique est responsable des failles d'inclusion de fichiers. La démarche suivante implémente la séparation de la logique applicative et des données persistantes.

### 7.1 Téléchargement et Déploiement des Sources

```bash title="Terminal"
wget https://github.com/glpi-project/glpi/releases/download/11.0.0/glpi-11.0.0.tgz
tar -xzvf glpi-11.0.0.tgz -C /var/www/html/
```

### 7.2 Ségrégation des Dossiers Sensibles et Externalisation

Création de la nouvelle arborescence de stockage :

```bash title="Terminal"
mkdir -p /etc/glpi /var/lib/glpi/files /var/lib/glpi/plugins /var/log/glpi
```

Déplacement des éléments fournis par défaut :

```bash title="Terminal"
mv /var/www/html/glpi/config/* /etc/glpi/
mv /var/www/html/glpi/files/* /var/lib/glpi/files/
```

### 7.3 Liaison Logique via downstream.php et local_define.php

Création du fichier d'amorçage primaire :

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

Ensuite, créez le registre des constantes globales qui cartographie l'architecture externalisée :

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

// Sécurisation critique des plugins (Mitigation CVE-2024-37149)
define('GLPI_MARKETPLACE_DIR', '/var/lib/glpi/plugins');
```

### 7.4 Application des Stratégies de Permissions

L'utilisation de permissions trop laxistes (comme chmod 777) est une aberration de sécurité proscrite par l'ANSSI. Le processus `www-data` doit être le propriétaire exclusif.

```bash title="Terminal"
chown -R www-data:www-data /var/www/html/glpi /etc/glpi /var/lib/glpi /var/log/glpi
```

## 8. Configuration du Routage Front Controller Apache

Le DocumentRoot pointe explicitement et uniquement vers le sous-dossier `/public` de GLPI. Les fichiers hors de ce dossier deviennent topologiquement invisibles depuis le réseau.

```bash title="Terminal"
nano /etc/apache2/sites-available/default-ssl.conf
```

```apache title="/etc/apache2/sites-available/default-ssl.conf"
# Modification du DocumentRoot pour cibler le Front Controller
DocumentRoot /var/www/html/glpi/public

# Définition des règles d'accès et de réécriture
<Directory /var/www/html/glpi/public>
    Require all granted
    
    # Activation du moteur de réécriture
    RewriteEngine On
    RewriteBase /
    
    # Sécurisation des en-têtes HTTP (Recommandations ANSSI-BP-028)
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

## 9. Initialisation par l'Interface en Ligne de Commande (CLI) et Chiffrement

L'anomalie critique du document original résidait dans l'instruction de finaliser l'installation via un navigateur web. Exposer une procédure d'installation non finalisée sur une IP de production constitue un risque d'interception inacceptable ("Race Condition").

### 9.1 Déploiement du Schéma de Base de Données

Lancez l'installation du schéma SQL en passant les variables d'environnement silencieusement (drapeau `--no-interaction`) en tant que `www-data`.

```bash title="Terminal"
cd /var/www/html/glpi
sudo -u www-data php bin/console db:install --db-host=localhost --db-name=glpi --db-user=glpi_user --db-password='Ecocert2026!' --no-interaction
```

### 9.2 Sécurisation Cryptographique du Moteur

La génération automatisée d'une clé robuste (`glpicrypt.key`) est une exigence absolue pour se prémunir contre les fuites de données.

```bash title="Terminal"
sudo -u www-data php bin/console glpi:security:change_key --no-interaction
```

### 9.3 Audit de Conformité de l'Environnement

Avant de confier le système aux administrateurs, il est nécessaire de réaliser un auto-diagnostic. Une sortie vierge d'erreur rouge confirme l'intégrité architecturale.

```bash title="Terminal"
sudo -u www-data php bin/console glpi:system:check_requirements
```

## 10. Post-Installation et Conformité Administrative (CNIL / Sécurité)

L'installation CLI est terminée. Le système est immédiatement opérationnel, fiable et accessible via l'URL sécurisée : [https://172.16.54.40](https://172.16.54.40).

### 10.1 Éradication du Répertoire d'Installation

La présence du dossier `install` constitue une menace résiduelle et doit être purgée du système de fichiers.

```bash title="Terminal"
rm -rf /var/www/html/glpi/install
```

### 10.2 Planification des Tâches Asynchrones (Cron)

L'intégration de la commande GLPI au planificateur garantit une exécution régulière et fiable.

```bash title="Terminal"
echo "* * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/glpi
```

### 10.3 Politiques d'Identité et Authentification

Lors de la première connexion à l'interface, l'administrateur de l'infrastructure d'ECOCERT est tenu d'appliquer ce protocole :

- **Destruction des comptes de démonstration** : L'accès immédiat aux comptes `glpi` (mdp: glpi), `tech` (mdp: tech), `normal` (mdp: normal), et `post-only` (mdp: postonly) représente une violation flagrante. Ils doivent être modifiés immédiatement.
- **Enrôlement MFA Obligatoire** : GLPI 11 intègre nativement l'Authentification Multi-Facteur (MFA/TOTP). Son activation doit être rendue obligatoire pour tous les profils de type "Super-Admin" et "Admin".
- **Paramétrage des stratégies de mots de passe** : Configurez la longueur minimale du mot de passe à 12 caractères, avec expiration et rotation obligatoire.
