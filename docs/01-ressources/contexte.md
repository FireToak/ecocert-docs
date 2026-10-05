# Contexte

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

## Informations

* **Auteur :** Louis MEDO
* **Date :** 04/09/2026
* **Domaine :** Ressource

---

## 1. Sommaire

* [1. Sommaire](#1-sommaire)
* [2. Contexte du projet ECOCERT](#2-contexte-du-projet-ecocert)
* [3. Situations professionnelles](#3-situations-professionnelles)

---

## 2. Contexte du projet ECOCERT

Ce document centralise les ressources et définit le cadre global du projet. Il sert de point de référence pour comprendre les besoins métiers, l'architecture cible et les contraintes techniques de l'infrastructure réseau.

* 📄 **Document de référence :** [Contexte ECOCERT](./assets/contexte/contexte-ecocert.pdf)

---

## 3. Situations professionnelles

### 3.1. Situation 0 : Mise en place de l'infrastructure

Cette phase initiale détaille le déploiement de base des services et de la topologie réseau requise pour le fonctionnement du système d'information.

* 📄 **Document technique :** [Situation 0 - Infrastructure et services](./assets/situations/situation-0-Infrastructure-services.pdf)

### 3.2. Situation 1 : Automatisation de la création et modification des comptes utilisateurs AD

Cette phase vise à automatiser la gestion des comptes utilisateurs dans l'annuaire Active Directory afin de sécuriser, standardiser et accélérer les opérations de création, de modification et de maintenance des identités.

* 📄 **Document technique :** [Situation 1 - Automatisation de la gestion des utilisateurs AD](./assets/situations/situation-1-automatisation-gestion-utilsateurs-ad.pdf)

### 3.3. Situation 2 : Automatisation de la configuration DHCP

Cette phase vise à automatiser la génération du fichier de configuration DHCP à partir d'un plan d'adressage produit avec la méthode VLSM. Le script doit recueillir les paramètres nécessaires, générer les étendues DHCP pour chaque sous-réseau et sauvegarder automatiquement la configuration existante avant toute modification.

* 📄 **Document technique :** [Situation 2 - Automatisation de la configuration DHCP](./assets/situations/situation-2-automatisation-configuration-dhcp.pdf)

### 3.4. Situation 3 : Gestion automatisée des configurations des postes de travail

Cette phase consiste à mettre en place un serveur de gestion centralisée afin d'administrer les postes Debian 13 de la salle. Elle couvre l'authentification SSH par clés, l'exécution de tâches avec les privilèges root, l'installation d'applications, les mises à jour automatiques et le contrôle de la politique de complexité des mots de passe à l'aide de playbooks Ansible.

* 📄 **Document technique :** [Situation 3 - Gestion automatisée des configurations](./assets/situations/situation-3-ansible.pdf)
