---
description: Configuration de WinPE x64, du Deployment Share MDT, du PXE WDS avec Kea DHCP, des séquences de tâches et des tests de validation
---

# Configuration du déploiement PXE (MDT / WDS / Kea DHCP) — Windows Server 2019

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
- [3. Configuration de l'architecture WinPE](#3-configuration-de-larchitecture-winpe)
- [4. Diagnostic des erreurs DISM et des montages WIM](#4-diagnostic-des-erreurs-dism-et-des-montages-wim)
- [5. Import des systèmes, pilotes et applications](#5-import-des-systemes-pilotes-et-applications)
- [6. Séquences de tâches](#6-sequences-de-taches)
- [7. Configuration PXE : WDS et Kea DHCP](#7-configuration-pxe-wds-et-kea-dhcp)
- [8. Sécurisation du PXE](#8-securisation-du-pxe)
- [9. Tests de validation](#9-tests-de-validation)
- [10. Journalisation et dépannage](#10-journalisation-et-depannage)
- [11. Sauvegarde, restauration et retour arrière](#11-sauvegarde-restauration-et-retour-arriere)
- [12. Sources](#12-sources)

## 2. Contexte

Cette fiche décrit la **procédure de configuration et de validation** du déploiement PXE, une fois WDS et MDT installés sur **MDTECOCERT** (`172.16.54.4`, Windows Server 2019) selon la fiche d'installation. Elle couvre l'architecture WinPE, le diagnostic DISM, l'import des ressources MDT, le PXE avec **DHCPECOCERT** (`172.16.54.2`, Kea DHCP) et les tests. Les résultats réels des tests sont consignés en section 9.

> [!warning] "Rappel de statut"
>
> MDT est retiré par Microsoft (06/01/2026) et WDS est déprécié à partir de la prochaine version de Windows Server (annonce du 21/09/2026). Cette procédure vise un laboratoire ou un environnement existant. Voir la fiche d'installation, section 2.

## 3. Configuration de l'architecture WinPE {#3-configuration-de-larchitecture-winpe}

3.1. **Problème d'architecture par défaut.** Le Deployment Share peut tenter de générer des images **x86 et x64**. Si les composants WinPE x86 ne sont pas présents dans l'ADK installé, DISM échoue. Les ADK récents ne fournissent plus WinPE x86, ce qui rend cette cause plausible sans la prouver : valider avec les vérifications du 3.3 et les journaux de la section 4.

> [!note] "Message d'erreur observé"
>
> ```text
> Unable to open the specified WIM file
> DISM /Set-TargetPath failed, rc = 1
> ```
>
> Traduction : « Impossible d'ouvrir le fichier WIM spécifié ». Ce message seul ne prouve pas la cause.

3.2. **Restriction à x64.** Dans le Deployment Workbench : clic droit sur le Deployment Share > **Properties**.

- Onglet **General** : dans *Platforms Supported*, **décocher x86** et conserver **x64**
- Onglet **Windows PE** : sélectionner *Platform : x64* et vérifier les paramètres de l'image (nom, pilotes, ISO éventuel)

3.3. **Vérification de l'ADK et de WinPE.**

```powershell title="Contrôle des composants WinPE x64"
Test-Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\en-us\winpe.wim"
Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment" -Directory
```

> [!note] "x64 n'est pas UEFI"
>
> L'architecture (x64) et le mode de démarrage (UEFI ou BIOS Legacy) sont deux notions distinctes. Un client x64 peut démarrer dans l'un ou l'autre mode. Cela a un impact direct sur le choix du programme de démarrage PXE (section 7).

## 4. Diagnostic des erreurs DISM et des montages WIM {#4-diagnostic-des-erreurs-dism-et-des-montages-wim}

4.1. **Identifier les montages avant toute action.**

```powershell title="Lister les images montées"
dism /Get-MountedWimInfo
```

4.2. **Appliquer la logique dans l'ordre.** Ne jamais lancer un nettoyage sur un montage encore utilisé par une opération en cours.

| Situation | Commande |
| :-------- | :------- |
| Montage récupérable | `dism /Remount-Image /MountDir:"<CHEMIN_MONTAGE>"` |
| Montage à abandonner proprement | `dism /Unmount-Image /MountDir:"<CHEMIN_MONTAGE>" /Discard` |
| Montage corrompu ou orphelin | `dism /Cleanup-Mountpoints` |

- `<CHEMIN_MONTAGE>` : le répertoire réellement indiqué par `dism /Get-MountedWimInfo` (à relever lors de l'erreur et à documenter)
- `/Discard` : abandonne les modifications de l'image montée
- `/Cleanup-Mountpoints` : nettoie les points de montage abandonnés ; ne remplace pas un démontage normal

4.3. **Régénérer correctement les images de démarrage.** La commande de régénération est celle du Deployment Share, **pas** `LiteTouch.vbs` (qui lance un déploiement Lite Touch).

```powershell title="Régénération du Deployment Share"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
Update-MDTDeploymentShare -Path "DS001:" -Force -Verbose
```

Équivalent graphique : **Deployment Workbench > Deployment Shares > clic droit > Update Deployment Share**.

4.4. **Journaux à consulter en cas d'échec.**

```text title="Emplacements des journaux"
C:\Windows\Logs\DISM\dism.log
Console Deployment Workbench : sortie de l'Update Deployment Share
Observateur d'événements : Journaux des applications et services
```

## 5. Import des systèmes, pilotes et applications {#5-import-des-systemes-pilotes-et-applications}

5.1. **Importer le système d'exploitation.** Monter l'ISO Windows et importer le contenu.

```powershell title="Import du système d'exploitation"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "S:\DeploymentShare" -ErrorAction SilentlyContinue
Import-MDTOperatingSystem -Path "DS001:\Operating Systems" -SourcePath "<LECTEUR_ISO>:\" -DestinationFolder "<NOM_DOSSIER_OS>" -Verbose
```

- `-SourcePath` : lecteur sur lequel l'ISO est monté (ex. `E:\`)
- `-DestinationFolder` : nom du dossier créé dans le Deployment Share

Équivalent graphique : **Deployment Shares > S:\DeploymentShare > Operating Systems > Import Operating System**.

Documenter pour chaque système importé : source ISO, version et build exacts, édition et index de l'image, provenance du média.

5.2. **Organiser les pilotes par modèle matériel.** Ne pas injecter un répertoire global de pilotes sur toutes les machines.

```text title="Arborescence conseillée dans Out-of-Box Drivers"
Windows 11 x64
├── <Constructeur 1>
│   └── <Modèle A>
└── <Constructeur 2>
    └── <Modèle B>
```

> [!warning] "Pilotes WinPE"
>
> Prévoir les pilotes **réseau** et **stockage** nécessaires à WinPE (onglet *Windows PE > Drivers and Patches* des propriétés du Deployment Share). Sans eux, WinPE ne détecte pas la carte réseau ou le disque cible et ne peut ni joindre `\\MDTECOCERT\MDTShare$` ni installer le système. Régénérer ensuite l'image (4.3) et la remplacer dans WDS.

5.3. **Importer les applications.** Deployment Workbench > *Applications* > *New Application*, avec une ligne de commande d'installation silencieuse testée à la main au préalable.

## 6. Séquences de tâches {#6-sequences-de-taches}

6.1. **Choisir le modèle de séquence.** Ne pas créer une séquence par département par défaut. Si les différences sont des logiciels ou des paramètres, utiliser **une séquence standard** et gérer les particularités avec des variables, des conditions et des profils de sélection. Séparer les séquences seulement si les processus d'installation diffèrent réellement.

| Département | Différence typique | Gestion recommandée |
| :---------- | :----------------- | :------------------ |
| Informatique | Outils d'administration | Profil de sélection d'applications |
| Comptabilité | Logiciels comptables | Profil de sélection d'applications |
| Direction / RH | Applications métier | Profil de sélection d'applications |

6.2. **Créer la séquence.** Deployment Workbench > *Task Sequences* > *New Task Sequence*, modèle **Standard Client Task Sequence**, puis sélection du système importé en 5.1.

6.3. **Renseigner les règles de jonction.** Dans *Deployment Share > Properties > Rules* (`CustomSettings.ini`) :

```ini title="CustomSettings.ini (extrait)"
[Settings]
Priority=Default

[Default]
OSInstall=Y
SkipBDDWelcome=NO
JoinDomain=local.ecocert4.fr
DomainAdmin=svc-mdt-join
DomainAdminDomain=local.ecocert4.fr
MachineObjectOU=OU=Postes,DC=local,DC=ecocert4,DC=fr
```

- `DomainAdmin` : compte de jonction à droits **délégués** sur l'OU, jamais un Domain Admin
- `MachineObjectOU` : OU cible (**à adapter** à ton annuaire)
- Le mot de passe n'est pas saisi dans ce fichier : le demander à l'assistant ou le fournir autrement, en tenant compte du risque décrit dans la fiche d'installation (section 7.3)

6.4. **Régénérer et remplacer l'image.** Après toute modification des règles ou des pilotes WinPE : `Update-MDTDeploymentShare -Path "DS001:" -Force`, puis *Replace Image* dans WDS.

## 7. Configuration PXE : WDS et Kea DHCP {#7-configuration-pxe-wds-et-kea-dhcp}

7.1. **Principe.** Kea attribue les adresses IP. WDS répond aux requêtes PXE et choisit le programme de démarrage selon l'architecture du client (BIOS ou UEFI). Microsoft déconseille de rediriger les clients PXE avec les options DHCP 66/67 : une valeur unique casse l'un des deux modes de démarrage.

| Mode du client | Programme WDS |
| :------------- | :------------ |
| BIOS Legacy (x86/x64) | `boot\x64\wdsnbp.com` |
| UEFI x64 | `boot\x64\wdsmgfw.efi` |

> [!note] "`next-server` n'est pas l'option 66"
>
> Dans Kea, `next-server` correspond au champ `siaddr` du paquet DHCP, `server-hostname` au champ `sname` et `boot-file-name` au champ `file`. Les options DHCP 66 et 67 sont des options distinctes. Beaucoup de clients PXE utilisent les champs fixes, d'autres les options : ne pas supposer l'équivalence.

7.2. **Configurer la réponse WDS.**

```powershell title="Réponse aux clients PXE"
WDSUTIL /Set-Server /Server:MDTECOCERT /AnswerClients:All
```

- `/AnswerClients:All` : répond à tous les clients (laboratoire)
- En production, utiliser `Known` pour ne répondre qu'aux ordinateurs préconfigurés dans AD

Dans `wdsmgmt.msc` > Propriétés du serveur > onglet **Boot** : définir l'image de démarrage par défaut sur `LiteTouchPE_x64` pour les architectures **x64** et **x64 uefi**.

7.3. **Scénario A (recommandé) : clients et WDS dans le même VLAN.** Ne définir **aucune** valeur PXE dans Kea : le client reçoit son IP de Kea, puis WDS répond à la requête PXE avec le bon programme. Vérifier sur Debian qu'aucune valeur résiduelle ne subsiste :

```bash title="Contrôle de l'absence de paramètres PXE dans Kea"
grep -nE 'next-server|boot-file-name|server-hostname' /etc/kea/kea-dhcp4.conf
```

Aucune ligne ne doit s'afficher. Si des lignes apparaissent, les retirer (après sauvegarde, section 11).

7.4. **Scénario B : clients dans d'autres VLAN.** Configurer sur les routeurs ou commutateurs de niveau 3 **deux IP Helpers** par interface VLAN : `172.16.54.2` (Kea) et `172.16.54.4` (WDS). Le serveur WDS reçoit ainsi une copie de la requête DHCP avec les informations PXE du client, et choisit lui-même le bon programme de démarrage.

7.5. **Scénario C (dernier recours) : Kea impose le fichier selon l'architecture.** À n'utiliser que si le scénario A ou B est impossible, et à tester sur chaque modèle de client. Kea classe les clients avec l'option 93 (architecture PXE) : `0x0000` pour BIOS, `0x0007` ou `0x0009` pour UEFI x64.

```json title="/etc/kea/kea-dhcp4.conf (extrait, dans le bloc Dhcp4)"
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
```

- `option[60]` : identifiant de classe du fournisseur (`PXEClient`)
- `option[93]` : architecture du client PXE (RFC 4578)
- `\\` : le backslash doit être doublé en JSON
- `vendor-class-identifier` (option 60) : certains chargeurs EFI en ont besoin quand DHCP et PXE sont sur des serveurs distincts, à valider en test

> [!warning] "Ne pas remplacer simplement le fichier"
>
> Remplacer `wdsnbp.com` par `wdsmgfw.efi` pour tout le monde ne ferait que déplacer le problème vers les clients BIOS.

7.6. **Valider la syntaxe avant tout redémarrage.**

```bash title="Contrôles de configuration Kea"
kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
kea-dhcp4 -T /etc/kea/kea-dhcp4.conf
```

- `-t` : vérifie la syntaxe de la configuration
- `-T` : effectue en plus des contrôles étendus (bibliothèques d'extension, connexions éventuelles à des bases de données)

Le code de sortie `0` indique une configuration correcte.

7.7. **Application et vérification du service.** Identifier d'abord le véritable nom de l'unité, car il dépend du paquet installé.

```bash title="Identification, redémarrage et contrôle"
systemctl list-unit-files 'kea*'
systemctl restart kea-dhcp4-server
systemctl status kea-dhcp4-server
journalctl -u kea-dhcp4-server -n 100 --no-pager
```

Un `systemctl status` positif ne prouve pas que le DHCP fonctionne : valider en section 9 qu'un client obtient bien une adresse.

## 8. Sécurisation du PXE {#8-securisation-du-pxe}

8.1. **Limiter l'exposition.**

- Restreindre le PXE aux VLAN de déploiement : IP Helpers uniquement sur ces VLAN
- Filtrer les flux au strict nécessaire (UDP 67, 69, 4011, TCP 445) entre les clients de déploiement et `MDTECOCERT`
- En production, répondre uniquement aux clients connus (`/AnswerClients:Known`)
- Conserver **Secure Boot** lorsque le matériel et la chaîne de démarrage le permettent
- Ne jamais utiliser WDS « hands-free » (fichiers `Unattend.xml` transmis par le mécanisme WDS non authentifié) : désactivé par défaut depuis les mises à jour d'avril 2026. L'automatisation de cette fiche repose sur MDT, pas sur ce mécanisme.

8.2. **Comptes.** Respecter la séparation décrite dans la fiche d'installation (3.4) : lecture seule pour WinPE, jonction déléguée à l'OU, administration par un compte dédié.

## 9. Tests de validation {#9-tests-de-validation}

9.1. **Préparer la VM cliente de test.** Créer une VM dans le même VLAN, ordre de démarrage réseau en premier, **mode UEFI** pour un premier test puis **BIOS** pour le second. Pour des essais de jonction, vérifier que la VM a assez de RAM pour WinPE (2 Go minimum recommandés).

9.2. **Exécuter la grille de tests et consigner les résultats.**

| Test | Résultat attendu | Résultat constaté / date |
| :--- | :--------------- | :----------------------- |
| Attribution DHCP | IP correcte dans la plage Kea | |
| Réponse PXE | Réponse de `172.16.54.4` | |
| Programme d'amorçage | `wdsmgfw.efi` (UEFI) ou `wdsnbp.com` (BIOS) | |
| Transfert TFTP | Aucun échec | |
| Démarrage WinPE | Image `LiteTouchPE_x64` chargée | |
| Carte réseau WinPE | Interface fonctionnelle, IP obtenue | |
| Stockage WinPE | Disque cible détecté | |
| Accès MDT | `\\MDTECOCERT\MDTShare$` accessible | |
| Séquence de tâches | Séquence correcte proposée | |
| Installation Windows | Fin sans erreur | |
| Pilotes | Aucun périphérique inconnu | |
| Domaine | Jonction réussie dans l'OU cible | |
| Applications | Installation validée | |
| Redémarrage | Système opérationnel | |

9.3. **Tests d'échec contrôlés.** Vérifier le comportement et la lisibilité des erreurs dans ces cas :

- Partage MDT inaccessible (service ou règle coupés)
- Absence de réponse PXE (service `WDSServer` arrêté)
- Pilote réseau manquant dans WinPE
- Espace disque insuffisant sur le poste cible

9.4. **Conserver les journaux et résultats** de chaque campagne de test.

## 10. Journalisation et dépannage {#10-journalisation-et-depannage}

10.1. **Où chercher.**

| Composant | Emplacement |
| :-------- | :---------- |
| WDS | Observateur d'événements : *Journaux des applications et services > Microsoft > Windows > Deployment-Services-Diagnostics* |
| DISM | `C:\Windows\Logs\DISM\dism.log` |
| MDT, pendant WinPE | `X:\MININT\SMSOSD\OSDLOGS` |
| MDT, après installation | `C:\MININT\SMSOSD\OSDLOGS` ou `C:\Windows\Temp\DeploymentLogs` (fichier `BDD.log`) |
| Kea | `journalctl -u kea-dhcp4-server` et fichiers définis dans la section `loggers` |

10.2. **Pour savoir à quelle étape un déploiement a échoué,** corréler : réponse DHCP (Kea), réponse PXE (WDS), chargement de l'image (TFTP), accès SMB (journaux Windows) et séquence de tâches (`BDD.log`).

## 11. Sauvegarde, restauration et retour arrière {#11-sauvegarde-restauration-et-retour-arriere}

11.1. **Avant toute modification de Kea en production.**

```bash title="Sauvegarde de la configuration Kea"
cp -a /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.$(date +%F-%H%M).bak
```

Puis : tester la configuration (7.6), appliquer pendant une fenêtre de maintenance, vérifier qu'un client obtient bien une adresse. Pour revenir en arrière, restaurer le `.bak`, relancer `kea-dhcp4 -t`, puis redémarrer le service.

11.2. **Sauvegarde côté Windows.** Sauvegarder `S:\RemoteInstall\` et `S:\DeploymentShare\` (sauvegarde Windows Server ou copie vers un volume distinct) et tester la restauration sur une VM isolée.

## 12. Sources {#12-sources}

- Microsoft TechNet — « You want to PXE boot? Don't use DHCP options » : https://techcommunity.microsoft.com/blog/configurationmanagerblog/you-want-to-pxe-boot-dont-use-dhcp-options-/275562
- Microsoft Learn — Retraite de MDT : https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/mdt/mdt-retirement
- Microsoft Learn — Download and install the Windows ADK : https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install
- Red Hat — Configuring the DHCPv4 server for network boot (Kea, classes par option 93) : https://docs.redhat.com/ja/documentation/red_hat_enterprise_linux/10/html/interactively_installing_rhel_over_the_network/configuring-the-dhcpv4-server-for-network-boot_http
- ISC Kea — Manuel de référence DHCPv4 (`next-server` / `siaddr`) : https://kea.readthedocs.io/en/kea-2.4.0/arm/dhcp4-srv.html#next-server-siaddr
- IT-Connect — PXE BIOS et UEFI avec WDS et DHCP : https://www.it-connect.fr/serveurs-dhcp-wds-boot-pxe-bios-et-uefi/
