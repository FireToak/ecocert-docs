# Recette - Script de suppression utilisateurs

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 05/10/2026
> - **Domaine :** Windows (Active Directory & NTFS)

---

## 1. Contexte du test

Validation du script PowerShell de suppression des utilisateurs depuis un fichier CSV. L'objectif est de s'assurer que les comptes sont correctement désactivés, déplacés dans l'UO de quarantaine, retirés de leurs groupes de sécurité et que leurs données sont archivées de façon sécurisée.

## 2. Procédures de validation

### 2.1. Vérification de la désactivation et du déplacement du compte

**Objectif :** S'assurer que le compte utilisateur est désactivé et qu'il a bien été déplacé dans l'UO `Desactives`.

**Commande utilisée :**

```powershell hl_lines="1"
Get-ADUser -Identity "prenom.nom" -Properties Enabled | Select-Object Name, Enabled, DistinguishedName
```

- `Get-ADUser` : Interroge la base de données Active Directory.
- `-Properties Enabled` : Demande spécifiquement l'attribut d'état du compte.
- `Select-Object` : Filtre la sortie pour ne conserver que les champs utiles au test.

**Résultat attendu :**

```powershell
Name       Enabled DistinguishedName
----       ------- -----------------
Prenom Nom   False CN=Prenom Nom,OU=Desactives,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de la mise à jour de la description

**Objectif :** Confirmer que la description du compte a bien été horodatée avec la mention de désactivation sans écraser l'ancienne description.

**Commande utilisée :**

```powershell
Get-ADUser -Identity "prenom.nom" -Properties Description | Select-Object Description
```

- `-Properties Description` : Charge le champ Description de l'objet utilisateur.

**Résultat attendu :**

```powershell
Description
-----------
Desactive le 05/10/2026 - Ancienne description du poste
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Vérification du retrait des groupes de sécurité

**Objectif :** Vérifier que l'utilisateur a été retiré de tous les groupes, à l'exception du groupe primaire obligatoire.

> [!warning] "Attention"
> Le script ne doit pas retirer le groupe par défaut `Utilisateurs du domaine` (Domain Users), sous peine d'erreur critique de l'API Active Directory.

**Commande utilisée :**

```powershell
Get-ADPrincipalGroupMembership -Identity "prenom.nom" | Select-Object Name
```

- `Get-ADPrincipalGroupMembership` : Récupère la liste de tous les groupes auxquels appartient l'utilisateur ciblé.

**Résultat attendu :**

```powershell
Name
----
Utilisateurs du domaine
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Vérification de l'archivage et de la sécurisation NTFS des données

**Objectif :** Contrôler que le dossier personnel a été déplacé dans le partage d'archive et que l'héritage des droits a été supprimé au profit des administrateurs seuls.

**Commande utilisée :**

```powershell
Get-Acl -Path "\\ADECOCERT\AnciensCollaborateurs\prenom.nom" | Format-List Owner, AccessToString, AreAccessRulesProtected
```

- `Get-Acl` : Lit le descripteur de sécurité complet (ACL) du dossier.
- `-Path` : Cible le chemin du nouveau répertoire archivé.
- `Format-List` : Affiche sous forme de liste pour vérifier si l'héritage est coupé (`AreAccessRulesProtected` à `True`).

**Résultat attendu :**

```powershell
Owner                   : BUILTIN\Administrateurs
AccessToString          : BUILTIN\Administrateurs Allow  FullControl
AreAccessRulesProtected : True
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
