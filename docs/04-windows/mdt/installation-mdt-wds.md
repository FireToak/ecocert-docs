---
description: Installation du serveur MDTECOCERT sous Proxmox avec Windows Server 2019, WDS, ADK et MDT.
---

# Installation de l'infrastructure de déploiement WDS et MDT

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

> [!note] "Informations"
> - **Auteur :** Amine KADA
> - **Domaine :** Windows Server 2019
> - **Objectif :** préparer le serveur de déploiement de la SP4

## 1. Contexte et architecture

Le serveur **MDTECOCERT** est une machine virtuelle dédiée à l'installation des postes Windows. WDS fournit le démarrage réseau ; MDT prépare les séquences d'installation et WinPE démarre le client avant l'installation de Windows.

| Élément | Valeur |
| :--- | :--- |
| Hyperviseur | Proxmox |
| Serveur | MDTECOCERT, Windows Server 2019 Desktop Experience |
| Adresse serveur | `172.16.54.4/24` |
| Passerelle du VLAN serveurs | `172.16.54.253` |
| DNS Active Directory | `172.16.54.1` |
| Domaine | `local.ecocert4.fr` |
| Volume de données | `S:` en NTFS |
| Répertoire WDS | `S:\RemoteInstall` |
| Répertoire MDT | `S:\DeploymentShare` |
| Partage MDT | `\\MDTECOCERT\MDTShare$` |

La passerelle `.253` est celle de l'interface VLAN 54 dans la configuration Cisco du dépôt. Vérifier l'adresse libre et la configuration réellement active avant de l'appliquer. Le sujet prévoit Server Core et un poste d'administration distant ; cette version centralisée avec interface graphique est une adaptation à faire valider par l'enseignant. MDT est retiré du support depuis 2026 ; Windows 10 22H2 a atteint sa fin de support ordinaire en octobre 2025. Leur utilisation ici correspond au laboratoire pédagogique.

## 2. Création de la machine virtuelle Proxmox

2.1. **Préparer les ISO.** Dans Proxmox, sélectionner le stockage des ISO > **ISO Images > Upload** et ajouter l'ISO de Windows Server 2019 et celle des pilotes VirtIO. Si la VM MDTECOCERT existe déjà, conserver sa configuration et passer à la section 3.

2.2. **Créer la VM.** Cliquer sur **Create VM** et renseigner :

| Onglet | Paramètre |
| :--- | :--- |
| General | ID libre ; nom `MDTECOCERT` |
| OS | ISO Windows Server 2019 ; type Microsoft Windows |
| System | Machine `q35`, BIOS `OVMF (UEFI)`, ajouter un disque EFI |
| Disks | Disque système 80 Gio, contrôleur VirtIO SCSI single |
| CPU | 4 vCPU pour le laboratoire |
| Memory | 8192 Mio |
| Network | Bridge relié au réseau serveurs, carte VirtIO, VLAN tag 54 si le bridge transporte les VLANs étiquetés |

Le bridge et le tag dépendent du câblage Proxmox : si le port est déjà configuré en accès VLAN 54, ne pas ajouter un second tag. Dans **Hardware > Add > Hard Disk**, ajouter un disque de données, par exemple 150 Gio. Ajouter l'ISO VirtIO dans un second lecteur CD. Le firmware de la VM serveur ne détermine pas le mode BIOS ou UEFI des clients.

2.3. **Installer Windows.** Démarrer la VM, ouvrir **Console**, lancer l'installation et choisir **Windows Server 2019 Standard (Desktop Experience)**. Si aucun disque n'apparaît, cliquer sur **Load driver**, parcourir le lecteur VirtIO et charger le pilote `vioscsi` correspondant à Windows Server 2019 et à l'architecture amd64. Après installation, installer le pilote réseau et l'agent QEMU depuis l'ISO VirtIO, puis activer **Options > QEMU Guest Agent** dans Proxmox.

## 3. Préparation du serveur Windows

3.1. **Renommer le serveur.** Dans une fenêtre Windows PowerShell 5.1 ouverte en administrateur :

```powershell
Rename-Computer -NewName 'MDTECOCERT' -Restart
```

Après redémarrage, `hostname` doit afficher `MDTECOCERT`.

3.2. **Préparer le volume de données.** Dans **Gestionnaire de serveur > Outils > Gestion de l'ordinateur > Gestion des disques**, identifier le disque supplémentaire par sa taille et son état. S'il est vierge, l'initialiser en GPT, créer un **Nouveau volume simple**, choisir la lettre `S:` et formater en NTFS avec le nom `DEPLOY`. Le formatage efface les données du volume sélectionné ; ne pas reformater un volume déjà utilisé.

