---
description: Procédure de création et de sécurisation d'un lecteur réseau dédié aux journaux sous Windows Server 2025.
---

# Créer un lecteur réseau pour les journaux

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

## 2. Contexte

Cette procédure détaille la réduction du volume système sur Windows Server 2025 afin de provisionner un lecteur dédié au stockage des journaux. Le volume est formaté en NTFS et monté avec la lettre `J`.

## 3. Réduction de la partition système {#3-reduction-de-la-partition-systeme}

3.1. **Redimensionnement du volume C:.** Libération de 10 GB sur le volume système afin de créer une zone non allouée pour le lecteur des journaux.

**Vérifier l'état de votre stockage avant le redimensionnement :**

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

**Redimensionnement du volume système :**

```powershell
Resize-Partition -DriveLetter C -Size 103GB
```

- `Get-Volume` : Affiche la liste des volumes locaux, leur système de fichiers et l'espace disponible/total.
- `Resize-Partition` : Commande (cmdlet) modifiant la taille physique d'une partition existante.
- `-DriveLetter C` : Identifie le lecteur ciblé par l'opération.
- `-Size 103GB` : Définit la nouvelle taille absolue souhaitée pour la partition système.

## 4. Provisionnement du lecteur

4.1. **Création et formatage.** Initialisation de la nouvelle partition sur l'espace disponible et attribution de la lettre `J`.

```powershell
New-Partition -DiskNumber 0 -UseMaximumSize -DriveLetter J | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Journaux"
```

- `New-Partition` : Crée une nouvelle partition dans l'espace non alloué.
- `-DiskNumber 0` : Cible le disque physique principal du serveur.
- `-UseMaximumSize` : Consomme la totalité de l'espace libre disponible.
- `-DriveLetter J` : Monte le volume en lui attribuant la lettre `J`.
- `|` (Pipeline) : Transmet l'objet créé à la commande suivante.
- `Format-Volume` : Prépare la partition à recevoir des données.
- `-FileSystem NTFS` : Système de fichiers requis pour une gestion stricte des permissions.
- `-NewFileSystemLabel "Journaux"` : Nomme le volume `Journaux`.

**Exemple de résultat :**

```text
DriveLetter FriendlyName FileSystemType DriveType HealthStatus OperationalStatus SizeRemaining  Size
----------- ------------ -------------- --------- ------------ ----------------- -------------  ----
J           Journaux     NTFS           Fixed     Healthy      OK                      9.96 GB 10 GB
```
