
---
description: Configuration de l'architecture WinPE, du Deployment Share MDT et des options DHCP PXE pour le déploiement réseau (Windows Server 2019)
---

# Configuration du déploiement PXE (MDT / WDS / DHCP) — Windows Server 2019

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
- [4. Résolution des conflits de montage WIM](#4-resolution-des-conflits-de-montage-wim)
- [5. Configuration des options DHCP PXE (Kea)](#5-configuration-des-options-dhcp-pxe-kea)
- [6. Création des séquences de tâches](#6-creation-des-sequences-de-taches)
- [7. Test de déploiement](#7-test-de-deploiement)

## 2. Contexte

Cette fiche décrit la configuration fonctionnelle du déploiement PXE une fois les rôles **WDS** et **MDT** installés sur **MDTECOCERT** (`172.16.54.4`, **Windows Server 2019**). Elle couvre le paramétrage de l'architecture WinPE ciblée, la résolution des erreurs de compilation DISM rencontrées, la configuration des options PXE sur le serveur **DHCPECOCERT** (Kea DHCP, `172.16.54.2`), ainsi que la création des séquences de tâches pour les postes des différents départements d'ECOCERT.

## 3. Configuration de l'architecture WinPE

3.1. **Problème d'architecture par défaut.** Par défaut, le Workbench MDT tente de compiler les images de démarrage pour les architectures **x86** et **x64**. Si les composants WinPE x86 ne sont pas installés dans l'ADK, DISM échoue.

> [!note] "Erreur rencontrée"
>
> ```text
> Unable to open the specified WIM file
> DISM /Set-TargetPath failed, rc = 1
> ```
>
> Traduction : *"Le chemin d'accès spécifié est introuvable"*.

3.2. **Restriction de l'architecture cible à x64.** Dans le Deployment Workbench, ouvrir les propriétés du Deployment Share et décocher la génération de l'image x86 pour ne conserver que l'architecture **x64**.

```text title="Chemin dans la console"
Deployment Share Properties > Windows PE > Platform : x64 only
```

- **Onglet concerné :** `Windows PE`
- **Action :** décocher `Generate x86 boot image`, ne laisser cochée que la case `x64`

## 4. Résolution des conflits de montage WIM {#4-resolution-des-conflits-de-montage-wim}

4.1. **Nettoyage des points de montage fantômes.** Lorsqu'une génération échoue en cours de route, des points de montage WIM peuvent rester bloqués sur le volume `S:\`, empêchant toute nouvelle tentative.

```powershell title="Vérification des montages existants"
dism /get-mountedwiminfo
```

```powershell title="Nettoyage DISM"
dism /Cleanup-Mountpoints
```

- `/get-mountedwiminfo` : liste les images WIM actuellement montées (à vérifier avant nettoyage)
- `/Cleanup-Mountpoints` : purge les points de montage orphelins restés bloqués après un échec

4.2. **Régénération du Deployment Share en ligne de commande.** En cas de blocage ou de mauvaise interprétation de la console MMC, utiliser le module PowerShell MDT pour regénérer les images WinPE directement, sans passer par l'interface graphique.

```powershell title="Régénération via PowerShell MDT"
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "S:\DeploymentShare"
Update-MDTDeploymentShare -Path "DS001:" -Force -Verbose
```

- `Import-Module` : charge le module PowerShell MDT indispensable pour accéder au provider MDT
- `New-PSDrive` : monte le Deployment Share comme un lecteur PowerShell (accès via `DS001:`)
- `Update-MDTDeploymentShare` : régénère les images WinPE (`.wim`) à partir des composants ADK installés ; `-Force` force la recompilation complète

## 5. Configuration des options DHCP PXE (Kea)

5.1. **Déclaration de l'option 66 (serveur TFTP).** Sur le serveur **DHCPECOCERT** (Debian / Kea DHCP), ajouter le paramètre `next-server` (équivalent option 66) pointant vers l'adresse du serveur WDS/MDT, dans le bloc du subnet concerné.

```json title="/etc/kea/kea-dhcp4.conf"
"next-server": "172.16.54.4",
```

5.2. **Déclaration de l'option 67 (fichier d'amorçage).** Ajouter le nom du fichier d'amorçage réseau diffusé par WDS.

```json title="/etc/kea/kea-dhcp4.conf"
"boot-file-name": "boot\\x64\\wdsnbp.com",
```

- `next-server` : adresse IP du serveur TFTP/WDS (`172.16.54.4`)
- `boot-file-name` : nom du binaire d'amorçage réseau servi par WDS

5.3. **Validation de la syntaxe avant application.** Vérifier que le fichier de configuration JSON est valide avant tout redémarrage du service, pour éviter une coupure DHCP sur le réseau ECOCERT.

```bash title="Test de syntaxe"
kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
```

5.4. **Application de la configuration.** Redémarrer le service Kea DHCP pour appliquer les nouvelles options.

```bash title="Redémarrage du service"
systemctl restart kea-dhcp4-server
```

5.5. **Vérification du service après redémarrage.** Confirmer que le service est bien actif.

```bash title="Vérification du statut"
systemctl status kea-dhcp4-server
```

## 6. Création des séquences de tâches {#6-creation-des-sequences-de-taches}

6.1. **Création d'une Task Sequence par département.** Dans le Deployment Workbench, créer une nouvelle séquence de tâches de type **Standard Client Task Sequence** pour chaque profil de poste à déployer.

6.2. **Association de l'image et des pilotes.** Associer à chaque séquence l'image système source ainsi que les packs de pilotes correspondant au modèle de matériel ciblé.

## 7. Test de déploiement {#7-test-de-deploiement}

7.1. **Démarrage PXE sur une VM cliente.** Créer une machine virtuelle de test configurée pour démarrer en réseau (PXE) et vérifier qu'elle récupère bien le fichier `wdsnbp.com` puis l'image `LiteTouchPE_x64.wim`.

7.2. **Validation de la séquence complète.** Dérouler la séquence de tâches de bout en bout et valider l'installation finale du poste.