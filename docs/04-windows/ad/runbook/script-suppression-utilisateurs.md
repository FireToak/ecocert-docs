---
description: Procédure de déploiement et d'utilisation du script de suppression des utilisateurs sur l'AD.
---

# Script - Suppression des utilisateurs sur l'AD

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 29/09/2026
> - **Domaine :** Windows

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Prérequis](#3-prérequis)
- [4. Utilisation du script](#4-utilisation-du-script)
- [5. Fonctionnement](#5-fonctionnement)

## 2. Contexte

Ce document décrit la procédure de déploiement et d'utilisation du script PowerShell automatisant la suppression d'utilisateurs dans l'Active Directory. Le script désactive les comptes, les déplace dans une unité d'organisation dédiée, archive leurs données personnelles et génère des journaux d'exécution. Il garantit la cohérence de l'annuaire et la sécurité des données lors du départ d'un collaborateur.

## 3. Prérequis

> [!warning] "Configuration requise"
> Vous devez impérativement créer les éléments suivants avant toute exécution :
> 
> 1. Une Unité d'Organisation (OU) nommée **Desactives** à la racine de l'OU **ECOCERT**.
> 2. Un dossier nommé **AnciensCollaborateurs** dans le partage **Données**.

**Arborescence Active Directory cible :**

```text
Ecocert/
  Desactives/
  ServiceNom/
    Utilisateurs/
    Ordinateurs/
    Groupes/
  ServiceNom/
    Utilisateurs/
    Ordinateurs/
    Groupes/
```

## 4. Utilisation du script

Le script principal se situe à l'emplacement suivant : `A:\Scripts\SupUtilisateurs.ps1` (Ou disponible sur le dépôt git : [SupUtilisateurs.ps1](./assets/script-suppression-utilisateurs/SupUtilisateurs.ps1) et [AnciensUtilisateursEcocert.csv](./assets/script-suppression-utilisateurs/AnciensUtilisateursEcocert.csv)).

4.1. **Préparer la liste des utilisateurs.** Alimentez le fichier source [AnciensUtilisateursEcocert.csv](./assets/script-suppression-utilisateurs/AnciensUtilisateursEcocert.csv) avec les utilisateurs à traiter. Il doit comporter à minima les colonnes `prenom` et `nom`.

4.2. **Exécuter le script de suppression.** Ouvrez une invite PowerShell en tant qu'administrateur et lancez le script en spécifiant si besoin les paramètres (ou laissez les valeurs par défaut définies dans le script).

```powershell
.\SupUtilisateurs.ps1 -csvPath ".\AnciensUtilisateursEcocert.csv" -archiveShare "\\ADECOCERT\AnciensCollaborateurs"
```

* `-csvPath` : Chemin d'accès au fichier CSV contenant les utilisateurs à désactiver.
* `-archiveShare` : Chemin réseau (UNC) pointant vers le dossier d'archivage des données.

## 5. Fonctionnement

Cette section détaille les commandes utilisées dans le script, expliquées pour permettre à tout administrateur, même débutant, d'en comprendre les rouages.

5.1. **Importation des modules.** Charge les outils nécessaires à l'administration de l'annuaire.

```powershell
Import-Module ActiveDirectory
```

* `Import-Module` : Importe un module PowerShell spécifique dans la session courante pour rendre ses commandes disponibles.
* `ActiveDirectory` : Le module officiel Microsoft contenant toutes les commandes (`cmdlets`) pour lire ou modifier l'AD.

5.2. **Vérification et création de l'environnement de journalisation (logs).** Assure que le dossier contenant les logs existe avant d'écrire.

```powershell
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
```

* `Test-Path` : Vérifie l'existence d'un chemin (fichier ou dossier) et renvoie un booléen (`$true` ou `$false`).
* `New-Item` : Crée un nouvel élément.
* `-ItemType Directory` : Spécifie que l'élément à créer est un dossier.
* `-Force` : Force la création de l'arborescence complète si les dossiers parents manquent.

5.3. **Lecture des données et requêtes AD.**

```powershell
$users = Import-Csv -Path $csvPath -Delimiter ","
$adUser = Get-ADUser -Identity $sam -Properties HomeDirectory, Description, MemberOf -ErrorAction Stop
```

* `Import-Csv` : Lit un fichier CSV et convertit chaque ligne en un objet PowerShell.
* `Get-ADUser` : Interroge l'Active Directory pour récupérer un objet utilisateur.
* `-Properties` : Charge des attributs spécifiques de l'utilisateur (comme `MemberOf` ou `HomeDirectory`) qui ne sont pas retournés par défaut pour des raisons d'optimisation.
* `-ErrorAction Stop` : Interrompt immédiatement le bloc en cours si une erreur survient (capturé par le bloc `catch`).

5.4. **Modification des attributs et des groupes AD.**

```powershell
$adUser.MemberOf | Where-Object { $_ -notmatch "CN=Utilisateurs du domaine" } | Remove-ADGroupMember -Members $sam -Confirm:$false
```

* `Where-Object` : Filtre les objets passant dans le pipeline. Ici, il exclut le groupe principal "Utilisateurs du domaine" car l'AD interdit de retirer un utilisateur de son groupe primaire.
* `Remove-ADGroupMember` : Retire l'utilisateur des groupes de sécurité restants.
* `-Confirm:$false` : Force l'exécution silencieuse sans demander à l'administrateur de valider chaque suppression.

5.5. **Désactivation et déplacement du compte.**

```powershell
Set-ADUser -Identity $sam -Description "Desactive le $dateStr - $($adUser.Description)"
Disable-ADAccount -Identity $sam
Move-ADObject -Identity $adUser.ObjectGUID -TargetPath $ouDesactives
```

* `Set-ADUser` : Modifie les propriétés d'un utilisateur existant (ici, on ajoute la date de désactivation à son ancienne description).
* `Disable-ADAccount` : Désactive le compte AD sans le supprimer (bonne pratique SRE pour l'auditabilité et la restauration).
* `Move-ADObject` : Déplace l'objet vers une autre Unité d'Organisation (OU).
* `$adUser.ObjectGUID` : Utilisation de l'identifiant unique et immuable de l'objet, une méthode plus fiable que le nom d'utilisateur.

5.6. **Archivage et sécurisation des données personnelles.**

```powershell
Move-Item -Path $homeDir -Destination $destDir -Force
icacls $destDir /inheritance:r /grant "Administrateurs:(OI)(CI)F" /T /Q
```

* `Move-Item` : Déplace physiquement le dossier personnel de l'utilisateur vers le partage d'archivage.
* `icacls` : Commande système pour configurer les permissions NTFS sur les fichiers/dossiers.
* `/inheritance:r` : Casse et supprime l'héritage des permissions depuis le dossier parent.
* `/grant "Administrateurs:(OI)(CI)F"` : Donne le contrôle total (`F` pour Full) au groupe Administrateurs. Les flags `(OI)(CI)` (Object Inherit, Container Inherit) assurent que ces droits s'appliquent aux sous-fichiers et sous-dossiers.
* `/T` : Applique la modification récursivement sur tout l'arbre du dossier (Tree).
* `/Q` : Exécute la commande de manière silencieuse (Quiet).
