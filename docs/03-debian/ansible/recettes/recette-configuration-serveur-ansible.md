# Recette - Configuration du serveur Ansible (CONFECOCERT)

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 19/10/2026
> - **Domaine :** Debian

---

## 1. Contexte

Validation de la préparation de l'environnement Ansible sur le serveur de centralisation **CONFECOCERT**. Ce scénario permet de s'assurer que le répertoire de travail, le dépôt Git de l'Infrastructure as Code (IaC), les droits d'accès associés à l'utilisateur `etudiant` et la sécurisation de la clé privée SSH sont correctement appliqués avant tout déploiement sur les postes clients.

## 2. Validation

### 2.1. Vérification de l'arborescence et du propriétaire

**Objectif :** S'assurer que le répertoire racine `/opt/ansible` a bien été créé et que l'utilisateur `etudiant` en est le propriétaire légitime.

**Commande utilisée :**

```bash
ls -ld /opt/ansible
```

* `ls` : Commande permettant de lister des fichiers ou répertoires.
* `-l` : Affiche les résultats au format long (inclut les droits, le propriétaire et le groupe).
* `-d` : Affiche les informations sur le répertoire lui-même et non sur son contenu.

**Résultat attendu :**

```bash
drwxr-xr-x 3 etudiant etudiant 4096 oct.  19 10:00 /opt/ansible
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de la présence et de l'état du dépôt Git

**Objectif :** Confirmer que le dépôt `ecocert-ansible` a été correctement cloné dans le répertoire cible et qu'il est synchronisé.

**Commande utilisée :**

```bash
git -C /opt/ansible/ecocert-ansible status
```

* `git` : Appelle l'outil de gestion de versions.
* `-C /opt/ansible/ecocert-ansible` : Spécifie à Git de se placer dans ce répertoire précis avant d'exécuter l'action.
* `status` : Affiche l'état actuel de l'arbre de travail (branche active, fichiers modifiés).

**Résultat attendu :**

```bash
Sur la branche main
Votre branche est à jour avec 'origin/main'.

rien à valider, la copie de travail est propre
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Vérification de la présence et des droits de la clé privée SSH

**Objectif :** Valider que la clé d'authentification de service `id_ed25519_svc-ansible` est présente à la racine du dépôt et que ses droits sont strictement limités pour des raisons de sécurité.

**Commande utilisée :**

```bash
ls -l /opt/ansible/ecocert-ansible/id_ed25519_svc-ansible
```

* `ls` : Liste les informations du fichier.
* `-l` : Affiche les détails pour permettre la lecture des permissions (qui doivent correspondre à 700).

**Résultat attendu :**

```bash
-rwx------ 1 etudiant etudiant 411 oct.  19 10:05 /opt/ansible/ecocert-ansible/id_ed25519_svc-ansible
```

> [!danger] "Risque de sécurité"
> Si les droits du fichier diffèrent de `-rwx------` (700) ou `-rw-------` (600), la clé est exposée. Le client SSH refusera d'ailleurs souvent de l'utiliser (erreur *Permissions are too open*).

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Validation syntaxique du playbook de bootstrap

**Objectif :** S'assurer que le binaire Ansible est bien installé, capable de lire l'inventaire et que la syntaxe du playbook principal est correcte, sans déclencher d'exécution réelle.

**Commande utilisée :**

```bash
cd /opt/ansible/ecocert-ansible && ansible-playbook -i inventories/production/hosts.yml playbooks/pc-bootstrap.yml --syntax-check
```

* `cd /opt/ansible/ecocert-ansible` : Se place dans le répertoire de travail.
* `&&` : Exécute la commande Ansible uniquement si le changement de dossier a réussi.
* `ansible-playbook` : Binaire d'exécution des playbooks.
* `-i inventories/production/hosts.yml` : Cible le fichier d'inventaire de production.
* `playbooks/pc-bootstrap.yml` : Le fichier de configuration (playbook) à vérifier.
* `--syntax-check` : Vérifie la validité du code YAML et des inclusions sans exécuter les tâches sur les hôtes.

**Résultat attendu :**

```bash
playbook: playbooks/pc-bootstrap.yml
```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
