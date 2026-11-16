---
description: Configuration de Windows 10, MDT, WinPE et du démarrage PXE pour la SP4 ECOCERT.
---

# Configuration du déploiement PXE avec MDT, WDS et Kea

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

> [!note] "Informations"
> - **Auteur :** Amine KADA
> - **Domaine :** Windows Server 2019 / Debian
> - **Prérequis :** [installation du serveur MDTECOCERT](installation-mdt-wds.md)

## 1. Contexte

Cette fiche permet de créer une séquence de déploiement Windows 10 x64, de construire l'image LiteTouch WinPE et de la démarrer sur des clients BIOS et UEFI. Le client récupère son adresse auprès de Kea, démarre avec WDS et utilise ensuite le partage MDT pour installer Windows, les pilotes et les applications.

| Élément | Valeur |
| :--- | :--- |
| Serveur WDS / MDT | `172.16.54.4` — `MDTECOCERT` |
| Serveur DHCP | `172.16.54.2` — `DHCPECOCERT` |
| AD / DNS | `172.16.54.1` — `ADECOCERT` |
| Partage | `\\MDTECOCERT\MDTShare$` |
| Image de démarrage | `S:\DeploymentShare\Boot\LiteTouchPE_x64.wim` |

## 2. Importer Windows 10

2.1. Monter l'ISO Windows 10 x64 sur MDTECOCERT. Dans l'explorateur, noter la lettre du lecteur contenant les dossiers `sources` et `boot`.

2.2. Dans **Deployment Workbench > Deployment Shares > ECOCERT Deployment Share > Operating Systems**, clic droit **Import Operating System**. Choisir **Full set of source files**, sélectionner la racine du lecteur ISO, puis saisir `Windows_10_Pro_x64` comme dossier de destination. Terminer et attendre la copie.

2.3. Développer **Operating Systems** et vérifier que l'édition Windows 10 souhaitée figure dans la liste. Le support et la licence de l'édition utilisée doivent correspondre au laboratoire.

## 3. Importer les applications et pilotes

3.1. **LibreOffice.** Télécharger le MSI Windows x64 officiel sur le serveur. Dans **Applications**, clic droit > **New Application > Application with source files**. Renseigner le nom `LibreOffice x64`, sélectionner le dossier contenant le MSI, puis un nom de dossier de destination. Dans **Command line**, saisir le nom exact du MSI importé :

```text
msiexec.exe /i "LibreOffice_x64.msi" /qn /norestart
```

Renommer préalablement une copie du MSI en `LibreOffice_x64.msi` dans le dossier source, ou adapter la commande à son nom réel. Laisser le répertoire de travail proposé par l'assistant et terminer.

3.2. **Firefox.** Télécharger le MSI officiel Firefox x64. Répéter **New Application > Application with source files**, nommer l'entrée `Firefox x64` et utiliser la commande suivante avec le nom réel du fichier MSI :

```text
msiexec.exe /i "Firefox_x64.msi" /qn /norestart
```

Tester les commandes silencieuses sur un poste de laboratoire avant de généraliser. Ces applications seront sélectionnées dans l'assistant MDT selon le service.

3.3. **Vérifier les fichiers importés et la commande.** Dans **Applications > Firefox x64 > Properties > Details**, le champ **Working directory** désigne le dossier relatif au partage MDT. Vérifier que le MSI s'y trouve et que **Quiet install command** reprend son nom exact, extension comprise. Par exemple, si le dossier est `S:\DeploymentShare\Applications\Firefox Setup 160.0` :

```powershell
Get-ChildItem 'S:\DeploymentShare\Applications\Firefox Setup 160.0' | Select-Object Name, Length
```

Si le fichier affiché est `Firefox Setup 160.0.msi`, utiliser :

```text
msiexec.exe /i "Firefox Setup 160.0.msi" /qn /norestart
```

Adapter le nom à la copie réellement présente. Procéder de même pour LibreOffice dans son propre dossier. Un fichier présent uniquement dans `S:\Appli` ne prouve pas qu'il est accessible dans le répertoire de travail MDT. L'erreur MSI `1619` signifie que le package n'a pas pu être ouvert ; vérifier le nom, le dossier, les permissions et les journaux.

