# Recette - Script de création et modification utilisateurs

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Louis MEDO
> - **Date :** 05/10/2026
> - **Domaine :** Windows (Active Directory & NTFS)

---

## 1. Contexte du test

Validation du script PowerShell `SyncUtilisateurs.ps1` de synchronisation depuis un fichier CSV. L'objectif est de vérifier la création de l'arborescence AD (UO, Groupes), la création et modification idempotente des comptes utilisateurs, ainsi que la configuration correcte des dossiers personnels et de leurs permissions NTFS.

## 2. Procédures de validation

### 2.1. Vérification de la création des Unités Organisationnelles (UO)

**Objectif :** S'assurer que les UO Service, Utilisateurs et Groupes sont bien créées dans l'UO parente `Ecocert`.

**Commande utilisée :**

```powershell
Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchBase "OU=Ecocert,DC=local,DC=ecocert4,DC=fr"
```

- `Get-ADOrganizationalUnit` : Récupère les Unités Organisationnelles dans l'Active Directory.
- `-Filter 'Name -like "*"'` : Filtre pour lister toutes les UO correspondantes.
- `-SearchBase` : Limite la recherche à l'arborescence spécifiée (ici `OU=Ecocert`).

**Résultat attendu :**

```powershell
DistinguishedName        : OU=Ecocert,DC=local,DC=ecocert4,DC=fr
LinkedGroupPolicyObjects : {}
ManagedBy                : 
Name                     : Ecocert
ObjectClass              : organizationalUnit
ObjectGUID               : c467e5c5-c386-4dc0-bfdc-58d8b7601f89
PostalCode               : 
State                    : 
StreetAddress            : 

City                     : 
Country                  : 
DistinguishedName        : OU=RH,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
LinkedGroupPolicyObjects : {}
ManagedBy                : 
Name                     : RH
ObjectClass              : organizationalUnit
ObjectGUID               : c1b90e07-bb76-4adf-ad89-b39442062ca5
PostalCode               : 
State                    : 
StreetAddress            : 

...
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.2. Vérification de la création et des attributs du compte utilisateur

**Objectif :** Contrôler que l'utilisateur est bien créé avec les bonnes propriétés (Email, UPN, Service, Dossier personnel).

**Commande utilisée :**

```powershell hl_lines="1"
Get-ADUser -Identity "prenom.nom" -Properties EmailAddress, Department, OfficePhone, Office, HomeDirectory
```

- `Get-ADUser` : Récupère les propriétés d'un compte utilisateur.
- `-Identity` : Spécifie l'identifiant unique de l'utilisateur (SamAccountName).
- `-Properties` : Charge les attributs spécifiques de l'utilisateur qui ne sont pas affichés par défaut.

**Résultat attendu :**

```powershell
EmailAddress  : p.nom@local.ecocert4.fr
Department    : Informatique
HomeDirectory : \\ADECOCERT\Donnees\prenom.nom
SamAccountName: prenom.nom
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.3. Vérification de la modification

**Objectif :** Valider qu'une modification d'un attribut (ex. : Numéro de téléphone) dans le CSV est bien mise à jour dans l'AD après relance du script.

> [!tip] "Action requise"
> Modifiez une valeur dans le fichier `UtilisateursEcocert.csv`, relancez le script, puis exécutez le test.

**Commande utilisée :**

```powershell
Get-ADUser -Identity "prenom.nom" -Properties OfficePhone | Select-Object Name, OfficePhone
```

- `Select-Object` : Filtre l'affichage pour ne retourner que les colonnes sélectionnées (`Name` et `OfficePhone`).

**Résultat attendu :**

```powershell
Name          OfficePhone
----          -----------
Prenom Nom    33 6 12 34 56 78
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.4. Vérification de l'appartenance au groupe de sécurité

**Objectif :** Vérifier que l'utilisateur est bien membre du groupe global de sécurité correspondant à son service.

**Commande utilisée :**

```powershell
Get-ADPrincipalGroupMembership -Identity "prenom.nom" | Select-Object Name, GroupCategory
```

- `Get-ADPrincipalGroupMembership` : Liste l'ensemble des groupes Active Directory dont l'utilisateur fait partie.

**Résultat attendu :**

```powershell
Name          GroupCategory
----          -------------
Informatique  Security
Domain Users  Security
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................

### 2.5. Vérification du dossier personnel et des permissions (ACL)

**Objectif :** S'assurer que le dossier réseau est créé et que les droits stricts (héritage coupé, contrôle total uniquement pour Système, Admin et Utilisateur) sont appliqués.

**Commande utilisée :**

```powershell
Get-Acl -Path "U:\Donnees\prenom.nom" | Format-List Owner, AccessToString, AreAccessRulesProtected
```

- `Get-Acl` : Lit le descripteur de sécurité (Access Control List) du dossier cible.
- `Format-List` : Formate le résultat en liste. L'attribut `AreAccessRulesProtected` à `True` confirme que l'héritage est bien désactivé.

**Résultat attendu :**

```powershell
Owner                   : LOCAL\prenom.nom
AccessToString          : BUILTIN\Administrateurs Allow  FullControl
                          AUTORITE NT\Système Allow  FullControl
                          LOCAL\prenom.nom Allow  FullControl
AreAccessRulesProtected : True
```

**Statut :**

- [ ] Ok
- [ ] KO

**Commentaire :**

................................................................................................................................................................................................................................................................................................................................................................
