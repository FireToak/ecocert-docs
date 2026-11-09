---
description: Procédure de configuration de Bind9 sur Debian 13.
---

# Configuration BIND9

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 02/11/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [2. Contexte](#2-contexte)
- [3. Configuration globale du service](#3-configuration-globale-du-service)
- [4. Déclaration de la zone DNS](#4-declaration-de-la-zone-dns)
- [5. Création et paramétrage du fichier de zone](#5-creation-et-parametrage-du-fichier-de-zone)
- [6. Configuration de la journalisation](#6-configuration-de-la-journalisation)
- [7. Configuration de la sécurité AppArmor](#7-configuration-de-la-securite-apparmor)
- [8. Vérification et validation](#8-verification-et-validation)

## 2. Contexte

Le serveur Bind9 agit comme serveur DNS faisant autorité pour l'infrastructure CUB. Cette procédure décrit la configuration en mode production de la zone `ecocert4.fr`. Elle inclut la scission des fichiers de configuration pour une meilleure maintenabilité, la sécurisation du service (désactivation de la récursivité, masquage de version), la mise en place d'une journalisation dédiée et l'ajustement des règles AppArmor pour autoriser l'écriture des logs.

## 3. Configuration globale du service

3.1. **Définition des options globales.** Modification du fichier d'options pour sécuriser Bind9 et définir ses interfaces d'écoute.

```bash
sudoedit /etc/bind/named.conf.options
```

```text title="/etc/bind/named.conf.options"
options {
    // Directory permet de définir où se situe le cache du serveur DNS
    directory "/var/cache/bind";

    // Définit le port et la ou les adresses IPv4 d’écoute du service Bind
    listen-on port 53 { 127.0.0.1; 172.16.54.50; };

    // Recursion permet d'autoriser ou d'interdire la récursivité sur un serveur DNS. 
    // Par défaut un serveur DNS faisant autorité ne doit pas être récursif.
    recursion no;

    // Empêche la diffusion de la version du service Bind utilisée (sécurité).
    version none;
};
```

- `listen-on` : Restreint l'écoute du service DNS aux adresses IP spécifiées.
- `recursion no` : Désactive la récursivité pour éviter les attaques d'amplification DNS.
- `version none` : Masque la version du daemon pour limiter la reconnaissance par d'éventuels attaquants.

## 4. Déclaration de la zone DNS {#4-declaration-de-la-zone-dns}

4.1. **Ajout de la zone locale.** Déclaration de la zone `ecocert4.fr` dans le fichier dédié aux zones locales.

```bash
sudoedit /etc/bind/named.conf.local
```

```text title="/etc/bind/named.conf.local"
zone "ecocert4.fr" {
    type master;
    file "/var/cache/bind/db.ecocert4.fr";
};
```

- `type master` : Définit ce serveur comme maître (faisant autorité) pour cette zone.
- `file` : Indique le chemin absolu vers le fichier contenant les enregistrements de la zone.

## 5. Création et paramétrage du fichier de zone {#5-creation-et-parametrage-du-fichier-de-zone}

> [!warning] Gestion du numéro de série (Serial)
> Le numéro de série ne doit jamais être choisi au hasard. Il doit systématiquement être incrémenté à chaque modification du fichier de zone (format recommandé : AAAAMMJJXX). Si le numéro de série du maître devient inférieur à celui de l'esclave, le transfert de zone sera rompu.

5.1. **Création du fichier de zone.** Édition du fichier contenant les enregistrements DNS (SOA, NS, A, CNAME).

```bash
sudoedit /var/cache/bind/db.ecocert4.fr
```

**Fichier de zone : [db.ecocert4.fr](../../01-ressources/assets/configurations/db.ecocert4.fr.txt)**

- `$TTL` : Définit la durée de mise en cache par défaut pour les résolveurs.
- `SOA` : (Start of Authority) Définit les paramètres globaux de la zone et le contact administratif.
- `NS` : Déclare les serveurs de noms faisant autorité.
- `A` : Associe un nom d'hôte à une adresse IPv4.
- `CNAME` : Crée un alias pointant vers un autre nom d'hôte existant.

5.2. **Application des droits.** Attribution du fichier à l'utilisateur et au groupe `bind`.

```bash
sudo chown bind:bind /var/cache/bind/db.ecocert4.fr
```

- `chown` : Modifie le propriétaire et le groupe d'un fichier.
- `bind:bind` : Spécifie l'utilisateur `bind` et le groupe `bind`.

## 6. Configuration de la journalisation

6.1. **Création du fichier de log.** Initialisation du fichier texte destiné à recevoir les journaux DNS.

```bash
sudo touch /var/log/bind.log
sudo chown bind:bind /var/log/bind.log
```

- `touch` : Crée un fichier vide s'il n'existe pas.

6.2. **Paramétrage du module de log.** Création d'un fichier de configuration dédié à la journalisation.

```bash
sudoedit /etc/bind/named.conf.log
```

```text title="/etc/bind/named.conf.log"
logging {
    channel bind_log {
        file "/var/log/bind.log" versions 3 size 100m;
        severity info;
        print-category  yes;
        print-severity  yes;
        print-time      yes;
    };
    category default { bind_log; };
};
```

- `file` : Indique le chemin du fichier, le nombre de rotations (`versions`) et la taille maximale (`size`).
- `severity` : Définit le niveau de verbosité des logs capturés.

6.3. **Inclusion de la configuration.** Ajout du fichier de journalisation à la configuration principale.

```bash
sudoedit /etc/bind/named.conf
```

```text title="/etc/bind/named.conf" hl_lines="10 11"
// This is the primary configuration file for the BIND DNS server named.

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.root-hints";

// Ajout du fichier de parametrage de la journalisation du service BIND
include "/etc/bind/named.conf.log";
```

- `include` : Charge dynamiquement un fichier de configuration externe dans le fichier principal.

## 7. Configuration de la sécurité AppArmor {#7-configuration-de-la-securite-apparmor}

> [!info] Protection MAC
> Sur Debian, AppArmor (Mandatory Access Control) surveille les accès des processus. Par défaut, il interdit à Bind9 d'écrire dans `/var/log/`. Une modification des permissions d'AppArmor est requise pour le bon fonctionnement des logs.

7.1. **Modification des règles AppArmor.** Autorisation de lecture et d'écriture pour le daemon Bind.

```bash
sudoedit /etc/apparmor.d/usr.sbin.named
```

```text title="/etc/apparmor.d/usr.sbin.named" hl_lines="3 4"
# On autorise le daemon Bind 9 à lire et ecrire dans le fichier /var/log/bind.log

/var/log/bind.log rw,
```

- `rw,` : Autorise les droits de lecture (Read) et d'écriture (Write) sur le fichier spécifié.

7.2. **Rechargement d'AppArmor.** Prise en compte de la nouvelle politique de sécurité.

```bash
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.named
sudo systemctl restart apparmor
```

- `apparmor_parser -r` : Recharge et remplace le profil spécifié sans avoir à redémarrer tout le service immédiatement.
- `systemctl restart apparmor` : Relance le service AppArmor pour garantir l'application globale.

## 8. Vérification et validation {#8-verification-et-validation}

8.1. **Contrôle de la syntaxe.** Vérification des fichiers de configuration pour éviter toute corruption au démarrage.

```bash
sudo named-checkconf -z
```

- `named-checkconf` : Utilitaire natif de validation de la configuration de Bind.
- `-z` : Tente de charger l'ensemble des zones définies pour vérifier leur validité.

8.2. **Redémarrage et vérification du statut.** Application des paramètres et contrôle de l'état du daemon.

```bash
sudo systemctl restart bind9
sudo systemctl status bind9
```

- `systemctl restart` : Arrête proprement le service et le démarre à nouveau.
- `systemctl status` : Affiche l'état d'exécution actuel, confirmant si le service est "active (running)".