---
description: Procédure générique pour l'ajout d'hôtes et la gestion des variables dans l'inventaire Ansible.
---

# Gestion de l'inventaire et ajout d'hôtes sur Ansible

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
- [3. Fonctionnement de l'inventaire sur ECOCERT](#3-fonctionnement-de-linventaire-sur-ecocert)
- [4. Ajouter un hôte dans l'inventaire](#4-ajouter-un-hote-dans-linventaire)
- [5. Gestion des variables d'inventaire](#5-gestion-des-variables-dinventaire)

## 2. Contexte

L'inventaire Ansible est le composant central qui répertorie les adresses et les noms des serveurs cibles (hôtes) sur lesquels les automatisations seront exécutées. Pour un débutant, il faut voir l'inventaire comme un carnet d'adresses organisé en groupes logiques (ex: bases de données, serveurs web, postes clients).

Cette structuration permet de cibler précisément l'exécution d'un playbook sur un ensemble spécifique de machines et d'y attacher des variables contextuelles de manière dynamique sans modifier le code des rôles.

## 3. Fonctionnement de l'inventaire sur ECOCERT

Au sein de l'infrastructure ECOCERT, les inventaires sont segmentés par environnement afin d'isoler les périmètres (ex: `production`, `staging`).

L'architecture repose sur deux éléments fondamentaux :

- **Le fichier des hôtes :** Situé dans `inventories/production/hosts.yml`, il déclare l'arborescence des groupes et les adresses IP associées à chaque machine.
- **Le répertoire des variables de groupe :** Situé dans `inventories/production/group_vars/`, il permet d'injecter des configurations spécifiques (identifiants, listes de paquets) automatiquement chargées selon l'appartenance d'un hôte à un groupe.

## 4. Ajouter un hôte dans l'inventaire {#4-ajouter-un-hote-dans-linventaire}

4.1. **Déclaration de la machine cible.** L'ajout d'un nouvel hôte s'effectue en modifiant le fichier YAML de l'inventaire correspondant à son environnement.

**Exemple :**

```yaml title="inventories/production/hosts.yml" hl_lines="11-13"
# ---
# Type          : Inventorie
# Description   : Inventaires des hôtes dans la zone de production.
# ---
---
all:
  children:
    pc:
      hosts:
        S406-1:
          ansible_host: 192.168.4.72
          hostname: S406-1
```

- `pc` : Déclare un groupe logique d'hôtes.
- `S406-1` : Identifiant (nom court) de la machine cible dans Ansible.
- `ansible_host` : Variable native (directive de connexion) indiquant l'adresse IP réelle ou le FQDN pour joindre la machine sur le réseau.

## 5. Gestion des variables d'inventaire

Afin de respecter le principe DRY (Don't Repeat Yourself), les variables ne sont pas déclarées directement dans le fichier `hosts.yml` par hôte, mais factorisées dans le dossier `group_vars/`.

5.1. **Ajouter des variables dans tous les groupes.** Le fichier `all.yml` s'applique à l'intégralité des machines de l'inventaire, indépendamment de leur sous-groupe. Il est idéal pour les configurations globales de connexion.

**Exemple :**

```yaml
# ---
# Type          : Vars
# Description   : Variables de production pour les rôles
# ---
---
# SSH
# !!! Ne pas modifier !!!
ansible_ssh_user: svc-ansible
ansible_ssh_pub_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAIIgURtK+Nz4gn6JadBPpQqdxqI2tsouieVi74sW02pkv svc-ansible@ecocert4.fr"
ansible_ssh_private_key_file: ./id_ed25519_svc-ansible
```

- `ansible_ssh_user` : Force l'utilisateur de connexion SSH par défaut pour tous les hôtes de l'environnement.

5.2. **Ajouter des variables à un groupe précis.** Pour cibler uniquement les machines du groupe `pc` ou un autre groupe, il faut créer ou modifier un fichier portant exactement le nom du groupe, soit `pc.yml`.

> [!note] "Héritage et surcharge"
> Les variables définies dans un fichier de groupe spécifique (ex: `pc.yml`) écraseront toujours les variables de même nom définies dans le fichier global `all.yml`.

**Exemple :**

```yaml
# ---
# Type          : Vars
# Description   : Variables pour le groupe pc.
# ---
---
pc_paquets:
  - git
  - curl
  - vim
  - btop
  - etckeeper
```

- `pc_paquets` : Variable de type liste (tableau) définie arbitrairement, qui sera exploitée par le rôle d'installation logicielle pour déployer spécifiquement ces outils sur les postes clients.
