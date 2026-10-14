---
description: Intégration d'une architecture LDAPS (AD CS Core) sur un domaine existant pour GLPI.
---

# Déploiement et intégration LDAPS entre Active Directory (Windows Server 2025) et GLPI

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] Informations
>
> - **Auteur :** Amine KADA
> - **Date :** 12/10/2026
> - **Domaine :** Windows Serveur 2025 / Infrastructure

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Matrice d'adressage et prérequis](#3-matrice-dadressage-et-prerequis)
- [4. Validation de l'infrastructure Active Directory existante](#4-validation-de-linfrastructure-active-directory-existante)
- [5. Préparation et intégration du serveur Core (AD CS)](#5-preparation-et-integration-du-serveur-core-ad-cs)
- [6. Configuration de l'administration à distance et modèle de certificat](#6-configuration-de-ladministration-a-distance-et-modele-de-certificat)
- [7. Déploiement des objets d'annuaire (Comptes de service)](#7-deploiement-des-objets-dannuaire-comptes-de-service)
- [8. Intégration sur le serveur GLPI (Debian)](#8-integration-sur-le-serveur-glpi-debian)

## 2. Contexte

La présente procédure détaille l'implémentation d'une infrastructure d'authentification centralisée et sécurisée via LDAPS (LDAP over SSL - port TCP 636) entre un annuaire Active Directory existant et un serveur d'inventaire GLPI. Afin de respecter les principes de sécurité du moindre privilège (Tiering Model Microsoft), l'architecture s'appuie sur la séparation des rôles : le contrôleur de domaine (AD DS) existant est dissocié de la nouvelle autorité de certification d'entreprise (AD CS). Cette dernière est hébergée sur un nouveau serveur Windows Server 2025 Core, réduisant ainsi drastiquement l'empreinte mémoire et la surface d'attaque.

## 3. Matrice d'adressage et prérequis

| Rôle / Équipement | Nom d'hôte (FQDN) | OS | Rôle réseau / Port |
| :--- | :--- | :--- | :--- |
| `Contrôleur de domaine` | `adecocert.local.ecocert4.fr` | Windows Server 2025 (GUI) | AD DS, DNS (TCP/636, 53) |
| `Autorité de certif.` | `adcs-core.local.ecocert4.fr` | Windows Server 2025 (Core) | AD CS (TCP/135, 445) |
| `Serveur GLPI` | `glpiecocert.local.ecocert4.fr` | Debian 12 | Apache / PHP (TCP/80, 443) |

> [!note] Contrainte de déploiement
> Le domaine `local.ecocert4.fr` étant déjà en production, l'autorité de certification d'entreprise (AD CS) sera déployée sur un serveur dédié puis intégrée à la forêt existante sans perturber les services d'annuaire en cours.

## 4. Validation de l'infrastructure Active Directory existante

4.1. **Vérification de l'état du domaine.** S'assurer que le contrôleur de domaine existant est joignable et opérationnel avant l'intégration du nouveau serveur Core.

```powershell title="Check_ADDS.ps1"
Get-ADDomain -Identity "local.ecocert4.fr"
```

- `Get-ADDomain` : Valide la présence, le niveau fonctionnel et la joignabilité de la forêt existante `local.ecocert4.fr`.

## 5. Préparation et intégration du serveur Core (AD CS)

5.1. **Configuration système du serveur Core.** Renommer le nouveau serveur Core et l'intégrer au domaine existant depuis son interface en ligne de commande.

```powershell title="Integration_Core.ps1" hl_lines="2"
Rename-Computer -NewName "ADCS-CORE" -Restart
Add-Computer -DomainName "local.ecocert4.fr" -Credential "ECOCERT4\Administrateur" -Restart
```

- `Rename-Computer` : Modifie le nom d'hôte NetBIOS du serveur Core.
- `Add-Computer` : Attache la machine à l'infrastructure de domaine existante.

5.2. **Déploiement du rôle AD CS (Sans interface).** Installer le service de certificats en environnement restreint (Core) en tant qu'autorité d'entreprise liée à l'AD existant.

```powershell title="Install_ADCS.ps1" hl_lines="3-7"
Install-WindowsFeature ADCS-Cert-Authority

Install-AdcsCertificationAuthority -CAType EnterpriseRootCA `
  -CACommonName "Ecocert-Root-CA" `
  -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
  -KeyLength 4096 -HashAlgorithmName SHA256 `
  -ValidityPeriod Years -ValidityPeriodUnits 10 -Force

Restart-Service CertSvc
```

- `Install-WindowsFeature` : Exécuté volontairement sans l'argument `-IncludeManagementTools` sur la version Core.
- `-CAType EnterpriseRootCA` : Instancie une autorité directement rattachée et reconnue par l'Active Directory.
- `-KeyLength 4096` : Définit une taille de clé de chiffrement robuste (4096 bits) pour le certificat racine.

## 6. Configuration de l'administration à distance et modèle de certificat

6.1. **Installation des outils RSAT.** Installer les modules de gestion à distance sur le Contrôleur de Domaine (GUI) afin de piloter le serveur Core.

```powershell title="Install_RSAT.ps1"
Install-WindowsFeature RSAT-ADCS-Mgmt
```

- `RSAT-ADCS-Mgmt` : Remote Server Administration Tools spécifiques aux services de certificats (Fournit MMC `certsrv.msc`).

6.2. **Création du modèle LDAPS et publication.**

> [!note] Administration déléguée
> Lors de l'ouverture de `certsrv.msc` sur le DC existant, le service ciblera `localhost` et échouera. Il faut effectuer un clic droit sur "Autorité de certification (Local)" > **Recibler l'Autorité** > Spécifier `ADCS-CORE.local.ecocert4.fr`.

Utiliser `certtmpl.msc` (Connecté au Core) pour dupliquer le modèle *Authentification Kerberos* et définir le nom du sujet sur *Nom DNS* avec des droits d'inscription automatique pour le groupe *Contrôleurs de domaine*.

6.3. **Auto-inscription par GPO.** Configurer la GPO *Default Domain Controllers Policy* existante pour automatiser la demande et le renouvellement des certificats, puis forcer son application.

```powershell title="Force_GPO.ps1"
gpupdate /force
certutil -pulse
```

- `gpupdate` : Applique la nouvelle stratégie d'inscription automatique immédiatement sur le DC.
- `certutil -pulse` : Déclenche manuellement la création de la requête de certificat vers la nouvelle CA Core.

## 7. Déploiement des objets d'annuaire (Comptes de service)

7.1. **Provisionnement des comptes.** Création de l'arborescence (UO) et du compte de service GLPI avec des droits de lecture stricts dans l'AD existant.

```powershell title="Creation_Comptes.ps1" hl_lines="3-7"
New-ADOrganizationalUnit -Name "Services" -Path "DC=local,DC=ecocert4,DC=fr"

New-ADUser -Name "svc_glpi" -SamAccountName "svc_glpi" `
  -UserPrincipalName "svc_glpi@local.ecocert4.fr" `
  -Path "OU=Services,DC=local,DC=ecocert4,DC=fr" `
  -AccountPassword (ConvertTo-SecureString "StrongPassword123!" -AsPlainText -Force) `
  -Enabled $true -PasswordNeverExpires $true

(Get-ADUser svc_glpi).DistinguishedName
```

- `New-ADUser` : Cmdlet générant l'identité système dans l'Active Directory.
- `DistinguishedName` : Affiche le chemin d'accès absolu (DN) de l'utilisateur généré, indispensable pour paramétrer le Bind LDAP dans GLPI.

## 8. Intégration sur le serveur GLPI (Debian)

8.1. **Installation des dépendances OpenLDAP.** Préparation du système Linux hébergeant le service web.

```bash title="Install_Dependencies.sh"
sudo apt update
sudo apt install -y php-ldap php-bcmath ldap-utils openssl ca-certificates
```

- `php-ldap` : Module PHP indispensable pour le fonctionnement du plugin LDAP d'authentification externe.
- `ldap-utils` : Fournit les outils de diagnostic réseau (tel que `ldapsearch`).

8.2. **Déclaration de l'autorité racine.** Importation du certificat public CA (.cer ou .crt exporté depuis Windows) dans le magasin de confiance de Debian.

```bash title="Import_CA.sh" hl_lines="2"
sudo nano /usr/local/share/ca-certificates/ecocert-root-ca.crt
sudo update-ca-certificates
```

- `update-ca-certificates` : Recompile le magasin de confiance local pour autoriser la validation de la chaîne de signature TLS du contrôleur de domaine.

8.3. **Configuration du client et validation TLS.** Imposer la vérification stricte du certificat et tester la requête sécurisée.

```bash title="LDAPS_Test.sh"
echo -e "TLS_CACERT /etc/ssl/certs/ca-certificates.crt\nTLS_REQCERT demand" | sudo tee -a /etc/ldap/ldap.conf

ldapsearch -x -H ldaps://adecocert.local.ecocert4.fr:636 \
  -D "CN=svc_glpi,OU=Services,DC=local,DC=ecocert4,DC=fr" \
  -w "StrongPassword123!" \
  -b "DC=local,DC=ecocert4,DC=fr" "(sAMAccountName=Administrateur)" dn
```

- `TLS_REQCERT demand` : Rejette catégoriquement la connexion si le certificat du serveur AD n'est pas authentique ou s'il n'est pas signé par `Ecocert-Root-CA`.
- `-H ldaps://` : Force l'utilisation du protocole d'annuaire sécurisé (TCP/636) pour la requête.