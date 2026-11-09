---
description: Procédure d'installation de Unbound sur Debian 13.
---

# Installation de Unbound

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 02/11/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Prérequis et mise à jour](#3-prerequis-et-mise-a-jour)
- [4. Installation de Unbound](#4-installation-de-unbound)
- [5. Activation du service](#5-activation-du-service)

## 2. Contexte

Unbound est un résolveur DNS récursif, validant (DNSSEC) et avec mise en cache. Il s'intègre à l'infrastructure CUB pour fournir une résolution de noms rapide, sécurisée et locale, réduisant ainsi la latence réseau et la dépendance aux résolveurs publics. L'objectif ici est d'automatiser son installation de base.

## 3. Prérequis et mise à jour {#3-prerequis-et-mise-a-jour}

3.1. **Mise à jour du système.** Avant toute installation, il est impératif d'actualiser la liste des paquets et de mettre à jour le système d'exploitation.

```bash
sudo apt update && sudo apt upgrade -y
```

- `sudo` : Exécute la commande avec les privilèges d'administrateur (root).
- `apt update` : Interroge les dépôts pour récupérer les dernières informations sur les versions de paquets.
- `&&` : Opérateur de chaînage qui exécute la seconde commande uniquement si la première a réussi.
- `apt upgrade` : Installe les mises à jour disponibles pour tous les paquets présents sur le système.
- `-y` : Force l'acceptation automatique (yes) pour éviter une attente de validation manuelle.

## 4. Installation de Unbound

4.1. **Déploiement du paquet.** Téléchargement et installation du service Unbound.

```bash
sudo apt install unbound -y
```

- `apt install` : Commande principale pour l'installation d'un nouveau paquetage.
- `unbound` : Le nom officiel du paquet contenant le résolveur DNS dans les dépôts.
- `-y` : Valide la confirmation d'installation pour s'intégrer parfaitement dans une démarche d'automatisation (IaC).

## 5. Activation du service

5.1. **Démarrage et persistance.** Configuration de Systemd pour que le service démarre immédiatement et survive aux redémarrages de la machine.

```bash
sudo systemctl enable --now unbound
```

- `systemctl` : Outil de l'espace utilisateur pour contrôler le système d'initialisation (Systemd) et ses services.
- `enable` : Crée les liens symboliques nécessaires pour que le service s'active automatiquement au démarrage (boot).
- `--now` : Option combinée permettant de lancer (start) le service immédiatement, sans nécessiter de commande supplémentaire.
- `unbound` : Identifiant du service à manipuler.

5.2. **Vérification de l'état.** Contrôle post-installation pour s'assurer que le processus est bien en cours d'exécution.

```bash
sudo systemctl status unbound
```

- `status` : Affiche l'état courant (running, failed, dead) du service, ainsi que les dernières lignes de son journal (logs) pour faciliter le débogage.