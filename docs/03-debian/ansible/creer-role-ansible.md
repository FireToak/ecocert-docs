---
description: Procédure de création d'un rôle Ansible générique et bonnes pratiques d'intégration au sein de l'infrastructure ECOCERT.
---

# Créer un rôle sur Ansible

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 19/10/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Fonctionnement des rôles sur ECOCERT](#3-fonctionnement-des-roles-sur-ecocert)
- [4. Création et structuration d'un nouveau rôle](#4-creation-et-structuration-dun-nouveau-role)

## 2. Contexte

Un rôle Ansible est une structure de répertoires standardisée permettant de regrouper des tâches, des variables, des fichiers et des modèles (templates) de manière modulaire et indépendante. Les bonnes pratiques exigent que chaque rôle ait une responsabilité unique et bien définie (ex: configurer l'authentification, installer une application, sécuriser un pare-feu).

Ce composant est systématiquement placé dans le répertoire `roles/` de l'arborescence du projet d'automatisation. Cette isolation structurelle permet de réutiliser aisément ce morceau de code dans de multiples Playbooks*.

*\*Un playbook est un fichier YAML définissant une série de tâches d'automatisation à exécuter de manière séquentielle sur un ou plusieurs serveurs cibles.*

## 3. Fonctionnement des rôles sur ECOCERT {#3-fonctionnement-des-roles-sur-ecocert}

Au sein du dépôt d'infrastructure `ecocert-ansible`, le sous-répertoire `roles/` centralise l'ensemble des modules d'automatisation. Le projet repose sur une approche composable : plutôt que de rédiger des playbooks monolithiques, on assemble des rôles indépendants.

Cette méthode garantit la maintenabilité du code. Si une procédure de configuration évolue (par exemple, la mise à jour d'un agent de supervision), la modification s'opère uniquement dans le rôle concerné. Tous les playbooks faisant appel à ce rôle bénéficieront automatiquement de la mise à jour lors de leur prochaine exécution.

## 4. Création et structuration d'un nouveau rôle {#4-creation-et-structuration-dun-nouveau-role}

> [!INFO]
> URL du dépôt contennant le code Ansible : [ecocert-ansible](https://github.com/FireToak/ecocert-ansible)

4.1. **Initialisation de l'arborescence.** Génération de la structure standard d'un rôle Ansible au sein du projet ECOCERT.

```bash
cd roles/
ansible-galaxy role init nom-de-votre-role
```

- `cd roles/` : Navigation vers le répertoire centralisant les rôles de l'infrastructure.
- `ansible-galaxy role init` : Commande native générant l'arborescence complète et standardisée (dossiers `tasks`, `handlers`, `vars`, `defaults`, `templates`) requise pour un nouveau rôle, garantissant le respect des conventions Ansible.

4.2. **Développement du fichier des tâches principales.** Édition du point d'entrée du rôle (`tasks/main.yml`) pour y définir les actions d'automatisation.

> [!note] "Bonnes pratiques de nommage"
> Nommez vos tâches de manière explicite pour faciliter la lecture des journaux d'exécution. Documentez toujours vos fichiers YAML avec un en-tête décrivant le périmètre d'action du rôle.

```yaml
# ---
# Type        : Tasks
# Rôle        : nom-de-votre-role
# Description : Description courte et précise de l'objectif du rôle.
# ---
---
- name: Intitulé clair de l'action à réaliser
  ansible.builtin.[nom_du_module]:
    [parametre_1]: "valeur_1"
    [parametre_2]: "valeur_2"
  notify: [Nom du handler éventuel]
```

- `ansible.builtin.[nom_du_module]` : Utilisation systématique du nom complet (FQCN - Fully Qualified Collection Name) des modules (ex: `ansible.builtin.apt`, `ansible.builtin.template`, `ansible.builtin.user`) pour éviter les ambiguïtés de résolution lors de l'exécution.
- `notify` : Directive optionnelle permettant de déclencher une action conditionnelle déclarée dans le dossier `handlers` (ex: redémarrage d'un service), exécutée uniquement si la tâche en cours applique une modification effective sur la cible.