3.4. **Pilotes.** Dans **Out-of-Box Drivers**, créer des dossiers par système et modèle, puis utiliser **Import Drivers** sur les dossiers contenant les fichiers `.inf` extraits des pilotes constructeur. Importer les pilotes réseau et stockage nécessaires à WinPE, notamment VirtIO pour les VM de test. Créer un **Selection Profile** dans **Advanced Configuration > Selection Profiles** pour ces pilotes de démarrage ; dans les propriétés du partage > **Windows PE > Drivers and Patches**, sélectionner ce profil. Pour les postes physiques, préparer et tester un profil adapté à chaque modèle ; la simple création des dossiers n'applique pas automatiquement une sélection par modèle.

## 4. Créer la séquence de tâches

4.1. Dans **Task Sequences**, clic droit > **New Task Sequence** et renseigner :

| Écran | Valeur |
| :--- | :--- |
| Task sequence ID | `DEPLOY-W10` |
| Task sequence name | `Déploiement Windows 10 ECOCERT` |
| Template | `Standard Client Task Sequence` |
| OS | Édition Windows 10 x64 importée |
| Product key | Choisir l'option adaptée à la licence du laboratoire |
| Nom d'organisation | `ECOCERT` |

Terminer l'assistant. La séquence standard comprend les étapes de partitionnement adaptées aux modes BIOS et UEFI ; vérifier dans **Properties > Task Sequence > Preinstall** que les étapes et leurs conditions BIOS/UEFI sont présentes. Le partitionnement efface le disque cible : utiliser une VM de test sans données à conserver.

4.2. **Activer l'installation des applications.** Dans **Task Sequences > Déploiement Windows 10 ECOCERT > Properties > Task Sequence > State Restore > Install Applications**, vérifier que l'étape est activée et que **Install multiple applications** est sélectionné.

4.3. Pour la première recette, garder la sélection interactive des applications :

| Service | Applications à sélectionner |
| :--- | :--- |
| Administration / Secrétariat | LibreOffice |
| Administration / Juridique | LibreOffice et Firefox |
| Référentiels | Firefox |

Cette sélection répond au besoin fonctionnel pour les tests ; pour automatiser ensuite par service, créer des séquences distinctes ou des règles MDT et vérifier chaque profil.

## 5. Configurer les règles MDT et les OU

5.1. **Préparer les OU.** Sur ADECOCERT, les OU `Postes` sous les services ci-dessous ont été relevées après leur création. Dans **Utilisateurs et ordinateurs Active Directory**, vérifier l'existence des OU et déléguer au compte de jonction autorisé les droits nécessaires à la création et, le cas échéant, à la réutilisation des objets ordinateurs. Ne pas confondre ce compte avec le compte de lecture du partage.

5.2. **Configurer les règles.** Sur MDTECOCERT, clic droit sur **ECOCERT Deployment Share > Properties > Rules**. Sauvegarder le contenu actuel, puis adapter les règles sans effacer d'autres réglages propres au site. Voici la configuration retenue pour le laboratoire :

```ini
[Settings]
Priority=Default

[Default]
OSInstall=Y
SkipBDDWelcome=YES
SkipTaskSequence=NO
SkipComputerName=NO
SkipDomainMembership=NO
JoinDomain=local.ecocert4.fr
DomainOUs1=OU=Postes,OU=Compta,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs2=OU=Postes,OU=Juridique,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs3=OU=Postes,OU=RH,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs4=OU=Postes,OU=Secretariat,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs5=OU=Postes,OU=ServiceCertif,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs6=OU=Postes,OU=ServiceExper,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs7=OU=Postes,OU=ServiceForm,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs8=OU=Postes,OU=ServiceRef,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
DomainOUs9=OU=Postes,OU=ServiceTech,OU=Ecocert,DC=local,DC=ecocert4,DC=fr
SkipApplications=NO
SkipAdminPassword=NO
SkipUserData=YES
SkipComputerBackup=YES
SkipTimeZone=YES
TimeZoneName=Romance Standard Time
EventService=http://MDTECOCERT:9800
```

Cliquer sur **Apply > OK**. L'assistant doit proposer le domaine, la liste des OU et la sélection d'applications ; vérifier ces champs lors du prochain test. Saisir les identifiants autorisés à la jonction à l'invite, sans enregistrer de mot de passe dans le fichier. Vérifier que d'autres règles ne définissent pas un groupe de travail ou une OU contradictoire. L'OU `ServiceAccounts` n'est pas proposée dans cette liste.

`SkipUserData=YES` et `SkipComputerBackup=YES` conviennent à une VM de test vierge ; prévoir une sauvegarde et une migration pour tout poste contenant des données. Un compte ordinateur déjà présent dans une autre OU n'est pas automatiquement déplacé : vérifier son emplacement et les droits de réutilisation avant un nouveau test.

