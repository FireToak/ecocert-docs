---
description: Procédure de déploiement et d'utilisation du script de synchronisation AD des utilisateurs ECOCERT.
---

# Script - Synchronisation des utilisateurs sur l'AD

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
- [3. Prérequis](#3-prerequis)
- [4. Utilisation du script](#4-utilisation-du-script)
- [5. Fonctionnement](#5-fonctionnement)
- [6. Points de vigilance](#6-points-de-vigilance)

## 2. Contexte

Cette procédure décrit le déploiement et le fonctionnement du script d'automatisation pour la création et la modification des utilisateurs Active Directory. Ce script PowerShell est "idempotent" : il peut être exécuté plusieurs fois sans créer de doublons, synchronisant uniquement les différences à partir d'un fichier source CSV. Il configure les attributs AD, génère les dossiers personnels sécurisés et affecte les groupes automatiquement.

## 3. Prérequis {#3-prerequis}

Avant la première exécution, l'Unité Organisationnelle (OU) racine "Ecocert" doit impérativement exister dans l'Active Directory, le script ne la créant pas lui-même pour des raisons de sécurité.

3.1. **Créer l'Unité Organisationnelle de base.**
Ouvrir la console *Utilisateurs et ordinateurs Active Directory* (ADUC), faire un clic droit sur le nom de domaine, aller dans **Nouveau > Unité d'organisation**, nommer l'unité `Ecocert` (en activant la protection contre la suppression accidentelle).

Le script génère ensuite dynamiquement la sous-arborescence pour chaque service identifié dans le fichier CSV. L'architecture cible est la suivante :

```text
Ecocert/
  ServiceNom/
    Utilisateurs/
    Groupes/
  ServiceNom/
    Utilisateurs/
    Groupes/
```

> [!note] "Gestion de l'arborescence"
> Le script provisionne automatiquement les OUs "ServiceNom", "Utilisateurs" et "Groupes". Si des groupes de sécurité associés au service n'existent pas, ils sont également créés à la volée.

## 4. Utilisation du script

Le script principal se situe à l'emplacement suivant : `A:\Scripts\SyncUtilisateurs.ps1` (Ou disponible sur le dépôt git : [SyncUtilisateurs.ps1](./assets/script-creation-modification-utilisateurs/SyncUtilisateurs.ps1) et [UtilisateursEcocert.csv](./assets/script-creation-modification-utilisateurs/UtilisateursEcocert.csv)).

Le script analyse le fichier CSV pour vérifier, créer ou mettre à jour les utilisateurs.

4.1. **Exécuter la synchronisation AD.** Depuis une console PowerShell lancée avec des privilèges d'administration :

```powershell
.\SyncUtilisateurs.ps1 -CsvPath ".\UtilisateursEcocert.csv" -Domaine "local.ecocert4.lan" -BaseOU "OU=Ecocert,DC=local,DC=ecocert4,DC=fr"
```

- `-CsvPath` : Spécifie le chemin d'accès vers le fichier CSV source.
- `-Domaine` : Définit le nom de domaine (pour les UPN et e-mails).
- `-BaseOU` : Détermine le Distinguished Name (DN) de l'OU racine.

## 5. Fonctionnement {#5-fonctionnement}

Cette section détaille le code étape par étape pour comprendre la logique métier (idempotence) et les commandes techniques (Active Directory, système de fichiers, ACLs).

### 5.1. Initialisation et lecture des données

```powershell
Import-Module ActiveDirectory
$Utilisateurs = Import-Csv -Path $CsvPath -Delimiter ","
```

- `Import-Module ActiveDirectory` : Charge en mémoire la bibliothèque de commandes permettant d'interagir avec l'annuaire (Get-ADUser, New-ADUser, etc.).
- `Import-Csv` : Ouvre le fichier CSV, utilise la virgule comme délimiteur, et transforme chaque ligne en un objet PowerShell. La boucle `ForEach ($User in $Utilisateurs)` permet ensuite de traiter chaque personne individuellement.

### 5.2. Validation des données par Expression Régulière (Regex)

Le script vérifie la conformité du numéro de téléphone avant de tenter quoi que ce soit dans l'AD.

```powershell
If ($User.Telephone -notmatch "^33 [1-9] \d{2} \d{2} \d{2} \d{2}$") {
    Continue
}
```

- `-notmatch` : Opérateur de comparaison qui renvoie "Vrai" si la valeur ne respecte pas le modèle (regex) fourni.
- `^` et `$` : Indiquent respectivement le début et la fin stricts de la chaîne (rien ne doit dépasser avant ou après).
- `33 ` : Exige exactement la chaîne "33 ".
- `[1-9]` : Exige un chiffre de 1 à 9 (interdit le 0 au début du numéro).
- `\d{2}` : `\d` signifie "digit" (un chiffre). `{2}` indique qu'il en faut exactement deux d'affilée.
- `Continue` : Si le test échoue (le numéro est mauvais), cette commande stoppe le traitement de cet utilisateur précis et passe directement au suivant dans le CSV.

### 5.3. Vérification et création des Unités Organisationnelles (OU)

Pour éviter les erreurs "Objet introuvable", le script s'assure que l'arborescence existe.

```powershell
Get-ADOrganizationalUnit -Filter "Name -eq '$($User.Service)'" -SearchBase $BaseOU -SearchScope OneLevel -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name $User.Service -Path $BaseOU
```

- `Get-ADOrganizationalUnit` : Cherche une OU spécifique.
- `-SearchBase` et `-SearchScope OneLevel` : Limite la recherche à la racine spécifiée (`$BaseOU`) et uniquement au premier niveau (pas dans les sous-dossiers), ce qui optimise les performances.
- `-ErrorAction SilentlyContinue` : Si l'OU n'existe pas, PowerShell génère normalement une erreur en texte rouge. Cet argument masque l'erreur pour permettre au script de gérer l'absence proprement via un `If (-not ...)`.
- `New-ADOrganizationalUnit` : Crée l'OU si la vérification précédente a échoué.

### 5.4. Création des utilisateurs

```powershell
$SecurePwd = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force
$NewUserParams = @{ Name = "..."; Enabled = $true; AccountPassword = $SecurePwd ... }
New-ADUser @NewUserParams
```

- `ConvertTo-SecureString` : L'Active Directory refuse les mots de passe en texte clair. Cette commande chiffre la chaîne de caractères en mémoire (SecureString) pour qu'elle soit acceptée par `New-ADUser`.
- `@NewUserParams` : C'est ce qu'on appelle le **Splatting**. Au lieu d'écrire une commande illisible avec 15 arguments (`New-ADUser -Name "..." -Enabled $true ...`), on stocke tous les arguments dans un tableau de hachage (dictionnaire) qu'on passe à la commande avec l'arobase `@`.

### 5.5. Modification des utilisateurs

Si l'utilisateur existe déjà, le script vérifie s'il doit le mettre à jour.

```powershell
$PropsToUpdate = @{}
If ($ADUser.Department -ne $User.Service) { $PropsToUpdate.Department = $User.Service }
If ($PropsToUpdate.Count -gt 0) { Set-ADUser -Identity $SamAccountName @PropsToUpdate }
```

- `$PropsToUpdate = @{}` : Initialise un tableau vide.
- `-ne` (Not Equal) : Compare la valeur actuelle de l'AD (`$ADUser.Department`) avec celle du CSV (`$User.Service`). Si elles sont différentes, l'attribut est ajouté à la liste des mises à jour.
- `$PropsToUpdate.Count -gt 0` : Vérifie si le tableau contient au moins un élément (Greater Than 0). Si oui, `Set-ADUser` applique uniquement les changements ciblés, minimisant les requêtes inutiles sur le contrôleur de domaine.

### 5.6. Maîtrise des droits NTFS (ACLs) sur les dossiers personnels

C'est la partie la plus critique : sécuriser le dossier pour que seul l'utilisateur (et le système) puisse y accéder.

```powershell
$Acl = Get-Acl $UserFolderPath
$Acl.SetAccessRuleProtection($true, $false)
```

- `Get-Acl` : Récupère la liste de contrôle d'accès (Access Control List) actuelle du dossier.
- `SetAccessRuleProtection($true, $false)` : Coupe l'héritage parent. Le premier `$true` bloque l'héritage depuis `U:\Données\`, le `$false` supprime les droits précédemment hérités pour partir d'une page blanche.

```powershell
$AdminSID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
$AdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule($AdminSID, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.AddAccessRule($AdminRule)
Set-Acl -Path $UserFolderPath -AclObject $Acl
```

- `SecurityIdentifier (SID)` : Identifiant unique. Utiliser les **Well-Known SIDs** (comme `S-1-5-32-544` pour le groupe Administrateurs locaux ou `S-1-5-18` pour SYSTEM) est une excellente pratique SRE. Cela garantit que le script fonctionne sur un serveur en français, en anglais, ou en allemand (le nom "Administrateurs" change, le SID jamais).
- `FileSystemAccessRule` : Instancie la règle concrète de sécurité. Ici on autorise (`Allow`) le contrôle total (`FullControl`).
- `ContainerInherit,ObjectInherit` : Indique que ce droit s'appliquera aux fichiers et dossiers créés à l'intérieur.
- `AddAccessRule` : Ajoute la règle dans l'objet mémoire `$Acl`.
- `Set-Acl` : Sauvegarde définitivement les nouveaux droits sur le dossier physique.

### 5.7. Affectation aux groupes

```powershell
$UserGroupMemberships = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty Name
If ($UserGroupMemberships -notcontains $GroupName) {
    Add-ADGroupMember -Identity $GroupName -Members $SamAccountName
}
```

- `Get-ADPrincipalGroupMembership` : Récupère tous les groupes dont l'utilisateur fait partie.
- `Select-Object -ExpandProperty Name` : Au lieu de retourner des objets complexes, extrait uniquement la liste des noms des groupes sous forme de texte simple.
- `-notcontains` : Vérifie si la liste extraite ne contient pas le groupe cible. Si c'est le cas, `Add-ADGroupMember` l'ajoute.

## 6. Points de vigilance

> [!warning] "Numéros de téléphone"
> Le contrôle par regex (`^33 [1-9] \d{2} \d{2} \d{2} \d{2}$`) est strict. Un numéro mal formaté dans le CSV entraînera le rejet pur et simple de la ligne (aucune création ni mise à jour).

- **Mot de passe initial :** Les nouveaux comptes reçoivent `ChangezMoiSVP@37ù`. Le paramètre `ChangePasswordAtLogon = $true` les force à le modifier à la première ouverture de session.
- **Modification des services :** Si un service change de nom dans le CSV, le script créera une nouvelle arborescence. Il ne renommera pas l'ancienne OU ni l'ancien groupe. L'administrateur doit gérer les reliquats manuellement ou via une procédure de nettoyage.
