---
description: Configuration de l'architecture WinPE x64, des séquences de tâches MDT et de l'amorçage PXE sur Kea DHCP pour Windows Server 2019.
---

# Configuration du déploiement PXE (MDT / WDS / Kea DHCP)

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
- [3. Matrice d'adressage et flux réseau](#3-matrice-dadressage-et-flux-réseau)
- [4. Configuration de l'architecture WinPE (x64)](#4-configuration-de-larchitecture-winpe-x64)
- [5. Résolution des conflits de montage DISM](#5-résolution-des-conflits-de-montage-dism)
- [6. Intégration du système d'exploitation et des applications](#6-intégration-du-système-dexploitation-et-des-applications)
- [7. Configuration de la séquence de tâches et des règles](#7-configuration-de-la-séquence-de-tâches-et-des-règles)
- [8. Génération de l'image LiteTouch et publication dans WDS](#8-génération-de-limage-litetouch-et-publication-dans-wds)
- [9. Configuration de l'amorçage PXE sur Kea DHCP (Debian)](#9-configuration-de-lamorçage-pxe-sur-kea-dhcp-debian)
- [10. Recette et validation du déploiement](#10-recette-et-validation-du-déploiement)

## 2. Contexte

Une fois les composants **WDS** et **MDT** déployés sur le serveur **MDTECOCERT**, la configuration opérationnelle du système de déploiement permet d'automatiser l'installation des postes clients de l'infrastructure ECOCERT.

Cette procédure standardise la génération de l'image de préinstallation **WinPE** (restreinte à l'architecture 64 bits), le paramétrage des règles d'automatisation (`CustomSettings.ini`), l'orchestration des flux PXE hybrides (BIOS Legacy et UEFI) sur le serveur **Kea DHCP** hébergé sous Debian, ainsi que la validation complète d'un déploiement sur machine cliente.

<a id="3-matrice-dadressage-et-flux-réseau"></a>
## 3. Matrice d'adressage et flux réseau

| Équipement | FQDN | Rôle | IP | Ports d'écoute |
| :--- | :--- | :--- | :--- | :--- |
| `MDTECOCERT` | `mdtecocert.local.ecocert4.fr` | Serveur WDS / MDT | `172.16.54.4` | UDP 69 (TFTP), UDP 4011 (BINL), TCP 445 (SMB) |
| `DHCPECOCERT` | `dhcpecocert.local.ecocert4.fr` | Serveur Kea DHCP | `172.16.54.2` | UDP 67 (DHCP Server), UDP 68 (DHCP Client) |
| `ADECOCERT` | `adecocert.local.ecocert4.fr` | Contrôleur de domaine | `172.16.54.1` | TCP/UDP 53 (DNS), TCP 389/636 (LDAP/LDAPS) |
| `Poste Client` | `cli-test.local.ecocert4.fr` | VM de test PXE | DHCP | N/A |

<a id="4-configuration-de-larchitecture-winpe-x64"></a>
## 4. Configuration de l'architecture WinPE (x64)

4.1. **Origine de l'anomalie de génération x86.** Par défaut, le Deployment Workbench tente de compiler les images de démarrage pour les architectures **x86** et **x64**. Si le module WinPE x86 n'est pas présent dans l'ADK installé (ce qui est le cas des distributions ADK récentes), DISM échoue avec l'erreur suivante :

```text title="Erreur de compilation DISM"
Unable to open the specified WIM file
DISM /Set-TargetPath failed, rc = 1
```

4.2. **Restriction de la plateforme à x64.** Configurer le Deployment Share pour ne générer que l'image de démarrage 64 bits indispensable au parc moderne.

```text title="Navigation dans le Deployment Workbench"
Deployment Shares > ECOCERT Deployment Share > Clic droit > Properties
```

- Onglet **General** : Dans *Platforms Supported*, décocher la case **x86** et conserver uniquement **x64**.
- Onglet **Windows PE** : Sélectionner la plateforme **x64**, vérifier que l'option *Generate a Lite Touch boot image* est cochée, puis valider par **Appliquer**.

<a id="5-résolution-des-conflits-de-montage-dism"></a>
## 5. Résolution des conflits de montage DISM

Lorsqu'une génération d'image WinPE est interrompue brutalement, des points de montage WIM orphelins peuvent verrouiller les fichiers temporaires et interdire toute recompilation ultérieure.

5.1. **Identification des répertoires de montage verrouillés.** Vérifier la présence de montages actifs sur le système.

```powershell title="Check_Mounted_WIM.ps1"
dism /Get-MountedWimInfo
```

- `Get-MountedWimInfo` : Liste les images WIM actuellement montées dans le répertoire temporaire `AppData\Local\Temp`.

5.2. **Nettoyage et purge des points de montage.** Si un montage orphelin est détecté, le démonter proprement ou exécuter la purge globale des descripteurs DISM.

```powershell title="Clean_DISM_Mounts.ps1"
dism /Cleanup-Mountpoints
```

- `Cleanup-Mountpoints` : Libère l'ensemble des points de montage orphelins et réinitialise l'état du pilote de filtre DISM (`wimmount.sys`).

<a id="6-intégration-du-système-dexploitation-et-des-applications"></a>
## 6. Intégration du système d'exploitation et des applications

6.1. **Importation du média d'installation Windows.** Monter l'image ISO de Windows (ex: Windows 10/11 ou Windows Server) sur un lecteur virtuel (ex: `D:\`) et l'importer dans l'arborescence MDT.

```powershell title="Import_OS.ps1"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "S:\DeploymentShare" -ErrorAction SilentlyContinue
Import-MDTOperatingSystem -Path "DS001:\Operating Systems" -SourcePath "D:\" -DestinationFolder "Windows_10_Pro_x64" -Verbose
```

- `-SourcePath` : Lecteur contenant l'image ISO montée.
- `-DestinationFolder` : Dossier créé dans `S:\DeploymentShare\Operating Systems` contenant les fichiers d'installation.

6.2. **Organisation des pilotes de périphériques.** Dans la rubrique **Out-of-Box Drivers**, structurer les pilotes par système d'exploitation et modèle matériel, et injecter les pilotes réseau/stockage dans l'image WinPE afin d'assurer la reconnaissance du disque dur et de la carte réseau dès le démarrage PXE.

<a id="7-configuration-de-la-séquence-de-tâches-et-des-règles"></a>
## 7. Configuration de la séquence de tâches et des règles

7.1. **Création de la séquence de tâches standard.** Dans **Deployment Workbench > Task Sequences**, créer une séquence basée sur le modèle **Standard Client Task Sequence** (ID : `DEPLOY-W10`, Nom : *Déploiement Windows 10 ECOCERT*), puis sélectionner le système d'exploitation importé à l'étape précédente.

7.2. **Automatisation des paramètres dans CustomSettings.ini.** Éditer les règles du partage de déploiement pour pré-renseigner la jonction au domaine et limiter les interactions utilisateur.

```ini title="S:\DeploymentShare\Control\CustomSettings.ini"
[Settings]
Priority=Default
Properties=

[Default]
OSInstall=Y
SkipBDDWelcome=YES
SkipAdminPassword=YES
AdminPassword=MotDePasseSecurise2026!
JoinDomain=local.ecocert4.fr
DomainAdmin=svc-mdt-join
DomainAdminDomain=local.ecocert4.fr
MachineObjectOU=OU=Postes,DC=local,DC=ecocert4,DC=fr
SkipUserData=YES
SkipComputerBackup=YES
SkipTimeZone=YES
TimeZoneName=Romance Standard Time
```

- `DomainAdmin` : Utilise le compte de service dédié `svc-mdt-join` disposant des droits délégués sur l'OU cible.
- `MachineObjectOU` : Assigne automatiquement les nouvelles machines à l'Unité d'Organisation `OU=Postes`.

<a id="8-génération-de-limage-litetouch-et-publication-dans-wds"></a>
## 8. Génération de l'image LiteTouch et publication dans WDS

8.1. **Génération de l'image de démarrage WinPE.** Déclencher la compilation complète des composants LiteTouch x64 via PowerShell.

```powershell title="Build_WinPE_WIM.ps1"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
Update-MDTDeploymentShare -Path "DS001:" -Force -Verbose
```

- `Update-MDTDeploymentShare` : Génère l'image de boot `LiteTouchPE_x64.wim` dans le dossier `S:\DeploymentShare\Boot\`.
- `-Force` : Réécrit intégralement l'image sans réutiliser d'anciens caches temporaires.

8.2. **Importation de l'image de démarrage dans WDS.** Déclarer l'image WIM générée en tant qu'image de démarrage réseau au sein du rôle WDS.

```powershell title="Import_WDS_BootImage.ps1"
WDSUTIL /Add-Image /ImageFile:"S:\DeploymentShare\Boot\LiteTouchPE_x64.wim" /ImageType:Boot /Server:MDTECOCERT
```

- `/ImageType:Boot` : Spécifie que l'image est dédiée à l'environnement de préinstallation PXE.
- `/ImageFile` : Chemin absolu vers l'image WinPE compilée par MDT.

8.3. **Vérification de l'image active dans WDS.** Confirmer que WDS propose bien l'image LiteTouch aux clients réseau.

```powershell title="Check_Boot_Images.ps1"
WDSUTIL /Get-AllImages /Server:MDTECOCERT /Show:Boot
```

<a id="9-configuration-de-lamorçage-pxe-sur-kea-dhcp-debian"></a>
## 9. Configuration de l'amorçage PXE sur Kea DHCP (Debian)

Sur une infrastructure combinant des postes en mode **BIOS hérité** et des postes en mode **UEFI**, un binaire d'amorçage unique ne peut convenir :
- **BIOS Legacy :** Nécessite le binaire `boot\x64\wdsnbp.com`.
- **UEFI x64 :** Nécessite le binaire `boot\x64\wdsmgfw.efi`.

9.1. **Sauvegarde préalable de la configuration Kea.** Sur le serveur Debian `DHCPECOCERT`, archiver le fichier de configuration avant modification.

```bash title="backup_kea.sh"
sudo cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak
```

9.2. **Déclaration des classes de clients PXE par architecture.** Éditer la configuration `/etc/kea/kea-dhcp4.conf` pour identifier dynamiquement l'architecture du client via l'option 93 (RFC 4578).

```json title="/etc/kea/kea-dhcp4.conf (extrait Dhcp4)"
{
  "Dhcp4": {
    "client-classes": [
      {
        "name": "PXE-BIOS-x64",
        "test": "substring(option[60].hex,0,9) == 'PXEClient' and option[93].hex == 0x0000",
        "next-server": "172.16.54.4",
        "boot-file-name": "boot\\x64\\wdsnbp.com"
      },
      {
        "name": "PXE-UEFI-x64",
        "test": "substring(option[60].hex,0,9) == 'PXEClient' and (option[93].hex == 0x0007 or option[93].hex == 0x0009)",
        "next-server": "172.16.54.4",
        "boot-file-name": "boot\\x64\\wdsmgfw.efi",
        "option-data": [
          { "name": "vendor-class-identifier", "data": "PXEClient" }
        ]
      }
    ]
  }
}
```

- `option[93] == 0x0000` : Détecte un client amorcé en BIOS x86/x64 et fournit le fichier `wdsnbp.com`.
- `option[93] == 0x0007 ou 0x0009` : Détecte un client amorcé en UEFI x64 et fournit le binaire EFI `wdsmgfw.efi`.
- `next-server` : Pointeur IP (`172.16.54.4`) vers le serveur TFTP hébergé sur `MDTECOCERT`.

9.3. **Validation de la syntaxe et application.** Contrôler la syntaxe JSON avant d'appliquer la nouvelle configuration.

```bash title="apply_kea_pxe.sh"
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl restart kea-dhcp4-server
sudo systemctl status kea-dhcp4-server
```

- `kea-dhcp4 -t` : Analyse la conformité du fichier JSON (doit renvoyer `0` sans erreur).
- `systemctl restart` : Recharge le service DHCP avec les nouvelles classes PXE.

<a id="10-recette-et-validation-du-déploiement"></a>
## 10. Recette et validation du déploiement

10.1. **Démarrage d'une machine virtuelle cliente.** Configurer une machine virtuelle cliente sur le réseau (VLAN 54 ou VLAN utilisateur routé) avec l'ordre de démarrage réseau (PXE) en priorité.

10.2. **Points de contrôle de la recette technique.**

| Étape de validation | Indicateur de succès | Statut attendu |
| :--- | :--- | :--- |
| **Bail DHCP** | Le client reçoit une IP et l'adresse `next-server: 172.16.54.4` | Conforme |
| **Téléchargement TFTP** | Téléchargement sans erreur de `wdsmgfw.efi` (UEFI) ou `wdsnbp.com` (BIOS) | Conforme |
| **Chargement WinPE** | Affichage de l'écran LiteTouch et chargement de `LiteTouchPE_x64.wim` | Conforme |
| **Montage SMB** | Authentification réussie du compte `svc-mdt-read` sur `\\MDTECOCERT\MDTShare$` | Conforme |
| **Exécution Task Sequence** | Partitionnement du disque, application du WIM et injection des pilotes | Conforme |
| **Jonction Active Directory** | Intégration du poste dans `OU=Postes,DC=local,DC=ecocert4,DC=fr` par `svc-mdt-join` | Conforme |

10.3. **Emplacement des journaux de diagnostic en cas d'erreur.**

```text title="Journaux de référence pour le dépannage"
- Logs de compilation DISM : C:\Windows\Logs\DISM\dism.log
- Logs d'exécution MDT (WinPE) : X:\MININT\SMSOSD\OSDLOGS\BDD.log
- Logs post-installation Windows : C:\Windows\Temp\DeploymentLogs\BDD.log
- Événements WDS : Observateur d'événements > Microsoft > Windows > Deployment-Services-Diagnostics
- Logs Kea DHCP (Debian) : sudo journalctl -u kea-dhcp4-server -n 50 --no-pager
```