5.3. **Vérifier Bootstrap.ini.** Ce fichier sert à trouver le partage au démarrage ; le choix du domaine et des OU se configure dans **Rules**, pas dans Bootstrap.ini. Un partage déjà accessible peut conserver ses paramètres existants. Pour une nouvelle installation, l'exemple minimal est :

```ini
[Settings]
Priority=Default

[Default]
DeployRoot=\\MDTECOCERT\MDTShare$
```

Saisir les identifiants de lecture à l'invite. Modifier Bootstrap.ini nécessite de régénérer WinPE et de republier l'image ; une modification limitée à Rules/CustomSettings.ini est lue depuis le partage au lancement de l'assistant et ne nécessite normalement pas cette régénération.

5.4. **Activer le suivi des déploiements.** Dans Deployment Workbench, clic droit sur **ECOCERT Deployment Share > Properties > Monitoring**. Cocher **Enable monitoring for this deployment share**, puis cliquer sur **Apply** et **OK**. Laisser le temps à MDT de créer son service de suivi. Si l'option est déjà cochée, la conserver.

Dans **Properties > Rules**, vérifier que l'adresse du service apparaît :

```ini
EventService=http://MDTECOCERT:9800
```

Vérifier que le nom se résout depuis les clients et qu'ils peuvent joindre le port TCP 9800. Ne pas ajouter une deuxième ligne `EventService` si elle est déjà présente. Le port TCP 9801 sert par défaut aux données de suivi ; vérifier les ports réellement configurés et les règles applicables avant toute modification du pare-feu.

Dans l'arborescence du partage, cliquer sur **Monitoring**, puis clic droit > **Refresh**. La liste présente les postes ayant communiqué avec le service, leur état, l'étape et la progression disponibles. Un poste dont l'état final n'a pas été reçu peut conserver une information ancienne ; consulter le poste et les journaux avant de conclure. Les déploiements terminés avant l'activation ne sont pas nécessairement présents. Le suivi sert à voir l'état des machines, pas à identifier avec certitude la personne qui a lancé le déploiement.

Sur la machine cliente Windows, chercher `BDD.log` dans `C:\Windows\Temp\DeploymentLogs` après le déploiement, ou dans `C:\MININT\SMSOSD\OSDLOGS` pendant l'installation ; sous WinPE, vérifier `X:\MININT\SMSOSD\OSDLOGS`. Les journaux peuvent contenir des informations sensibles. Une liste vide peut simplement signifier qu'aucun client n'a encore transmis d'événement depuis l'activation.

