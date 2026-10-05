---
description: Procédure de configuration, modification et vérification du nom d'hôte (FQDN) sur un système Debian.
---

# Configuration du hostname

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

!!! note "Méta-informations"
    - **Auteur(s) :** KADA Amine
    - **Classe :** BTS SIO 2 - Option SISR
    - **Date de MAJ :** 02/10/2026
    - **Contexte :** Standardisation des noms d'hôtes (FQDN) des serveurs Debian ECOCERT

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Vérification de l'état actuel](#3-verification-de-letat-actuel)
- [4. Changement du nom d'hôte](#4-changement-du-nom-dhote)
- [5. Configuration de la résolution locale (/etc/hosts)](#5-configuration-de-la-resolution-locale-etchosts)
- [6. Vérification de la persistance et résolution](#6-verification-de-la-persistance-et-resolution)

## 2. Contexte

La configuration rigoureuse du nom d'hôte (hostname) est primordiale pour l'identification unique et standardisée des serveurs au sein de l'infrastructure ECOCERT. Ce paramètre impacte directement la journalisation centralisée, la résolution DNS interne et le bon fonctionnement de certains services. 

Dans le contexte du projet ECOCERT, le nom de domaine complet (FQDN) doit impérativement respecter la structure suivante :
`NOM_VM.local.ecocert4.fr` *(ex : `glpiecocert.local.ecocert4.fr`)*.

## 3. Vérification de l'état actuel

**3.1. Consultation des paramètres d'hôte.** 
Identifier l'identité courante du serveur avant d'appliquer la nouvelle norme de nommage.

```bash title="Terminal"
hostnamectl status
hostname
```

## 4. Changement du nom d'hôte

!!! warning "Avertissement de redémarrage de services"
    Bien que la modification du hostname soit appliquée à chaud, certains processus (ex: `syslog`) peuvent nécessiter un redémarrage pour acquérir la nouvelle valeur.

**4.1. Définition de la nouvelle identité cible.** 
Utilisation de l'outil d'administration `hostnamectl` pour modifier le hostname localement de manière persistante (remplacez `NOM_VM` par le nom court de votre serveur).

```bash title="Terminal"
sudo hostnamectl set-hostname NOM_VM
```

- `set-hostname` : Met à jour le nom d'hôte statique dans le fichier `/etc/hostname`.

## 5. Configuration de la résolution locale (/etc/hosts)

Le changement via `hostnamectl` ne met pas à jour le fichier de résolution local `/etc/hosts`. Il est impératif de le modifier manuellement pour que la machine puisse résoudre son propre FQDN sur son adresse locale. Sans cela, des commandes comme `sudo` risquent d'afficher des avertissements du type *"unable to resolve host"*.

**5.1. Édition du fichier hosts :**

```bash title="Terminal"
sudo nano /etc/hosts
```

**5.2. Ajout du FQDN ECOCERT :**
Modifiez la ligne `127.0.1.1` (ou ajoutez l'IP de votre serveur si elle est fixe) pour y intégrer le FQDN complet suivi du nom court :

```text title="/etc/hosts"
127.0.0.1       localhost
127.0.1.1       NOM_VM.local.ecocert4.fr    NOM_VM

# Lignes suivantes inchangées...
```

*Remarque : Respectez bien la syntaxe `IP FQDN Alias`.*

## 6. Vérification de la persistance et résolution

**6.1. Vérification de l'écriture disque.** 
S'assurer que le fichier de configuration statique contient le bon nom court.

```bash title="Terminal"
cat /etc/hostname
```

**6.2. Test de la résolution système.** 
Vérifier que le système d'exploitation parvient à résoudre le nouveau nom d'hôte et afficher son FQDN complet ECOCERT.

```bash title="Terminal"
hostname -f
```
*(Le résultat attendu est : `NOM_VM.local.ecocert4.fr`)*

```bash title="Terminal"
getent hosts NOM_VM
```

!!! success "Critère de réussite"
    L'opération est validée si la commande `hostname -f` renvoie bien le FQDN complet (`NOM_VM.local.ecocert4.fr`) et qu'aucune erreur réseau locale n'est remontée par le système.