```powershell
Get-Disk | Format-Table Number, FriendlyName, Size, PartitionStyle
Get-Volume | Format-Table DriveLetter, FileSystemLabel, FileSystem, SizeRemaining, Size
```

3.3. **Configurer IPv4 et DNS.** Ouvrir **Gestionnaire de serveur > Serveur local > Ethernet > Propriétés > Protocole Internet version 4**. Pour une nouvelle interface, renseigner : IP `172.16.54.4`, masque `255.255.255.0`, passerelle `172.16.54.253`, DNS préféré `172.16.54.1`. Ne pas ajouter une seconde passerelle à une configuration existante. Depuis PowerShell, la configuration équivalente, après identification de l'interface et vérification que l'adresse est libre, est :

```powershell
Get-NetIPConfiguration
New-NetIPAddress -InterfaceAlias 'Ethernet' -IPAddress 172.16.54.4 -PrefixLength 24 -DefaultGateway 172.16.54.253
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet' -ServerAddresses 172.16.54.1
Get-NetIPConfiguration
Resolve-DnsName -Type SRV '_ldap._tcp.dc._msdcs.local.ecocert4.fr'
Test-NetConnection 172.16.54.1 -Port 389
```

La résolution SRV doit retourner le contrôleur de domaine et le test LDAP doit afficher `TcpTestSucceeded : True`.

3.4. **Joindre le domaine.** Dans **Gestionnaire de serveur > Serveur local > Groupe de travail > Modifier**, choisir **Domaine**, saisir `local.ecocert4.fr`, puis un compte autorisé à joindre la machine. Redémarrer. Équivalent PowerShell :

```powershell
Add-Computer -DomainName 'local.ecocert4.fr' -Credential (Get-Credential) -Restart
```

