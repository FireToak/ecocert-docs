---
description: Procédure d'installation d'Ansible sur un serveur Debian selon les bonnes pratiques.
---

# Installation de Ansible

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 12/10/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Prérequis et mise à jour](#3-prerequis-et-mise-a-jour)
- [4. Installation d'Ansible](#4-installation-dansible)
- [5. Vérification de l'installation](#5-verification-de-linstallation)

## 2. Contexte

Ansible est un outil d'automatisation IT (IaC) permettant la gestion de configuration et le déploiement. Sur un système Debian, il s'intègre en tant que nœud de contrôle "sans agent" (*agentless*), communiquant directement avec les infrastructures distantes via le protocole SSH.

## 3. Prérequis et mise à jour {#3-prerequis-et-mise-a-jour}

3.1. **Mise à jour du système.** Actualisation des listes de dépôts et mise à niveau des paquets installés pour garantir un système stable.

```bash
sudo apt update && sudo apt upgrade -y
```

- `sudo` : Exécute la commande avec les droits d'administration (root).
- `apt update` : Met à jour le cache local des paquets disponibles.
- `&&` : Opérateur logique permettant de lancer la seconde commande uniquement si la première réussit.
- `apt upgrade` : Installe les nouvelles versions des paquets existants.
- `-y` : Accepte automatiquement les invites de confirmation (indispensable en automatisation).

## 4. Installation d'Ansible

4.1. **Installation d'Ansible.** Lancement de l'installation du binaire Ansible.

```bash
sudo apt install -y ansible
```

- `ansible` : Nom du paquet contenant le moteur d'automatisation.

## 5. Vérification de l'installation {#5-verification-de-linstallation}

5.1. **Test du binaire.** Validation du bon fonctionnement de l'outil et affichage de sa configuration système.

```bash
ansible --version
```

- `ansible` : Exécute le programme principal.
- `--version` : Argument demandant l'affichage de la version d'Ansible installée, du chemin du fichier de configuration et de la version de Python utilisée en arrière-plan.
