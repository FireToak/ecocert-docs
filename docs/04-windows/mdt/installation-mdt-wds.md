
---
description: Installation du rôle WDS et du Microsoft Deployment Toolkit sur MDTECOCERT (Windows Server 2019) pour le déploiement de postes
---

# Installation de WDS et MDT sur le serveur MDTECOCERT (Windows Server 2019)

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Amine KADA
> - **Date :** 02/11/2026
> - **Domaine :** Windows Server 2019

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Préparation de la machine virtuelle](#3-preparation-de-la-machine-virtuelle)
- [4. Installation du rôle WDS](#4-installation-du-role-wds)
- [5. Installation de Windows ADK et MDT](#5-installation-de-windows-adk-et-mdt)
- [6. Création du Deployment Share](#6-creation-du-deployment-share)
- [7. Génération et import de l'image de démarrage WinPE](#7-generation-et-import-de-limage-de-demarrage-winpe)

## 2. Contexte

Le serveur **MDTECOCERT** héberge les services **WDS** (Windows Deployment Services) et **MDT** (Microsoft Deployment Toolkit) sous **Windows Server 2019 (GUI - Expérience de bureau)**, permettant le déploiement réseau (PXE) de postes de travail standardisés pour les différents départements d'ECOCERT. Ce serveur est intégré au domaine **local.ecocert4.fr**, s'appuie sur le contrôleur de domaine **ADECOCERT** (DNS/AD DS) et sur le serveur **DHCPECOCERT** (Kea DHCP sous Debian) pour la diffusion des options d'amorçage réseau (PXE). Un disque secondaire **S:\** est dédié au stockage des images et du partage de déploiement, séparé du disque système **C:\**.

> [!note] "Prérequis d'infrastructure"
>
> - Serveur membre du domaine `local.ecocert4.fr`, adresse IP fixe `172.16.54.4`
> - Un serveur DHCP doit déjà exister sur le réseau (DHCPECOCERT)
> - Un serveur DNS doit être disponible (ADECOCERT)
> - Au moins 20 Go d'espace disque dédié au stockage des images, isolé sur `S:\`
> - WDS peut s'installer sur Server Core via PowerShell ; c'est la **console d'administration** (`wdsmgmt.msc`) et le **Deployment Workbench MDT** qui nécessitent une version avec expérience de bureau (GUI)

## 3. Préparation de la machine virtuelle {#3-preparation-de-la-machine-virtuelle}

3.1. **Création de la VM sous Proxmox.** Créer une machine virtuelle sous Proxmox avec **Windows Server 2019 (GUI - Expérience de bureau)**, en lui attribuant un disque système `C:\` et un disque secondaire dédié au stockage des données de déploiement.

3.2. **Intégration au domaine.** Joindre la machine au domaine Active Directory existant.

```powershell title="Jonction au domaine"
Add-Computer -DomainName "local.ecocert4.fr" -Credential (Get-Credential) -Restart
```

- `-DomainName` : nom du domaine Active Directory cible
- `-Credential` : compte disposant des droits de jonction au domaine
- `-Restart` : redémarre automatiquement le serveur après la jonction

## 4. Installation du rôle WDS {#4-installation-du-role-wds}

4.1. **Ajout du rôle Windows Deployment Services (Deployment Server + Transport Server).** Installer le rôle WDS avec **tous** ses sous-services via PowerShell. L'option `-IncludeAllSubFeature` est indispensable pour obtenir à la fois le Deployment Server (fonctionnalités complètes) et le Transport Server (multicast).

```powershell title="Installation du rôle WDS complet"
Install-WindowsFeature WDS -IncludeAllSubFeature -IncludeManagementTools
```

- `WDS` : identifiant du rôle Windows Deployment Services
- `-IncludeAllSubFeature` : installe les deux sous-rôles `WDS-Deployment` et `WDS-Transport`
- `-IncludeManagementTools` : installe la console `wdsmgmt.msc` et le module PowerShell WDS

4.2. **Vérification de l'installation.** Confirmer que les deux sous-rôles sont bien installés.

```powershell title="Vérification des sous-rôles WDS"
Get-WindowsFeature -Name WDS*
```

4.3. **Initialisation du répertoire de stockage.** Configurer WDS pour stocker ses images sur le lecteur secondaire dédié plutôt que sur le disque système, en précisant le nom du serveur.

```powershell title="Initialisation de WDS"
WDSUTIL /Initialize-Server /Server:MDTECOCERT /RemInst:"S:\RemoteInstall"
```

- `/Server` : nom NetBIOS du serveur WDS
- `/RemInst` : chemin du répertoire `RemoteInstall` sur le volume `S:\`

> [!note] "Accès aux consoles de gestion"
>
> En cas de blocage de droits lors de l'ouverture de `wdsmgmt.msc`, lancer systématiquement la console avec le compte administrateur du domaine via `runas` :
>
> ```powershell
> runas /user:local.ecocert4.fr\Administrateur "mmc wdsmgmt.msc"
> ```

4.4. **Vérification de la règle de pare-feu TFTP.** S'assurer que le pare-feu Windows autorise bien le trafic TFTP, indispensable au démarrage PXE.

```powershell title="Vérification du pare-feu TFTP"
Get-NetFirewallRule -DisplayGroup "Windows Deployment Services" | Select-Object DisplayName, Enabled
```

## 5. Installation de Windows ADK et MDT

5.1. **Installation de Windows ADK.** Télécharger et installer le **Windows Assessment and Deployment Kit** correspondant à la version de Windows à déployer (ex. ADK pour Windows 10/11, compatible Server 2019), en sélectionnant au minimum les fonctionnalités de déploiement.

```text title="Composants ADK requis"
- Outils de déploiement (Deployment Tools)
```

5.2. **Installation du module complémentaire WinPE.** Installer séparément le module complémentaire **Windows PE Add-on** correspondant à la même version que l'ADK, requis pour générer les images de démarrage LiteTouch.

5.3. **Installation du Microsoft Deployment Toolkit (MDT).** Installer MDT **après** l'ADK et son module WinPE, jamais avant.

## 6. Création du Deployment Share {#6-creation-du-deployment-share}

6.1. **Création d'un dossier dédié.** Créer un dossier de partage distinct de `RemoteInstall`, à la racine du volume `S:\`, pour éviter les conflits de structure.

```powershell title="Création du dossier"
New-Item -Path "S:\DeploymentShare" -ItemType Directory
```

> [!note] "Erreur connue"
>
> Pointer le partage MDT directement sur `S:\` échoue avec le message :
> `The path 'S:\' exists but is not a valid deployment share and is not empty`
> car le dossier `RemoteInstall` y réside déjà. Utiliser impérativement un sous-dossier dédié.

6.2. **Création du partage via l'assistant MDT.** Lancer le **Deployment Workbench**, créer un nouveau Deployment Share pointant vers `S:\DeploymentShare` et nommer le partage réseau associé `MDTShare$`.

## 7. Génération et import de l'image de démarrage WinPE {#7-generation-et-import-de-limage-de-demarrage-winpe}

7.1. **Mise à jour du Deployment Share.** Lancer la génération des images de démarrage via le clic droit sur le Deployment Share > **Update Deployment Share**.

7.2. **Import dans WDS.** Importer l'image `LiteTouchPE_x64.wim` générée dans `S:\DeploymentShare\Boot\` au sein du service WDS.

```powershell title="Import de l'image de démarrage"
WDSUTIL /Add-Image /ImageType:Boot /ImageFile:"S:\DeploymentShare\Boot\LiteTouchPE_x64.wim"
```

- `/ImageType:Boot` : type d'image importée (image de démarrage PXE)
- `/ImageFile` : chemin complet du fichier WIM généré par MDT

7.3. **Vérification de l'import.** Lister les images de démarrage présentes sur le serveur WDS pour confirmer l'import.

```powershell title="Liste des images de démarrage"
WDSUTIL /Get-AllImages /Show:all
```