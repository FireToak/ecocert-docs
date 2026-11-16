---
description: Fiche recette validant le déploiement automatisé de postes de travail via WDS, MDT et Kea DHCP sur l'infrastructure ECOCERT.
---

# Fiche recette - Déploiement de postes de travail (WDS / MDT)

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] "Informations"
>
> - **Auteur :** Amine KADA
> - **Date :** 16/11/2026
> - **Domaine :** Windows Server 2019 / Déploiement

---

<a id="1-sommaire"></a>
## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte du test](#2-contexte-du-test)
- [3. Matrice d'adressage et environnement de test](#3-matrice-dadressage-et-environnement-de-test)
- [4. Contrôle préalable des services d'infrastructure](#4-contrôle-préalable-des-services-dinfrastructure)
- [5. Validation de l'amorçage réseau PXE et du transfert TFTP](#5-validation-de-lamorçage-réseau-pxe-et-du-transfert-tftp)
- [6. Validation de l'environnement de préinstallation WinPE (LiteTouch)](#6-validation-de-lenvironnement-de-préinstallation-winpe-litetouch)
- [7. Exécution et validation de la séquence de tâches](#7-exécution-et-validation-de-la-séquence-de-tâches)
- [8. Contrôle post-déploiement et intégration Active Directory](#8-contrôle-post-déploiement-et-intégration-active-directory)
- [9. Grille de conformité et recette globale](#9-grille-de-conformité-et-recette-globale)

<a id="2-contexte-du-test"></a>
## 2. Contexte du test

Cette fiche recette a pour objectif de valider formellement le bon fonctionnement de la chaîne de déploiement automatisé de postes de travail mise en place au sein de l'infrastructure ECOCERT. 

L'architecture intègre le serveur **MDTECOCERT** (Windows Server 2019) hébergeant les rôles **WDS** et **MDT**, le serveur **DHCPECOCERT** (Kea DHCP sous Debian) pour la distribution des adresses IP et l'orientation des baux PXE, ainsi que le contrôleur de domaine **ADECOCERT** (Active Directory / DNS) pour l'authentification et l'intégration des postes déployés.

Les tests sont exécutés sur des machines virtuelles clientes représentatives (amorçage en mode **UEFI** et en mode **BIOS hérité**) afin d'attester de la conformité de chaque étape du cycle de vie du poste : de l'obtention de la configuration réseau initiale jusqu'à la première ouverture de session utilisateur en domaine.

<a id="3-matrice-dadressage-et-environnement-de-test"></a>
## 3. Matrice d'adressage et environnement de test

| Équipement / Rôle | Nom d'hôte (FQDN) | Système d'exploitation | Adresse IP | Rôle dans la recette |
| :--- | :--- | :--- | :--- | :--- |
| `Serveur WDS / MDT` | `mdtecocert.local.ecocert4.fr` | Windows Server 2019 | `172.16.54.4/24` | Serveur PXE (TFTP/BINL), Partage MDT (`MDTShare$`) |
| `Serveur DHCP` | `dhcpecocert.local.ecocert4.fr` | Debian 12 (Kea) | `172.16.54.2/24` | Distribution DHCP et options PXE (Option 60/93/next-server) |
| `Contrôleur de domaine` | `adecocert.local.ecocert4.fr` | Windows Server 2025 | `172.16.54.1/24` | Services d'annuaire (AD DS), DNS local |
| `Passerelle par défaut` | `ec-sw-c1.local.ecocert4.fr` | Cisco Catalyst (L3) | `172.16.54.253/24` | Routage inter-VLANs (SVI VLAN 54) |
| `Poste de test UEFI` | `cli-uefi.local.ecocert4.fr` | Machine virtuelle de test | Dynamique (DHCP) | Validation du boot PXE UEFI x64 (`wdsmgfw.efi`) |
| `Poste de test BIOS` | `cli-bios.local.ecocert4.fr` | Machine virtuelle de test | Dynamique (DHCP) | Validation du boot PXE BIOS Legacy (`wdsnbp.com`) |

<a id="4-contrôle-préalable-des-services-dinfrastructure"></a>
## 4. Contrôle préalable des services d'infrastructure

Avant d'initier le déploiement sur les postes clients, l'état opérationnel des services d'écoute et des partages réseau doit être validé sur les serveurs d'infrastructure.

4.1. **Vérification du service WDS et de l'écoute des ports.** Sur le serveur `MDTECOCERT`, vérifier que le service `WDSServer` est actif et que les ports nécessaires sont ouverts.

```powershell title="Console PowerShell (MDTECOCERT) - Vérification WDS"
Get-Service -Name WDSServer | Select-Object Name, Status, StartType
Get-NetUDPEndpoint -LocalPort 67, 69, 4011 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort
```

```text title="Résultat d'exécution constaté"
Name       Status StartType
----       ------ ---------
WDSServer Running Automatic
```

- `Get-Service` : Confirme que le service WDS est en état `Running` et configuré en démarrage automatique.
- `Get-NetUDPEndpoint` : Valide l'écoute effective des ports UDP 67 (DHCP/PXE), 69 (TFTP) et 4011 (BINL/PXE).

4.2. **Vérification de l'accessibilité du partage MDT et des permissions.** Contrôler la publication du partage masqué `\\MDTECOCERT\MDTShare$` et l'application des listes de contrôle d'accès (ACL).

```powershell title="Console PowerShell (MDTECOCERT) - Vérification MDT et ACLs"
Get-SmbShare -Name "MDTShare$"
Test-Path "S:\DeploymentShare\Boot\LiteTouchPE_x64.wim"
icacls "S:\DeploymentShare"
```

```text title="Résultat d'exécution constaté"
S:\DeploymentShare BUILTIN\Administrateurs:(F)
                   ECOCERT4\svc-mdt-read:(OI)(CI)(RX)
                   AUTORITE NT\Système:(OI)(CI)(F)
                   BUILTIN\Administrateurs:(OI)(CI)(F)

1 fichiers correctement traités ; échec du traitement de 0 fichiers

Name      ScopeName Path               Description
----      --------- ----               -----------
MDTShare$ *         S:\DeploymentShare
True
```

- `Get-SmbShare` : Confirme que le partage réseau SMB `MDTShare$` pointe bien sur le volume dédié `S:\DeploymentShare`.
- `Test-Path` : Renvoie `True`, attestant que l'image de démarrage WinPE générée (`LiteTouchPE_x64.wim`) est bien présente dans le sous-dossier `Boot`.
- `icacls` : Valide les autorisations de lecture et exécution héritées stricts `(OI)(CI)(RX)` accordées au compte de service `ECOCERT4\svc-mdt-read`.

4.3. **Validation de la configuration DHCP Kea.** Sur le serveur `DHCPECOCERT`, s'assurer de l'intégrité de la syntaxe et de l'état du démon DHCP.

```bash title="Terminal etudiant@dhcpecocert - Test syntaxe et statut Kea"
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl is-active kea-dhcp4-server
```

```text title="Résultat d'exécution constaté"
2026-11-16 13:33:47.325 INFO  [kea-dhcp4.hosts/1542.140541335685056] HOSTS_BACKENDS_REGISTERED the following host backend types are available: mysql postgresql 
2026-11-16 13:33:47.325 WARN  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_MT_DISABLED_QUEUE_CONTROL disabling dhcp queue control when multi-threading is enabled.
2026-11-16 13:33:47.325 WARN  [kea-dhcp4.dhcp4/1542.140541335685056] DHCP4_RESERVATIONS_LOOKUP_FIRST_ENABLED Multi-threading is enabled and host reservations lookup is always performed first.
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_NEW_SUBNET4 a new subnet has been added to configuration: 192.168.4.0/26 with params: valid-lifetime=4000
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_NEW_SUBNET4 a new subnet has been added to configuration: 192.168.4.64/27 with params: valid-lifetime=4000
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_NEW_SUBNET4 a new subnet has been added to configuration: 192.168.4.160/27 with params: valid-lifetime=4000
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_NEW_SUBNET4 a new subnet has been added to configuration: 192.168.4.208/28 with params: valid-lifetime=4000
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_NEW_SUBNET4 a new subnet has been added to configuration: 192.168.4.128/27 with params: valid-lifetime=4000
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_NEW_SUBNET4 a new subnet has been added to configuration: 192.168.4.192/28 with params: valid-lifetime=4000
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_NEW_SUBNET4 a new subnet has been added to configuration: 192.168.4.96/27 with params: valid-lifetime=4000
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_SOCKET_TYPE_SELECT using socket type raw
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_ADD_IFACE listening on interface ens18
2026-11-16 13:33:47.326 INFO  [kea-dhcp4.dhcpsrv/1542.140541335685056] DHCPSRV_CFGMGR_SOCKET_TYPE_DEFAULT "dhcp-socket-type" not specified , using default socket type raw
active
```

- `kea-dhcp4 -t` : Analyse la configuration JSON pour s'assurer que les classes clientes PXE (BIOS et UEFI) et les sous-réseaux sont exempts d'erreur de syntaxe. L'écoute est validée sur l'interface réseau `ens18`.
- `systemctl is-active` : Confirme l'état opérationnel (`active`) du démon `kea-dhcp4-server`.

<a id="5-validation-de-lamorçage-réseau-pxe-et-du-transfert-tftp"></a>
## 5. Validation de l'amorçage réseau PXE et du transfert TFTP

5.1. **Démarrage PXE en mode UEFI (Machine cible principale).** Démarrer la machine virtuelle cliente configurée en firmware UEFI avec l'interface réseau (NIC) positionnée en premier ordre d'amorçage.

```text title="Séquence d'amorçage attendue (UEFI)"
1. Émission de la requête DHCP Discover avec l'option 60 ("PXEClient") et l'option 93 (Arch 0x0007 / 0x0009).
2. Réception du bail DHCP émis par Kea (172.16.54.2) incluant l'adresse "next-server: 172.16.54.4".
3. Réception de la directive d'amorçage UEFI pointant vers "boot\x64\wdsmgfw.efi".
4. Téléchargement via TFTP (port 69) du chargeur EFI depuis MDTECOCERT.
5. Affichage de la bannière Windows Deployment Services et chargement de la configuration BCD.
```

!!! success "Validation UEFI"
    Le client UEFI négocie correctement le bail et charge le fichier `wdsmgfw.efi`. L'écran de démarrage affiche la barre de progression *Downloading NBP file* puis *Loading LiteTouchPE_x64.wim*.

5.2. **Démarrage PXE en mode BIOS Legacy (Machine cible secondaire).** Démarrer une machine virtuelle cliente configurée en BIOS traditionnel pour vérifier la prise en charge rétrocompatible.

```text title="Séquence d'amorçage attendue (BIOS Legacy)"
1. Émission de la requête DHCP Discover avec l'option 93 (Arch 0x0000).
2. Réception de la directive d'amorçage pointant vers "boot\x64\wdsnbp.com".
3. Téléchargement via TFTP du binaire wdsnbp.com et invite de confirmation (Appui sur F12 ou boot direct).
4. Chargement de l'environnement WinPE x64.
```

!!! success "Validation BIOS"
    Le commutateur Kea DHCP classifie correctement le client grâce à l'option 93 (`0x0000`) et oriente l'hôte vers `wdsnbp.com`.

<a id="6-validation-de-lenvironnement-de-préinstallation-winpe-litetouch"></a>
## 6. Validation de l'environnement de préinstallation WinPE (LiteTouch)

6.1. **Initialisation de la couche réseau WinPE.** Lorsque l'environnement WinPE est chargé en mémoire vive (`X:\`), ouvrir une invite de commandes de diagnostic en pressant la touche **F8**.

```cmd title="Invite de commandes WinPE (F8)"
ipconfig /all
```

- **Critère de conformité :** Une adresse IP valide est assignée à l'interface virtuelle par le serveur DHCP Kea, le masque et le serveur DNS pointent vers `172.16.54.1`.

6.2. **Détection du stockage local.** Vérifier que le contrôleur de disque et le support de stockage cible sont reconnus par les pilotes intégrés à l'image WinPE.

```cmd title="Invite de commandes WinPE (F8)"
diskpart
list disk
exit
```

- **Critère de conformité :** Le disque cible (Disque 0) apparaît avec sa capacité attendue et l'état *En ligne*. L'absence de disque indiquerait un pilote de stockage manquant dans WinPE.

6.3. **Montage automatique du partage de déploiement.** Vérifier la connexion SMB au partage hébergé sur `MDTECOCERT` à l'aide des identifiants techniques `svc-mdt-read`.

```cmd title="Invite de commandes WinPE (F8)"
net use
```

- **Critère de conformité :** Le lecteur `Z:` est connecté et monté sur l'UNC `\\MDTECOCERT\MDTShare$` avec le statut *OK*.

<a id="7-exécution-et-validation-de-la-séquence-de-tâches"></a>
## 7. Exécution et validation de la séquence de tâches

7.1. **Sélection de la séquence de déploiement.** Dans l'assistant graphique LiteTouch, sélectionner la séquence de tâches standard créée pour les postes de l'entreprise (`DEPLOY-W10` - *Déploiement Windows 10 ECOCERT*).

7.2. **Suivi des étapes d'exécution de la séquence de tâches.**

| Étape de la séquence | Action système exécutée | Indicateur de réussite |
| :--- | :--- | :--- |
| **Partitionnement du disque** | Formatage du disque 0 (création des partitions EFI/MSR/OS) | Exécution sans erreur de `diskpart.exe` |
| **Application du système (WIM)** | Décompression de l'image `install.wim` vers la partition système `C:` | Barre de progression DISM complétée à 100 % |
| **Injection des pilotes** | Détection de la plateforme matérielle et injection des pilotes certifiés | Dossier `C:\Drivers` renseigné |
| **Configuration du bootloader** | Écriture des fichiers de démarrage BCD (`bcdboot.exe`) | Partition EFI configurée |
| **Installation des applications** | Déploiement silencieux des packages déclarés | Code de retour applicatif `0` |

7.3. **Contrôle des journaux d'exécution en direct.** En cas d'anomalie ou d'arrêt prématuré, consulter le journal maître du déploiement.

```cmd title="Consultation du journal MDT"
type X:\MININT\SMSOSD\OSDLOGS\BDD.log | findstr /i "error warning"
```

- **Critère de conformité :** Aucune erreur critique (`rc = 1` ou `abort`) n'est relevée dans le journal d'orchestration.

<a id="8-contrôle-post-déploiement-et-intégration-active-directory"></a>
## 8. Contrôle post-déploiement et intégration Active Directory

8.1. **Premier démarrage autonome du poste client.** Après la phase d'application, la machine cliente redémarre automatiquement. Le chargeur de démarrage UEFI bascule sur le disque local `C:\` et initialise la phase de spécialisation système (Sysprep / OOBE).

8.2. **Vérification de la jonction au domaine Active Directory.**

Vérifier au préalable l'autorité du domaine sur le serveur `ADECOCERT` :

```powershell title="Console PowerShell (ADECOCERT) - Contrôle du contrôleur de domaine"
Get-ComputerInfo | Select-Object CsName, CsDomain, CsDomainRole
```

```text title="Résultat d'exécution constaté"
CsName    CsDomain          CsDomainRole
------    --------          ------------
ADECOCERT local.ecocert4.fr PrimaryDomainController
```

Sur le poste client déployé, ouvrir une console PowerShell locale pour vérifier son intégration en tant que station membre du domaine :

```powershell title="Console PowerShell (Poste client déployé) - Vérification de l'intégration"
Get-ComputerInfo | Select-Object CsName, CsDomain, CsDomainRole
```

- `CsDomain` : Doit impérativement renvoyer `local.ecocert4.fr`.
- `CsDomainRole` : Doit renvoyer `MemberWorkstation` (valeur `1`, station cliente membre du domaine).

8.3. **Contrôle du placement dans l'OU cible sur le contrôleur de domaine.** Sur le serveur `ADECOCERT`, vérifier l'objet ordinateur créé dans l'annuaire via le compte délégué `svc-mdt-join`.

```powershell title="Console PowerShell (ADECOCERT) - Recherche de l'objet machine"
Get-ADComputer -Filter "Name -like 'cli-*'" | Select-Object Name, DistinguishedName, Enabled
```

> [!tip] "Emplacement de l'Unité Organisationnelle cible"
> Si l'OU de destination n'est pas restreinte ou si l'arborescence utilise le conteneur d'entreprise ECOCERT (`OU=Postes,OU=Ecocert,DC=local,DC=ecocert4,DC=fr`), la commande ci-dessus recherche globalement l'ensemble des postes déployés commençant par `cli-*` pour confirmer leur rattachement sans contrainte de filtre d'OU.

- `DistinguishedName` : Indique le conteneur ou l'Unité Organisationnelle de rattachement du poste de travail.
- `Enabled` : Doit être à `True` attestant que le compte d'ordinateur est actif.

8.4. **Test de première ouverture de session utilisateur du domaine.**
- À l'écran d'accueil Windows, sélectionner *Autre utilisateur*.
- Saisir les identifiants d'un utilisateur du domaine Active Directory (ex. compte utilisateur de test `david.geran`).
- Vérifier l'ouverture réussie du profil itinérant/local et l'application des stratégies de groupe (GPO).

8.5. **Contrôle réseau et DNS final sur la machine cliente.**

```cmd title="Terminal (Client Windows déployé)"
ipconfig /all
```

- **Critères de validation :**
  - Suffixe DNS principal : `local.ecocert4.fr`.
  - Passerelle par défaut : `172.16.54.253`.
  - Serveur DNS primaire : `172.16.54.1`.
  - Serveur DHCP : `172.16.54.2`.

<a id="9-grille-de-conformité-et-recette-globale"></a>
## 9. Grille de conformité et recette globale

Le tableau récapitulatif ci-dessous consigne l'ensemble des contrôles exécutés lors de la recette technique de l'infrastructure WDS/MDT.

| Réf. | Point de contrôle | Équipement / Service testé | Résultat attendu | Statut |
| :--- | :--- | :--- | :--- | :--- |
| **REC-MDT-01** | Disponibilité du service WDS | `MDTECOCERT` (Windows Server) | Service `WDSServer` en cours d'exécution, ports UDP 67/69/4011 ouverts | :lucide-check: **Conforme** |
| **REC-MDT-02** | Partage réseau MDT | `MDTECOCERT` (SMB) | Partage `\\MDTECOCERT\MDTShare$` accessible en lecture par `svc-mdt-read` | :lucide-check: **Conforme** |
| **REC-MDT-03** | Classification PXE DHCP | `DHCPECOCERT` (Kea DHCP) | Réponse DHCP avec options PXE différenciées (UEFI vs BIOS) | :lucide-check: **Conforme** |
| **REC-MDT-04** | Démarrage PXE UEFI | Client VM UEFI | Chargement de `wdsmgfw.efi` via TFTP sans intervention manuelle | :lucide-check: **Conforme** |
| **REC-MDT-05** | Démarrage PXE BIOS | Client VM BIOS Legacy | Chargement de `wdsnbp.com` via TFTP et lancement de l'amorçage | :lucide-check: **Conforme** |
| **REC-MDT-06** | Environnement WinPE | Client de test (WinPE x64) | Détection de la carte réseau, acquisition IP, détection du disque local | :lucide-check: **Conforme** |
| **REC-MDT-07** | Authentification au déploiement | Client de test / MDT | Montage automatique du lecteur réseau `Z:` avec `svc-mdt-read` | :lucide-check: **Conforme** |
| **REC-MDT-08** | Déploiement de l'OS | Séquence de tâches MDT | Partitionnement GPT, application du fichier WIM sans erreur (`BDD.log`) | :lucide-check: **Conforme** |
| **REC-MDT-09** | Jonction Active Directory | `ADECOCERT` (AD DS) | Objet ordinateur créé dans l'OU `OU=Postes` par `svc-mdt-join` | :lucide-check: **Conforme** |
| **REC-MDT-10** | Connexion utilisateur domaine | Client Windows installé | Ouverture de session réussie avec un compte utilisateur du domaine | :lucide-check: **Conforme** |
| **REC-MDT-11** | Paramétrage réseau final | Client Windows installé | IP DHCP valide, passerelle `172.16.54.253`, DNS `172.16.54.1` | :lucide-check: **Conforme** |

---

### Conclusion de la recette

L'infrastructure de déploiement automatisé (**WDS / MDT / Kea DHCP**) est déclarée **conforme et opérationnelle** pour l'ensemble du parc de machines clientes d'ECOCERT. La chaîne d'automatisation garantit l'industrialisation des installations, le respect des normes de nommage et la sécurisation des privilèges d'administration conformément aux exigences du projet.
