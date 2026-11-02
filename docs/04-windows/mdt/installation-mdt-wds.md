---
description: Installation et sécurisation des services WDS, Windows ADK, WinPE et MDT sur le serveur MDTECOCERT (Windows Server 2019).
---

# Installation de l'infrastructure de déploiement WDS et MDT

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
- [3. Matrice d'adressage et prérequis](#3-matrice-dadressage-et-prérequis)
- [4. Préparation du stockage et intégration au domaine](#4-préparation-du-stockage-et-intégration-au-domaine)
- [5. Déploiement des comptes de service dédiés (Active Directory)](#5-déploiement-des-comptes-de-service-dédiés-active-directory)
- [6. Installation et initialisation du rôle WDS](#6-installation-et-initialisation-du-rôle-wds)
- [7. Installation de Windows ADK, du module WinPE et de MDT](#7-installation-de-windows-adk-du-module-winpe-et-de-mdt)
- [8. Création et sécurisation du Deployment Share](#8-création-et-sécurisation-du-deployment-share)
- [9. Vérification des flux et du service](#9-vérification-des-flux-et-du-service)

## 2. Contexte

La gestion des postes de travail au sein d'ECOCERT requiert une infrastructure de déploiement réseau automatisée et reproductible. Le serveur **MDTECOCERT** héberge **WDS** (Windows Deployment Services) pour la prise en charge de l'amorçage réseau PXE et **MDT** (Microsoft Deployment Toolkit) pour l'orchestration des séquences de tâches, des images systèmes et des applications.

Afin de préserver les performances du contrôleur de domaine principal (**ADECOCERT**), ces services sont déployés sur une machine dédiée sous **Windows Server 2019** (GUI). Les données de déploiement sont isolées sur un volume secondaire dédié (`S:\`), séparant ainsi l'arborescence PXE (`RemoteInstall`) et le partage MDT (`DeploymentShare`) du volume système.

> [!warning] "Cycle de vie des composants"
>
> - **MDT :** Retiré du support actif par Microsoft au début de l'année 2026 (dernier build stable : 8456). Il demeure pleinement fonctionnel et pertinent pour un environnement de laboratoire ou de formation (BTS SIO / ECOCERT).
> - **WDS :** Maintenu sous Windows Server 2019, 2022 et 2025, mais sujet à dépréciation pour les futures versions de Windows Server au profit de solutions infonuagiques (Autopilot / Intune) ou MECM.

<a id="3-matrice-dadressage-et-prérequis"></a>
## 3. Matrice d'adressage et prérequis

| Équipement / Rôle | Nom d'hôte (FQDN) | Système d'exploitation | Adresse IP | Rôle et flux associés |
| :--- | :--- | :--- | :--- | :--- |
| `Contrôleur de domaine` | `adecocert.local.ecocert4.fr` | Windows Server 2025 | `172.16.54.1/24` | AD DS, DNS (TCP/UDP 53, TCP 389, TCP 636) |
| `Serveur DHCP` | `dhcpecocert.local.ecocert4.fr` | Debian 12 (Kea) | `172.16.54.2/24` | Distribution des baux IPv4 (UDP 67/68) |
| `Serveur WDS / MDT` | `mdtecocert.local.ecocert4.fr` | Windows Server 2019 | `172.16.54.4/24` | TFTP (UDP 69), BINL (UDP 4011), SMB (TCP 445) |
| `Passerelle par défaut` | `ec-sw-c1.local.ecocert4.fr` | Switch Cisco L3 (C1) | `172.16.54.253/24` | Routage inter-VLANs (SVI VLAN 54) |

> [!note] "Prérequis matériels et système"
>
> - Une machine virtuelle provisionnée sous Windows Server 2019 avec expérience de bureau (la console MDT Workbench nécessite une interface graphique).
> - Un disque système `C:\` de 60 Go et un disque secondaire `S:\` d'au minimum 40 Go pour le stockage des images WIM et des pilotes.
> - La connectivité réseau opérationnelle avec le contrôleur de domaine et le serveur DHCP.

<a id="4-préparation-du-stockage-et-intégration-au-domaine"></a>
## 4. Préparation du stockage et intégration au domaine

4.1. **Initialisation et formatage du volume de données S:.** Repérer le disque secondaire vierge attaché à la machine virtuelle et créer la partition NTFS dédiée aux données de déploiement.

```powershell title="Init_Storage.ps1"
Get-Disk
Initialize-Disk -Number 1 -PartitionStyle GPT
New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter S | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DEPLOY"
```

- `Get-Disk` : Liste l'ensemble des disques physiques reconnus par le système d'exploitation.
- `Initialize-Disk` : Initialise le disque vierge avec une table de partitionnement GPT.
- `New-Partition` : Alloue la totalité de l'espace disque disponible et assigne la lettre de lecteur `S:`.
- `Format-Volume` : Formate le volume en NTFS avec l'étiquette `DEPLOY`.

4.2. **Configuration de l'adressage IP statique.** Appliquer la configuration réseau statique sur l'interface connectée au VLAN Serveurs (VLAN 54).

```powershell title="Config_Network.ps1"
Get-NetAdapter
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.54.4 -PrefixLength 24 -DefaultGateway 172.16.54.253
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.54.1
```

- `New-NetIPAddress` : Assigne l'adresse IP statique `172.16.54.4` avec un masque `/24` et la passerelle par défaut `172.16.54.253` (SVI Switch L3).
- `Set-DnsClientServerAddress` : Oriente les résolutions DNS exclusivement vers le contrôleur de domaine `ADECOCERT`.

4.3. **Validation de la découverte DNS et jonction au domaine.** Vérifier que le contrôleur de domaine est résolu via son enregistrement SRV, puis joindre le serveur au domaine Active Directory.

```powershell title="Join_Domain.ps1"
Resolve-DnsName -Type SRV "_ldap._tcp.dc._msdcs.local.ecocert4.fr"
Add-Computer -DomainName "local.ecocert4.fr" -Credential (Get-Credential) -Restart
```

- `Resolve-DnsName` : Confirme la joignabilité et la découverte du service d'annuaire avant la tentative de jonction.
- `Add-Computer` : Intègre la machine au domaine `local.ecocert4.fr` et déclenche un redémarrage automatique.

4.4. **Vérification du canal sécurisé après redémarrage.** Contrôler la validité de l'authentification Kerberos entre le serveur MDT et le contrôleur de domaine.

```powershell title="Check_SecureChannel.ps1"
Test-ComputerSecureChannel -Verbose
```

- `Test-ComputerSecureChannel` : Valide l'état de la relation d'approbation (résultat attendu : `True`).

<a id="5-déploiement-des-comptes-de-service-dédiés-active-directory"></a>
## 5. Déploiement des comptes de service dédiés (Active Directory)

Afin de respecter le principe du moindre privilège, aucun compte administrateur du domaine ne doit être utilisé lors des déploiements automatisés des postes clients.

5.1. **Création des comptes sur le contrôleur de domaine (ADECOCERT).** Déclarer des comptes de service spécifiques pour la lecture du partage MDT et la jonction au domaine.

```powershell title="Create_Service_Accounts.ps1"
$pwd = Read-Host -AsSecureString "Mot de passe sécurisé"
New-ADUser -Name "svc-mdt-read" -SamAccountName "svc-mdt-read" -AccountPassword $pwd -Enabled $true -PasswordNeverExpires $true -Description "Lecture du partage MDT depuis WinPE"
New-ADUser -Name "svc-mdt-join" -SamAccountName "svc-mdt-join" -AccountPassword $pwd -Enabled $true -PasswordNeverExpires $true -Description "Jonction automatique des postes au domaine"
New-ADUser -Name "adm-mdt"      -SamAccountName "adm-mdt"      -AccountPassword $pwd -Enabled $true -Description "Administration locale du serveur MDTECOCERT"
```

- `svc-mdt-read` : Compte technique utilisé dans `Bootstrap.ini` pour monter le partage réseau `\\MDTECOCERT\MDTShare$` depuis WinPE.
- `svc-mdt-join` : Compte restreint dédié à la jonction au domaine lors de l'exécution de la séquence de tâches.
- `adm-mdt` : Compte d'administration délégué, à intégrer au groupe local `Administrateurs` de `MDTECOCERT`.

> [!note] "Délégation de contrôle pour la jonction au domaine"
>
> Sur le contrôleur de domaine, ouvrir la console **Utilisateurs et ordinateurs Active Directory** (`dsa.msc`), faire un clic droit sur l'OU cible des postes (`OU=Postes,DC=local,DC=ecocert4,DC=fr`) > **Déléguer le contrôle** > Ajouter `svc-mdt-join` > Cocher l'option *Joindre un ordinateur au domaine*.

<a id="6-installation-et-initialisation-du-rôle-wds"></a>
## 6. Installation et initialisation du rôle WDS

6.1. **Installation du rôle WDS complet.** Déployer le service de transport et le service de déploiement ainsi que les outils d'administration RSAT.

```powershell title="Install_WDS.ps1"
Install-WindowsFeature WDS -IncludeAllSubFeature -IncludeManagementTools
Get-WindowsFeature -Name WDS*
```

- `-IncludeAllSubFeature` : Installe simultanément `WDS-Deployment` (gestion des images PXE) et `WDS-Transport` (serveur TFTP/Multicast).
- `-IncludeManagementTools` : Installe la console de gestion MMC (`wdsmgmt.msc`).

6.2. **Initialisation du référentiel RemoteInstall sur S:.** Configurer l'arborescence PXE sur la partition de données dédiée plutôt que sur le volume système `C:`.

```powershell title="Init_WDS.ps1"
WDSUTIL /Initialize-Server /Server:MDTECOCERT /RemInst:"S:\RemoteInstall"
```

- `/Initialize-Server` : Crée l'arborescence TFTP/PXE, les répertoires d'amorçage (`boot\x64`) et configure le service.
- `/RemInst` : Spécifie l'emplacement du dossier `RemoteInstall` sur le volume `S:\`.

6.3. **Configuration de la réponse PXE.** Configurer WDS pour répondre aux requêtes de démarrage réseau.

```powershell title="Config_PXE_Response.ps1"
WDSUTIL /Set-Server /Server:MDTECOCERT /AnswerClients:All
```

- `/AnswerClients:All` : Autorise le serveur à répondre aux demandes d'amorçage PXE des machines connues et inconnues (adapté au laboratoire).

6.4. **Vérification de l'état du service et des permissions.** Confirmer que le service d'écoute WDS est actif et opérationnel.

```powershell title="Check_WDS.ps1"
Get-Service WDSServer
Test-Path "S:\RemoteInstall"
WDSUTIL /Get-Server /Server:MDTECOCERT /Show:Config
```

- `WDSServer` : L'état du service doit être `Running`.
- `Test-Path` : Confirme la présence du dossier racine d'installation réseau.

<a id="7-installation-de-windows-adk-du-module-winpe-et-de-mdt"></a>
## 7. Installation de Windows ADK, du module WinPE et de MDT

L'ordre d'installation de ces trois composants est strict : Windows ADK en premier, suivi du module complémentaire WinPE, puis de MDT en dernier.

7.1. **Installation du Windows Assessment and Deployment Kit (ADK).** Exécuter `adksetup.exe` et sélectionner les composants minimaux nécessaires à la création d'images.

```text title="Composants ADK sélectionnés"
- Outils de déploiement (Deployment Tools)
```

> [!note] "Séparation de WinPE depuis ADK 1809"
>
> Depuis la version 1809 de Windows 10, l'environnement de préinstallation Windows PE ne fait plus partie de l'installeur ADK principal. Il fait l'objet d'un installeur séparé (`adkwinpesetup.exe`) qui doit impérativement être installé avec le même numéro de build que l'ADK.

7.2. **Installation de l'Add-on Windows PE pour ADK.** Exécuter `adkwinpesetup.exe` pour déployer les fichiers sources WinPE x64 (`winpe.wim`).

7.3. **Installation du Microsoft Deployment Toolkit (MDT).** Exécuter le package `MicrosoftDeploymentToolkit_x64.msi` pour installer la console **Deployment Workbench** et le module PowerShell associé.

7.4. **Validation de la présence des composants.** Contrôler la bonne présence des bibliothèques WinPE et du module MDT sur le disque système.

```powershell title="Check_ADK_MDT.ps1"
Test-Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64"
Test-Path "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
```

- Les deux commandes doivent impérativement renvoyer `True`.

<a id="8-création-et-sécurisation-du-deployment-share"></a>
## 8. Création et sécurisation du Deployment Share

8.1. **Création du dossier physique.** Créer un dossier distinct à la racine du disque `S:\` pour éviter tout conflit avec `RemoteInstall`.

```powershell title="Create_MDT_Folder.ps1"
New-Item -Path "S:\DeploymentShare" -ItemType Directory
```

8.2. **Publication et sécurisation du partage SMB.** Créer le partage administratif masqué (`MDTShare$`) et appliquer des permissions NTFS et SMB strictes.

```powershell title="Config_MDT_Permissions.ps1"
New-SmbShare -Name 'MDTShare$' -Path 'S:\DeploymentShare' -FullAccess "BUILTIN\Administrateurs" -ReadAccess "local\svc-mdt-read"
icacls "S:\DeploymentShare" /inheritance:r
icacls "S:\DeploymentShare" /grant "BUILTIN\Administrateurs:(OI)(CI)F"
icacls "S:\DeploymentShare" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F"
icacls "S:\DeploymentShare" /grant "local\svc-mdt-read:(OI)(CI)RX"
```

- `New-SmbShare` : Crée le partage `\\MDTECOCERT\MDTShare$` avec des droits de lecture réservés au compte `svc-mdt-read`.
- `/inheritance:r` : Supprime l'héritage des droits depuis la racine de `S:\`.
- `(OI)(CI)RX` : Accorde les droits de lecture et d'exécution transmissibles aux sous-dossiers et fichiers.

8.3. **Déclaration du Deployment Share dans la console MDT.** Enregistrer le partage de déploiement via le fournisseur PowerShell MDT.

```powershell title="Register_DeploymentShare.ps1"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "S:\DeploymentShare" -Description "ECOCERT Deployment Share" -NetworkPath '\\MDTECOCERT\MDTShare$' -Verbose | Add-MDTPersistentDrive -Verbose
```

- `Import-Module` : Charge les cmdlets et le fournisseur PowerShell MDT (`MDTProvider`).
- `New-PSDrive` : Enregistre le lecteur virtuel `DS001:` pointant vers le dossier physique et son chemin réseau UNC.

<a id="9-vérification-des-flux-et-du-service"></a>
## 9. Vérification des flux et du service

9.1. **Contrôle des règles de pare-feu WDS et SMB.** Vérifier que le pare-feu local autorise bien les ports indispensables au démarrage PXE et au téléchargement des images.

```powershell title="Check_Firewall.ps1"
Get-NetFirewallRule -Direction Inbound -Enabled True | ForEach-Object {
    $r = $_; $pf = $r | Get-NetFirewallPortFilter
    if ($pf.Protocol -eq 'UDP' -and $pf.LocalPort -match '^(67|69|4011)$') {
        [pscustomobject]@{ Regle = $r.DisplayName; Protocole = $pf.Protocol; Port = $pf.LocalPort; Profil = $r.Profile }
    }
}
```

- **Ports requis :**
  - **UDP 67/68 :** Découverte et réponses DHCP / PXE.
  - **UDP 69 :** Transfert TFTP du binaire de démarrage réseau.
  - **UDP 4011 :** Port BINL (Boot Information Negotiation Layer) géré par WDS.
  - **TCP 445 :** Accès SMB au partage `\\MDTECOCERT\MDTShare$`.

L'infrastructure WDS/MDT est désormais prête pour la configuration des séquences de tâches, de l'image WinPE et du serveur DHCP détaillée dans la procédure de configuration.
