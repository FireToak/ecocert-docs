
---

description: Initialisation du stockage RAIDZ1 TrueNAS, configuration réseau, et intégration Active Directory (SMB).

---

# Configuration Initiale et Réseau TrueNAS

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)


- **Auteur :** KADA Amine
- **Date :** 23/09/2026
- **Domaine :** NAS / Stockage

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Configuration de l'Interface Réseau](#3-configuration-de-linterface-reseau)
- [4. Configuration Globale (Passerelle & DNS)](#4-configuration-globale-passerelle--dns)
- [5. Configuration NTP & Active Directory](#5-configuration-ntp--active-directory)
- [6. Partage de fichiers (SMB) et Droits (ACL)](#6-partage-de-fichiers-smb-et-droits-acl)
- [7. Validation Côté Client (Windows)](#7-validation-cote-client-windows)

## 2. Contexte

Le serveur **NASECOCERT** (172.16.54.20) tourne sous TrueNAS. Il a pour rôle d'initialiser l'espace de stockage réseau avec une tolérance aux pannes (RAID 5, min. 20 Go) dédié à la gestion des sauvegardes. Le service doit s'intégrer à l'annuaire Active Directory (`local.ecocert4.fr`) pour gérer l'authentification et les droits d'accès.

## 3. Configuration de l'Interface Réseau

3.1.  **Attribution de l'adresse IP fixe**. Cette étape est réalisée depuis la console locale de TrueNAS.

1. Dans le menu de la console TrueNAS, accédez à `Configure Network Interfaces`.
2. Éditez la carte réseau principale (ex: `ens18`).
3. Ajoutez un Alias avec l'adresse IP fixe `172.16.54.20/24`.

> [!important] Connectivité
> Sans cette étape, le NAS ne peut pas communiquer sur le réseau local ni être administré via l'interface web.

## 4. Configuration Globale (Passerelle & DNS)

4.1.  **Paramétrage du routage**. Configuration effectuée depuis la console locale.

1. Accédez au menu `Global Configuration`.
2. Renseignez la passerelle par défaut : `172.16.54.253`.
3. Renseignez le serveur DNS : `172.16.54.1` (Contrôleur de domaine).

> [!warning] DNS Secondaire
> Ne pas renseigner de "DNS Secondary" avec un DNS public (ex: 8.8.8.8). En effet, le système risquerait de rejeter les requêtes ou de faire la demande à l'extérieur plutôt qu'en interne, brisant la résolution de nom pour le domaine `local.ecocert4.fr`.

![Configuration Réseau](assets/conf-nas-truenas/network-nas.jpg)

## 5. Configuration NTP & Active Directory

5.1.  **Configuration NTP (Pré-requis)**. L'intégration à un domaine Active Directory requiert une synchronisation temporelle stricte.

1. Naviguez dans **System > NTP Servers**.
2. Ajoutez ou modifiez un serveur NTP pour pointer vers votre contrôleur de domaine (`172.16.54.1`).

![Configuration NTP](assets/conf-nas-truenas/config-ntp.jpg)

5.2.  **Intégration à l'annuaire (Active Directory)**. Liaison du NAS avec l'annuaire pour l'authentification centralisée.

1. Allez dans le menu **Directory Services > Active Directory**.
2. Renseignez le domaine `local.ecocert4.fr` et les identifiants de l'administrateur du domaine.

![Annuaire LDAP/AD](assets/conf-nas-truenas/ldap-truenas.jpg)

![Configuration AD - Étape 1](assets/conf-nas-truenas/1config-ad.jpg)
![Configuration AD - Étape 2](assets/conf-nas-truenas/2config-ad.jpg)

## 6. Partage de fichiers (SMB) et Droits (ACL)

6.1.  **Activation du service SMB**. Permet le partage de fichiers sur le réseau Windows.

1. Naviguez dans le menu **Services**.
2. Activez le service **SMB** et cochez "Start Automatically".

![Services Système](assets/conf-nas-truenas/system-service.jpg)
![Service SMB](assets/conf-nas-truenas/service-smb.jpg)

6.2.  **Création du partage et gestion des permissions (ACL)**.

1. Naviguez dans **Sharing > Windows Shares (SMB)** et cliquez sur **Add**.
2. Sélectionnez le chemin correspondant à votre pool de stockage (ex: `Sauvegardes`).
3. Modifiez les droits d'accès (ACL) sur le Dataset pour autoriser les utilisateurs et groupes de l'Active Directory.

![Permissions Dataset](assets/conf-nas-truenas/permission-dataset.jpg)
![Ajout ACL NAS](assets/conf-nas-truenas/ajout-acl-nas.jpg)