[Documentation Microsoft : activation du suivi MDT](https://learn.microsoft.com/en-us/windows/deployment/deploy-windows-mdt/deploy-a-windows-10-image-using-mdt) · [Ports et service de suivi](https://learn.microsoft.com/en-us/intune/configmgr/mdt/mdt-windows-powershell-cmdlets).

## 6. Générer WinPE et publier l'image dans WDS

6.1. Dans **Properties > General** du partage, conserver la plateforme x64 et désactiver x86 si elle n'est pas utilisée. Dans **Windows PE**, sélectionner x64 et vérifier que la génération de l'image Lite Touch est activée. Vérifier la sélection des pilotes réseau et stockage à la section 3.

6.2. Clic droit sur le partage > **Update Deployment Share** > **Completely regenerate the boot images** > **Next**. À la fin, vérifier que les fichiers suivants existent :

```powershell
Get-ChildItem 'S:\DeploymentShare\Boot\LiteTouchPE_x64.*'
```

6.3. Ouvrir **Services de déploiement Windows > Serveurs > MDTECOCERT > Images de démarrage**. Clic droit **Ajouter une image de démarrage**, sélectionner `S:\DeploymentShare\Boot\LiteTouchPE_x64.wim`, nommer l'image `ECOCERT LiteTouch x64`, puis terminer. Lors d'une régénération ultérieure, remplacer l'ancienne image WDS par la nouvelle avec la console avant de tester.

## 7. Configuration PXE existante sur Kea

7.1. **Architecture.** DHCPECOCERT héberge Kea DHCP sur `172.16.54.2` ; MDTECOCERT héberge WDS sur `172.16.54.4`. Les classes ci-dessous sont présentes dans le fichier `/etc/kea/kea-dhcp4.conf` communiqué le 16/11/2026. Elles sont déclarées dans l'objet `Dhcp4`, tandis que les sous-réseaux restent chargés par l'index `/etc/kea/subnets/annuaires-reseaux.conf`.

**Lecture commentée du bloc.** Les commentaires ci-dessous expliquent chaque partie ; ils servent à la lecture et ne font pas partie de l'extrait à copier.

```jsonc
// Liste des règles qui identifient les clients PXE
"client-classes": [
    {
        // Classe des clients qui annoncent un démarrage BIOS
        "name": "PXE-BIOS-x64",
        // Option 60 : commence par PXEClient ; option 93 : 0x0000 (BIOS)
        "test": "substring(option[60].hex,0,9) == 'PXEClient' and option[93].hex == 0x0000",
        // Adresse du serveur de démarrage WDS : MDTECOCERT
        "next-server": "172.16.54.4",
        // Programme de démarrage WDS pour BIOS
        "boot-file-name": "boot\\x64\\wdsnbp.com"
    },
    {
        // Classe des clients annonçant l'une des deux valeurs UEFI/EBC prévues
        "name": "PXE-UEFI-x64",
        // Option 60 : PXEClient ; option 93 : 0x0007 ou 0x0009
        "test": "substring(option[60].hex,0,9) == 'PXEClient' and (option[93].hex == 0x0007 or option[93].hex == 0x0009)",
        // Même serveur WDS pour les clients UEFI
        "next-server": "172.16.54.4",
        // Programme de démarrage EFI indiqué au client
        "boot-file-name": "boot\\x64\\wdsmgfw.efi",
        "option-data": [
            // Option 60 configurée dans la réponse de cette classe UEFI
            { "name": "vendor-class-identifier", "data": "PXEClient" }
        ]
    }
],
```

**Extrait de configuration sans commentaires :**

```json
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
],
```

Cet extrait est un élément de l'objet `Dhcp4`, pas un fichier JSON complet. Les doubles barres obliques inverses sont nécessaires dans les chaînes JSON. L'option client 60 sert au test du préfixe `PXEClient`, tandis que l'option 93 est utilisée pour distinguer les architectures déclarées par les clients. La classe UEFI contient également une option 60 dans la réponse : ce réglage est conservé tel qu'observé et doit être vérifié dans le contexte PXE utilisé.

7.2. **Portée et validation.** Ces classes sont déclarées globalement : selon les requêtes et les paramètres des sous-réseaux, elles peuvent concerner d'autres clients PXE que la VM de test. Ne pas les ajouter une seconde fois, ni modifier la configuration fonctionnelle sans vérifier la portée, la version de Kea et les sauvegardes. Le déploiement d'une VM BIOS a atteint le bureau Windows ; le fonctionnement UEFI reste à confirmer par une recette dédiée.

```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl status kea-dhcp4-server --no-pager
sudo journalctl -u kea-dhcp4-server -n 50 --no-pager
```

Le test `kea-dhcp4 -t` vérifie la configuration et ses inclusions ; il ne prouve pas la réussite d'un démarrage PXE. En cas de modification ultérieure, sauvegarder au préalable le fichier principal et ses inclusions, ne redémarrer le service qu'après un test réussi, puis tester le DHCP existant et les démarrages BIOS/UEFI.

7.3. **Vérifier le DNS réellement distribué.** Le fichier principal communiqué indique `172.16.54.51, 1.1.1.1` pour `domain-name-servers`, tandis que la matrice de cette documentation indique `172.16.54.1` pour ADECOCERT. Une valeur propre à un sous-réseau peut aussi modifier les paramètres reçus. Avant toute modification, identifier le rôle de `172.16.54.51`, vérifier les inclusions et contrôler sur le client les DNS effectifs avec `ipconfig /all`, puis la résolution des enregistrements AD. Ne pas remplacer ces adresses sans connaître l'architecture DNS réelle.

7.4. **Conformité SP4.** Le sujet demande un sous-réseau dédié et les options DHCP 66/67. Les champs Kea `next-server` et `boot-file-name` configurent respectivement l'adresse du serveur et le nom de fichier dans les champs BOOTP ; ils ne prouvent pas à eux seuls que les options DHCP 66/67 sont émises. Vérifier la réponse sur le réseau avec une capture DHCP et clarifier l'attendu avec l'enseignant. Les relais Cisco réellement en place et la méthode retenue pour les clients de chaque réseau restent à confirmer. Microsoft recommande les relais IP pour un scénario WDS mixte BIOS/UEFI : [dépannage Microsoft WDS](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/invalid-boot-file-received-error). Référence Kea : [manuel DHCPv4](https://kea.readthedocs.io/en/stable/arm/dhcp4-srv.html).

## 8. Recette du déploiement

8.1. Créer deux VM de test vides dans Proxmox ou utiliser les VM clientes VirtualBox : l'une en **SeaBIOS**, l'autre en **OVMF**, connectées au réseau de test ayant accès à DHCP et à WDS. Une carte réseau prise en charge par WinPE et un disque cible vierge sont nécessaires.

Pour VirtualBox en BIOS, laisser le disque dur avant le réseau dans l'ordre de démarrage. Au premier démarrage d'un disque vierge, utiliser le menu temporaire **F12 > l (LAN)** si nécessaire ; après application de l'image, laisser la VM redémarrer sur le disque. Retirer l'ISO Windows du lecteur virtuel si elle détourne le démarrage, sans supprimer le fichier ISO ou le disque de la VM. Si le disque ne démarre pas, examiner l'erreur et les journaux avant de relancer une séquence susceptible de le reformater.

8.2. Démarrer chaque VM par PXE, choisir `ECOCERT LiteTouch x64`, puis saisir les identifiants de `svc-mdt-read` si demandés. Dans l'assistant MDT, choisir `DEPLOY-W10`, nommer la machine, renseigner le domaine et le compte de jonction, choisir l’OU proposée, saisir un compte de jonction autorisé, puis sélectionner les applications correspondant au service. Pour une installation standard, choisir **Do not capture an image of this computer** à l’étape de capture. Laisser la séquence installer Windows et redémarrer.

| Contrôle | Résultat attendu | Résultat / preuve |
| :--- | :--- | :--- |
| Bail DHCP | Adresse et passerelle cohérentes avec le réseau de test ; DNS AD accessible | À renseigner |
| Démarrage BIOS | WDS puis LiteTouch s'affichent | À renseigner |
| Démarrage UEFI | WDS puis LiteTouch s'affichent | À renseigner |
| Installation Windows | Bureau Windows accessible et aucun échec MDT | À renseigner |
| Domaine | Machine visible dans l'OU de test et connexion domaine fonctionnelle | À renseigner |
| Applications | Logiciels du service installé présents | À renseigner |
| Pilotes | Réseau et stockage fonctionnels ; gestionnaire de périphériques contrôlé | À renseigner |

Répéter les tests pour les trois profils applicatifs et un autre modèle de matériel si disponible. Conserver les captures et les journaux pour la présentation BTS.

## 9. Dépannage

| Symptôme | Vérification |
| :--- | :--- |
| Aucun bail DHCP | VLAN, trunk, bridge Proxmox, SVI et relais ; `journalctl -u kea-dhcp4-server`. |
| Bail reçu, WDS absent | Vérifier le second relais, le service WDS et les règles réseau UDP 67/68, 69 et 4011. TFTP utilise aussi des ports de transfert négociés. |
| WinPE sans réseau ou sans disque | Ajouter le pilote réseau ou stockage au profil WinPE, régénérer l'image et la remplacer dans WDS. |
| Accès MDT refusé | Vérifier résolution DNS, TCP 445 et droits SMB/NTFS de `svc-mdt-read`. |
| Application : erreur MSI `1619` | Vérifier le nom exact du MSI, son dossier de travail dans le partage et les droits de lecture ; consulter `BDD.log`. |
| Après redémarrage, retour PXE | Vérifier démarrage disque, média optique et mode BIOS/UEFI ; ne pas effacer le disque pour diagnostiquer. |
| Échec d'une séquence | Examiner `BDD.log` dans `X:\MININT\SMSOSD\OSDLOGS` pendant WinPE ou `C:\MININT\SMSOSD\OSDLOGS` pendant l'installation ; après fin, vérifier aussi `C:\Windows\Temp\DeploymentLogs`. |
| BIOS détecté comme UEFI | Vérifier MDT 8456, ADK 2004 et l'application du correctif KB4564442. |

Sources : [Configuration MDT Microsoft](https://learn.microsoft.com/en-us/intune/configmgr/mdt/use-the-mdt), [démarrage PXE inter-réseaux](https://learn.microsoft.com/en-us/troubleshoot/mem/configmgr/os-deployment/boot-from-pxe-server), [BIOS et UEFI avec WDS](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/invalid-boot-file-received-error).
