---
description: Procédure d'installation de Bind9 sur Debian 13.
---

# Installation de BIND9

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
- [3. Préparation du système](#3-preparation-du-systeme)
- [4. Installation de bind9](#4-installation-de-bind9)
- [5. Configuration du résolveur DNS](#5-configuration-du-resolveur-dns)

## 2. Contexte

Bind9 est un serveur DNS (Domain Name System) open source. Dans l'infrastructure, ce service permet de résoudre les noms de domaine en adresses IP, agissant comme le point central de résolution pour le réseau. Cette procédure documente son installation de base et la configuration du résolveur local, sans configuration DNS avancée.

## 3. Préparation du système {#3-preparation-du-systeme}

3.1. **Mise à jour du système.** Actualisation des listes de paquets et mise à niveau des paquets existants.

```bash
sudo apt update && sudo apt upgrade -y
```

- `sudo` : Exécute la commande avec les privilèges d'administrateur (root).
- `apt update` : Met à jour la liste des paquets disponibles depuis les dépôts.
- `&&` : Permet d'exécuter la seconde commande uniquement si la première réussit.
- `apt upgrade` : Installe les versions les plus récentes des paquets du système.
- `-y` : Valide automatiquement toutes les demandes de confirmation.

## 4. Installation de bind9

4.1. **Installation du service.** Déploiement du paquet serveur DNS sur la machine.

```bash
sudo apt install bind9 -y
```

- `apt install` : Commande d'installation de nouveaux paquets.
- `bind9` : Nom du paquet correspondant au serveur DNS.
- `-y` : Approuve l'installation sans nécessiter d'intervention manuelle.

## 5. Configuration du résolveur DNS {#5-configuration-du-resolveur-dns}

5.1. **Modification du fichier resolv.conf.** Déclaration des serveurs de noms utilisés par le système.

```text title="/etc/resolv.conf"
nameserver 127.0.0.1
nameserver 86.54.11.1
```

- `nameserver 127.0.0.1` : Définit l'adresse IP locale du serveur DNS primaire (bind9 lui-même).
- `nameserver 86.54.11.1` : Définit l'adresse IP du serveur DNS de secours (résolveur public DNS4EU).

5.2. **Application de la configuration réseau.** Redémarrage du service réseau pour la prise en compte des nouveaux résolveurs.

```bash
sudo systemctl restart networking
```

- `sudo` : Exécute avec les privilèges d'administrateur.
- `systemctl restart` : Commande de gestion des services pour stopper puis relancer un service.
- `networking` : Nom du service en charge de la configuration des interfaces réseau.