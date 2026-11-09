---
description: Procédure d'installation de l'autorité de certification step-ca et de son client sous Debian.
---

# Installation de step-ca

![Bannière ECOCERT](https://ecocert.bts.loutik.fr/assets/banniere_ecocert.png)

---

> [!note] Informations
>
> - **Auteur :** Équipe SRE
> - **Date :** 09/11/2026
> - **Domaine :** Debian

---

## 1. Sommaire

- [1. Sommaire](#1-sommaire)
- [2. Contexte](#2-contexte)
- [3. Installation de step-ca](#3-installation-de-step-ca)

## 2. Contexte

Déploiement de `step-ca`, une autorité de certification (CA) interne légère et sécurisée éditée par Smallstep. Ce composant PKI s'intègre au reste de l'infrastructure pour délivrer et gérer le cycle de vie des certificats X.509/TLS, garantissant ainsi la sécurisation des flux réseau intra-services et l'authentification des clients/serveurs au sein de l'environnement.

## 3. Installation de step-ca

3.1. **Installation des dépendances.** Mise à jour des dépôts locaux et installation des paquets nécessaires pour la gestion des clés GPG et des transferts sécurisés.

```bash
sudo apt update && sudo apt install -y --no-install-recommends curl gpg ca-certificates
```

* `--no-install-recommends` : Empêche l'installation de paquets optionnels pour garder un système minimaliste (KISS) et limiter la surface d'attaque.
* `curl` : Utilitaire de transfert réseau utilisé pour rapatrier la clé de signature.
* `gpg` : Outil de cryptographie GNU nécessaire au traitement des clés de dépôt.
* `ca-certificates` : Fournit les autorités de certification racines pour valider les connexions HTTPS lors des téléchargements.

3.2. **Ajout de la clé GPG et du dépôt.** Récupération de la clé de signature de l'éditeur Smallstep et déclaration du dépôt officiel pour Debian.

```bash title="add_repository.sh"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://packages.smallstep.com/keys/apt/repo-signing-key.gpg -o /etc/apt/keyrings/smallstep.asc
sudo chmod a+r /etc/apt/keyrings/smallstep.asc
sudo tee /etc/apt/sources.list.d/smallstep.sources <<EOF
Types: deb
URIs: https://packages.smallstep.com/stable/debian
Suites: debs
Components: main
Signed-By: /etc/apt/keyrings/smallstep.asc
EOF
```

3.3. **Installation des binaires.** Téléchargement et installation des paquets CLI et CA de Smallstep.

```bash title="install_step.sh"
sudo apt update && sudo apt -y install step-cli step-ca
```
