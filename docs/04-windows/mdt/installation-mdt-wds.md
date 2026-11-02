---
description: Installation de WDS, Windows ADK, WinPE et MDT sur MDTECOCERT (Windows Server 2019) avec vérifications et sécurisation
---

# Installation de WDS et MDT sur MDTECOCERT (Windows Server 2019)

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
- [3. Prérequis et traçabilité](#3-prerequis-et-tracabilite)
- [4. Préparation du serveur et jonction au domaine](#4-preparation-du-serveur-et-jonction-au-domaine)
- [5. Installation et initialisation de WDS](#5-installation-et-initialisation-de-wds)
- [6. Installation de Windows ADK, WinPE et MDT](#6-installation-de-windows-adk-winpe-et-mdt)
- [7. Création et sécurisation du Deployment Share](#7-creation-et-securisation-du-deployment-share)
- [8. Génération de l'image WinPE et import dans WDS](#8-generation-de-limage-winpe-et-import-dans-wds)
- [9. Sauvegarde de l'existant](#9-sauvegarde-de-lexistant)
- [10. Sources](#10-sources)

## 2. Contexte

Le serveur **MDTECOCERT** (Windows Server 2019, expérience de bureau) héberge **WDS** (service PXE et images de démarrage) et **MDT** (ressources de déploiement : systèmes, pilotes, applications, séquences de tâches). Il est membre du domaine `local.ecocert4.fr`, résout ses noms via **ADECOCERT** (AD DS/DNS) et reçoit son adressage via **DHCPECOCERT** (Kea DHCP, Debian). Un disque dédié `S:\` isole `RemoteInstall` (WDS) et `DeploymentShare` (MDT) du disque système.

Flux principaux : le client PXE obtient son IP auprès de Kea, démarre le programme réseau fourni par WDS (UDP 4011 / TFTP 69), charge l'image WinPE, puis accède au partage SMB `\\MDTECOCERT\MDTShare$` (TCP 445) et rejoint le domaine.

> [!warning] "Statut des composants"
>
> - **MDT est retiré** par Microsoft depuis le 06/01/2026 : plus de mises à jour, de correctifs de sécurité ni de support. Les installations existantes continuent de fonctionner en l'état. Cette procédure est valable pour un **laboratoire pédagogique** ; pour une production, prévoir une migration (Configuration Manager OSD ou Autopilot).
> - **WDS** reste disponible sur Windows Server 2019, 2022 et 2025, mais Microsoft a annoncé le 21/09/2026 sa dépréciation à partir de la prochaine version de Windows Server.
> - **Windows Server 2019** : support étendu jusqu'en janvier 2029.
> - L'installateur MDT a pu être retiré des canaux de distribution officiels : conserver une copie vérifiée (hash) de celui utilisé.

## 3. Prérequis et traçabilité {#3-prerequis-et-tracabilite}

3.1. **Prérequis d'infrastructure.** Vérifier avant de commencer.

- Domaine AD fonctionnel et DNS opérationnel (`ADECOCERT`, `172.16.54.1`)
- Serveur DHCP opérationnel (`DHCPECOCERT`, `172.16.54.2`)
- Adresse IP fixe du serveur : `172.16.54.4`
- Disque secondaire attaché à la VM, dimensionné selon le calcul ci-dessous

3.2. **Dimensionnement du volume `S:\`.** Il n'existe pas de minimum universel. Calculer selon les besoins réels et conserver une marge.

| Poste | À estimer |
| :---- | :-------- |
| Images Windows sources et personnalisées | nombre de systèmes × taille du WIM |
| Images de démarrage WinPE | environ 1 à 2 Go avec pilotes |
| Pilotes matériels | par modèle |
| Applications et packages | selon le catalogue |
| Espace temporaire (mises à jour, captures) | marge de 20 à 30 % |

3.3. **Fiche de traçabilité.** Renseigner les versions réellement installées pour rendre l'installation reproductible.

```text title="Traçabilité (à compléter)"
Windows ADK            : version exacte = ______  date = ______
Windows PE Add-on      : version exacte = ______  date = ______
Patch ADK (CVE-2026-25166) : KB = ______
MDT                    : version/build = ______  hash installeur = ______
OS cible               : édition = ______  version = ______  build = ______
Architecture           : x64
Mode de démarrage      : UEFI / BIOS Legacy (cocher)
```

> [!note] "Versions ADK de référence"
>
> Au 02/11/2026, la page Microsoft Learn indique l'ADK `10.1.26100.9457` (septembre 2026), qui cible notamment Windows 11 26H2/25H2/24H2 et Windows Server 2022/2025. Toujours installer l'ADK et le module WinPE de **même version**, et appliquer le dernier patch ADK (CVE-2026-25166). La compatibilité de l'ADK ne vaut pas support de MDT.

3.4. **Comptes dédiés.** Ne jamais utiliser un compte Domain Admin pour les opérations automatisées. Créer ces comptes sur **ADECOCERT**.

| Compte | Rôle | Droits |
| :----- | :--- | :----- |
| `svc-mdt-read` | Accès au partage depuis WinPE | Lecture seule sur `MDTShare$` |
| `svc-mdt-join` | Jonction des postes au domaine | Création d'objets ordinateur dans l'OU cible uniquement |
| `adm-mdt` | Administration MDT/WDS | Administrateur local de `MDTECOCERT` |

```powershell title="Création des comptes (sur ADECOCERT)"
$pwd = Read-Host -AsSecureString "Mot de passe"
New-ADUser -Name "svc-mdt-read" -SamAccountName "svc-mdt-read" -AccountPassword $pwd -Enabled $true -PasswordNeverExpires $true
New-ADUser -Name "svc-mdt-join" -SamAccountName "svc-mdt-join" -AccountPassword $pwd -Enabled $true -PasswordNeverExpires $true
New-ADUser -Name "adm-mdt"      -SamAccountName "adm-mdt"      -AccountPassword $pwd -Enabled $true
```

- `-AccountPassword` : mot de passe saisi de façon masquée (utiliser un mot de passe différent par compte en pratique)
- `-PasswordNeverExpires` : évite l'expiration silencieuse d'un compte de service

> [!note] "Délégation du compte de jonction"
>
> Dans **Utilisateurs et ordinateurs Active Directory**, clic droit sur l'OU des postes > **Déléguer le contrôle** > `svc-mdt-join` > tâche personnalisée > objets *Ordinateur* > cocher *Créer* et *Supprimer* les objets sélectionnés, puis les droits de lecture/écriture nécessaires à la jonction.

## 4. Préparation du serveur et jonction au domaine {#4-preparation-du-serveur-et-jonction-au-domaine}

4.1. **Préparation du volume `S:\`.** Identifier le disque avec `Get-Disk` avant de l'initialiser.

```powershell title="Initialisation du disque de données"
Get-Disk
Initialize-Disk -Number 1 -PartitionStyle GPT
New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter S | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DEPLOY"
```

- `-Number 1` : numéro du disque vierge affiché par `Get-Disk` (**à vérifier**, un mauvais numéro détruit des données)
- `-DriveLetter S` : lettre attribuée au volume

4.2. **Configuration IP fixe.** Adapter l'alias d'interface, la passerelle et le préfixe à ton réseau.

```powershell title="Adressage statique"
Get-NetAdapter
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.16.54.4 -PrefixLength <PREFIXE> -DefaultGateway <PASSERELLE>
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.16.54.1
```

- `-InterfaceAlias` : nom de la carte réseau affiché par `Get-NetAdapter`
- `-ServerAddresses` : DNS pointant sur ADECOCERT

4.3. **Vérification DNS avant jonction.** Le contrôleur de domaine doit être découvrable.

```powershell title="Test de découverte du contrôleur de domaine"
Resolve-DnsName -Type SRV "_ldap._tcp.dc._msdcs.local.ecocert4.fr"
```

4.4. **Jonction au domaine.**

```powershell title="Jonction au domaine"
Add-Computer -DomainName "local.ecocert4.fr" -Credential (Get-Credential) -Restart
```

- `-DomainName` : domaine AD cible
- `-Credential` : compte autorisé à joindre des machines
- `-Restart` : redémarre le serveur après la jonction

4.5. **Vérification après redémarrage.**

```powershell title="Test du canal sécurisé"
Test-ComputerSecureChannel -Verbose
```

Le résultat attendu est `True`. Ajouter ensuite `adm-mdt` au groupe local *Administrateurs* de `MDTECOCERT`.

## 5. Installation et initialisation de WDS {#5-installation-et-initialisation-de-wds}

5.1. **Installation du rôle avec ses deux services.** WDS nécessite une expérience de bureau (il ne s'installe pas sur Server Core).

```powershell title="Installation du rôle WDS"
Install-WindowsFeature WDS -IncludeAllSubFeature -IncludeManagementTools
Get-WindowsFeature -Name WDS*
```

- `-IncludeAllSubFeature` : installe `WDS-Deployment` (Deployment Server) et `WDS-Transport` (Transport Server)
- `-IncludeManagementTools` : installe la console `wdsmgmt.msc` et le module PowerShell

Le résultat attendu est `[X]` devant `WDS`, `WDS-Deployment` et `WDS-Transport`.

5.2. **Initialisation du magasin d'images sur `S:\`.**

```powershell title="Initialisation de WDS"
WDSUTIL /Initialize-Server /Server:MDTECOCERT /RemInst:"S:\RemoteInstall"
```

- `/Server` : nom du serveur WDS
- `/RemInst` : emplacement de `RemoteInstall` (volume `S:\`, jamais le disque système)

5.3. **Validation de l'initialisation.**

```powershell title="Contrôles post-initialisation"
Get-Service WDSServer
Test-Path "S:\RemoteInstall"
icacls "S:\RemoteInstall"
WDSUTIL /Get-Server /Server:MDTECOCERT /Show:Config
```

Le service `WDSServer` doit être `Running`, le dossier doit exister avec ses ACL, et la configuration doit s'afficher sans erreur.

5.4. **Paramètres de réponse PXE.** Dans `wdsmgmt.msc` : clic droit sur le serveur > **Propriétés**.

- Onglet **PXE Response** : pour un laboratoire, *Respond to all client computers (known and unknown)* ; pour une production, *Respond only to known client computers* (ordinateurs préconfigurés dans AD)
- Onglet **DHCP** : laisser **décochées** les deux cases. Elles ne concernent que le cas où DHCP et WDS sont hébergés sur le même serveur, ce qui n'est pas le cas ici (Kea est sur `DHCPECOCERT`).

5.5. **Vérification des flux réseau.** Un groupe de règles « activé » ne prouve pas que le trafic passe, et son nom varie selon la langue de Windows. Contrôler les ports effectifs.

| Protocole | Port | Usage |
| :-------- | :--- | :---- |
| UDP | 67 | DHCP / réponse PXE |
| UDP | 69 | TFTP |
| UDP | 4011 | PXE / BINL |
| TCP | 445 | Partage MDT (SMB) |

```powershell title="Règles entrantes effectives sur les ports PXE"
Get-NetFirewallRule -Direction Inbound -Enabled True | ForEach-Object {
    $r = $_; $pf = $r | Get-NetFirewallPortFilter
    if ($pf.Protocol -eq 'UDP' -and $pf.LocalPort -match '^(67|69|4011)$') {
        [pscustomobject]@{ Regle = $r.DisplayName; Protocole = $pf.Protocol; Port = $pf.LocalPort; Profil = $r.Profile }
    }
}
```

> [!note] "Test depuis un client"
>
> Depuis un poste du même VLAN : `Test-NetConnection MDTECOCERT -Port 445`. Le TFTP et le PXE ne se valident réellement que par un démarrage PXE de test (voir la fiche de configuration).

5.6. **Console de gestion.** Ouvrir `wdsmgmt.msc` avec `adm-mdt` (compte d'administration dédié), et non avec un compte Domain Admin.

## 6. Installation de Windows ADK, WinPE et MDT {#6-installation-de-windows-adk-winpe-et-mdt}

6.1. **Installer l'ADK.** Lancer `adksetup.exe` (version relevée en 3.3) et cocher au minimum **Deployment Tools**.

6.2. **Installer le module WinPE.** Lancer `adkwinpesetup.exe` de **même version** que l'ADK. Le module WinPE est un téléchargement séparé, à installer **après** l'ADK.

6.3. **Appliquer le patch ADK.** Installer le dernier patch ADK publié par Microsoft (CVE-2026-25166).

6.4. **Installer MDT.** Installer MDT (version notée en 3.3) **après** l'ADK et WinPE.

```powershell title="Vérification des composants installés"
Test-Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64"
Test-Path "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
```

Les deux commandes doivent renvoyer `True`. Si la première renvoie `False`, le module WinPE n'est pas installé ou n'est pas aligné avec l'ADK.

> [!warning] "À valider sur ton serveur"
>
> Vérifier que l'ADK choisi s'installe correctement sur Windows Server 2019 et qu'il génère bien une image WinPE x64 fonctionnelle avec MDT. Noter dans la fiche de traçabilité la combinaison testée. En cas d'incompatibilité, utiliser l'ADK d'une version antérieure encore proposée par Microsoft.

## 7. Création et sécurisation du Deployment Share {#7-creation-et-securisation-du-deployment-share}

7.1. **Création du dossier dédié.** Ne jamais pointer le partage sur la racine de `S:\` (elle contient déjà `RemoteInstall`).

```powershell title="Création de l'arborescence"
New-Item -Path "S:\DeploymentShare" -ItemType Directory
```

```text title="Arborescence attendue"
S:\
├── RemoteInstall\
└── DeploymentShare\
```

> [!note] "Erreur connue"
>
> Un partage MDT créé sur `S:\` échoue avec : `The path 'S:\' exists but is not a valid deployment share and is not empty`.

7.2. **Publication du partage SMB avec permissions minimales.** Le `$` final masque le partage dans la navigation mais **ne protège pas l'accès** : les ACL sont indispensables.

```powershell title="Création du partage et des permissions"
$nb = $env:USERDOMAIN
New-SmbShare -Name 'MDTShare$' -Path 'S:\DeploymentShare' -FullAccess "BUILTIN\Administrators" -ReadAccess "$nb\svc-mdt-read"
icacls "S:\DeploymentShare" /inheritance:r
icacls "S:\DeploymentShare" /grant "BUILTIN\Administrators:(OI)(CI)F"
icacls "S:\DeploymentShare" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F"
icacls "S:\DeploymentShare" /grant "${nb}\svc-mdt-read:(OI)(CI)RX"
```

- `$env:USERDOMAIN` : nom NetBIOS du domaine, déduit de la session
- `-FullAccess` / `-ReadAccess` : permissions de **partage** SMB
- `/inheritance:r` : supprime l'héritage depuis `S:\`
- `(OI)(CI)RX` : lecture et exécution, héritées par les fichiers et sous-dossiers (permissions **NTFS**)

Le chemin UNC à documenter est `\\MDTECOCERT\MDTShare$`.

7.3. **Création du Deployment Share MDT.** Via PowerShell (méthode scriptable) :

```powershell title="Création du Deployment Share MDT"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "S:\DeploymentShare" -Description "ECOCERT Deployment Share" -NetworkPath '\\MDTECOCERT\MDTShare$' -Verbose | Add-MDTPersistentDrive -Verbose
```

- `-Name DS001` : nom du lecteur MDT, réutilisé dans les commandes suivantes
- `-Root` : dossier physique du partage
- `-NetworkPath` : chemin UNC publié (partage créé en 7.2)

Équivalent graphique : **Deployment Workbench > Deployment Shares > New Deployment Share**, avec le chemin `S:\DeploymentShare` et le nom de partage `MDTShare$`. S'il propose de créer lui-même le partage, il faudra ensuite revoir ses permissions (7.2).

> [!warning] "Identifiants dans les fichiers MDT"
>
> Les fichiers `Bootstrap.ini`, `CustomSettings.ini` et les journaux de déploiement peuvent contenir des identifiants. Ceux qui sont embarqués dans l'image de démarrage ne sont **pas** protégés par défaut. N'y mettre que `svc-mdt-read` (lecture seule) et `svc-mdt-join` (droits limités à l'OU), jamais un compte privilégié.

## 8. Génération de l'image WinPE et import dans WDS {#8-generation-de-limage-winpe-et-import-dans-wds}

8.1. **Restreindre l'architecture à x64.** Si le Deployment Share génère aussi du x86 sans les composants correspondants, DISM échoue. Voir la fiche de configuration (section 3) avant de lancer la génération.

8.2. **Mise à jour du Deployment Share.**

```powershell title="Génération des images de démarrage"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
Update-MDTDeploymentShare -Path "DS001:" -Force -Verbose
```

- `-Path "DS001:"` : lecteur MDT créé en 7.3
- `-Force` : régénère complètement les images WinPE
- `-Verbose` : affiche le détail utile au diagnostic

Équivalent graphique : **Deployment Workbench > Deployment Shares > clic droit sur le partage > Update Deployment Share**. Contrôler ensuite la présence et la taille du fichier :

```powershell title="Contrôle de l'image générée"
Get-Item "S:\DeploymentShare\Boot\LiteTouchPE_x64.wim" | Select-Object Name, Length, LastWriteTime
```

8.3. **Import dans WDS.**

```powershell title="Import de l'image de démarrage"
WDSUTIL /Add-Image /ImageFile:"S:\DeploymentShare\Boot\LiteTouchPE_x64.wim" /ImageType:Boot /Server:MDTECOCERT
```

- `/ImageFile` : WIM généré par MDT
- `/ImageType:Boot` : image de démarrage PXE
- `/Server` : serveur WDS cible

8.4. **Vérification de l'import.**

```powershell title="Liste des images de démarrage"
WDSUTIL /Get-AllImages /Server:MDTECOCERT /Show:Boot
```

> [!note] "Régénération"
>
> Après chaque nouvelle génération de `LiteTouchPE_x64.wim` (ajout de pilotes, modification de `Bootstrap.ini`), il faut **remplacer** l'image dans WDS : clic droit sur l'image de démarrage > **Replace Image**, ou supprimer puis réimporter.

## 9. Sauvegarde de l'existant {#9-sauvegarde-de-lexistant}

9.1. **Éléments à sauvegarder.** `S:\RemoteInstall\`, `S:\DeploymentShare\`, la configuration WDS exportée, et sur Debian `/etc/kea/kea-dhcp4.conf`.

```powershell title="Export de la configuration WDS"
WDSUTIL /Get-Server /Server:MDTECOCERT /Show:Config > "S:\wds-config-$(Get-Date -Format yyyyMMdd).txt"
```

9.2. **Test de restauration.** Une sauvegarde jamais restaurée n'est pas une garantie. Planifier une restauration de test sur une VM isolée et noter la date et le résultat.

## 10. Sources {#10-sources}

- Microsoft Learn — Retraite de MDT : https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/mdt/mdt-retirement
- Microsoft 365 Message Center MC1478819 — Dépréciation de WDS : https://mc.merill.net/message/MC1478819
- Microsoft Learn — Download and install the Windows ADK : https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install
- RDR-IT — WDS, installation et configuration : https://rdr-it.com/wds-installation-et-configuration/
- Server World — WDS sur Windows Server 2019 : https://www.server-world.info/en/note?os=Windows_Server_2019&p=wds&f=1
