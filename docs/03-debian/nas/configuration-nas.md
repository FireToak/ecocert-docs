# Configuration Initiale et Réseau TrueNAS

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

- **Auteur :** Amine KADA
- **Classe :** BTS SIO 2 - Option SISR (Tours)
- **Date :** 22 Septembre 2026
- **Domaine :** NAS / Stockage

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Configuration de l'interface réseau](#3-configuration-de-linterface-reseau)
- [4. Configuration globale (Passerelle & DNS)](#4-configuration-globale-passerelle--dns)
- [5. Création du Pool de stockage](#5-creation-du-pool-de-stockage)
- [6. Partage de fichiers (SMB)](#6-partage-de-fichiers-smb)

## 2. Contexte

- **Serveur NAS :** NASECOCERT (172.16.54.20)
- **Système d'exploitation :** TrueNAS (basé sur Debian/FreeBSD)
- **Objectif :** Initialiser le stockage réseau (RAID 5, min. 20Go) pour la gestion des sauvegardes et intégrer le NAS à l'Active Directory pour l'authentification.

## 3. Configuration de l'interface réseau

Cette étape est réalisée depuis la console locale de TrueNAS.

1. Dans le menu de la console TrueNAS, accédez à **Configure Network Interfaces**.
2. Éditez la carte réseau principale (par exemple `ens18`).
3. Ajoutez un Alias avec l'adresse IP fixe **172.16.54.20/24** et sauvegardez. 
*(Sans cette étape, le NAS ne peut pas communiquer sur le réseau local).*

## 4. Configuration globale (Passerelle & DNS)

Cette étape est également réalisée depuis la console locale.

1. Accédez au menu **Global Configuration**.
2. Renseignez la passerelle par défaut : **172.16.54.253**.
3. Renseignez le serveur DNS : **172.16.54.1** (qui pointe vers votre Active Directory). Cela permet la résolution de noms pour le domaine `local.ecocert4.fr`.
4. Sauvegardez les paramètres.

## 5. Création du Pool de stockage (RAID 5)

Cette étape est réalisée depuis l'interface d'administration Web.

1. Ouvrez un navigateur web et connectez-vous sur [http://172.16.54.20](http://172.16.54.20).
2. Rendez-vous dans le menu **Storage > Pools**.
3. Cliquez sur **Add** pour créer un nouveau pool en sélectionnant au moins 3 disques virtuels disponibles.
4. Validez la création en choisissant l'agencement **RAIDZ1** (équivalent au RAID 5) pour initialiser l'espace de stockage, en s'assurant d'avoir au moins **20 Go** d'espace disponible pour les données.

## 6. Intégration Active Directory & Partage (SMB)

1. **Active Directory :** Dans le menu **Directory Services > Active Directory**, renseignez le domaine `local.ecocert4.fr` et les identifiants administrateur pour lier le NAS à l'annuaire.
2. **Partage :** Naviguez dans **Sharing > Windows Shares (SMB)** et cliquez sur **Add**.
3. Sélectionnez le chemin correspondant à votre nouveau pool de stockage.
4. Donnez un nom explicite au partage (ex: `Sauvegardes`) puis validez.
5. *Note :* L'accès au partage sera désormais conditionné par l'authentification des utilisateurs via l'Active Directory.
