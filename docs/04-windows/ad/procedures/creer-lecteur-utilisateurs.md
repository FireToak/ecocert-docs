---
description: Procédure de création et de sécurisation d'un lecteur réseau utilisateur sous Windows Server 2025.
---

# Créer un lecteur réseau pour les utilisateurs

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] Informations
>
> - **Auteur :** Louis MEDO
> - **Date :** 29/09/2026
> - **Domaine :** Windows

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Réduction de la partition système](#3-reduction-de-la-partition-systeme)
- [4. Provisionnement du lecteur](#4-provisionnement-du-lecteur)
- [5. Partage](#5-partage)

## 2. Contexte

Cette procédure détaille la réduction du volume système sur Windows Server 2025 afin de provisionner un lecteur réseau destiné aux utilisateurs du domaine `local.ecocert4.lan`. Le dossier est partagé en SMB et sécurisé avec des droits de modification pour le groupe `Utilisateurs du domaine`.

## 3. Réduction de la partition système {#3-reduction-de-la-partition-systeme}

3.1. **Redimensionnement du volume C:.** Libération de l'espace disque afin de créer une zone non allouée.

**Vérifier l'état du stockage avant le redimensionnement :**

```powershell
Get-Volume
```

**Exemple de résultat :**

```powershell
DriveLetter FriendlyName          FileSystemType DriveType HealthStatus OperationalStatus SizeRemaining     Size
----------- ------------          -------------- --------- ------------ ----------------- -------------     ----
C                                 NTFS           Fixed     Healthy      OK                     94.36 GB 118.9 GB
                                  NTFS           Fixed     Healthy      OK                    147.26 MB   904 MB
```

**Redimensionner le volume système :**

```powershell
Resize-Partition -DriveLetter C -Size 80GB
```

- `Get-Volume` : Affiche la liste des volumes locaux, leur système de fichiers et l'espace disponible/total.
- `Resize-Partition` : Modifie la taille physique d'une partition existante.
- `-DriveLetter C` : Identifie le lecteur ciblé par l'opération.
- `-Size 80GB` : Définit la nouvelle taille absolue souhaitée pour la partition.

## 4. Provisionnement du lecteur

4.1. **Création et formatage.** Initialisation de la nouvelle partition sur l'espace disponible.

```powershell
New-Partition -DiskNumber 0 -UseMaximumSize -DriveLetter U | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Utilisateurs"
```

- `New-Partition` : Crée une nouvelle partition dans l'espace non alloué.
- `-DiskNumber 0` : Cible le disque physique principal du serveur.
- `-UseMaximumSize` : Consomme la totalité de l'espace libre disponible.
- `-DriveLetter A` : Monte le volume en lui attribuant la lettre `A`.
- `Format-Volume` : Prépare la partition à recevoir des données.
- `-FileSystem NTFS` : Utilise le système de fichiers nécessaire à la gestion des permissions Windows.
- `-NewFileSystemLabel` : Nomme le volume `Utilisateurs`.

## 5. Partage

5.1. **Création du répertoire partagé.** Création du dossier racine destiné aux fichiers utilisateurs.

```powershell
New-Item -Path "U:\Donnees" -ItemType Directory
```

- `New-Item` : Crée un nouvel élément dans l'arborescence.
- `-Path "A:\Donnees"` : Définit l'emplacement du dossier partagé.
- `-ItemType Directory` : Indique que l'élément créé est un répertoire.

5.2. **Déploiement du partage SMB.** Publication du dossier sur le réseau avec des droits de modification pour les utilisateurs du domaine.

```powershell
New-SmbShare -Name "Donnees" -Path "U:\Donnees" -ChangeAccess "Utilisateurs du domaine" -FolderEnumerationMode AccessBased
```

- `New-SmbShare` : Crée le point de montage réseau via le protocole SMB.
- `-Name "Donnees"` : Définit le nom du partage visible sur le réseau.
- `-Path "A:\Données"` : Indique le répertoire publié.
- `-ChangeAccess "Utilisateurs du domaine"` : Autorise la modification des fichiers aux utilisateurs appartenant au groupe du domaine.
- `-FolderEnumerationMode AccessBased` : Masque les fichiers et dossiers auxquels l'utilisateur n'a pas accès.

Le partage est accessible depuis un poste Windows avec le chemin suivant :

```text
\\SERVEUR\\PartageUtilisateurs
```
