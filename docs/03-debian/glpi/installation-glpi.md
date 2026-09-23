
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
- [4. Installation de la pile LAMP](#4-installation-de-la-pile-lamp)
- [5. Configuration des fuseaux horaires (Timezone)](#5-configuration-des-fuseaux-horaires-timezone)
- [6. Création de la base de données MariaDB](#6-creation-de-la-base-de-donnees-mariadb)
- [7. Téléchargement et déploiement de GLPI](#7-telechargement-et-deploiement-de-glpi)
- [8. Configuration du VirtualHost Apache](#8-configuration-du-virtualhost-apache)
- [9. Installation finale (Interface Web)](#9-installation-finale-interface-web)

## 2. Contexte

La **Mission 3** requiert l'installation en ligne de commande (CLI) du système de Helpdesk et d'inventaire GLPI (version 11). Ce déploiement s'effectue sur le nœud hyperviseur `pve2` (ID : 20805) via la machine virtuelle Debian 13 nommée **GLPIECOCERT** (IP : `172.16.54.40`, Passerelle : `172.16.54.253`).

## 3. Préparation du système d'exploitation

3.1.  **Mise à jour**. Avant toute installation, il est nécessaire de mettre à jour la liste des paquets et le système Debian.

```bash title="Terminal"
apt update && apt upgrade -y
```

- `update` : Actualise la liste des paquets disponibles depuis les dépôts.
- `upgrade` : Installe les dernières versions des paquets déjà présents sur le système.

## 4. Installation de la pile LAMP

4.1.  **Installation des paquets**. GLPI nécessite un serveur web (Apache), un moteur de base de données (MariaDB) et PHP avec de nombreux modules spécifiques.

```bash title="Terminal"
apt install apache2 mariadb-server -y
apt install php php-mysql php-xml php-curl php-gd php-mbstring php-intl php-ldap php-apcu php-zip php-bz2 -y
```

- `apache2` : Démon du serveur web HTTP.
- `mariadb-server` : Moteur de base de données relationnelle libre.
- `php-*` : Extensions PHP requises par le code source de GLPI.

## 5. Configuration des fuseaux horaires (Timezone)

5.1.  **Injection des fuseaux horaires dans MariaDB**. Il faut importer la base de données des fuseaux horaires de Debian directement dans le moteur SQL pour que GLPI puisse les utiliser. (Le mot de passe root SQL vous sera demandé).

```bash title="Terminal"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
```

- `mysql_tzinfo_to_sql` : Convertit les tables de fuseaux horaires du système en requêtes SQL.

5.2.  **Configuration du fuseau horaire web (PHP)**. Modification du fichier de configuration PHP pour forcer l'heure française. Remplacez `8.x` par votre version de PHP installée (ex: 8.2).

```bash title="Terminal"
nano /etc/php/8.x/apache2/php.ini
```

Recherchez la ligne `;date.timezone =` et modifiez-la en enlevant le point-virgule :

```ini title="php.ini"
date.timezone = Europe/Paris
```

- `date.timezone` : Définit la zone de temps de référence pour toutes les dates traitées par l'application web.

## 6. Création de la base de données MariaDB

6.1.  **Création de l'espace SQL et attribution des droits**. Connexion au moteur de base de données pour créer l'espace dédié à GLPI, son utilisateur privilégié, et lui octroyer l'accès en lecture à la table des fuseaux horaires.

```bash title="Terminal"
mysql -u root -p
```

Dans l'invite de commande MariaDB, exécutez les requêtes suivantes :

```sql title="Invite MariaDB"
CREATE DATABASE glpi;
CREATE USER 'glpi_user'@'localhost' IDENTIFIED BY 'Ecocert2026!';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi_user'@'localhost';
GRANT SELECT ON mysql.time_zone_name TO 'glpi_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

- `GRANT SELECT ON mysql.time_zone_name` : Autorise l'utilisateur GLPI à lire la table des fuseaux horaires importée à l'étape 5.

## 7. Téléchargement et déploiement de GLPI

7.1.  **Téléchargement et extraction de l'archive**. Récupération de la version 11 depuis GitHub et extraction dans le répertoire web.

```bash title="Terminal"
wget https://github.com/glpi-project/glpi/releases/download/11.0.0/glpi-11.0.0.tgz
tar -xzvf glpi-11.0.0.tgz -C /var/www/html/
```

- `wget` : Télécharge l'archive compressée.
- `tar -xzvf` : Décompresse et extrait l'archive vers le répertoire web.

7.2.  **Attribution des permissions (Propriétaire)**. L'utilisateur système d'Apache (`www-data`) doit posséder les droits complets sur le dossier de l'application.

```bash title="Terminal"
chown -R www-data:www-data /var/www/html/glpi
chmod -R 755 /var/www/html/glpi
```

## 8. Configuration du VirtualHost Apache

8.1.  **Création du fichier de configuration**. Création du fichier pour exposer uniquement le sous-dossier sécurisé `/public`.

```bash title="Terminal"
nano /etc/apache2/sites-available/glpi.conf
```

Contenu à insérer :

```apacheconf title="/etc/apache2/sites-available/glpi.conf"
<VirtualHost *:80>
    ServerName glpiecocert
    DocumentRoot /var/www/html/glpi/public
    
    <Directory /var/www/html/glpi/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

8.2.  **Activation et redémarrage des services**. Activation du site GLPI, du module de réécriture d'URL, et redémarrage d'Apache pour appliquer les modifications (dont la timezone PHP).

```bash title="Terminal"
a2dissite 000-default.conf
a2ensite glpi.conf
a2enmod rewrite
systemctl restart apache2
```

## 9. Installation finale (Interface Web)

L'installation en ligne de commande est terminée. L'initialisation finale (peuplement de la base de données et création des comptes administrateurs par défaut) s'effectue via un navigateur web.

1. Sur un poste client, ouvrez un navigateur web.
2. Accédez à l'URL suivante : [http://172.16.54.40](http://172.16.54.40).
3. Suivez l'assistant d'installation graphique de GLPI.
