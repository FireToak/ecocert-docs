# Recette - Application playbook Bootstrap Ansible

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 19/10/2026
> - **Domaine :** Debian

---

## 1. Contexte

Validation de la bonne exécution du playbook de bootstrap Ansible sur les serveurs Debian cibles. Ce scénario vérifie l'application correcte des rôles définis dans le dépôt : configuration de l'authentification (`pc-authentification`), durcissement de la politique des mots de passe (`pc-password-check`), et la mise à jour des paquets système (`pc-update-apps`).

## 2. Validation

### 2.1. Vérification de la politique de mot de passe (pwquality)

**Objectif :** S'assurer que le fichier `pwquality.conf` a bien été déployé avec les règles de complexité attendues.

**Commande utilisée :**

*Depuis le poste client.*

~~~bash
cat /etc/security/pwquality.conf | grep -E "^[[:space:]]*(minlen|minclass)[[:space:]]*="
~~~

* `cat` : Affiche le contenu intégral du fichier de configuration.
* `|` (pipe) : Redirige la sortie de `cat` vers l'entrée de la commande `grep`.
* `grep` : Commande permettant de rechercher des chaînes de caractères.
* `-E` : Active les expressions régulières étendues ; l'expression ancrée ne retient que les affectations actives de `minlen` et `minclass`, en ignorant les commentaires.

**Résultat attendu :**

~~~bash
minlen = 12
minclass = 4
~~~

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de l'accès SSH via clé de service (Authentification)

**Objectif :** Valider que la clé publique de service a bien été déployée sur l'hôte et permet l'authentification sans mot de passe.

**Commande utilisée :**

*Depuis le serveur de configuration.*

```bash
ssh -i ./id_ed25519_svc-ansible -o BatchMode=yes svc-ansible@<IP_CIBLE> "echo 'Connexion OK'"
```

* `ssh` : Outil client pour ouvrir une session distante sécurisée.
* `-i ./id_ed25519_svc-ansible` : Spécifie le chemin vers le fichier d'identité (clé privée) à utiliser pour l'authentification.
* `-o BatchMode=yes` : Désactive les demandes interactives de mot de passe (échoue directement si la clé n'est pas acceptée).
* `svc-ansible@<IP_CIBLE>` : Spécifie l'utilisateur de destination et l'adresse IP de l'hôte à tester.
* `"echo 'Connexion OK'"` : Commande exécutée à distance une fois connecté pour confirmer le succès.

**Résultat attendu :**

```bash
Connexion OK

```

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Vérification de l'installation des paquets requis

**Objectif :** S'assurer que les paquets de base (git, curl, vim, btop, etckeeper) ont été correctement installés par le playbook.

**Commande utilisée :**

*Depuis le poste client.*

```bash
dpkg -l git curl vim btop etckeeper
```

* `dpkg` : Outil bas niveau de gestion des paquets sous Debian.
* `-l` : Argument demandant d'afficher la liste et l'état actuel des paquets spécifiés.
* `git curl vim btop etckeeper` : Liste explicite des paquets ciblés par la vérification.

**Résultat attendu :**

```bash
Souhait=inconnU/Installé/retiré/Purgé/H=à garder
| État=Non/Installé/fichier-Config/dépaqUeté/échec-conFig/H=semi-installé/W=attend-traitement-déclenchements
|/ Err?=(aucune)/besoin Réinstallation (État,Err: majuscule=mauvais)
||/ Nom            Version      Architecture Description
+++-==============-============-============-=================================
ii  btop           ...          ...          ...
ii  curl           ...          ...          ...
ii  etckeeper      ...          ...          ...
ii  git            ...          ...          ...
ii  vim            ...          ...          ...

```

> [!note] "Indicateur d'état"
> Le statut `ii` en début de ligne est indispensable : le premier `i` indique que l'installation était souhaitée, le second `i` confirme que le paquet est actuellement installé avec succès.

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Vérification de l'utilisateur svc-ansible et de sa clé publique

**Objectif :** Confirmer que le compte de service `svc-ansible` existe bien sur l'hôte cible et que la clé publique permettant l'authentification sans mot de passe d'Ansible y est bien configurée.

**Commande utilisée :**

*Depuis le poste client.*

```bash
id svc-ansible && sudo cat /home/svc-ansible/.ssh/authorized_keys
```

* `id` : Affiche les informations systèmes (UID, GID et groupes) associés à un utilisateur.
* `svc-ansible` : Nom de l'utilisateur de service à vérifier.
* `&&` : Opérateur logique permettant d'enchaîner une seconde commande uniquement si la première (la vérification de l'utilisateur) s'est terminée sans erreur.
* `sudo` : Exécute la commande suivante avec les privilèges d'administration (utile si on exécute le test depuis un autre compte admin).
* `cat` : Affiche le contenu brut du fichier ciblé.
* `/home/svc-ansible/.ssh/authorized_keys` : Chemin absolu vers le fichier contenant les clés publiques SSH autorisées pour ce compte.

**Résultat attendu :**

```bash
uid=1001(svc-ansible) gid=1001(svc-ansible) groupes=1001(svc-ansible),27(sudo)
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... svc-ansible@management-node
```

> [!tip] "Bonne pratique"
> Vérifiez dans le retour de la commande `id` que l'utilisateur `svc-ansible` appartient bien au groupe `sudo` pour garantir le bon fonctionnement des directives `become: true` lors des futures exécutions de playbooks.

**Statut :**

* [ ] Ok
* [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
