---
description: Procédure de création, structuration et utilisation d'un playbook Ansible générique pour l'orchestration des rôles.
---

# Créer un Playbook sur Ansible

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
- [3. Fonctionnement de l'orchestration sur ECOCERT](#3-fonctionnement-de-lorchestration-sur-ecocert)
- [4. Création et structuration d'un playbook générique](#4-creation-et-structuration-dun-playbook-generique)

## 2. Contexte

Un playbook Ansible est le fichier d'orchestration principal rédigé en YAML. Il définit l'état désiré d'un ou plusieurs serveurs cibles en liant un groupe d'hôtes (défini dans l'inventaire) à une série de configurations.

Dans une démarche d'ingénierie et d'Infrastructure as Code (IaC) respectant les bonnes pratiques, le playbook ne contient généralement pas la logique d'exécution détaillée. Il agit comme un chef d'orchestre qui se charge d'appeler les différents **rôles** (composants modulaires) dans un ordre séquentiel précis. Cela permet de garder un code propre, lisible et hautement réutilisable.

## 3. Fonctionnement de l'orchestration sur ECOCERT

Au sein de l'infrastructure ECOCERT, les playbooks sont centralisés dans le répertoire `playbooks/`. Leur structure est standardisée pour permettre à tout nouvel arrivant de comprendre immédiatement le cycle de déploiement.

Un playbook type sur le dépôt commence toujours par un en-tête documenté. Il définit ensuite la cible (par exemple le groupe `pc`), gère les droits d'administration requis, importe les éventuelles variables ou fichiers de secrets (ex: mots de passe de connexion initiaux), puis délègue le travail aux rôles.

Par exemple, lors du déploiement initial d'un poste (Bootstrap), le playbook va appeler successivement le rôle d'authentification (`pc-authentification`), puis le rôle de politique de sécurité (`pc-password-check`), et enfin le rôle d'installation logicielle (`pc-update-apps`).

## 4. Création et structuration d'un playbook générique {#4-creation-et-structuration-dun-playbook-generique}

4.1. **Rédaction du fichier d'orchestration.** Création d'un nouveau fichier YAML dans le dossier `playbooks/` en respectant le template standard du projet.

> [!note] "Gestion des secrets et variables"
> Privilégiez l'utilisation de `vars_files` couplé à Ansible Vault pour l'intégration de mots de passe ou de clés sensibles, plutôt que de définir des identifiants en clair dans le bloc `vars`.

```yaml
# ---
# Type           : Playbook
# Description    : [Description courte et précise des rôles orchestrés par ce playbook]
# ---
---

- name: [Nom explicite du déploiement global]

  hosts: [groupe_cible_inventaire]
  become: true

  # vars_files:
  #   - ../secrets/[fichier_secret].yml

  vars:
    [variable_specifique]: "[valeur_par_defaut]"

  roles:
    - role: [nom-du-role-1]
    - role: [nom-du-role-2]
    - role: [nom-du-role-3]
```

- `hosts` : Définit le ou les groupes de machines (déclarés dans le fichier d'inventaire) sur lesquels les rôles seront exécutés.
- `become` : Active l'élévation de privilèges (généralement via `sudo`) sur les machines cibles, indispensable pour les tâches d'administration système.
- `vars_files` : Importe des fichiers externes contenant des variables, particulièrement utile pour l'intégration sécurisée de secrets chiffrés.
- `vars` : Permet de surcharger ou de déclarer des variables locales temporaires nécessaires à l'exécution de ce playbook spécifique.
- `roles` : Liste ordonnée des composants modulaires à appliquer. L'ordre d'appel est strictement respecté par Ansible de haut en bas.