Après redémarrage :

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object Name, Domain, PartOfDomain
Test-ComputerSecureChannel
```

`PartOfDomain` et le canal sécurisé doivent renvoyer `True`.

## 4. Installation et configuration de WDS

4.1. **Installer le rôle.** Dans **Gestionnaire de serveur > Gérer > Ajouter des rôles et fonctionnalités**, choisir une installation basée sur un rôle, sélectionner MDTECOCERT, puis **Services de déploiement Windows** et accepter les outils. Cocher **Serveur de déploiement** et **Serveur de transport**, puis installer.

```powershell
Install-WindowsFeature WDS -IncludeAllSubFeature -IncludeManagementTools
Get-WindowsFeature WDS*
```

4.2. **Ouvrir la console avec un compte du domaine.** Sur MDTECOCERT, ouvrir une session avec un compte du domaine disposant des droits d'administration WDS, puis lancer **Services de déploiement Windows** en administrateur. Si le serveur ne figure pas dans la liste, clic droit sur **Serveurs > Ajouter un serveur > Ordinateur local**.

Lors du test ECOCERT, l'ajout échouait avec le compte local `MDTECOCERT\Administrateur` et l'erreur `0x52E` ; le serveur est apparu avec un compte du domaine. Ce résultat ne prouve pas que toute erreur `0x52E` a la même cause. Vérifier `whoami`, les droits et le canal sécurisé si l'erreur persiste. Ne pas réinitialiser WDS pour résoudre ce symptôme.

4.3. **Initialiser WDS.** Ouvrir **Outils > Services de déploiement Windows**, développer **Serveurs**, clic droit sur MDTECOCERT > **Configurer le serveur**. Choisir **Intégré à Active Directory**, définir `S:\RemoteInstall`, puis sélectionner la réponse aux clients connus et inconnus pour le laboratoire. Terminer et démarrer le service. Utiliser ce mode uniquement sur le réseau de déploiement prévu.

Pour une installation neuve non encore initialisée, les commandes équivalentes sont :

```powershell
WDSUTIL /Initialize-Server /Server:MDTECOCERT /RemInst:"S:\RemoteInstall"
WDSUTIL /Set-Server /Server:MDTECOCERT /AnswerClients:All
Start-Service WDSServer
Get-Service WDSServer
WDSUTIL /Get-Server /Server:MDTECOCERT /Show:Config
```

Le service doit être `Running`. Kea et WDS étant sur deux serveurs distincts, ne pas appliquer les réglages réservés à une installation DHCP et WDS sur la même machine.

## 5. Installation d'ADK, WinPE et MDT

5.1. **Télécharger les composants.**

| Composant | Téléchargement ou référence | Utilisation |
| :--- | :--- | :--- |
| Windows ADK pour Windows 10, version 2004 | [Télécharger l’installateur ADK](https://go.microsoft.com/fwlink/?linkid=2120254) | Lancer `adksetup.exe` et sélectionner **Deployment Tools**. |
| Module complémentaire Windows PE pour ADK 2004 | [Télécharger l’installateur WinPE](https://go.microsoft.com/fwlink/?linkid=2120253) | Lancer `adkwinpesetup.exe` après l’ADK. |
| Microsoft Deployment Toolkit 8456 | [Copie archivée du MSI x64 sur Internet Archive](https://web.archive.org/web/20240315155222/https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi) · [Notes de version Microsoft](https://learn.microsoft.com/en-us/intune/configmgr/mdt/release-notes) | L’archive est une source tierce : vérifier signature et empreinte avant installation. Le lien historique du centre Microsoft renvoie une erreur 404. |
| Correctif MDT KB4564442 | [Télécharger le correctif Microsoft](https://download.microsoft.com/download/3/0/6/306AC1B2-59BE-43B8-8C65-E141EF287A5E/KB4564442/MDT_KB4564442.exe) · [Notice d’installation Microsoft](https://support.microsoft.com/help/4564442) | Corrige la détection BIOS/UEFI avec MDT 8456 et l’ADK 2004. |

Les deux liens ADK et WinPE proviennent de la [page officielle de téléchargement des ADK](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install#other-adk-downloads) : choisir la version Windows 10 **2004**, republiée en mai 2025. Installer dans l’ordre : **ADK**, **module Windows PE**, puis **MDT 8456**. Microsoft indique que MDT est retiré du support depuis 2026. La disponibilité des fichiers peut évoluer ; l’accès au contenu binaire n’a pas été vérifié par téléchargement complet.

5.2. **Vérifier puis installer MDT 8456.** Privilégier une copie conservée par l’établissement si elle est disponible. Sinon, télécharger la copie archivée ci-dessus. Internet Archive n’est pas un canal de téléchargement Microsoft ; la disponibilité du fichier et sa signature doivent être vérifiées au moment du téléchargement.

Sur MDTECOCERT, dans Windows PowerShell, remplacer le chemin suivant par celui du fichier MSI téléchargé :

```powershell
$msi = 'C:\Users\Administrateur\Downloads\MicrosoftDeploymentToolkit_x64.msi'
Get-AuthenticodeSignature -FilePath $msi | Format-List Status, StatusMessage, SignerCertificate
Get-FileHash -Path $msi -Algorithm SHA256
```

La signature doit afficher `Valid` et identifier Microsoft comme signataire. Comparer également le résultat SHA-256 à cette empreinte de référence publiée par une [source communautaire spécialisée](https://www.deploymentresearch.com/to-use-or-not-to-use-mdt/) :

```text
DABFD183C525BDB4866D2D9324F064A291CA62F3A16AC429CF3338BE529D1D58
```

Cette empreinte est fournie par un tiers, pas par une page Microsoft vérifiée. Si la signature n’est pas valide ou si l’empreinte diffère, ne pas installer le fichier et rechercher une copie vérifiable. Lancer ensuite le MSI, terminer l’assistant, puis ouvrir **Deployment Workbench > Help > About** : la version recherchée est **6.3.8456.1000**. Le nom du MSI seul ne prouve pas la version.

5.3. **Appliquer le correctif KB4564442.** Ce correctif s’applique uniquement à **MDT build 8456** ; il ne met pas une version antérieure de MDT à niveau vers 8456. Après vérification de la version :

1. Fermer **Deployment Workbench** et extraire `MDT_KB4564442.exe` dans un dossier temporaire.
2. Sauvegarder les fichiers `Microsoft.BDD.Utility.dll` existants dans les dossiers `C:\Programmes\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x86` et `x64`.
3. Copier les DLL extraites en respectant leur architecture : DLL x86 dans `x86`, DLL x64 dans `x64`.
4. Si un partage MDT existe déjà, sauvegarder puis remplacer aussi les DLL correspondantes dans `S:\DeploymentShare\Tools\x86` et `S:\DeploymentShare\Tools\x64`. Si le partage n’existe pas encore, cette étape sera inutile lors de sa création à partir des modèles corrigés ; contrôler néanmoins les versions après création.
5. Pour chaque partage déjà créé, rouvrir Deployment Workbench, clic droit sur le partage > **Update Deployment Share** > **Completely regenerate the boot images**. Si une image a déjà été publiée dans WDS, la remplacer par l’image régénérée.

La version attendue des DLL corrigées est `6.3.8456.1001`, selon la notice Microsoft. Vérifier les copies du modèle et du partage ; contrôler aussi x86 si cette architecture est utilisée :

```powershell
(Get-Item 'C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\Microsoft.BDD.Utility.dll').VersionInfo.FileVersion
(Get-Item 'S:\DeploymentShare\Tools\x64\Microsoft.BDD.Utility.dll').VersionInfo.FileVersion
```

5.4. **Vérifier les composants.** Contrôler les chemins ci-dessous :

```powershell
Test-Path 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64'
Test-Path 'C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1'
```

Les deux résultats attendus sont `True`. Ouvrir **Démarrer > Microsoft Deployment Toolkit > Deployment Workbench**.

## 6. Comptes et partage de déploiement

6.1. **Créer les comptes.** Sur ADECOCERT, ouvrir **Outils > Utilisateurs et ordinateurs Active Directory**. Dans une OU de comptes de service existante, créer `svc-mdt-read` pour la lecture du partage et `svc-mdt-join` pour la jonction des clients. Définir deux mots de passe distincts. Dans l'OU réellement destinée aux ordinateurs de test, utiliser **Délégation de contrôle** pour accorder à `svc-mdt-join` les droits nécessaires à la création des comptes ordinateurs ; vérifier les droits complémentaires nécessaires pour les comptes déjà existants. La suppression des ordinateurs n'est pas nécessaire par défaut.

6.2. **Créer le partage MDT.** Dans Deployment Workbench, clic droit **Deployment Shares > New Deployment Share** :

| Écran | Valeur |
| :--- | :--- |
| Deployment share path | `S:\DeploymentShare` |
| Share name | `MDTShare$` |
| Description | `ECOCERT Deployment Share` |
| Options | Conserver les demandes interactives pour le premier déploiement |

Terminer l'assistant. Si le partage existe déjà, choisir **Open Deployment Share** et le chemin existant ; ne pas recréer le dossier.

6.3. **Attribuer les droits.** Dans **Gestion de l'ordinateur > Dossiers partagés > Partages**, ouvrir les propriétés de `MDTShare$` et l'onglet des autorisations de partage : conserver le contrôle total pour les administrateurs et ajouter la lecture pour `svc-mdt-read`. Dans les propriétés de `S:\DeploymentShare` > **Sécurité**, conserver les droits d'administration et de SYSTEM, et accorder lecture/exécution à `svc-mdt-read`, applicables aux sous-dossiers et fichiers. Vérifier les droits existants avant toute modification et tester depuis un client avec ce compte.

```powershell
Get-SmbShareAccess -Name 'MDTShare$'
Get-Acl 'S:\DeploymentShare' | Format-List
```

La configuration de Windows, des applications, de WinPE et du PXE se poursuit dans [Configuration du déploiement PXE](configuration-mdt-wds.md).

Les OU de postes créées dans chaque service ECOCERT sont renseignées dans les règles de la [fiche de configuration](configuration-mdt-wds.md). Accorder au compte de jonction les droits nécessaires dans chaque OU utilisée ; ne pas supposer que les droits sont déjà accordés.

## 7. Dépannage

| Symptôme | Contrôle |
| :--- | :--- |
| Disque absent pendant l'installation | Charger `vioscsi` depuis l'ISO VirtIO, ou contrôler le contrôleur choisi dans Proxmox. |
| Domaine introuvable | Vérifier VLAN, passerelle, DNS `172.16.54.1`, heure et enregistrement SRV. |
| WDS renvoie `0x52E` lors de l’ajout du serveur | Contrôler `whoami` et essayer une session avec un compte du domaine autorisé. Vérifier le canal sécurisé et les journaux si l’erreur persiste. |
| WDS arrêté | Consulter `Get-Service WDSServer`, l'observateur d'événements et la disponibilité de `S:\RemoteInstall`. |
| Partage refusé | Comparer autorisations de partage et de sécurité NTFS ; tester avec `svc-mdt-read`. |

Sources : [Préparation MDT Microsoft](https://learn.microsoft.com/fr-fr/windows/deployment/deploy-windows-mdt/prepare-for-windows-deployment-with-mdt), [problèmes connus MDT](https://learn.microsoft.com/en-us/mem/configmgr/mdt/known-issues), [retrait de MDT](https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/mdt/mdt-retirement).
